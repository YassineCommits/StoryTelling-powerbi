# PBIX Storytelling UI (Vercel AI SDK)

Streams narrative text from Ollama using `ai` + `@ai-sdk/openai`, with PBIX context from Flask `/api/pbix/context`.

## Run

Terminal 1 — Flask (pick a free port automatically):

```bash
cd ..
./scripts/run_flask_dashboard.sh
```

Terminal 2 — this app:

```bash
cp .env.example .env.local
# edit FLASK_URL to match Flask’s port (e.g. 5052)
npm install
npm run dev
```

Open `http://127.0.0.1:3000`.

## Env

| Variable | Purpose |
|----------|---------|
| `FLASK_URL` | Base URL of `pbixray_flask_app` (e.g. `http://127.0.0.1:5052`) |
| `OLLAMA_BASE_URL` | Ollama host (default `http://127.0.0.1:11434`) |
| `OLLAMA_MODEL` | Default model name |

Flask `GET /storytelling` redirects here when `STORY_UI_URL` is unset.
