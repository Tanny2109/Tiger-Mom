from __future__ import annotations

from datetime import datetime, timedelta
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from .analytics import get_recent_activities, get_today_summary
from .classifier import call_openrouter_chat
from .database import Activity, ChatMessage, NudgeQueue, Nudge
from .settings_manager import (
    get_distraction_threshold_seconds,
    get_nudge_cooldown_seconds,
    get_screenshot_interval_seconds,
    get_setting,
)


TIGER_MOM_CHAT_SYSTEM = """You are Tiger Mom. You monitor your child's computer and they can chat with you anytime.
You know what they've been doing recently:
{recent_activity}
Today's stats so far:
{today_stats}
Intensity level: {intensity}

PERSONALITY:
- You're always in character. Never break the fourth wall.
- Reference their actual activity when relevant.
- If they ask how they are doing, give real feedback from the data.
- If they try to justify distraction, be skeptical but fair.
- You can be funny, warm, sarcastic, disappointed, or proud.
- Keep responses conversational and usually 1-4 sentences.
- You're not a generic assistant. You're their mom."""


def format_activities(activities: list[Any]) -> str:
    if not activities:
        return "No recent activity recorded."

    lines = []
    for activity in reversed(activities[:8]):
        stamp = activity.timestamp.strftime("%I:%M %p").lstrip("0")
        lines.append(f"- {stamp}: {activity.category} in {activity.app_name} ({activity.detail or activity.window_title})")
    return "\n".join(lines)


def format_stats(stats: dict[str, Any]) -> str:
    return (
        f"Focus score {stats.get('focus_score', 0)}. "
        f"Deep work {stats.get('deep_work_minutes', 0)} min. "
        f"Distraction {stats.get('distraction_minutes', 0)} min. "
        f"Shallow work {stats.get('shallow_work_minutes', 0)} min. "
        f"Communication {stats.get('communication_minutes', 0)} min."
    )


def _context_summary(session: Session) -> str:
    recent = get_recent_activities(session, minutes=60, limit=6)
    stats = get_today_summary(session)
    return f"{format_activities(recent)}\n{format_stats(stats)}"


def save_chat_message(session: Session, role: str, content: str, context_summary: str) -> ChatMessage:
    message = ChatMessage(role=role, content=content, context_summary=context_summary)
    session.add(message)
    session.flush()
    return message


def get_chat_history(session: Session, limit: int = 20) -> list[dict[str, str]]:
    statement = select(ChatMessage).order_by(ChatMessage.timestamp.desc()).limit(limit)
    rows = list(session.scalars(statement))
    rows.reverse()
    return [{"role": row.role, "content": row.content} for row in rows]


def get_chat_history_payload(session: Session, limit: int = 50) -> dict[str, Any]:
    statement = select(ChatMessage).order_by(ChatMessage.timestamp.desc()).limit(limit)
    rows = list(session.scalars(statement))
    rows.reverse()
    return {"messages": [row.to_dict() for row in rows]}


def _fallback_reply(user_msg: str, stats: dict[str, Any], recent_summary: str, intensity: str) -> str:
    lowered = user_msg.lower()
    deep = stats.get("deep_work_minutes", 0)
    distraction = stats.get("distraction_minutes", 0)
    score = stats.get("focus_score", 0)

    if "how am i doing" in lowered or "stats" in lowered or "on track" in lowered:
        return (
            f"You are at a focus score of {score}. "
            f"That is {deep} minutes of deep work and {distraction} minutes of distraction so far. "
            f"{'I am cautiously impressed.' if score >= 80 else 'There is room for dramatic improvement.'}"
        )
    if "focus" in lowered or "what should i" in lowered:
        return (
            f"Recent activity says: {recent_summary.splitlines()[-1] if recent_summary.splitlines() else 'not much yet'}. "
            "Pick one concrete task and stay there for the next block. No wandering."
        )
    if intensity == "fierce":
        return "You asked Tiger Mom, so here it is: stop negotiating with yourself and do the next important thing."
    if score >= 85:
        return "You are actually doing well. Do not waste the streak by opening something stupid now."
    return "You can still salvage this day. Close the distractions and give me one honest block of focused work."


