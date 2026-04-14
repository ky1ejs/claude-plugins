#!/usr/bin/env bash
set -euo pipefail

# reply-to-comment.sh — Posts a reply to a PR review comment thread or top-level comment
#
# Usage:
#   bash reply-to-comment.sh --thread <PR_URL> <COMMENT_DATABASE_ID> <BODY>
#   bash reply-to-comment.sh --top-level <PR_URL> <BODY>
#
# Modes:
#   --thread     Reply to a review comment thread (inline code comment).
#                Uses firstCommentDatabaseId from fetch-comments.sh output.
#   --top-level  Post a new top-level comment on the PR conversation.
#
# Outputs the API response JSON to stdout. Errors go to stderr.
# Requires: gh (authenticated), jq

die() {
  echo "Error: $1" >&2
  exit 1
}

usage() {
  cat >&2 <<'EOF'
Usage:
  bash reply-to-comment.sh --thread <PR_URL> <COMMENT_DATABASE_ID> <BODY>
  bash reply-to-comment.sh --top-level <PR_URL> <BODY>

Examples:
  bash reply-to-comment.sh --thread https://github.com/org/repo/pull/123 12345678 "Good catch, fixed!"
  bash reply-to-comment.sh --top-level https://github.com/org/repo/pull/123 "All feedback addressed."
EOF
  exit 1
}

# --- Argument parsing ---

[[ $# -ge 1 ]] || usage

MODE="$1"
shift

case "$MODE" in
  --thread)
    [[ $# -eq 3 ]] || { echo "Error: --thread requires <PR_URL> <COMMENT_DATABASE_ID> <BODY>" >&2; usage; }
    PR_URL="$1"
    COMMENT_ID="$2"
    BODY="$3"
    ;;
  --top-level)
    [[ $# -eq 2 ]] || { echo "Error: --top-level requires <PR_URL> <BODY>" >&2; usage; }
    PR_URL="$1"
    BODY="$2"
    ;;
  *)
    echo "Error: Unknown mode '$MODE'" >&2
    usage
    ;;
esac

# --- Parse PR URL ---

if [[ ! "$PR_URL" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
  die "Invalid PR URL: $PR_URL (expected https://github.com/owner/repo/pull/123)"
fi

OWNER="${BASH_REMATCH[1]}"
REPO="${BASH_REMATCH[2]}"
PR_NUMBER="${BASH_REMATCH[3]}"

# --- Prerequisite checks ---

command -v gh >/dev/null 2>&1 || die "gh CLI is not installed"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated (run 'gh auth login')"

# --- Post the reply ---

case "$MODE" in
  --thread)
    # Reply to a review comment thread using the REST API
    gh api \
      "repos/${OWNER}/${REPO}/pulls/${PR_NUMBER}/comments/${COMMENT_ID}/replies" \
      -f body="$BODY"
    ;;
  --top-level)
    # Post a top-level comment on the PR (issue comment)
    gh api \
      "repos/${OWNER}/${REPO}/issues/${PR_NUMBER}/comments" \
      -f body="$BODY"
    ;;
esac
