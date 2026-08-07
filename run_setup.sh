#!/usr/bin/env bash

# ==============================================================================
# All-in-One Setup & Launcher for Raju's Royal Artifacts Shop (Linux / macOS)
# Checks prerequisites, sets up deps, runs tests, and launches app.
# Works on all Linux distros (Debian, Ubuntu, Cloud Shell, Fedora, macOS).
# Usage: ./run_setup.sh
# ==============================================================================

set +e

echo "========================================================="
echo "  👳‍♂️ Raju's Royal Artifacts — All-in-One Linux/macOS    "
echo "========================================================="
echo ""

# 1. Prerequisite Check: Python 3
echo "[1/5] Checking Python installation..."
if command -v python3 &> /dev/null; then
    PYTHON_BIN="python3"
elif command -v python &> /dev/null; then
    PYTHON_BIN="python"
else
    echo "[-] Error: Python is not installed. Please install Python 3.10+."
    exit 1
fi

PY_VER=$($PYTHON_BIN --version 2>&1)
echo "[+] Found $PY_VER ($PYTHON_BIN)"

# 2. Prerequisite Check: GEMINI_API_KEY
echo ""
echo "[2/5] Checking GEMINI_API_KEY..."

if [ -f ".env" ]; then
    export $(grep -v '^#' .env | xargs) 2>/dev/null || true
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo "[!] GEMINI_API_KEY is not set."
    read -p "Please enter your Gemini API Key (or press Enter to skip): " USER_KEY
    if [ -n "$USER_KEY" ]; then
        export GEMINI_API_KEY="$USER_KEY"
        echo "GEMINI_API_KEY=$GEMINI_API_KEY" > .env
        echo "[+] Saved API key to .env file."
    fi
else
    echo "[+] GEMINI_API_KEY is configured."
fi

# 3. Virtual Environment & Dependencies Setup
echo ""
echo "[3/5] Setting up Environment & Dependencies..."

# Clean up broken venv if activate script is missing
if [ -d ".venv" ] && [ ! -f ".venv/bin/activate" ]; then
    echo "[!] Cleaning up incomplete .venv directory..."
    rm -rf .venv
fi

# Try creating venv
if [ ! -d ".venv" ]; then
    $PYTHON_BIN -m venv .venv 2>/dev/null || virtualenv .venv 2>/dev/null || true
fi

# Determine python and pip executables
if [ -f ".venv/bin/activate" ]; then
    echo "[+] Activating virtual environment (.venv)..."
    source .venv/bin/activate
    ENV_PYTHON=".venv/bin/python"
    ENV_PIP=".venv/bin/pip"
else
    echo "[!] Note: Operating using $PYTHON_BIN directly."
    ENV_PYTHON="$PYTHON_BIN"
    ENV_PIP="$PYTHON_BIN -m pip"
fi

echo "[+] Installing/Updating dependencies from requirements.txt..."
$ENV_PIP install --upgrade pip 2>/dev/null || true
$ENV_PIP install -r requirements.txt
echo "[+] Dependencies installed successfully."

# 4. Run Automated Tests
echo ""
echo "[4/5] Running automated unit tests (pytest)..."
export PYTHONPATH="."
$ENV_PYTHON -m pytest tests/test_agent.py || echo "[!] Warning: Some tests failed, continuing setup..."

# 5. Launch FastAPI Server & Open Browser
echo ""
echo "[5/5] Launching Raju's Shop Server at http://localhost:8000 ..."
echo "========================================================="
echo "👉 Press CTRL+C to stop the server."
echo "========================================================="

# Try opening default browser in background
if command -v xdg-open &> /dev/null; then
    xdg-open "http://localhost:8000" &> /dev/null &
elif command -v open &> /dev/null; then
    open "http://localhost:8000" &> /dev/null &
fi

# Start uvicorn server
$ENV_PYTHON -m uvicorn app.fast_api_app:app --host 0.0.0.0 --port 8000
