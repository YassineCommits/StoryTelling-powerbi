"use client";

import { useChat } from "ai/react";
import { useCallback, useMemo, useState } from "react";

export default function StoryPage() {
  const [pbixPath, setPbixPath] = useState(
    "/home/guepard/yassine/tasnim/pbixray-mcp-server/Employee Hiring and History.pbix"
  );
  const [model, setModel] = useState("llama3.2:3b");

  const body = useMemo(() => ({ pbixPath, model }), [pbixPath, model]);

  const { messages, append, isLoading, error } = useChat({
    api: "/api/chat",
    body,
  });

  const onGenerate = useCallback(() => {
    if (!pbixPath.trim()) return;
    void append({
      role: "user",
      content:
        "Generate the Power BI storytelling narrative with the four markdown sections (Overview, Key Insights, Risks or Data Quality Concerns, Recommended Actions).",
    });
  }, [append, pbixPath]);

  const lastAssistant = [...messages].reverse().find((m) => m.role === "assistant");

  return (
    <div
      style={{
        maxWidth: 900,
        margin: "0 auto",
        padding: 24,
        background: "linear-gradient(120deg, #020617, #0b1223)",
        minHeight: "100vh",
        color: "#e5e7eb",
      }}
    >
      <h1 style={{ marginTop: 0 }}>PBIX Storytelling (streamed)</h1>
      <p style={{ color: "#94a3b8", fontSize: 14 }}>
        Uses Vercel AI SDK (<code>ai</code> + <code>@ai-sdk/openai</code>) against Ollama. Context comes from the Flask
        API (<code>/api/pbix/context</code>). Run Flask first: <code>./scripts/run_flask_dashboard.sh</code>
      </p>

      <div
        style={{
          display: "grid",
          gap: 10,
          marginBottom: 16,
          background: "rgba(17,24,39,0.85)",
          border: "1px solid #1f2937",
          borderRadius: 12,
          padding: 16,
        }}
      >
        <label style={{ fontSize: 12, color: "#94a3b8" }}>PBIX absolute path</label>
        <input
          value={pbixPath}
          onChange={(e) => setPbixPath(e.target.value)}
          style={{
            width: "100%",
            padding: 10,
            borderRadius: 8,
            border: "1px solid #334155",
            background: "#0b1223",
            color: "#e5e7eb",
          }}
        />
        <label style={{ fontSize: 12, color: "#94a3b8" }}>Ollama model</label>
        <input
          value={model}
          onChange={(e) => setModel(e.target.value)}
          style={{
            maxWidth: 280,
            padding: 10,
            borderRadius: 8,
            border: "1px solid #334155",
            background: "#0b1223",
            color: "#e5e7eb",
          }}
        />
        <div>
          <button
            type="button"
            onClick={onGenerate}
            disabled={isLoading || !pbixPath.trim()}
            style={{
              padding: "10px 18px",
              borderRadius: 8,
              border: "none",
              background: "#38bdf8",
              color: "#001018",
              fontWeight: 700,
              cursor: isLoading ? "wait" : "pointer",
            }}
          >
            {isLoading ? "Streaming…" : "Generate story"}
          </button>
        </div>
      </div>

      {error && (
        <div
          style={{
            padding: 12,
            borderRadius: 8,
            background: "#7f1d1d",
            border: "1px solid #ef4444",
            color: "#fecaca",
            marginBottom: 16,
          }}
        >
          {error instanceof Error ? error.message : String(error)}
        </div>
      )}

      <div
        style={{
          background: "rgba(17,24,39,0.85)",
          border: "1px solid #1f2937",
          borderRadius: 12,
          padding: 16,
          whiteSpace: "pre-wrap",
          fontSize: 14,
          lineHeight: 1.55,
        }}
      >
        {lastAssistant?.content ? (
          lastAssistant.content
        ) : (
          <span style={{ color: "#64748b" }}>Story appears here as the model streams.</span>
        )}
      </div>
    </div>
  );
}
