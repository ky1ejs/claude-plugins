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

### ios-engineer

iOS development tools with visual feedback via iOS Simulator MCP integration.

**Features:**
- iOS Simulator automation (screenshots, UI inspection, tap/swipe/type)
- Xcode build and test tools
- iOS Engineer skill with SwiftUI patterns and best practices

**Setup:**
```bash
# After installing the plugin, run the setup script for dependencies
~/.claude/plugins/cache/ios-engineer/setup.sh
```

See [ios-engineer README](./plugins/ios-engineer/README.md) for details.
