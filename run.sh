#!/usr/bin/env bash
# Woeyyy Discord Bot — Server Mode (Cached Download)
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

# Check if dependencies are installed; if not, set up venv and install
if ! python3 -c "import discord, yt_dlp, imageio_ffmpeg, aiohttp" &>/dev/null; then
    if [ ! -f "venv/bin/activate" ]; then
        echo "Creating virtual environment..."
        python3 -m venv venv || { echo "[ERROR] Failed to create virtual environment."; exit 1; }
    fi
    source venv/bin/activate
    echo "Installing dependencies from requirements.txt..."
    python3 -m pip install --upgrade pip --quiet
    pip install -r requirements.txt || { echo "[ERROR] Failed to install dependencies."; exit 1; }
fi

python3 main.py "$@"

