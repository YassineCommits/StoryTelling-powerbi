#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Accept both:
#   ./scripts/demo_pbix.sh "/path/with spaces/file.pbix"
# and (tolerant mode):
#   ./scripts/demo_pbix.sh /path/with spaces/file.pbix
DEFAULT_PBIX="/home/guepard/yassine/tasnim/pbixray-mcp-server/Employee Hiring and History.pbix"
if [[ "$#" -eq 0 ]]; then
  PBIX_PATH="$DEFAULT_PBIX"
else
  PBIX_PATH="$*"
fi

if [[ ! -f "$PBIX_PATH" ]]; then
  echo "PBIX file not found: $PBIX_PATH"
  echo "Usage: ./scripts/demo_pbix.sh \"/absolute/path/to/file.pbix\""
  exit 1
fi

if [[ ! -x "venv/bin/python" ]]; then
  echo "Missing venv. Run:"
  echo "  python3 -m venv venv && venv/bin/pip install -r requirements.txt"
  exit 1
fi

venv/bin/python - <<PY
import asyncio
from mcp.client.session import ClientSession
from mcp.client.stdio import stdio_client
from mcp import StdioServerParameters

PBIX = r"""$PBIX_PATH"""

async def main():
    params = StdioServerParameters(command="./scripts/run_with_ollama.sh", args=[], env=None)
    async with stdio_client(params) as (r, w):
        async with ClientSession(r, w) as s:
            await s.initialize()

            print("\\n== load_pbix_file ==")
            res = await s.call_tool("load_pbix_file", {"file_path": PBIX})
            for c in res.content:
                if getattr(c, "text", None):
                    print(c.text)

            print("\\n== get_tables ==")
            res = await s.call_tool("get_tables", {})
            for c in res.content:
                if getattr(c, "text", None):
                    print(c.text)

            print("\\n== get_statistics ==")
            res = await s.call_tool("get_statistics", {})
            for c in res.content:
                if getattr(c, "text", None):
                    print(c.text)

asyncio.run(main())
PY
