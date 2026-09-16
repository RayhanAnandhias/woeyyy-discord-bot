#!/usr/bin/env bash
# Woeyyy Discord Bot — Lightweight Launcher
set -euo pipefail

# Change to the directory where this script lives
cd "$(dirname "$0")"

# Check Python is available
if ! command -v python3 &>/dev/null; then
    echo "[ERROR] Python not found. Please install Python 3.10+ and ensure it is in PATH."
    exit 1
fi

# Activate venv if it exists
if [ -f "venv/bin/activate" ]; then
    source venv/bin/activate
fi

python3 main.py "$@"

