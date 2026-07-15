#!/usr/bin/env bash
set -euo pipefail

# post-review.sh — Posts a single PR review with inline comments + a summary body.
#
# Usage:
#   bash post-review.sh <PR_URL> <COMMENTS_JSON_FILE> <SUMMARY_FILE> [EVENT]
#
#   COMMENTS_JSON_FILE : path to a JSON array of findings, each:
#       { "path": "src/foo.ts", "line": 42, "side": "RIGHT",
#         "body": "…", "start_line": 40, "start_side": "RIGHT" }
#     - side defaults to "RIGHT" (the added/new version of the code).
#     - start_line/start_side are optional (for a multi-line comment range).
#   SUMMARY_FILE : path to a file whose contents become the review's summary body.
#   EVENT        : COMMENT (default) | APPROVE | REQUEST_CHANGES
#
# Why the validation step: GitHub's "create review" API is all-or-nothing — if a
# single comment points at a line that isn't part of the diff, the WHOLE review is
# rejected (422). So we compute the set of commentable (path, side, line) tuples
# from the actual diff and drop any finding that doesn't match, reporting what was
# dropped on stderr rather than losing the entire review.
#
# Works against github.com and GitHub Enterprise Server (host parsed from the URL).
# Outputs the created review's JSON to stdout. Requires: gh (authenticated), jq, awk

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWK_LIB="$SCRIPT_DIR/lib/diff-lines.awk"

die() { echo "Error: $1" >&2; exit 1; }

[[ $# -ge 3 ]] || die "Usage: bash post-review.sh <PR_URL> <COMMENTS_JSON_FILE> <SUMMARY_FILE> [EVENT]"
PR_URL="$1"
COMMENTS_FILE="$2"
SUMMARY_FILE="$3"
EVENT="${4:-COMMENT}"

[[ -f "$COMMENTS_FILE" ]] || die "comments file not found: $COMMENTS_FILE"
[[ -f "$SUMMARY_FILE" ]]  || die "summary file not found: $SUMMARY_FILE"
[[ -f "$AWK_LIB" ]]       || die "missing helper: $AWK_LIB"
case "$EVENT" in COMMENT|APPROVE|REQUEST_CHANGES) ;; *) die "EVENT must be COMMENT, APPROVE, or REQUEST_CHANGES" ;; esac

url_no_scheme="${PR_URL#*://}"
if [[ ! "$url_no_scheme" =~ ^([^/]+)/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
  die "Invalid PR URL: $PR_URL (expected https://<host>/owner/repo/pull/123)"
fi
HOST="${BASH_REMATCH[1]}"
OWNER="${BASH_REMATCH[2]}"
REPO="${BASH_REMATCH[3]}"
NUM="${BASH_REMATCH[4]}"

command -v gh >/dev/null 2>&1 || die "gh CLI is not installed"
command -v jq >/dev/null 2>&1 || die "jq is not installed"
command -v awk >/dev/null 2>&1 || die "awk is not installed"
gh auth status --hostname "$HOST" >/dev/null 2>&1 || die "gh is not authenticated for $HOST (run 'gh auth login --hostname $HOST')"

api() { gh api --hostname "$HOST" "$@"; }

# Normalize comments: default side to RIGHT, coerce line to a number.
comments=$(jq '[.[] | .side = (.side // "RIGHT") | .line = (.line|tonumber)]' "$COMMENTS_FILE") \
  || die "could not parse comments JSON (expected an array of {path,line,side?,body})"

# Build the set of commentable (path, side, line) tuples from the diff.
diff_text=$(api "repos/$OWNER/$REPO/pulls/$NUM" -H "Accept: application/vnd.github.v3.diff") \
  || die "could not fetch diff for PR #$NUM"
commentable=$(printf '%s\n' "$diff_text" \
  | awk -v MODE=commentable -f "$AWK_LIB" \
  | jq -R 'split("\t") | {path: .[0], side: .[1], line: (.[2]|tonumber)}' \
  | jq -s '.')

# Partition findings into valid (anchor is in the diff) and dropped.
valid=$(jq -n --argjson c "$comments" --argjson set "$commentable" \
  '[ $c[] | . as $x | select(any($set[]; .path==$x.path and .side==$x.side and .line==$x.line)) ]')
dropped=$(jq -n --argjson c "$comments" --argjson set "$commentable" \
  '[ $c[] | . as $x | select(any($set[]; .path==$x.path and .side==$x.side and .line==$x.line) | not) ]')

dropped_count=$(echo "$dropped" | jq 'length')
valid_count=$(echo "$valid" | jq 'length')

if [[ "$dropped_count" -gt 0 ]]; then
  echo "Warning: dropped $dropped_count comment(s) whose line is not part of the diff:" >&2
  echo "$dropped" | jq -r '.[] | "  - \(.path):\(.line) [\(.side)] — \(.body[0:80])"' >&2
fi

# Assemble the review comments payload (only fields the API accepts).
comments_payload=$(echo "$valid" | jq '[.[] | {path, line, side, body}
  + (if .start_line then {start_line: (.start_line|tonumber), start_side: (.start_side // "RIGHT")} else {} end)]')

summary=$(cat "$SUMMARY_FILE")
# Pin the review to the current head commit so anchors resolve against the diff we validated against.
head_sha=$(api "repos/$OWNER/$REPO/pulls/$NUM" --jq '.head.sha')

payload=$(jq -n \
  --arg commit "$head_sha" \
  --arg body "$summary" \
  --arg event "$EVENT" \
  --argjson comments "$comments_payload" \
  '{commit_id: $commit, body: $body, event: $event, comments: $comments}')

echo "Posting review to $OWNER/$REPO#$NUM on $HOST ($valid_count inline comment(s), event=$EVENT)..." >&2
echo "$payload" | api "repos/$OWNER/$REPO/pulls/$NUM/reviews" --input -
