from __future__ import annotations

import json
from datetime import datetime
from pathlib import Path
from typing import Any

from fastapi import FastAPI, File, HTTPException, Query, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, or_, select

from .analytics import get_daily_analytics_payload, get_timeline_payload, get_weekly_analytics_payload
from .classifier import process_screenshot, test_openrouter_api_key
from .database import (
    DATABASE_PATH,
    SCREENSHOT_DIR,
    Activity,
    ChatMessage,
    DailySummary,
    Nudge,
    NudgeQueue,
    Setting,
    init_db,
    session_scope,
)
from .models import ApiKeyTestRequest, ChatRequest, NudgeResponseRequest
from .settings_manager import apply_updates, get_settings_payload, get_setting, seed_default_settings
from .tiger_mom import generate_chat_reply, get_chat_history_payload, maybe_queue_nudge, record_nudge_response


app = FastAPI(title="Tiger Mom Sidecar", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def reconfigure_scheduler() -> None:
    return None


def _recommended_models() -> dict[str, Any]:
    vision_models = [
        {"id": "qwen/qwen3.6-plus:free", "name": "Qwen3.6 Plus", "price": "$0/$0"},
    ]
    brain_models = [
        {"id": "qwen/qwen3.6-plus:free", "name": "Qwen3.6 Plus", "price": "$0/$0"},
    ]
    models = [*vision_models, *brain_models]
    return {"vision_models": vision_models, "brain_models": brain_models, "models": models}


def _save_screenshot(image_bytes: bytes) -> Path:
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    filename = datetime.now().strftime("%Y%m%d-%H%M%S-%f") + ".jpg"
    target = SCREENSHOT_DIR / filename
    target.write_bytes(image_bytes)
    return target


def _export_payload() -> dict[str, Any]:
    with session_scope() as session:
        return {
            "exported_at": datetime.utcnow().isoformat(),
            "settings": {row.key: row.value for row in session.scalars(select(Setting).order_by(Setting.key.asc()))},
            "activities": [row.to_dict() for row in session.scalars(select(Activity).order_by(Activity.timestamp.asc()))],
            "chat_messages": [row.to_dict() for row in session.scalars(select(ChatMessage).order_by(ChatMessage.timestamp.asc()))],
            "nudges": [
                {
                    "id": row.id,
                    "created_at": row.created_at.isoformat(),
                    "queue_id": row.queue_id,
                    "message": row.message,
                    "severity": row.severity,
                    "trigger": row.trigger,
                    "response": row.response,
                }
                for row in session.scalars(select(Nudge).order_by(Nudge.created_at.asc()))
            ],
            "daily_summaries": [
                {
                    "date": row.date,
                    "focus_score": row.focus_score,
                    "deep_work_minutes": row.deep_work_minutes,
                    "distraction_minutes": row.distraction_minutes,
                    "shallow_work_minutes": row.shallow_work_minutes,
                    "categories": json.loads(row.categories_json or "[]"),
                    "top_distractors": json.loads(row.top_distractors_json or "[]"),
                    "grade": row.grade,
                    "commentary": row.commentary,
                }
                for row in session.scalars(select(DailySummary).order_by(DailySummary.date.asc()))
            ],
        }


@app.on_event("startup")
def startup_event() -> None:
    init_db()
    with session_scope() as session:
        seed_default_settings(session)


@app.get("/health")
def health() -> dict[str, Any]:
    with session_scope() as session:
        return {
            "status": "ok",
            "database_path": str(DATABASE_PATH),
            "screenshots_path": str(SCREENSHOT_DIR),
            "activity_count": session.scalar(select(func.count()).select_from(Activity)) or 0,
            "chat_count": session.scalar(select(func.count()).select_from(ChatMessage)) or 0,
        }


@app.post("/screenshot")
async def screenshot(screenshot: UploadFile = File(...)) -> dict[str, Any]:
    image_bytes = await screenshot.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Screenshot payload was empty.")

    with session_scope() as session:
        store_screenshots = bool(get_setting(session, "store_screenshots", True))
        saved_path = _save_screenshot(image_bytes) if store_screenshots else None
        # calling vision model to see whats in screenshot...
        description, activity_data = process_screenshot(session, image_bytes, saved_path)

        activity = Activity(
            app_name=str(activity_data.get("app_name") or "Unknown App"),
            window_title=str(activity_data.get("window_title") or ""),
            category=str(activity_data.get("category") or "Shallow Work"),
            subcategory=str(activity_data.get("subcategory") or ""),
            detail=str(activity_data.get("detail") or ""),
            confidence=float(activity_data.get("confidence") or 0.0),
            classification_reason=str(activity_data.get("classification_reason") or ""),
            screenshot_path=str(saved_path or ""),
            description=description,
        )
        session.add(activity)
        session.flush()

        return {
            "status": "ok",
            "description": description,
            "activity": activity.to_dict(),
        }


@app.get("/nudge")
def get_nudge() -> dict[str, Any]:
    with session_scope() as session:
        queue_item = maybe_queue_nudge(session)
        if not queue_item:
            return {"has_nudge": False}
        return {"has_nudge": True, "nudge": queue_item.to_dict()}


@app.post("/nudge/response")
def nudge_response(payload: NudgeResponseRequest) -> dict[str, Any]:
    with session_scope() as session:
        record_nudge_response(session, payload.nudge_id, payload.response)
        return {"status": "logged"}


@app.post("/chat")
def chat(payload: ChatRequest) -> dict[str, Any]:
    with session_scope() as session:
        reply = generate_chat_reply(session, payload.content)
        return {"reply": reply}


@app.get("/chat/history")
def chat_history(limit: int = Query(default=50, ge=1, le=200)) -> dict[str, Any]:
    with session_scope() as session:
        return get_chat_history_payload(session, limit=limit)


@app.get("/activities")
def get_activities(
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=200),
    category: str | None = None,
) -> dict[str, Any]:
    with session_scope() as session:
        statement = select(Activity).order_by(Activity.timestamp.desc())
        if category:
            statement = statement.where(Activity.category == category)
        total = session.scalar(select(func.count()).select_from(statement.subquery())) or 0
        activities = list(session.scalars(statement.offset((page - 1) * limit).limit(limit)))
        return {"activities": [activity.to_dict() for activity in activities], "page": page, "total": total}


