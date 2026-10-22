#!/bin/sh
set -e

BIN_NAME="nano-whale.exe"
INSTALL_DIR="${USERPROFILE}/.local/bin"
if [ -z "$USERPROFILE" ]; then
    INSTALL_DIR="${HOME}/.local/bin"
fi
INSTALL_PATH="${INSTALL_DIR}/${BIN_NAME}"

if [ -f "$INSTALL_PATH" ]; then
    echo "Removing ${INSTALL_PATH}..."
    rm -f "$INSTALL_PATH"
    echo "nano-whale has been successfully uninstalled."
else
    echo "nano-whale is not installed in ${INSTALL_DIR}."
fi
