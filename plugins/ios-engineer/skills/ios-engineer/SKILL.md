---
name: ios-engineer
description: You MUST use this skill for ANY changes you make within to the iOS app. Senior iOS engineer with visual feedback capabilities via simulator MCP tools.
allowed-tools:
  - Read
  - Grep
  - Glob
  - Edit(ios/*)
  - Write(ios/*)
  - Bash(xcodebuild *)
  - Bash(xcrun simctl *)
  - Bash(git *)
  - Bash(./apollo-codegen*)
  - Task
  - mcp__ios-simulator__*
  - mcp__xcodebuild__*
---

# iOS Engineer

Senior iOS engineer with expertise in building iOS applications and gathering visual feedback via iOS Simulator MCP integration.

## Prerequisites

This skill requires external tools for simulator automation. Run the setup script:

```bash
.claude/plugins/ios-engineer/setup.sh
```

**Required dependencies:**
- **Xcode** - iOS development environment
- **Homebrew** - Package manager for macOS
- **pyenv** - Python version manager (fb-idb requires Python ≤3.13, not 3.14+)
- **idb-companion** - Facebook's iOS automation tool (`brew tap facebook/fb && brew install idb-companion`)
- **fb-idb** - Python client for IDB (`pip install fb-idb`)
- **Node.js** - For running MCP servers via npx

The setup script will configure pyenv to use Python 3.13.5 for this project via `.python-version`.

## Visual Feedback Loop

This skill has access to iOS Simulator MCP tools that enable a powerful feedback loop:

### Available MCP Tools

| Tool | Purpose |
|------|---------|
| `mcp__ios-simulator__ui_view` | Take screenshot and return image data for analysis |
| `mcp__ios-simulator__ui_describe_all` | Get full accessibility tree of current screen |
| `mcp__ios-simulator__ui_describe_point` | Describe element at specific coordinates |
| `mcp__ios-simulator__ui_tap` | Tap at coordinates (x, y) |
| `mcp__ios-simulator__ui_swipe` | Swipe gesture between coordinates |
| `mcp__ios-simulator__ui_type` | Type text into focused field |
| `mcp__ios-simulator__screenshot` | Save screenshot to file |
| `mcp__ios-simulator__record_video` | Record screen video |
| `mcp__ios-simulator__launch_app` | Launch app by bundle ID |
| `mcp__ios-simulator__install_app` | Install .app bundle |
| `mcp__xcodebuild__*` | Build, test, and deployment tools |

### Screenshots Directory

Screenshots and recordings are saved to `ios/.screenshots/` (gitignored). This directory:
- Keeps simulator artifacts organized within the iOS directory
- Is automatically used by the MCP server via `IOS_SIMULATOR_MCP_DEFAULT_OUTPUT_DIR`
- Can be cleaned up with `ios/.screenshots/cleanup.sh` (deletes files older than 7 days)
- Use `ios/.screenshots/cleanup.sh --all` to delete everything

### Workflow: Build-See-Iterate

After making UI changes, follow this workflow:

1. **Build the app**
   ```
   Use mcp__xcodebuild tools or:
   xcodebuild -scheme Cut -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
   ```

2. **Launch in simulator**
   ```
   mcp__ios-simulator__launch_app with bundle ID: com.watch.cut
   ```

3. **Navigate to the changed screen**
   - Use deep links: `xcrun simctl openurl booted "cut://..."`
   - Or use `ui_tap` to navigate through the UI

4. **Capture and analyze**
   - Use `ui_view` to get screenshot for visual analysis
   - Use `ui_describe_all` to verify accessibility tree
   - Verify elements exist and are correctly positioned

5. **Iterate if needed**
   - If something looks wrong, make code changes and repeat

### When to Use Visual Feedback

**Always use** visual feedback for:
- New UI components or screens
- Layout changes (spacing, alignment, sizing)
- Animation or transition work
- Accessibility changes
- Dark mode / appearance changes

**Optional** for:
- Business logic changes with no UI impact
- GraphQL query/mutation changes (test via backend)
- Minor text changes (can verify via accessibility tree)

## Core Patterns

### Coding Best Practices
- Prefer composition over inheritance
- Extract reusable views into separate files

### Accessibility
- Always set `accessibilityIdentifier` for testable elements
- Use semantic labels for VoiceOver
- Test with `ui_describe_all` to verify hierarchy

## Code Quality Workflow

After completing ANY iOS work:

1. **Build** - Verify no compilation errors

2. **Visual verification** - Use simulator MCP tools to see your changes

3. **Accessibility check** - Use `ui_describe_all` to verify element tree

## Simulator Automation Examples

### Take screenshot after navigation
```
1. mcp__ios-simulator__launch_app(bundleId: "com.watch.cut")
2. Wait 3 seconds for app load
3. mcp__ios-simulator__ui_view() - analyze the home screen
4. mcp__ios-simulator__ui_tap(x: 200, y: 400) - tap on element
5. mcp__ios-simulator__ui_view() - verify navigation worked
```

### Verify accessibility
```
1. mcp__ios-simulator__ui_describe_all() - get full element tree
2. Verify expected elements are present with correct labels
3. Check for missing accessibility identifiers
```

### Test dark mode
```bash
xcrun simctl ui booted appearance dark
# Then use ui_view to capture and compare
```
