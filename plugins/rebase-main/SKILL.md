---
name: rebase-main
description: Rebases the current branch on the latest default branch (main, master, etc.), resolving any merge conflicts automatically. Detects the default branch and remote, fetches latest, performs rebase, and handles conflicts file-by-file.
---

# Rebase on Default Branch

Rebases the current branch onto the latest default branch, resolving conflicts along the way.

## Process

### 1. Pre-flight Checks

- Run `git status` to confirm there are no uncommitted changes. If there are, stop and ask the user to commit or stash first.
- Detect the default branch and remote:
  ```bash
  git remote show origin | grep 'HEAD branch' | sed 's/.*: //'
  ```
  This gives you the default branch name (e.g., `main`, `master`, `develop`). If the remote is not `origin`, detect it with `git remote`. Use whatever remote and branch name you find throughout the rest of this process — don't assume `origin/main`.
- Confirm the current branch is NOT the default branch. If it is, stop — there's nothing to rebase.

### 2. Fetch Latest Default Branch

```bash
git fetch <remote> <default-branch>
```

### 3. Start Rebase

```bash
git rebase <remote>/<default-branch>
```

If the rebase completes without conflicts, report success with the number of commits replayed and exit.

### 4. Resolve Conflicts (loop until rebase completes)

When conflicts occur, for each conflicted file:

1. Run `git diff --name-only --diff-filter=U` to list all conflicted files.
2. For each conflicted file:
   a. Read the file to see the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).
   b. Understand both sides:
      - **ours** (during rebase) = the commit being replayed (your branch's changes)
      - **theirs** (during rebase) = the default branch (the new base)
   c. Resolve the conflict following the rules below.
   d. Stage the resolved file with `git add <file>`.
3. After all files in the current step are resolved, continue the rebase:
   ```bash
   git rebase --continue
   ```
4. If new conflicts arise on subsequent commits, repeat from step 1.

### 5. Post-rebase Verification

After the rebase completes:
- Run `git log --oneline <remote>/<default-branch>..HEAD` to show the replayed commits.
- Report the result to the user.

## Conflict Resolution Rules

### General Rule

Default to the default branch (theirs during rebase) as the source of truth, then re-apply local branch changes on top only when they can be preserved cleanly.

- Preserve the default branch's implementation, architecture, and public behavior.
- Re-apply local changes only when they are additive and don't conflict with the intent of the default branch's changes.
- If both sides made meaningful but incompatible changes, stop and ask the user.

### Auto-generated Files

For files that are auto-generated (e.g., `schema.graphql`, Prisma client, Apollo codegen output):
- Accept the default branch version entirely.
- After the rebase completes, re-run the relevant codegen commands to incorporate local changes.

### Lock Files & Dependencies

For `bun.lock`, `package-lock.json`, `yarn.lock`, or similar:
- Accept the default branch version.
- After the rebase, re-run the package manager install to regenerate the lock file if local changes added/changed dependencies.

## When to Stop and Ask

- Conflicting business logic where both sides made intentional, incompatible changes.
- Deleted vs. modified conflicts where the intent is unclear.
- More than 20 conflicted files in a single rebase step (likely a sign of divergence that needs human judgment).

## Output

When complete, report:
- Total commits replayed
- Files that had conflicts and how they were resolved
- Any codegen or install commands that were re-run
- Any conflicts that required user input
