#!/bin/bash

# ================================
# Node.js LTS Installer Script
# Author: YourNameHere
# GitHub: https://github.com/yourusername/nodejs-installer
# Description: Installs the latest Node.js LTS version with fallbacks and safety checks.
# ================================

# Terminal formatting
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
PINK='\033[1;35m'

# Function to display formatted messages
show() {
    case $2 in
        "error")
            echo -e "${PINK}${BOLD}❌ $1${NORMAL}"
            ;;
        "progress")
            echo -e "${PINK}${BOLD}⏳ $1${NORMAL}"
            ;;
        *)
            echo -e "${PINK}${BOLD}✅ $1${NORMAL}"
            ;;
    esac
}

# Check for curl
if ! command -v curl &> /dev/null; then
    show "curl is not installed. Installing curl..." "progress"
    sudo apt-get update
    sudo apt-get install -y curl || {
        show "Failed to install curl. Please install it manually and rerun the script." "error"
        exit 1
    }
fi

# Check for existing Node.js
EXISTING_NODE=$(which node 2>/dev/null)
if [ -n "$EXISTING_NODE" ]; then
    show "Existing Node.js found at $EXISTING_NODE. It will be updated." 
fi

# Fetch the latest LTS version
show "Fetching latest Node.js LTS version..." "progress"
LATEST_VERSION=$(curl -s https://nodejs.org/dist/index.tab | grep -E "^v[0-9]+\.[0-9]+\.[0-9]+.*latest.*LTS" | head -1 | cut -f1 | sed 's/^v//')

if [ -z "$LATEST_VERSION" ]; then
    show "Trying alternative method to fetch Node.js version..." "progress"
    LATEST_VERSION=$(curl -s https://nodejs.org/en/download/ | grep -oP 'Latest LTS Version.*?(\d+\.\d+\.\d+)' | grep -oP '\d+\.\d+\.\d+' | head -1)
fi

if [ -z "$LATEST_VERSION" ]; then
    show "Failed to fetch latest version. Using fallback version: 20.x" "progress"
    MAJOR_VERSION=20
else
    show "Latest Node.js LTS version is $LATEST_VERSION"
    MAJOR_VERSION=$(echo $LATEST_VERSION | cut -d. -f1)
fi

# Prepare to install Node.js
show "Setting up NodeSource repository for Node.js $MAJOR_VERSION.x..." "progress"
TEMP_SCRIPT=$(mktemp)

if ! curl -sL "https://deb.nodesource.com/setup_${MAJOR_VERSION}.x" -o "$TEMP_SCRIPT"; then
    show "Failed to download NodeSource script. Trying fallback..." "error"
    rm -f "$TEMP_SCRIPT"
    exit 1
fi

if grep -q "<html>" "$TEMP_SCRIPT" || grep -q "404" "$TEMP_SCRIPT" || [ $(wc -l < "$TEMP_SCRIPT") -lt 10 ]; then
    show "Invalid NodeSource script detected. Using alternative setup..." "progress"
    rm -f "$TEMP_SCRIPT"
    
    sudo apt-get update
    sudo apt-get install -y ca-certificates gnupg
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg

    echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$MAJOR_VERSION.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y nodejs || {
        show "Failed to install Node.js using alternative method." "error"
        exit 1
    }
else
    sudo bash "$TEMP_SCRIPT" && rm -f "$TEMP_SCRIPT"
    sudo apt-get install -y nodejs || {
        show "Failed to install Node.js and npm." "error"
        exit 1
    }
fi

# Verify installation
show "Verifying installation..." "progress"
if command -v node &> /dev/null && command -v npm &> /dev/null; then
    NODE_VERSION=$(node -v)
    NPM_VERSION=$(npm -v)
    INSTALLED_NODE=$(which node)

    show "Node.js $NODE_VERSION and npm $NPM_VERSION installed at $INSTALLED_NODE."
    if [ "$INSTALLED_NODE" != "/usr/bin/node" ]; then
        show "Warning: Node.js is installed at $INSTALLED_NODE. Check your PATH."
    fi
else
    show "Installation complete, but Node.js not found in PATH." "error"
    exit 1
fi

show "✅ Node.js installation completed successfully!"
