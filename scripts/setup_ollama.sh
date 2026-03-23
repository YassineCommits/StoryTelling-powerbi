#!/usr/bin/env bash
set -euo pipefail

# User-local Ollama install (no sudo).
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OLLAMA_HOME="${HOME}/.local/ollama"
OLLAMA_BIN="${HOME}/.local/bin/ollama"
MODEL="${1:-llama3.2:3b}"

mkdir -p "${HOME}/.local/bin" "${OLLAMA_HOME}"

if [[ ! -x "${OLLAMA_BIN}" ]]; then
  echo "Installing Ollama locally..."
  python3 - <<'PY'
import json
import pathlib
import urllib.request

release = json.load(urllib.request.urlopen("https://api.github.com/repos/ollama/ollama/releases/latest"))
url = None
for asset in release.get("assets", []):
    if asset["name"] == "ollama-linux-amd64.tar.zst":
        url = asset["browser_download_url"]
        break
if not url:
    raise SystemExit("Could not find linux amd64 Ollama binary in latest release assets.")
pathlib.Path("/tmp/ollama_download_url.txt").write_text(url)
PY
  OLLAMA_URL="$(< /tmp/ollama_download_url.txt)"
  curl -L "${OLLAMA_URL}" -o "${OLLAMA_HOME}/ollama-linux-amd64.tar.zst"
  tar --use-compress-program=unzstd -xf "${OLLAMA_HOME}/ollama-linux-amd64.tar.zst" -C "${OLLAMA_HOME}"
  ln -sf "${OLLAMA_HOME}/bin/ollama" "${OLLAMA_BIN}"
fi

echo "Ollama version:"
"${OLLAMA_BIN}" --version

if ! pgrep -f "ollama serve" >/dev/null 2>&1; then
  echo "Starting Ollama server..."
  "${OLLAMA_BIN}" serve >/tmp/ollama.log 2>&1 &
  sleep 2
fi

echo "Pulling model ${MODEL}..."
"${OLLAMA_BIN}" pull "${MODEL}"

cat <<EOF

Done.
Use this in your shell when running local tools:
  export PATH="\$HOME/.local/bin:\$PATH"
EOF
