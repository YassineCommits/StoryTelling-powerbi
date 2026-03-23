#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

export PATH="$HOME/.local/bin:$PATH"

if ! command -v ollama >/dev/null 2>&1; then
  echo "ollama not found. Run: ./scripts/setup_ollama.sh"
  exit 1
fi

if ! pgrep -f "ollama serve" >/dev/null 2>&1; then
  ollama serve >/tmp/ollama.log 2>&1 &
  sleep 2
fi

if [[ -d "venv" ]]; then
  # shellcheck disable=SC1091
  source venv/bin/activate
fi

if [[ -x "venv/bin/python" ]]; then
  PYTHON_BIN="venv/bin/python"
elif command -v python3 >/dev/null 2>&1; then
  PYTHON_BIN="python3"
elif command -v python >/dev/null 2>&1; then
  PYTHON_BIN="python"
else
  echo "python not found. Install Python 3 or create venv."
  exit 1
fi

"${PYTHON_BIN}" src/pbixray_server.py "$@"
