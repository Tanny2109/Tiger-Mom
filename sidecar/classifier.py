from __future__ import annotations

from pathlib import Path

import httpx
from sqlalchemy.orm import Session

from .llm import run_structured_agent, to_data_url
from .models import ScreenshotAnalysis


SCREENSHOT_ANALYSIS_INSTRUCTIONS = """You analyze desktop screenshots for a productivity tracker.

Look directly at the screenshot and return one structured result with:
- a concise factual description of what is visible
- the most likely active app
- the most likely window title
- one category from exactly: Deep Work, Communication, Shallow Work, Distraction, Break
- a subcategory
- a short detail line
- a confidence score from 0 to 1
- a short classification reason

Use your best judgment from the image itself. Do not hedge unless the screenshot is genuinely ambiguous.
Keep detail concise and concrete."""


def _fallback_analysis() -> ScreenshotAnalysis:
    return ScreenshotAnalysis(
        description="A desktop screenshot was captured, but no model analysis is available.",
        app_name="Unknown App",
        window_title="Desktop activity",
        category="Shallow Work",
        subcategory="Unknown",
        detail="Unable to classify this screenshot.",
        confidence=0.2,
        classification_reason="Fallback classification used because the model was unavailable.",
    )


def process_screenshot(
    session: Session,
    image_bytes: bytes,
    screenshot_path: Path | None = None,
) -> tuple[str, dict[str, object]]:
    analysis = run_structured_agent(
        session,
        name="Screenshot Analyzer",
        instructions=SCREENSHOT_ANALYSIS_INSTRUCTIONS,
        input_data=[
            {
                "role": "user",
                "content": [
                    {"type": "input_text", "text": "Analyze this screenshot."},
                    {"type": "input_image", "image_url": to_data_url(image_bytes)},
                ],
            }
        ],
        output_type=ScreenshotAnalysis,
        model_key="vision_model",
        default_model="qwen/qwen3.6-plus:free",
        temperature=0.1,
        max_tokens=500,
    ) or _fallback_analysis()

    activity = analysis.model_dump()
    if screenshot_path:
        activity["screenshot_path"] = str(screenshot_path)
    return analysis.description, activity


def test_openrouter_api_key(api_key: str) -> tuple[bool, str]:
    if not api_key.strip():
        return False, "Missing API key."

    try:
        with httpx.Client(timeout=20.0) as client:
            response = client.get(
                "https://openrouter.ai/api/v1/models",
                headers={
                    "Authorization": f"Bearer {api_key.strip()}",
                    "HTTP-Referer": "https://localhost/tiger-mom",
                    "X-Title": "Tiger Mom",
                },
            )
        if response.is_success:
            return True, "API key is valid."
        return False, f"OpenRouter returned {response.status_code}."
    except Exception as exc:
        return False, f"Validation failed: {exc}"
