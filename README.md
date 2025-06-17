# Node.js LTS Installer Script

This Bash script installs the latest **Node.js LTS** version on Debian/Ubuntu-based systems, with graceful fallbacks and useful status messages.

## 🚀 Features

- Auto-detects and installs the latest LTS version
- Verifies and installs `curl` if missing
- Uses NodeSource or manual APT method as fallback
- Color-coded output and robust error handling

## 📦 Installation

```bash
curl -sL https://raw.githubusercontent.com/MetaBooy/nodejs-installer-/refs/heads/main/install-node.sh | bash
