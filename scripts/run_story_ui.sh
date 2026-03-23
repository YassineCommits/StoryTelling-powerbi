#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../web"

if [[ ! -d node_modules ]]; then
  npm install
fi

echo "Story UI: http://127.0.0.1:3000"
echo "Set FLASK_URL if Flask is not on 5052, e.g.: FLASK_URL=http://127.0.0.1:5052 npm run dev"

exec npm run dev
