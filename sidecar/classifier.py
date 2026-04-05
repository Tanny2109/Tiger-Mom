from __future__ import annotations

import base64
import json
import re
from pathlib import Path
from typing import Any

import httpx
from sqlalchemy.orm import Session

from .settings_manager import get_api_key, get_setting


OPENROUTER_URL = "https://openrouter.ai/api/v1/chat/completions"
APP_NAME = "Tiger Mom"
APP_URL = "https://localhost/tiger-mom"

VISION_PROMPT = """You are describing a computer screenshot for a productivity tracker.
Summarize only what is likely visible on screen in 2-4 short sentences.
Include:
- likely app/site names
- what the user seems to be doing
- whether it looks focused work, communication, shallow admin, distraction, or break
Do not mention uncertainty unless necessary."""

CLASSIFY_PROMPT = """Classify this desktop activity for a Tiger Mom productivity app.
Return JSON only with these keys:
app_name, window_title, category, subcategory, detail, confidence, classification_reason

Rules:
- category must be exactly one of: Deep Work, Communication, Shallow Work, Distraction, Break
- confidence must be a number from 0 to 1
- keep detail under 160 characters
- keep classification_reason under 140 characters

Screenshot description:
{description}
"""


def _headers(api_key: str) -> dict[str, str]:
    return {
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
        "HTTP-Referer": APP_URL,
        "X-Title": APP_NAME,
    }


def call_openrouter_chat(
    session: Session,
    model: str,
    messages: list[dict[str, Any]],
    *,
    temperature: float = 0.2,
    max_tokens: int = 350,
) -> str | None:
    api_key = get_api_key(session)
    if not api_key or not model:
        return None

    payload = {
        "model": model,
        "messages": messages,
        "temperature": temperature,
        "max_tokens": max_tokens,
    }

    try:
        with httpx.Client(timeout=45.0) as client:
            response = client.post(OPENROUTER_URL, headers=_headers(api_key), json=payload)
            response.raise_for_status()
        data = response.json()
        return data["choices"][0]["message"]["content"]
    except Exception:
        return None


def _extract_json(text: str) -> dict[str, Any] | None:
    match = re.search(r"\{.*\}", text, re.DOTALL)
    if not match:
        return None
    try:
        return json.loads(match.group(0))
    except json.JSONDecodeError:
        return None


def _to_data_url(image_bytes: bytes) -> str:
    encoded = base64.b64encode(image_bytes).decode("utf-8")
    return f"data:image/jpeg;base64,{encoded}"


def describe_screenshot(session: Session, image_bytes: bytes) -> str:
    model = str(get_setting(session, "vision_model", "qwen/qwen3.5-plus-02-15"))
    content = call_openrouter_chat(
        session,
        model,
        [
            {"role": "system", "content": "You turn screenshots into concise factual descriptions."},
            {
                "role": "user",
                "content": [
                    {"type": "text", "text": VISION_PROMPT},
                    {"type": "image_url", "image_url": {"url": _to_data_url(image_bytes)}},
                ],
            },
        ],
        max_tokens=220,
    )
    if content:
        return content.strip()
    return "A desktop screenshot was captured, but no vision summary is available."


def _fallback_activity(description: str) -> dict[str, Any]:
    lowered = description.lower()
    keyword_groups = [
        (
            "Distraction",
            "Entertainment",
            "Distraction-like content detected",
            {
                "reddit": "Reddit",
                "youtube": "YouTube",
                "twitter": "X",
                "x.com": "X",
                "instagram": "Instagram",
                "tiktok": "TikTok",
                "netflix": "Netflix",
            },
        ),
        (
            "Communication",
            "Messaging",
            "Communication tools appear visible",
            {
                "slack": "Slack",
                "gmail": "Gmail",
                "mail": "Mail",
                "zoom": "Zoom",
                "meet": "Google Meet",
                "calendar": "Calendar",
                "discord": "Discord",
            },
        ),
        (
            "Deep Work",
            "Building",
            "Looks like hands-on creation or coding work",
            {
                "xcode": "Xcode",
                "cursor": "Cursor",
                "terminal": "Terminal",
                "iterm": "iTerm",
                "vscode": "VS Code",
                "github": "GitHub",
                "pycharm": "PyCharm",
            },
        ),
        (
            "Shallow Work",
            "Planning",
            "Looks like planning, reading, or admin work",
            {
                "notion": "Notion",
                "docs": "Google Docs",
                "sheet": "Spreadsheet",
                "spreadsheet": "Spreadsheet",
                "chrome": "Browser",
                "safari": "Browser",
            },
        ),
    ]

    for category, subcategory, reason, mapping in keyword_groups:
        for keyword, app_name in mapping.items():
            if keyword in lowered:
                return {
                    "app_name": app_name,
                    "window_title": f"{app_name} window",
                    "category": category,
                    "subcategory": subcategory,
                    "detail": description[:160],
                    "confidence": 0.62,
                    "classification_reason": reason,
                }

    return {
        "app_name": "Unknown App",
        "window_title": "Desktop activity",
        "category": "Shallow Work",
        "subcategory": "Unknown",
        "detail": description[:160],
        "confidence": 0.35,
        "classification_reason": "Fallback classification used because no structured model output was available.",
    }


def classify_description(session: Session, description: str) -> dict[str, Any]:
    model = str(get_setting(session, "brain_model", "openai/gpt-5-mini"))
    content = call_openrouter_chat(
        session,
        model,
        [
            {"role": "system", "content": "You are a precise productivity classifier. Return JSON only."},
            {"role": "user", "content": CLASSIFY_PROMPT.format(description=description)},
        ],
        max_tokens=240,
        temperature=0.1,
    )

    if content:
        parsed = _extract_json(content)
        if parsed:
            parsed["category"] = parsed.get("category", "Shallow Work")
            if parsed["category"] not in {"Deep Work", "Communication", "Shallow Work", "Distraction", "Break"}:
                parsed["category"] = "Shallow Work"
            parsed["confidence"] = max(0.0, min(float(parsed.get("confidence", 0.5)), 1.0))
            parsed["app_name"] = str(parsed.get("app_name") or "Unknown App")
            parsed["window_title"] = str(parsed.get("window_title") or "Desktop activity")
            parsed["subcategory"] = str(parsed.get("subcategory") or "Unknown")
            parsed["detail"] = str(parsed.get("detail") or description[:160])[:160]
            parsed["classification_reason"] = str(
                parsed.get("classification_reason") or "Model-based classification."
            )[:140]
            return parsed

    return _fallback_activity(description)


def process_screenshot(session: Session, image_bytes: bytes, screenshot_path: Path | None = None) -> tuple[str, dict[str, Any]]:
    description = describe_screenshot(session, image_bytes)
    activity = classify_description(session, description)
    if screenshot_path:
        activity["screenshot_path"] = str(screenshot_path)
    return description, activity


def test_openrouter_api_key(api_key: str) -> tuple[bool, str]:
    if not api_key.strip():
        return False, "Missing API key."

    try:
        with httpx.Client(timeout=20.0) as client:
            response = client.get(
                "https://openrouter.ai/api/v1/models",
                headers=_headers(api_key.strip()),
            )
        if response.is_success:
            return True, "API key is valid."
        return False, f"OpenRouter returned {response.status_code}."
    except Exception as exc:
        return False, f"Validation failed: {exc}"
