#!/usr/bin/env bash
set -euo pipefail

# fetch-pr.sh — Fetches a PR's metadata, changed-file list, and diff for review.
#
# Usage: bash fetch-pr.sh <PR_URL>
# Example: bash fetch-pr.sh https://github.com/org/repo/pull/123
#          bash fetch-pr.sh https://github.mycompany.com/org/repo/pull/123
#
# Works against github.com and GitHub Enterprise Server. The host is parsed from
# the PR URL and passed to `gh api --hostname`, which routes to the correct
# REST endpoints. You must be authenticated to that host.
#
# Outputs a single JSON object to stdout:
#   {
#     "pr":    { number, title, body, state, isDraft, merged,
#                baseRefName, headRefName, headSha, url,
#                host, owner, repo, changedFiles, additions, deletions },
#     "files": [ { path, status, additions, deletions } ],
#     "diff":  "<raw unified diff>",
#     "annotatedDiff": "<diff with an 'old new' line-number gutter>"
#   }
#
# The annotatedDiff exists so the reviewer can anchor comments to exact line
# numbers. Only lines shown in the diff are commentable on GitHub — post-review.sh
# enforces that, but reading the right number up front avoids dropped comments.
#
# Requires: gh (authenticated), jq, awk

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWK_LIB="$SCRIPT_DIR/lib/diff-lines.awk"

die() { echo "Error: $1" >&2; exit 1; }

[[ $# -eq 1 ]] || { echo "Usage: bash fetch-pr.sh <PR_URL>" >&2; exit 1; }
PR_URL="$1"

# Parse host/owner/repo/number; accept URLs with or without a scheme.
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
[[ -f "$AWK_LIB" ]] || die "missing helper: $AWK_LIB"
gh auth status --hostname "$HOST" >/dev/null 2>&1 || die "gh is not authenticated for $HOST (run 'gh auth login --hostname $HOST')"

api() { gh api --hostname "$HOST" "$@"; }

# --- PR metadata ---
pr_json=$(api "repos/$OWNER/$REPO/pulls/$NUM") || die "could not fetch PR #$NUM from $OWNER/$REPO"

pr_meta=$(echo "$pr_json" | jq \
  --arg host "$HOST" --arg owner "$OWNER" --arg repo "$REPO" '{
    number: .number,
    title: .title,
    body: (.body // ""),
    state: .state,
    isDraft: .draft,
    merged: .merged,
    baseRefName: .base.ref,
    headRefName: .head.ref,
    headSha: .head.sha,
    url: .html_url,
    host: $host, owner: $owner, repo: $repo,
    changedFiles: .changed_files,
    additions: .additions,
    deletions: .deletions
  }')

# --- Changed files (paginated) ---
files_json=$(api --paginate "repos/$OWNER/$REPO/pulls/$NUM/files" | jq -s 'add // [] | [
  .[] | { path: .filename, status: .status, additions: .additions, deletions: .deletions }
]')

# --- Diff (raw), then an annotated copy with line-number gutter ---
diff_text=$(api "repos/$OWNER/$REPO/pulls/$NUM" -H "Accept: application/vnd.github.v3.diff") \
  || die "could not fetch diff for PR #$NUM"
annotated=$(printf '%s\n' "$diff_text" | awk -v MODE=annotate -f "$AWK_LIB")

jq -n \
  --argjson pr "$pr_meta" \
  --argjson files "$files_json" \
  --arg diff "$diff_text" \
  --arg annotatedDiff "$annotated" \
  '{ pr: $pr, files: $files, diff: $diff, annotatedDiff: $annotatedDiff }'
