#!/usr/bin/env bash
set -euo pipefail

# fetch-comments.sh — Fetches all unresolved PR review threads via GitHub GraphQL API
#
# Usage: bash fetch-comments.sh <PR_URL>
# Example: bash fetch-comments.sh https://github.com/org/repo/pull/123
#
# Outputs structured JSON to stdout. Errors go to stderr.
# Requires: gh (authenticated), jq

# --- Helpers ---

die() {
  echo "Error: $1" >&2
  exit 1
}

warn() {
  echo "Warning: $1" >&2
}

# --- Argument validation ---

if [[ $# -ne 1 ]]; then
  echo "Usage: bash fetch-comments.sh <PR_URL>" >&2
  echo "Example: bash fetch-comments.sh https://github.com/org/repo/pull/123" >&2
  exit 1
fi

PR_URL="$1"

# Parse owner, repo, and PR number from URL
if [[ ! "$PR_URL" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
  die "Invalid PR URL: $PR_URL (expected https://github.com/owner/repo/pull/123)"
fi

OWNER="${BASH_REMATCH[1]}"
REPO="${BASH_REMATCH[2]}"
PR_NUMBER="${BASH_REMATCH[3]}"

# --- Prerequisite checks ---

command -v gh >/dev/null 2>&1 || die "gh CLI is not installed"
command -v jq >/dev/null 2>&1 || die "jq is not installed"
gh auth status >/dev/null 2>&1 || die "gh is not authenticated (run 'gh auth login')"

# --- GraphQL query ---

QUERY='
query($owner: String!, $repo: String!, $number: Int!, $threadCursor: String) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      number
      state
      title
      url
      headRefName
      baseRefName
      reviewThreads(first: 100, after: $threadCursor) {
        totalCount
        pageInfo {
          hasNextPage
          endCursor
        }
        nodes {
          id
          path
          line
          startLine
          originalLine
          originalStartLine
          diffSide
          isResolved
          isOutdated
          comments(first: 100) {
            pageInfo {
              hasNextPage
            }
            nodes {
              databaseId
              id
              body
              author {
                login
              }
              createdAt
              diffHunk
            }
          }
        }
      }
      comments(first: 100) {
        nodes {
          databaseId
          id
          body
          author {
            login
          }
          createdAt
        }
      }
      reviews(first: 100) {
        nodes {
          databaseId
          id
          body
          state
          author {
            login
          }
          createdAt
        }
      }
    }
  }
}
'

# --- Fetch with pagination ---

all_threads="[]"
all_top_level_comments="[]"
pr_metadata=""
total_thread_count=0
cursor=""
page=0

while true; do
  page=$((page + 1))

  # Build gh api graphql command
  cmd=(gh api graphql
    -f query="$QUERY"
    -F owner="$OWNER"
    -F repo="$REPO"
    -F number="$PR_NUMBER"
  )

  # Add cursor for subsequent pages
  if [[ -n "$cursor" ]]; then
    cmd+=(-f threadCursor="$cursor")
  fi

  result=$("${cmd[@]}") || die "GraphQL query failed"

  # Check for GraphQL errors
  errors=$(echo "$result" | jq -r '.errors[0].message // empty')
  if [[ -n "$errors" ]]; then
    die "GraphQL error: $errors"
  fi

  # Check PR exists
  pr_null=$(echo "$result" | jq '.data.repository.pullRequest == null')
  if [[ "$pr_null" == "true" ]]; then
    die "PR #$PR_NUMBER not found in $OWNER/$REPO"
  fi

  # Extract PR metadata (only on first page)
  if [[ $page -eq 1 ]]; then
    pr_metadata=$(echo "$result" | jq '{
      number: .data.repository.pullRequest.number,
      state: .data.repository.pullRequest.state,
      title: .data.repository.pullRequest.title,
      url: .data.repository.pullRequest.url,
      headRefName: .data.repository.pullRequest.headRefName,
      baseRefName: .data.repository.pullRequest.baseRefName
    }')

    total_thread_count=$(echo "$result" | jq '.data.repository.pullRequest.reviewThreads.totalCount')

    # Extract top-level comments (only on first page, they don't paginate with threads)
    all_top_level_comments=$(echo "$result" | jq '[
      .data.repository.pullRequest.comments.nodes[] |
      {
        databaseId: .databaseId,
        id: .id,
        body: .body,
        author: (.author.login // "ghost"),
        createdAt: .createdAt
      }
    ]')

    # Extract review body comments (the high-level text reviewers write when submitting a review)
    # These are separate from inline thread comments and often contain important feedback
    all_review_body_comments=$(echo "$result" | jq '[
      .data.repository.pullRequest.reviews.nodes[] |
      select(.body != null and .body != "") |
      {
        databaseId: .databaseId,
        id: .id,
        body: .body,
        state: .state,
        author: (.author.login // "ghost"),
        createdAt: .createdAt
      }
    ]')
  fi

  # Extract thread nodes from this page
  page_threads=$(echo "$result" | jq '[
    .data.repository.pullRequest.reviewThreads.nodes[] |
    {
      id: .id,
      path: .path,
      line: .line,
      startLine: .startLine,
      originalLine: .originalLine,
      originalStartLine: .originalStartLine,
      diffSide: .diffSide,
      isResolved: .isResolved,
      isOutdated: .isOutdated,
      firstCommentDatabaseId: (.comments.nodes[0].databaseId // null),
      comments: [
        .comments.nodes[] |
        {
          databaseId: .databaseId,
          id: .id,
          body: .body,
          author: (.author.login // "ghost"),
          createdAt: .createdAt,
          diffHunk: .diffHunk
        }
      ]
    }
  ]')

  # Warn if any thread has truncated comments
  truncated=$(echo "$result" | jq '[.data.repository.pullRequest.reviewThreads.nodes[] | select(.comments.pageInfo.hasNextPage == true)] | length')
  if [[ "$truncated" -gt 0 ]]; then
    warn "$truncated thread(s) have more than 100 comments (truncated)"
  fi

  # Accumulate threads
  all_threads=$(echo "$all_threads" "$page_threads" | jq -s '.[0] + .[1]')

  # Check for next page
  has_next=$(echo "$result" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.hasNextPage')
  if [[ "$has_next" != "true" ]]; then
    break
  fi

  cursor=$(echo "$result" | jq -r '.data.repository.pullRequest.reviewThreads.pageInfo.endCursor')
done

# --- Build final output ---

# Filter to unresolved threads and compute counts
unresolved_threads=$(echo "$all_threads" | jq '[.[] | select(.isResolved == false)]')
resolved_count=$(echo "$all_threads" | jq '[.[] | select(.isResolved == true)] | length')
unresolved_count=$(echo "$unresolved_threads" | jq 'length')
top_level_count=$(echo "$all_top_level_comments" | jq 'length')
review_body_count=$(echo "$all_review_body_comments" | jq 'length')

# Assemble final JSON
jq -n \
  --argjson pr "$pr_metadata" \
  --argjson unresolvedThreads "$unresolved_threads" \
  --argjson topLevelComments "$all_top_level_comments" \
  --argjson reviewBodyComments "$all_review_body_comments" \
  --argjson totalThreads "$total_thread_count" \
  --argjson unresolvedCount "$unresolved_count" \
  --argjson resolvedCount "$resolved_count" \
  --argjson topLevelCount "$top_level_count" \
  --argjson reviewBodyCount "$review_body_count" \
  '{
    pr: $pr,
    unresolvedThreads: $unresolvedThreads,
    topLevelComments: $topLevelComments,
    reviewBodyComments: $reviewBodyComments,
    meta: {
      totalThreads: $totalThreads,
      unresolvedThreads: $unresolvedCount,
      resolvedThreads: $resolvedCount,
      topLevelComments: $topLevelCount,
      reviewBodyComments: $reviewBodyCount
    }
  }'
