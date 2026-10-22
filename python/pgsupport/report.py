"""Форматирование результатов: текст, JSON, Markdown."""
from __future__ import annotations

import json
from datetime import datetime, timezone

from .checks import LABELS, Result, worst


def as_text(results: list[Result]) -> str:
    return "\n".join(f"{r.label:<9} {r.name:<22} {r.detail}" for r in results)


def as_json(results: list[Result]) -> str:
    return json.dumps(
        {"status": LABELS[worst(results)], "checks": [{"name": r.name, "status": r.label, "detail": r.detail} for r in results]},
        ensure_ascii=False, indent=2)


def as_markdown(results: list[Result]) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    lines = [f"# Отчёт о состоянии PostgreSQL — {now}", "", f"**Итог: {LABELS[worst(results)]}**", "",
             "| Проверка | Статус | Подробности |", "|---|---|---|"]
    lines += [f"| {r.name} | {r.label} | {r.detail} |" for r in results]
    return "\n".join(lines) + "\n"


FORMATS = {"text": as_text, "json": as_json, "md": as_markdown}
