# Claude Plugins

Personal Claude Code plugin marketplace.

## Installation

Add this marketplace to your Claude Code settings:

```json
{
  "extraKnownMarketplaces": {
    "ky1ejs-plugins": {
      "source": {
        "source": "github",
        "repo": "ky1ejs/claude-plugins"
      }
    }
  }
}
```

Then install plugins:

```
/plugin install ios-engineer@ky1ejs-plugins
```

## Available Plugins

### spec-workflow

Spec-driven development workflow: explore ideas, write specs, review with AI personas, and execute implementations.

**Skills:**
- `/idea-explorer` - Collaborative exploration to refine ideas
- `/spec-writer` - Transform ideas into detailed specifications
- `/spec-orchestrator` - Multi-agent review with AI personas
- `/spec-executor` - Execute specs with batched checkpoints
- `/create-worktree` - Create isolated git worktrees
- `/spec-workflow-init` - Scaffold configuration in your project

**Install:**
```
/plugin install spec-workflow@ky1ejs-plugins
```

See [spec-workflow README](./plugins/spec-workflow/README.md) for details.

---

### ios-engineer

iOS development tools with visual feedback via iOS Simulator MCP integration.

**Features:**
- iOS Simulator automation (screenshots, UI inspection, tap/swipe/type)
- iOS Engineer skill with SwiftUI patterns and best practices

**Setup:**
```bash
# After installing the plugin, run the setup script for dependencies
~/.claude/plugins/cache/ios-engineer/setup.sh
```

See [ios-engineer README](./plugins/ios-engineer/README.md) for details.

---

### rebase-main

Rebases the current branch onto the latest default branch (main, master, etc.), automatically resolving merge conflicts.

**Features:**
- Detects default branch and remote automatically
- Resolves conflicts favoring the default branch, re-applying local changes when additive
- Special handling for auto-generated files and lock files
- Stops and asks on ambiguous conflicts

**Install:**
```
/plugin install rebase-main@ky1ejs-plugins
```

---

### pr-review-handler

Processes PR review comments: assesses each piece of feedback, creates an action plan, implements changes, and responds to reviewers.

**Features:**
- Fetches unresolved review threads via GitHub GraphQL API
- Parallel assessment of each comment with spec-awareness
- Conflict detection when reviewers disagree
- Drafts and posts responses with user approval

**Install:**
```
/plugin install pr-review-handler@ky1ejs-plugins
```
