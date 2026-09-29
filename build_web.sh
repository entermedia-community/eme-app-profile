#!/usr/bin/env bash
set -euo pipefail

# Determine script and project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

cd "$PROJECT_DIR"

ENV_FILE="$PROJECT_DIR/.env"

# Check if .env exists
if [ ! -f "$ENV_FILE" ]; then
  echo "⚠️  .env file not found at $ENV_FILE"
  if [ -f "$PROJECT_DIR/.env.example" ]; then
    echo "ℹ️  Creating .env from .env.example..."
    cp "$PROJECT_DIR/.env.example" "$ENV_FILE"
  else
    echo "❌ Please create a .env file with BUILD_PATH defined."
    exit 1
  fi
fi

# Extract BUILD_PATH from .env (handling quotes, spaces, and comments)
BUILD_PATH=$(grep -E '^[[:space:]]*BUILD_PATH[[:space:]]*=' "$ENV_FILE" | head -n 1 | cut -d '=' -f2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^["'\'']//' -e 's/["'\'']$//')

if [ -z "${BUILD_PATH:-}" ]; then
  echo "❌ Error: BUILD_PATH is not set in $ENV_FILE"
  echo "Example: BUILD_PATH=./build/web_dist"
  exit 1
fi

# Expand tilde ~ if present
BUILD_PATH="${BUILD_PATH/#\~/$HOME}"

# If BUILD_PATH is a relative path, make it relative to PROJECT_DIR
if [[ "$BUILD_PATH" != /* ]]; then
  BUILD_PATH="$PROJECT_DIR/$BUILD_PATH"
fi

echo "=========================================="
echo "🚀 Starting Flutter Web Build"
echo "📂 Target destination: $BUILD_PATH"
echo "=========================================="

# Run flutter build web
flutter build web --release --wasm --base-href /site/app/ "$@"

SOURCE_BUILD_DIR="$PROJECT_DIR/build/web"

if [ ! -d "$SOURCE_BUILD_DIR" ]; then
  echo "❌ Error: Flutter web build failed or directory $SOURCE_BUILD_DIR does not exist."
  exit 1
fi

# Ensure target directory exists
mkdir -p "$BUILD_PATH"

# Copy built files to BUILD_PATH
echo "📦 Copying web build to $BUILD_PATH..."
if command -v rsync >/dev/null 2>&1; then
  rsync -av --delete "$SOURCE_BUILD_DIR/" "$BUILD_PATH/"
else
  rm -rf "${BUILD_PATH:?}"/*
  cp -R "$SOURCE_BUILD_DIR"/* "$BUILD_PATH/"
fi

echo "=========================================="
echo "✅ Web build successfully deployed to:"
echo "👉 $BUILD_PATH"
echo "=========================================="
