from __future__ import annotations

import json
from collections import Counter
from datetime import datetime, time, timedelta
from typing import Any

from sqlalchemy import select
from sqlalchemy.orm import Session

from .database import Activity, DailySummary
from .llm import run_structured_agent
from .models import TigerMomCommentary
from .settings_manager import get_screenshot_interval_seconds, get_setting


CATEGORY_ORDER = ["Deep Work", "Communication", "Shallow Work", "Distraction", "Break"]


def _day_bounds(day: datetime | None = None) -> tuple[datetime, datetime]:
    now = day or datetime.now()
    start = datetime.combine(now.date(), time.min)
    end = start + timedelta(days=1)
    return start, end


def _activities_for_window(session: Session, start: datetime, end: datetime) -> list[Activity]:
    statement = (
        select(Activity)
        .where(Activity.timestamp >= start, Activity.timestamp < end)
        .order_by(Activity.timestamp.asc())
    )
    return list(session.scalars(statement))


def _category_minutes(activities: list[Activity], minutes_per_activity: int) -> dict[str, int]:
    totals = {category: 0 for category in CATEGORY_ORDER}
    for activity in activities:
        totals[activity.category if activity.category in totals else "Shallow Work"] += minutes_per_activity
    return totals


def _focus_score(totals: dict[str, int]) -> int:
    productive = totals["Deep Work"] * 1.0 + totals["Communication"] * 0.55 + totals["Shallow Work"] * 0.45
    total = sum(totals.values())
    if total == 0:
        return 0
    raw = (productive / total) * 100
    penalty = min(35, totals["Distraction"] // 4)
    return max(0, min(100, int(round(raw - penalty))))


def _top_distractors(activities: list[Activity]) -> list[str]:
    counts = Counter(activity.app_name for activity in activities if activity.category == "Distraction")
    return [name for name, _ in counts.most_common(3)]


def _grade(score: int) -> str:
    if score >= 90:
        return "A"
    if score >= 80:
        return "B"
    if score >= 70:
        return "C"
    if score >= 60:
        return "D"
    return "F"


def _fallback_commentary(totals: dict[str, int], score: int) -> str:
    if score >= 90:
        return "Fine. This is what competence looks like. Keep the momentum and don't get smug."
    if score >= 80:
        return "Solid day. You worked more than you wandered, which is already better than most people manage."
    if score >= 70:
        return "Decent effort, but there was too much drift. Trim the distractions and this becomes a strong day."
    if score >= 60:
        return "You kept touching work, but not with enough discipline. The day needs more deep focus and fewer detours."
    if totals["Distraction"] > totals["Deep Work"]:
        return "You spent more time distracted than doing deep work. That is not a schedule, that is a cautionary tale."
    return "Not your best showing. Reset tomorrow with one clear target and stop making side quests out of everything."


def _maybe_generate_commentary(session: Session, totals: dict[str, int], score: int, distractors: list[str]) -> str:
    stats_payload = {
        "focus_score": score,
        "deep_work_minutes": totals["Deep Work"],
        "communication_minutes": totals["Communication"],
        "shallow_work_minutes": totals["Shallow Work"],
        "distraction_minutes": totals["Distraction"],
        "top_distractors": distractors,
    }
    result = run_structured_agent(
        session,
        name="Daily Analytics Commentary",
        instructions="""You are Tiger Mom writing a daily report card comment.

Use the provided JSON data directly.
- Stay in character: sharp, funny, fair.
- Write 2-3 short sentences.
- Mention specifics from the stats when useful.
- Do not add markdown or bullet points.""",
        input_data=(
            "Here is today's productivity data as JSON.\n"
            f"{json.dumps(stats_payload, ensure_ascii=True)}"
        ),
        output_type=TigerMomCommentary,
        model_key="brain_model",
        default_model=str(get_setting(session, "brain_model", "qwen/qwen3.6-plus:free")),
        temperature=0.4,
        max_tokens=180,
    )
    return result.commentary.strip() if result else _fallback_commentary(totals, score)


def _serialize_categories(totals: dict[str, int]) -> list[dict[str, Any]]:
    return [
        {"name": category, "minutes": minutes, "type": category}
        for category, minutes in totals.items()
        if minutes > 0
    ]


def get_daily_analytics_payload(
    session: Session,
    *,
    include_report: bool = True,
    generate_report_if_missing: bool = True,
) -> dict[str, Any]:
    start, end = _day_bounds()
    activities = _activities_for_window(session, start, end)
    minutes_per_activity = max(1, get_screenshot_interval_seconds(session) // 60)
    totals = _category_minutes(activities, minutes_per_activity)
    distractors = _top_distractors(activities)
    score = _focus_score(totals)

    payload: dict[str, Any] = {
        "focus_score": score,
        "deep_work_minutes": totals["Deep Work"],
        "communication_minutes": totals["Communication"],
        "distraction_minutes": totals["Distraction"],
        "shallow_work_minutes": totals["Shallow Work"],
        "categories": _serialize_categories(totals),
        "top_distractors": distractors,
    }

    should_include_report = include_report and datetime.now().hour >= 18 and bool(activities)
    if should_include_report:
        day_key = start.date().isoformat()
        grade = _grade(score)
        summary = session.get(DailySummary, day_key) or DailySummary(date=day_key)
        summary.focus_score = score
        summary.deep_work_minutes = totals["Deep Work"]
        summary.distraction_minutes = totals["Distraction"]
        summary.shallow_work_minutes = totals["Shallow Work"]
        summary.categories_json = json.dumps(payload["categories"])
        summary.top_distractors_json = json.dumps(distractors)
        summary.grade = grade

        if summary.commentary:
            commentary = summary.commentary
        elif generate_report_if_missing:
            commentary = _maybe_generate_commentary(session, totals, score, distractors)
            summary.commentary = commentary
        else:
            commentary = _fallback_commentary(totals, score)

        session.merge(summary)
        payload["mom_report"] = {"grade": grade, "commentary": commentary}

    return payload


def get_weekly_analytics_payload(session: Session) -> dict[str, Any]:
    now = datetime.now()
    minutes_per_activity = max(1, get_screenshot_interval_seconds(session) // 60)
    days: list[dict[str, Any]] = []

    for offset in range(6, -1, -1):
        current = now - timedelta(days=offset)
        start, end = _day_bounds(current)
        activities = _activities_for_window(session, start, end)
        totals = _category_minutes(activities, minutes_per_activity)
        total_minutes = max(sum(totals.values()), 1)
        focus_hours = round((totals["Deep Work"] + totals["Communication"] + totals["Shallow Work"]) / 60.0, 1)
        distraction_percent = round((totals["Distraction"] / total_minutes) * 100, 1)
        days.append(
            {
                "label": current.strftime("%a"),
                "focus_hours": focus_hours,
                "distraction_percent": distraction_percent,
            }
        )

    return {"days": days}


def get_timeline_payload(session: Session) -> dict[str, Any]:
    start, end = _day_bounds()
    activities = _activities_for_window(session, start, end)
    minutes_per_activity = max(1, get_screenshot_interval_seconds(session) // 60)

    if not activities:
        return {"blocks": []}

    blocks: list[dict[str, Any]] = []
    first_timestamp = activities[0].timestamp

    for activity in activities:
        start_minute = int((activity.timestamp - first_timestamp).total_seconds() // 60)
        end_minute = start_minute + minutes_per_activity
        if blocks and blocks[-1]["type"] == activity.category and blocks[-1]["end_minute"] >= start_minute:
            blocks[-1]["end_minute"] = end_minute
        else:
            blocks.append(
                {
                    "start_minute": start_minute,
                    "end_minute": end_minute,
                    "type": activity.category,
                }
            )

    return {"blocks": blocks}


def get_recent_activities(session: Session, *, minutes: int = 60, limit: int = 12) -> list[Activity]:
    cutoff = datetime.now() - timedelta(minutes=minutes)
    statement = (
        select(Activity)
        .where(Activity.timestamp >= cutoff)
        .order_by(Activity.timestamp.desc())
        .limit(limit)
    )
    return list(session.scalars(statement))


def get_today_summary(session: Session) -> dict[str, Any]:
    return get_daily_analytics_payload(session, include_report=False, generate_report_if_missing=False)