@app.get("/activities/search")
def search_activities(
    q: str = Query(default=""),
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=50, ge=1, le=200),
    category: str | None = None,
) -> dict[str, Any]:
    with session_scope() as session:
        statement = select(Activity).order_by(Activity.timestamp.desc())
        if category:
            statement = statement.where(Activity.category == category)
        if q.strip():
            pattern = f"%{q.strip()}%"
            statement = statement.where(
                or_(
                    Activity.app_name.ilike(pattern),
                    Activity.window_title.ilike(pattern),
                    Activity.detail.ilike(pattern),
                    Activity.subcategory.ilike(pattern),
                    Activity.classification_reason.ilike(pattern),
                )
            )
        total = session.scalar(select(func.count()).select_from(statement.subquery())) or 0
        activities = list(session.scalars(statement.offset((page - 1) * limit).limit(limit)))
        return {"activities": [activity.to_dict() for activity in activities], "page": page, "total": total, "query": q}


@app.get("/analytics/daily")
def analytics_daily(include_report: bool = Query(default=True)) -> dict[str, Any]:
    with session_scope() as session:
        return get_daily_analytics_payload(
            session,
            include_report=include_report,
            generate_report_if_missing=include_report,
        )


@app.get("/analytics/weekly")
def analytics_weekly() -> dict[str, Any]:
    with session_scope() as session:
        return get_weekly_analytics_payload(session)


@app.get("/analytics/timeline")
def analytics_timeline() -> dict[str, Any]:
    with session_scope() as session:
        return get_timeline_payload(session)


@app.get("/settings")
def get_settings() -> dict[str, Any]:
    with session_scope() as session:
        return get_settings_payload(session)


@app.put("/settings")
def put_settings(updates: dict[str, Any]) -> dict[str, Any]:
    with session_scope() as session:
        apply_updates(session, updates)
        reconfigure_scheduler()
        return {"status": "updated", "settings": get_settings_payload(session)}


@app.post("/settings")
def post_settings(updates: dict[str, Any]) -> dict[str, Any]:
    return put_settings(updates)


@app.post("/settings/test-key")
def settings_test_key(payload: ApiKeyTestRequest) -> dict[str, Any]:
    valid, detail = test_openrouter_api_key(payload.api_key)
    return {"valid": valid, "detail": detail}


@app.post("/settings/clear-data")
def clear_data() -> dict[str, Any]:
    with session_scope() as session:
        for model in (Activity, ChatMessage, Nudge, NudgeQueue, DailySummary):
            session.query(model).delete()
        for file_path in SCREENSHOT_DIR.glob("*.jpg"):
            file_path.unlink(missing_ok=True)
        return {"status": "cleared"}


@app.get("/settings/export")
def export_data() -> dict[str, Any]:
    return _export_payload()


@app.get("/models/available")
def list_models() -> dict[str, Any]:
    return _recommended_models()
