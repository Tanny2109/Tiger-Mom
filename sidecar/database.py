from __future__ import annotations

import json
from contextlib import contextmanager
from datetime import datetime
from pathlib import Path
from typing import Any, Iterator

from sqlalchemy import DateTime, Float, Integer, String, Text, create_engine
from sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column, sessionmaker


ROOT_DIR = Path(__file__).resolve().parent.parent
DATABASE_PATH = ROOT_DIR / "tiger_eye.db"
SCREENSHOT_DIR = ROOT_DIR / "screenshots"


def utcnow() -> datetime:
    return datetime.now()


class Base(DeclarativeBase):
    pass


class Activity(Base):
    __tablename__ = "activities"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=utcnow, index=True)
    app_name: Mapped[str] = mapped_column(String(255), default="Unknown App", index=True)
    window_title: Mapped[str] = mapped_column(String(500), default="")
    category: Mapped[str] = mapped_column(String(64), default="Shallow Work", index=True)
    subcategory: Mapped[str] = mapped_column(String(128), default="")
    detail: Mapped[str] = mapped_column(Text, default="")
    confidence: Mapped[float] = mapped_column(Float, default=0.0)
    classification_reason: Mapped[str] = mapped_column(Text, default="")
    screenshot_path: Mapped[str] = mapped_column(String(500), default="")
    description: Mapped[str] = mapped_column(Text, default="")

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": str(self.id),
            "timestamp": self.timestamp.timestamp(),
            "app_name": self.app_name,
            "window_title": self.window_title,
            "category": self.category,
            "subcategory": self.subcategory,
            "detail": self.detail,
            "confidence": round(self.confidence or 0.0, 3),
            "classification_reason": self.classification_reason,
            "screenshot_path": self.screenshot_path,
            "description": self.description,
        }


class Nudge(Base):
    __tablename__ = "nudges"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, index=True)
    queue_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    emoji: Mapped[str] = mapped_column(String(16), default="🐯")
    message: Mapped[str] = mapped_column(Text, default="")
    severity: Mapped[str] = mapped_column(String(32), default="yellow")
    trigger: Mapped[str] = mapped_column(String(128), default="")
    response: Mapped[str] = mapped_column(Text, default="")
    responded_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)


class DailySummary(Base):
    __tablename__ = "daily_summaries"

    date: Mapped[str] = mapped_column(String(16), primary_key=True)
    focus_score: Mapped[int] = mapped_column(Integer, default=0)
    deep_work_minutes: Mapped[int] = mapped_column(Integer, default=0)
    distraction_minutes: Mapped[int] = mapped_column(Integer, default=0)
    shallow_work_minutes: Mapped[int] = mapped_column(Integer, default=0)
    categories_json: Mapped[str] = mapped_column(Text, default="[]")
    top_distractors_json: Mapped[str] = mapped_column(Text, default="[]")
    grade: Mapped[str] = mapped_column(String(8), default="")
    commentary: Mapped[str] = mapped_column(Text, default="")

    def categories(self) -> list[dict[str, Any]]:
        return json.loads(self.categories_json or "[]")

    def top_distractors(self) -> list[str]:
        return json.loads(self.top_distractors_json or "[]")


class NudgeQueue(Base):
    __tablename__ = "nudge_queue"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, index=True)
    available_at: Mapped[datetime] = mapped_column(DateTime, default=utcnow, index=True)
    status: Mapped[str] = mapped_column(String(32), default="pending", index=True)
    emoji: Mapped[str] = mapped_column(String(16), default="🐯")
    message: Mapped[str] = mapped_column(Text, default="")
    severity: Mapped[str] = mapped_column(String(32), default="yellow")
    trigger: Mapped[str] = mapped_column(String(128), default="")
    response: Mapped[str] = mapped_column(Text, default="")
    responded_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    activity_window_minutes: Mapped[int] = mapped_column(Integer, default=0)

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": str(self.id),
            "emoji": self.emoji,
            "message": self.message,
            "severity": self.severity,
            "trigger": self.trigger,
            "created_at": self.created_at.timestamp(),
            "activity_window_minutes": self.activity_window_minutes,
        }


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=utcnow, index=True)
    role: Mapped[str] = mapped_column(String(32), default="user")
    content: Mapped[str] = mapped_column(Text, default="")
    context_summary: Mapped[str] = mapped_column(Text, default="")

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": str(self.id),
            "role": self.role,
            "is_user": self.role == "user",
            "content": self.content,
            "timestamp": self.timestamp.timestamp(),
            "context_summary": self.context_summary,
        }


class Setting(Base):
    __tablename__ = "settings"

    key: Mapped[str] = mapped_column(String(128), primary_key=True)
    value: Mapped[str] = mapped_column(Text, default="")


engine = create_engine(
    f"sqlite:///{DATABASE_PATH}",
    connect_args={"check_same_thread": False},
    future=True,
)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, expire_on_commit=False)


def init_db() -> None:
    SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)
    Base.metadata.create_all(bind=engine)


@contextmanager
def session_scope() -> Iterator[Session]:
    session = SessionLocal()
    try:
        yield session
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()
