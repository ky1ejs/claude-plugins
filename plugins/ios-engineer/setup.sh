#!/bin/bash
# iOS Engineer Plugin Setup
# Run this script to install dependencies for the ios-engineer plugin

set -e

echo "Setting up iOS Engineer plugin dependencies..."

# Check for Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo "ERROR: Xcode is required but not installed."
    echo "Install Xcode from the App Store or https://developer.apple.com/xcode/"
    exit 1
fi
echo "✓ Xcode found"

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo "ERROR: Homebrew is required but not installed."
    echo "Install from https://brew.sh/"
    exit 1
fi
echo "✓ Homebrew found"

# Install idb-companion via Homebrew
echo "Installing Facebook IDB companion..."
brew tap facebook/fb 2>/dev/null || true
if brew list idb-companion &>/dev/null; then
    echo "✓ idb-companion already installed"
else
    brew install idb-companion
    echo "✓ idb-companion installed"
fi

# Check for pyenv
if ! command -v pyenv &> /dev/null; then
    echo "ERROR: pyenv is required but not installed."
    echo "Install from https://github.com/pyenv/pyenv or via 'brew install pyenv'"
    exit 1
fi
echo "✓ pyenv found"

# Ensure Python 3.13.x is available (fb-idb has issues with 3.14+)
PYTHON_VERSION="3.13.5"
if ! pyenv versions | grep -q "$PYTHON_VERSION"; then
    echo "Installing Python $PYTHON_VERSION via pyenv..."
    pyenv install "$PYTHON_VERSION"
fi
echo "✓ Python $PYTHON_VERSION available"

# Install Python IDB client using the correct Python version
echo "Installing IDB Python client..."
PYENV_VERSION=$PYTHON_VERSION pip install fb-idb
echo "✓ fb-idb installed"

# Check for Node.js (needed for npx)
if ! command -v npx &> /dev/null; then
    echo "ERROR: Node.js/npx is required but not installed."
    echo "Install from https://nodejs.org/ or via 'brew install node'"
    exit 1
fi
echo "✓ Node.js/npx found"

echo ""
echo "Setup complete! The ios-engineer plugin is ready to use."
echo ""
echo "Note: If your project needs Python 3.13 for fb-idb, run:"
echo "  pyenv local $PYTHON_VERSION"
echo ""
echo "Restart Claude Code to load the plugin and MCP servers."
