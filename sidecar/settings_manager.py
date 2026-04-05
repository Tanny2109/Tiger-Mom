from __future__ import annotations

from typing import Any

from sqlalchemy.orm import Session

from .database import Setting
from dotenv import load_dotenv

load_dotenv()
import os
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY", "")
VISION_MODEL = "qwen/qwen3.6-plus:free"
BRAIN_MODEL = "qwen/qwen3.6-plus:free"
DEFAULT_SETTINGS: dict[str, str] = {
    "openrouter_api_key": OPENROUTER_API_KEY,
    "vision_model": VISION_MODEL,
    "brain_model": BRAIN_MODEL,
    "screenshot_interval": "120",
    "distraction_threshold": "15",
    "nudge_cooldown": "30",
    "work_hours_start": "09:00",
    "work_hours_end": "18:00",
    "tiger_mom_intensity": "medium",
    "track_outside_hours": "false",
    "pause_when_idle": "true",
    "enable_nudge_sounds": "true",
    "store_screenshots": "true",
    "launch_at_login": "false",
    "show_in_dock": "true",
    "start_tracking_on_launch": "false",
}

BOOL_KEYS = {
    "track_outside_hours",
    "pause_when_idle",
    "enable_nudge_sounds",
    "store_screenshots",
    "launch_at_login",
    "show_in_dock",
    "start_tracking_on_launch",
}
FLOAT_KEYS = {"screenshot_interval", "distraction_threshold", "nudge_cooldown"}


def seed_default_settings(session: Session) -> None:
    for key, value in DEFAULT_SETTINGS.items():
        if session.get(Setting, key) is None:
            session.add(Setting(key=key, value=value))
    session.flush()


def _canonical_key(key: str) -> str:
    alias_map = {
        "api_key": "openrouter_api_key",
        "intensity": "tiger_mom_intensity",
        "work_start_hour": "work_hours_start",
        "work_end_hour": "work_hours_end",
    }
    return alias_map.get(key, key)


def _serialize(key: str, value: Any) -> str:
    key = _canonical_key(key)
    if key in BOOL_KEYS:
        return "true" if bool(value) else "false"
    if key in {"work_hours_start", "work_hours_end"}:
        if isinstance(value, (int, float)):
            return f"{int(value):02d}:00"
        return str(value)
    if value is None:
        return ""
    return str(value)


def _parse_bool(value: str | None, default: bool = False) -> bool:
    if value is None:
        return default
    return str(value).strip().lower() in {"1", "true", "yes", "on"}


def _parse_float(value: str | None, default: float) -> float:
    try:
        if value is None or value == "":
            return default
        return float(value)
    except (TypeError, ValueError):
        return default


def _parse_hour(value: str | None, default: int) -> int:
    if not value:
        return default
    head = str(value).split(":", 1)[0]
    try:
        return int(head)
    except ValueError:
        return default


def get_raw_setting(session: Session, key: str, default: str | None = None) -> str | None:
    canonical = _canonical_key(key)
    row = session.get(Setting, canonical)
    if row is not None:
        return row.value
    return DEFAULT_SETTINGS.get(canonical, default)


def get_setting(session: Session, key: str, default: Any = None) -> Any:
    canonical = _canonical_key(key)
    raw = get_raw_setting(session, canonical, None)
    if canonical in BOOL_KEYS:
        return _parse_bool(raw, bool(default) if default is not None else False)
    if canonical in FLOAT_KEYS:
        default_value = float(default) if default is not None else float(DEFAULT_SETTINGS[canonical])
        return _parse_float(raw, default_value)
    if canonical in {"work_hours_start", "work_hours_end"}:
        return raw or DEFAULT_SETTINGS[canonical]
    return raw if raw is not None else default


def apply_updates(session: Session, updates: dict[str, Any]) -> None:
    for key, value in updates.items():
        canonical = _canonical_key(key)
        stored = _serialize(canonical, value)
        row = session.get(Setting, canonical)
        if row is None:
            session.add(Setting(key=canonical, value=stored))
        else:
            row.value = stored
    session.flush()


def get_api_key(session: Session) -> str:
    return str(get_setting(session, "openrouter_api_key", "") or "").strip()


def get_screenshot_interval_seconds(session: Session) -> int:
    return int(max(get_setting(session, "screenshot_interval", 120), 30))


def get_distraction_threshold_seconds(session: Session) -> int:
    raw = float(get_setting(session, "distraction_threshold", 15))
    return int(raw * 60 if raw <= 180 else raw)


def get_nudge_cooldown_seconds(session: Session) -> int:
    raw = float(get_setting(session, "nudge_cooldown", 30))
    return int(raw * 60 if raw <= 180 else raw)


def _display_minutes(raw: float) -> float:
    return round(raw / 60, 2) if raw > 180 else raw


def get_settings_payload(session: Session) -> dict[str, Any]:
    api_key = str(get_setting(session, "openrouter_api_key", "") or "")
    work_start = str(get_setting(session, "work_hours_start", "09:00"))
    work_end = str(get_setting(session, "work_hours_end", "18:00"))
    intensity = str(get_setting(session, "tiger_mom_intensity", "medium"))
    distraction_threshold = float(get_setting(session, "distraction_threshold", 15))
    nudge_cooldown = float(get_setting(session, "nudge_cooldown", 30))

    return {
        "openrouter_api_key": api_key,
        "api_key": api_key,
        "vision_model": str(get_setting(session, "vision_model", DEFAULT_SETTINGS["vision_model"])),
        "brain_model": str(get_setting(session, "brain_model", DEFAULT_SETTINGS["brain_model"])),
        "screenshot_interval": float(get_setting(session, "screenshot_interval", 120)),
        "distraction_threshold": _display_minutes(distraction_threshold),
        "nudge_cooldown": _display_minutes(nudge_cooldown),
        "work_hours_start": work_start,
        "work_hours_end": work_end,
        "work_start_hour": _parse_hour(work_start, 9),
        "work_end_hour": _parse_hour(work_end, 18),
        "tiger_mom_intensity": intensity,
        "intensity": intensity,
        "track_outside_hours": bool(get_setting(session, "track_outside_hours", False)),
        "pause_when_idle": bool(get_setting(session, "pause_when_idle", True)),
        "enable_nudge_sounds": bool(get_setting(session, "enable_nudge_sounds", True)),
        "store_screenshots": bool(get_setting(session, "store_screenshots", True)),
        "launch_at_login": bool(get_setting(session, "launch_at_login", False)),
        "show_in_dock": bool(get_setting(session, "show_in_dock", True)),
        "start_tracking_on_launch": bool(get_setting(session, "start_tracking_on_launch", False)),
    }
