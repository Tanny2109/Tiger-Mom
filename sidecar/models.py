from __future__ import annotations

from pydantic import BaseModel, Field


class ChatRequest(BaseModel):
    content: str = Field(min_length=1, max_length=4000)


class NudgeResponseRequest(BaseModel):
    nudge_id: str
    response: str = Field(min_length=1, max_length=2000)


class ApiKeyTestRequest(BaseModel):
    api_key: str = Field(default="")
