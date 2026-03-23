import json
import os
import re
import urllib.error
import urllib.request
from typing import Any


def _safe_int(value: Any) -> int:
    try:
        return int(value or 0)
    except (ValueError, TypeError):
        return 0


def normalize_tables(tables_obj: Any) -> list[str]:
    if tables_obj is None:
        return []
    if hasattr(tables_obj, "tolist"):
        return [str(v) for v in tables_obj.tolist()]
    return [str(v) for v in tables_obj]


def normalize_statistics(stats_obj: Any) -> list[dict[str, Any]]:
    if stats_obj is None:
        return []
    if hasattr(stats_obj, "to_dict"):
        return stats_obj.to_dict(orient="records")
    if isinstance(stats_obj, list):
        return stats_obj
    return []


def build_story_context(file_path: str, tables_obj: Any, statistics_obj: Any) -> dict[str, Any]:
    tables = normalize_tables(tables_obj)
    stats_rows = normalize_statistics(statistics_obj)

    total_size = sum(_safe_int(r.get("DataSize")) for r in stats_rows)
    total_dictionary = sum(_safe_int(r.get("Dictionary")) for r in stats_rows)
    total_hash_index = sum(_safe_int(r.get("HashIndex")) for r in stats_rows)

    top_size = sorted(stats_rows, key=lambda r: _safe_int(r.get("DataSize")), reverse=True)[:15]
    top_cardinality = sorted(stats_rows, key=lambda r: _safe_int(r.get("Cardinality")), reverse=True)[:15]

    def reduce_row(row: dict[str, Any]) -> dict[str, Any]:
        return {
            "table": row.get("TableName"),
            "column": row.get("ColumnName"),
            "cardinality": _safe_int(row.get("Cardinality")),
            "data_size": _safe_int(row.get("DataSize")),
        }

    return {
        "file_name": os.path.basename(file_path),
        "table_count": len(tables),
        "tables": tables,
        "column_count": len(stats_rows),
        "total_data_size": total_size,
        "total_dictionary": total_dictionary,
        "total_hash_index": total_hash_index,
        "top_size_columns": [reduce_row(r) for r in top_size],
        "top_cardinality_columns": [reduce_row(r) for r in top_cardinality],
    }


def _story_prompt(context: dict[str, Any]) -> str:
    compact = json.dumps(context, ensure_ascii=True)
    return (
        "You are a senior Power BI analytics storyteller. "
        "Create a concise but specific narrative for a business stakeholder using this model context.\n\n"
        "Output format rules:\n"
        "1) Use exactly these markdown headings:\n"
        "## Overview\n## Key Insights\n## Risks or Data Quality Concerns\n## Recommended Actions\n"
        "2) Under each heading use 3-6 bullet points.\n"
        "3) Be concrete with names of tables/columns when possible.\n"
        "4) No generic fluff.\n\n"
        f"Context JSON:\n{compact}"
    )


def generate_story_with_ollama(
    context: dict[str, Any],
    model: str | None = None,
    base_url: str | None = None,
    timeout_seconds: int = 300,
) -> str:
    ollama_model = model or os.environ.get("OLLAMA_MODEL", "llama3.2:3b")
    ollama_base = (base_url or os.environ.get("OLLAMA_BASE_URL", "http://127.0.0.1:11434")).rstrip("/")
    url = f"{ollama_base}/v1/chat/completions"

    payload = {
        "model": ollama_model,
        "messages": [
            {"role": "system", "content": "You write sharp Power BI narratives from metadata and statistics."},
            {"role": "user", "content": _story_prompt(context)},
        ],
        "temperature": 0.2,
    }

    request = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json", "Authorization": "Bearer ollama"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
            body = json.loads(response.read().decode("utf-8"))
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Could not reach Ollama at {ollama_base}: {exc}") from exc
    except json.JSONDecodeError as exc:
        raise RuntimeError("Invalid JSON response from Ollama.") from exc

    try:
        return body["choices"][0]["message"]["content"].strip()
    except (KeyError, IndexError, TypeError) as exc:
        raise RuntimeError("Unexpected response format from Ollama.") from exc


def split_story_sections(story_text: str) -> dict[str, str]:
    headings = [
        "Overview",
        "Key Insights",
        "Risks or Data Quality Concerns",
        "Recommended Actions",
    ]
    sections = {heading: "" for heading in headings}

    for idx, heading in enumerate(headings):
        pattern = rf"##\s*{re.escape(heading)}\s*(.*?)"
        if idx + 1 < len(headings):
            next_heading = headings[idx + 1]
            pattern += rf"(?=##\s*{re.escape(next_heading)}|\Z)"
        match = re.search(pattern, story_text, flags=re.DOTALL | re.IGNORECASE)
        if match:
            sections[heading] = match.group(1).strip()

    return sections
