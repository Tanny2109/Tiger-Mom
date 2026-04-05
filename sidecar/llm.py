from __future__ import annotations

import base64
from functools import lru_cache
from typing import Any, TypeVar

from agents import Agent, ModelSettings, OpenAIProvider, RunConfig, Runner
from openai import AsyncOpenAI
from openrouter import OpenRouter
from pydantic import BaseModel
from sqlalchemy.orm import Session

from .settings_manager import get_api_key, get_setting


APP_NAME = "Tiger Mom"
APP_URL = "https://localhost/tiger-mom"
OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"

T = TypeVar("T", bound=BaseModel)


def _openrouter_headers() -> dict[str, str]:
    return {
        "HTTP-Referer": APP_URL,
        "X-Title": APP_NAME,
    }


@lru_cache(maxsize=8)
def _openrouter_client(api_key: str) -> OpenRouter:
    return OpenRouter(
        api_key=api_key,
        http_referer=APP_URL,
        x_open_router_title=APP_NAME,
        timeout_ms=20_000,
    )


@lru_cache(maxsize=8)
def _agents_run_config(api_key: str) -> RunConfig:
    openai_client = AsyncOpenAI(
        api_key=api_key,
        base_url=OPENROUTER_BASE_URL,
        default_headers=_openrouter_headers(),
        max_retries=2,
        timeout=20.0,
    )
    provider = OpenAIProvider(openai_client=openai_client, use_responses=False)
    return RunConfig(model_provider=provider, tracing_disabled=True)


def _text_from_openrouter_response(response: Any) -> str | None:
    try:
        choice = response.choices[0]
        content = choice.message.content
    except (AttributeError, IndexError, KeyError, TypeError):
        return None

    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        text_parts: list[str] = []
        for part in content:
            text = getattr(part, "text", None)
            if text:
                text_parts.append(str(text))
            elif isinstance(part, dict) and part.get("type") == "text" and part.get("text"):
                text_parts.append(str(part["text"]))
        return "\n".join(text_parts).strip() or None
    return None


def to_data_url(image_bytes: bytes) -> str:
    encoded = base64.b64encode(image_bytes).decode("utf-8")
    return f"data:image/jpeg;base64,{encoded}"


def openrouter_chat(
    session: Session,
    *,
    messages: list[dict[str, Any]],
    model_key: str = "brain_model",
    default_model: str = "qwen/qwen3.6-plus:free",
    temperature: float = 0.5,
    max_tokens: int = 220,
) -> str | None:
    api_key = get_api_key(session)
    model = str(get_setting(session, model_key, default_model) or default_model)
    if not api_key or not model:
        return None

    try:
        response = _openrouter_client(api_key).chat.send(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens,
        )
        return _text_from_openrouter_response(response)
    except Exception:
        return None


def run_structured_agent(
    session: Session,
    *,
    name: str,
    instructions: str,
    input_data: str | list[dict[str, Any]],
    output_type: type[T],
    model_key: str = "brain_model",
    default_model: str = "qwen/qwen3.6-plus:free",
    temperature: float = 0.2,
    max_tokens: int = 400,
) -> T | None:
    api_key = get_api_key(session)
    model = str(get_setting(session, model_key, default_model) or default_model)
    if not api_key or not model:
        return None

    agent = Agent(
        name=name,
        instructions=instructions,
        model=model,
        output_type=output_type,
        model_settings=ModelSettings(
            temperature=temperature,
            max_tokens=max_tokens,
        ),
    )

    try:
        result = Runner.run_sync(
            agent,
            input=input_data,
            max_turns=1,
            run_config=_agents_run_config(api_key),
        )
        if isinstance(result.final_output, output_type):
            return result.final_output
        return output_type.model_validate(result.final_output)
    except Exception:
        return None
