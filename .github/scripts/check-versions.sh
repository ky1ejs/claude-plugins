#!/bin/bash
set -e

MARKETPLACE_FILE=".claude-plugin/marketplace.json"
ERRORS=()

# Get the previous commit
PREV_COMMIT="HEAD~1"
CURR_COMMIT="HEAD"

echo "Comparing $PREV_COMMIT to $CURR_COMMIT"
echo "=========================================="

# Get list of changed files
CHANGED_FILES=$(git diff --name-only "$PREV_COMMIT" "$CURR_COMMIT")

if [ -z "$CHANGED_FILES" ]; then
    echo "No files changed."
    exit 0
fi

echo "Changed files:"
echo "$CHANGED_FILES"
echo ""

# Function to get JSON value using jq-like parsing with grep/sed (no jq dependency)
get_json_value() {
    local file="$1"
    local key="$2"
    grep -o "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" "$file" 2>/dev/null | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/'
}

# Function to get nested metadata.version
get_metadata_version() {
    local file="$1"
    # Extract the metadata block and find version within it
    sed -n '/"metadata"/,/}/p' "$file" 2>/dev/null | grep -o '"version"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*:[[:space:]]*"\([^"]*\)".*/\1/'
}

# Function to get file content from a specific commit
get_file_at_commit() {
    local commit="$1"
    local file="$2"
    git show "$commit:$file" 2>/dev/null || echo ""
}

# Check if marketplace metadata changed (excluding plugins array)
check_marketplace_metadata() {
    echo "Checking marketplace metadata..."

    # Get old and new file contents
    OLD_CONTENT=$(get_file_at_commit "$PREV_COMMIT" "$MARKETPLACE_FILE")

    if [ -z "$OLD_CONTENT" ]; then
        echo "  Marketplace file is new, skipping metadata check."
        return
    fi

    # Create temp files for comparison
    OLD_TEMP=$(mktemp)
    NEW_TEMP=$(mktemp)

    echo "$OLD_CONTENT" > "$OLD_TEMP"
    cat "$MARKETPLACE_FILE" > "$NEW_TEMP"

    # Extract metadata fields (name, owner, metadata block) - exclude plugins
    OLD_NAME=$(get_json_value "$OLD_TEMP" "name")
    NEW_NAME=$(get_json_value "$NEW_TEMP" "name")

    OLD_OWNER=$(grep -o '"owner"[[:space:]]*:[[:space:]]*{[^}]*}' "$OLD_TEMP" 2>/dev/null | head -1 || echo "")
    NEW_OWNER=$(grep -o '"owner"[[:space:]]*:[[:space:]]*{[^}]*}' "$NEW_TEMP" 2>/dev/null | head -1 || echo "")

    OLD_DESC=$(sed -n '/"metadata"/,/}/p' "$OLD_TEMP" 2>/dev/null | grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 || echo "")
    NEW_DESC=$(sed -n '/"metadata"/,/}/p' "$NEW_TEMP" 2>/dev/null | grep -o '"description"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 || echo "")

    OLD_VERSION=$(get_metadata_version "$OLD_TEMP")
    NEW_VERSION=$(get_metadata_version "$NEW_TEMP")

    # Check if any metadata changed
    METADATA_CHANGED=false

    if [ "$OLD_NAME" != "$NEW_NAME" ]; then
        echo "  - name changed: '$OLD_NAME' -> '$NEW_NAME'"
        METADATA_CHANGED=true
    fi

    if [ "$OLD_OWNER" != "$NEW_OWNER" ]; then
        echo "  - owner changed"
        METADATA_CHANGED=true
    fi

    if [ "$OLD_DESC" != "$NEW_DESC" ]; then
        echo "  - description changed"
        METADATA_CHANGED=true
    fi

    if [ "$METADATA_CHANGED" = true ]; then
        if [ "$OLD_VERSION" = "$NEW_VERSION" ]; then
            ERRORS+=("Marketplace metadata changed but version was not bumped (still $OLD_VERSION)")
        else
            echo "  Version bumped: $OLD_VERSION -> $NEW_VERSION"
        fi
    else
        echo "  No metadata changes detected."
    fi

    rm -f "$OLD_TEMP" "$NEW_TEMP"
}

# Check if plugin files changed and version was bumped
check_plugin_versions() {
    echo ""
    echo "Checking plugin versions..."

    # Find all changed plugin directories
    CHANGED_PLUGINS=$(echo "$CHANGED_FILES" | grep "^plugins/" | cut -d'/' -f2 | sort -u || true)

    if [ -z "$CHANGED_PLUGINS" ]; then
        echo "  No plugin changes detected."
        return
    fi

    for plugin in $CHANGED_PLUGINS; do
        # Skip template
        if [ "$plugin" = "_template" ]; then
            echo "  Skipping _template plugin"
            continue
        fi

        PLUGIN_JSON="plugins/$plugin/.claude-plugin/plugin.json"

        if [ ! -f "$PLUGIN_JSON" ]; then
            echo "  Warning: $plugin has no plugin.json"
            continue
        fi

        echo "  Checking plugin: $plugin"

        # Get old plugin.json content
        OLD_PLUGIN_CONTENT=$(get_file_at_commit "$PREV_COMMIT" "$PLUGIN_JSON")

        if [ -z "$OLD_PLUGIN_CONTENT" ]; then
            echo "    New plugin, skipping version check."
            continue
        fi

        # Create temp files
        OLD_PLUGIN_TEMP=$(mktemp)
        echo "$OLD_PLUGIN_CONTENT" > "$OLD_PLUGIN_TEMP"

        OLD_PLUGIN_VERSION=$(get_json_value "$OLD_PLUGIN_TEMP" "version")
        NEW_PLUGIN_VERSION=$(get_json_value "$PLUGIN_JSON" "version")

        rm -f "$OLD_PLUGIN_TEMP"

        if [ "$OLD_PLUGIN_VERSION" = "$NEW_PLUGIN_VERSION" ]; then
            ERRORS+=("Plugin '$plugin' has changes but version was not bumped (still $OLD_PLUGIN_VERSION)")
        else
            echo "    Version bumped: $OLD_PLUGIN_VERSION -> $NEW_PLUGIN_VERSION"
        fi
    done
}

# Run checks
if echo "$CHANGED_FILES" | grep -q "^\.claude-plugin/marketplace\.json$"; then
    check_marketplace_metadata
else
    echo "Marketplace file not changed, skipping metadata check."
fi

check_plugin_versions

# Report results
echo ""
echo "=========================================="

if [ ${#ERRORS[@]} -gt 0 ]; then
    echo "FAILED: Version check errors found:"
    for error in "${ERRORS[@]}"; do
        echo "  - $error"
    done
    exit 1
else
    echo "PASSED: All version checks passed."
    exit 0
fi
