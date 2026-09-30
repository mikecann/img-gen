#!/usr/bin/env bash
# Re-run after moving the clone so the absolute symlink points at its new home.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.local/bin"
WITH_BUN_INSTALL=0

for arg in "$@"; do
  case "$arg" in
    --with-bun-install|-B) WITH_BUN_INSTALL=1 ;;
    -h|--help)
      echo "Usage: install.sh [target_bin_dir] [--with-bun-install|-B]"
      exit 0
      ;;
    -*) echo "Unknown option: $arg (try --help)" >&2; exit 1 ;;
    *) TARGET_DIR="$arg" ;;
  esac
done

if [[ "$WITH_BUN_INSTALL" -eq 1 ]]; then
  if ! command -v bun >/dev/null 2>&1; then
    echo "Install Bun from https://bun.sh first." >&2
    exit 1
  fi
  (cd "$REPO_DIR" && bun install --frozen-lockfile)
fi

mkdir -p "$TARGET_DIR"
chmod +x "$REPO_DIR/img-gen"
ln -sf "$REPO_DIR/img-gen" "$TARGET_DIR/img-gen"
echo "Installed $TARGET_DIR/img-gen -> $REPO_DIR/img-gen"
case ":$PATH:" in
  *":$TARGET_DIR:"*) ;;
  *) echo "Add $TARGET_DIR to PATH in your shell profile." ;;
esac
echo "Set OPENROUTER_API_KEY in $REPO_DIR/.env, then run: img-gen /path/to/folder"
