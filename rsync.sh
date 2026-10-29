#!/bin/bash
set -e

# iOS Simulator rsync script
# Copies a file or directory into the "On My iPhone" / Files LocalStorage of the currently booted iOS simulator.

if [ -z "$1" ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo "Usage: $0 <source_file_or_directory>"
  exit 1
fi

SOURCE="$1"
if [ ! -e "$SOURCE" ]; then
  echo "Error: Source '$SOURCE' does not exist."
  exit 1
fi

# 1. Get booted simulator ID
SIM_ID=$(xcrun simctl list devices | grep -E '\(Booted\)' | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' | head -n 1)

if [ -z "$SIM_ID" ]; then
  echo "Error: No booted iOS simulator found."
  exit 1
fi

echo "Booted Simulator ID: $SIM_ID"

# 2. Get the app group container path for com.apple.FileProvider.LocalStorage
APP_GROUP_DIR=$(xcrun simctl get_app_container "$SIM_ID" com.apple.DocumentsApp groups 2>/dev/null | grep 'group.com.apple.FileProvider.LocalStorage' | cut -f2)

if [ -z "$APP_GROUP_DIR" ]; then
  echo "Error: Could not find FileProvider.LocalStorage container for simulator $SIM_ID."
  exit 1
fi

DEST_DIR="$APP_GROUP_DIR/File Provider Storage"
mkdir -p "$DEST_DIR"

# 3. Extract the part after the last / in the path and construct destination
NAME=$(basename "$SOURCE")
DEST_PATH="$DEST_DIR/$NAME"

echo "Syncing '$SOURCE' to '$DEST_PATH'..."

if [ -d "$SOURCE" ]; then
  mkdir -p "$DEST_PATH"
  rsync -av "$SOURCE/" "$DEST_PATH/"
else
  rsync -av "$SOURCE" "$DEST_PATH"
fi

echo "Successfully synced to iOS simulator."
