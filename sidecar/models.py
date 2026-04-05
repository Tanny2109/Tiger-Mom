from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    content: str = Field(min_length=1, max_length=4000)


class NudgeResponseRequest(BaseModel):
    nudge_id: str
    response: str = Field(min_length=1, max_length=2000)


class ApiKeyTestRequest(BaseModel):
    api_key: str = Field(default="")


class ScreenshotAnalysis(BaseModel):
    description: str = Field(min_length=1, max_length=1200)
    app_name: str = Field(min_length=1, max_length=255)
    window_title: str = Field(min_length=1, max_length=500)
    category: Literal["Deep Work", "Communication", "Shallow Work", "Distraction", "Break"]
    subcategory: str = Field(min_length=1, max_length=128)
    detail: str = Field(min_length=1, max_length=160)
    confidence: float = Field(ge=0.0, le=1.0)
    classification_reason: str = Field(min_length=1, max_length=240)


class TigerMomCommentary(BaseModel):
    commentary: str = Field(min_length=1, max_length=600)


class TigerMomNudgeCopy(BaseModel):
    message: str = Field(min_length=1, max_length=240)
    severity: Literal["gray", "yellow", "red"] = "yellow"
    emoji: str = Field(default="🐯", min_length=1, max_length=16)
