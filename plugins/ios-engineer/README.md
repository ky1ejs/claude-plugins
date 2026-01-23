# iOS Engineer Plugin

This plugin provides Claude Code with iOS development capabilities including visual feedback via iOS Simulator automation.

## Features

- **iOS Simulator MCP** - Take screenshots, inspect UI hierarchy, tap/swipe/type
- **iOS Engineer Skill** - SwiftUI patterns, Apollo GraphQL, and best practices for Cut

## Setup

Run the setup script to install required dependencies:

```bash
.claude/plugins/ios-engineer/setup.sh
```

### Manual Installation

If you prefer to install manually:

```bash
# Install Facebook IDB (required for simulator automation)
brew tap facebook/fb
brew install idb-companion

# Set Python 3.13 for project (fb-idb doesn't work with Python 3.14+)
pyenv local 3.13.5
pip install fb-idb

# Node.js is required for MCP servers (install if not present)
brew install node
```

## Requirements

- macOS
- Xcode with iOS Simulators
- Homebrew
- pyenv with Python 3.13.x (fb-idb has issues with 3.14+)
- Node.js (for npx)

## Usage

The skill automatically activates when working on files in `/ios/`. It provides:

1. **Visual Feedback Loop** - Build, launch, screenshot, analyze, iterate
2. **UI Automation** - Tap, swipe, type via MCP tools
3. **Accessibility Inspection** - Verify UI hierarchy and labels

## MCP Servers

This plugin bundles two MCP servers:

| Server | Purpose |
|--------|---------|
| `ios-simulator` | UI automation, screenshots, accessibility inspection |

## Troubleshooting

**MCP tools not working?**
1. Ensure you've run the setup script
2. Restart Claude Code after setup
3. Check that a simulator is booted: `xcrun simctl list devices`

**IDB errors?**
1. Verify idb-companion is installed: `which idb_companion`
2. Verify fb-idb is installed: `pip3 show fb-idb`