def generate_chat_reply(session: Session, user_message: str) -> str:
    recent = get_recent_activities(session, minutes=60, limit=10)
    stats = get_today_summary(session)
    history = get_chat_history(session, limit=20)
    intensity = str(get_setting(session, "tiger_mom_intensity", "medium"))
    recent_summary = format_activities(recent)
    stats_summary = format_stats(stats)
    context_summary = f"{recent_summary}\n{stats_summary}"

    system_prompt = TIGER_MOM_CHAT_SYSTEM.format(
        recent_activity=recent_summary,
        today_stats=stats_summary,
        intensity=intensity,
    )
    model = str(get_setting(session, "brain_model", "openai/gpt-5-mini"))
    response = call_openrouter_chat(
        session,
        model,
        [
            {"role": "system", "content": system_prompt},
            *history,
            {"role": "user", "content": user_message},
        ],
        max_tokens=220,
        temperature=0.7,
    )
    reply = response.strip() if response else _fallback_reply(user_message, stats, recent_summary, intensity)

    save_chat_message(session, "user", user_message, context_summary)
    save_chat_message(session, "assistant", reply, context_summary)
    return reply


def _nudge_message(intensity: str, distraction_minutes: int, apps: list[str]) -> tuple[str, str, str]:
    app_phrase = ", ".join(apps[:2]) if apps else "whatever this is"
    if distraction_minutes >= 45 or intensity == "fierce":
        return (
            "🐯",
            f"{distraction_minutes} minutes distracted already, mostly in {app_phrase}. This is not a personality trait; close it and work.",
            "red",
        )
    if intensity == "gentle":
        return (
            "🐯",
            f"You've been drifting for about {distraction_minutes} minutes in {app_phrase}. Let's reset and get back on track.",
            "yellow",
        )
    return (
        "🐯",
        f"You've spent {distraction_minutes} distraction minutes in {app_phrase}. Explain yourself later. Refocus now.",
        "yellow",
    )


def maybe_queue_nudge(session: Session) -> NudgeQueue | None:
    now = datetime.now()
    pending = session.scalar(
        select(NudgeQueue)
        .where(NudgeQueue.status == "pending", NudgeQueue.available_at <= now)
        .order_by(NudgeQueue.created_at.asc())
    )
    if pending:
        return pending

    threshold_seconds = get_distraction_threshold_seconds(session)
    cooldown_seconds = get_nudge_cooldown_seconds(session)
    recent_cutoff = now - timedelta(seconds=threshold_seconds)

    recent_nudge = session.scalar(
        select(NudgeQueue)
        .where(NudgeQueue.created_at >= now - timedelta(seconds=cooldown_seconds))
        .order_by(NudgeQueue.created_at.desc())
    )
    if recent_nudge:
        return None

    recent = list(
        session.scalars(
            select(Activity)
            .where(Activity.timestamp >= recent_cutoff, Activity.category == "Distraction")
            .order_by(Activity.timestamp.desc())
        )
    )
    if not recent:
        return None

    interval_minutes = max(1, get_screenshot_interval_seconds(session) // 60)
    distraction_minutes = len(recent) * interval_minutes

    intensity = str(get_setting(session, "tiger_mom_intensity", "medium"))
    app_names = [activity.app_name for activity in recent if activity.app_name]
    emoji, message, severity = _nudge_message(intensity, distraction_minutes, app_names)
    queue_item = NudgeQueue(
        emoji=emoji,
        message=message,
        severity=severity,
        trigger="distraction_threshold",
        activity_window_minutes=distraction_minutes,
    )
    session.add(queue_item)
    session.flush()
    return queue_item


def record_nudge_response(session: Session, nudge_id: str, response: str) -> None:
    queue_item = session.get(NudgeQueue, int(nudge_id))
    now = datetime.now()

    if queue_item is not None:
        queue_item.status = "responded"
        queue_item.response = response
        queue_item.responded_at = now
        session.add(
            Nudge(
                queue_id=queue_item.id,
                emoji=queue_item.emoji,
                message=queue_item.message,
                severity=queue_item.severity,
                trigger=queue_item.trigger,
                response=response,
                responded_at=now,
            )
        )
        return

    session.add(
        Nudge(
            queue_id=None,
            emoji="🐯",
            message="Orphaned nudge response",
            severity="gray",
            trigger="unknown",
            response=response,
            responded_at=now,
        )
    )
