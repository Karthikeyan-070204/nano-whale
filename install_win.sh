#!/bin/sh
set -e

REPO="Vriddhachalam/nano-whale"
BIN_NAME="nano-whale.exe"
ASSET_NAME="nano-whale-windows-x86_64.exe"

echo "Fetching latest release for ${ASSET_NAME}..."
LATEST_URL=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep -Eo "\"browser_download_url\": \"[^\"]*${ASSET_NAME}\"" | cut -d '"' -f 4 | head -n 1)

if [ -z "$LATEST_URL" ]; then
    echo "Could not find a release asset for Windows (${ASSET_NAME})."
    echo "Make sure a release exists in the repository."
    exit 1
fi

echo "Downloading ${LATEST_URL}..."

# Determine install location
INSTALL_DIR="${USERPROFILE}/.local/bin"
if [ -z "$USERPROFILE" ]; then
    INSTALL_DIR="${HOME}/.local/bin"
fi
mkdir -p "$INSTALL_DIR"

INSTALL_PATH="${INSTALL_DIR}/${BIN_NAME}"
curl -fsSL "$LATEST_URL" -o "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "Installation complete! ${INSTALL_PATH} has been created."
echo "Make sure ${INSTALL_DIR} is in your PATH."
echo "Run 'nano-whale' to start."
