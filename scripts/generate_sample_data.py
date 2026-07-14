#!/usr/bin/env python3
"""Generate synthetic public-sector workshop CSV data."""

from __future__ import annotations

import csv
import random
from datetime import date, datetime, timedelta
from pathlib import Path

SEED = 20260608
REQUEST_COUNT = 10_000
FEEDBACK_COUNT = 3_000
EVENT_COUNT_TARGET = 30_000
START_DATE = date(2025, 6, 1)
END_DATE = date(2026, 5, 31)
ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "data"

random.seed(SEED)

AGENCIES = [
    ("AGY001", "Digital Services Office", "TM001", "Citizen Portal Team", "Digital Services", "Central"),
    ("AGY002", "Municipal Services Group", "TM002", "Case Operations Team", "Municipal Services", "East"),
    ("AGY003", "Business Licensing Office", "TM003", "Licensing Review Team", "Licensing", "West"),
    ("AGY004", "Transport Services Office", "TM004", "Mobility Response Team", "Transport", "North"),
    ("AGY005", "Housing Support Office", "TM005", "Housing Assistance Team", "Housing", "North-East"),
    ("AGY006", "Community Grants Office", "TM006", "Grant Operations Team", "Grants", "Central"),
    ("AGY007", "Public Health Services Office", "TM007", "Health Service Desk", "Health", "East"),
    ("AGY008", "Employment Support Office", "TM008", "Workforce Case Team", "Employment", "West"),
]

SERVICES = [
    ("SVC001", "Permit Application", "Licensing", "Integrated", True, "AGY003", 12),
    ("SVC002", "Service Feedback", "Citizen Experience", "Basic", False, "AGY001", 6),
    ("SVC003", "Grant Status Check", "Grants", "Proactive", True, "AGY006", 8),
    ("SVC004", "Facility Issue Report", "Municipal Services", "Integrated", True, "AGY002", 13),
    ("SVC005", "Public Transport Appeal", "Transport", "Integrated", True, "AGY004", 7),
    ("SVC006", "Housing Assistance Request", "Housing", "Basic", True, "AGY005", 10),
    ("SVC007", "Vaccination Appointment Support", "Health", "Proactive", True, "AGY007", 6),
    ("SVC008", "Employment Support Enquiry", "Employment", "Integrated", False, "AGY008", 6),
    ("SVC009", "Digital Account Help", "Digital Services", "Proactive", True, "AGY001", 11),
    ("SVC010", "Business Grant Application", "Grants", "Integrated", True, "AGY006", 8),
    ("SVC011", "Noise Complaint", "Municipal Services", "Basic", False, "AGY002", 7),
    ("SVC012", "Road Defect Report", "Transport", "Integrated", True, "AGY004", 6),
]

CHANNELS = [
    ("CH001", "Web", "Digital", 34),
    ("CH002", "Mobile App", "Digital", 28),
    ("CH003", "Call Centre", "Assisted", 18),
    ("CH004", "Service Centre", "Physical", 8),
    ("CH005", "Chatbot", "Digital", 12),
]

PRIORITY_WEIGHTS = {"Low": 12, "Normal": 60, "High": 22, "Urgent": 6}
SLA_TARGETS = {"Low": 120, "Normal": 72, "High": 48, "Urgent": 24}
SEGMENTS = ["Resident", "Business User", "Senior", "Caregiver", "Community Partner", "Visitor"]
FEEDBACK_CATEGORIES = ["Wait Time", "Usability", "Clarity", "Staff Support", "Outcome"]
PUBLIC_HOLIDAYS = {date(2025, 8, 9), date(2025, 12, 25), date(2026, 1, 1), date(2026, 2, 17), date(2026, 2, 18), date(2026, 5, 1)}

AGENCY_BY_ID = {row[0]: row for row in AGENCIES}
SERVICE_BY_ID = {row[0]: row for row in SERVICES}


def bool_text(value: bool) -> str:
    return "True" if value else "False"


def dt_text(value: datetime | None) -> str:
    return "" if value is None else value.strftime("%Y-%m-%d %H:%M")


def date_key(value: date) -> int:
    return value.year * 10000 + value.month * 100 + value.day


def weighted(items: list[tuple[str, int]]) -> str:
    return random.choices([item[0] for item in items], weights=[item[1] for item in items], k=1)[0]


def write_csv(path: Path, rows: list[dict[str, object]], fieldnames: list[str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def parse_dt(value: object) -> datetime | None:
    text = str(value)
    return None if not text else datetime.strptime(text, "%Y-%m-%d %H:%M")


def build_dim_date() -> list[dict[str, object]]:
    rows = []
    current = START_DATE
    while current <= END_DATE:
        rows.append({
            "DateKey": date_key(current),
            "Date": current.isoformat(),
            "Year": current.year,
            "Quarter": f"Q{((current.month - 1) // 3) + 1}",
            "MonthNumber": current.month,
            "MonthName": current.strftime("%B"),
            "WeekdayName": current.strftime("%A"),
            "IsWeekend": bool_text(current.weekday() >= 5),
            "IsPublicHoliday": bool_text(current in PUBLIC_HOLIDAYS),
        })
        current += timedelta(days=1)
    return rows


def build_dim_sla() -> list[dict[str, object]]:
    rows = []
    counter = 1
    for service in SERVICES:
        for priority, target in SLA_TARGETS.items():
            rows.append({
                "SLAId": f"SLA{counter:03d}",
                "ServiceId": service[0],
                "Priority": priority,
                "TargetResolutionHours": target,
                "EscalationThresholdHours": max(4, int(target * 0.65)),
            })
            counter += 1
    return rows


def pick_submission_date() -> date:
    days = (END_DATE - START_DATE).days + 1
    while True:
        candidate = START_DATE + timedelta(days=random.randrange(days))
        weight = 1.0
        if candidate.weekday() >= 5:
            weight *= 0.45
        if candidate.month in {8, 11, 3}:
            weight *= 1.45
        if candidate in PUBLIC_HOLIDAYS:
            weight *= 0.35
        if random.random() <= min(1.0, weight):
            return candidate


def pick_submission_datetime() -> datetime:
    selected = pick_submission_date()
    if selected.weekday() >= 5:
        hour = random.choices([9, 10, 11, 14, 15, 16, 20, 21], weights=[10, 10, 8, 10, 10, 8, 4, 3], k=1)[0]
    else:
        hour = random.choices(range(7, 23), weights=[4, 8, 14, 12, 10, 8, 7, 8, 10, 12, 13, 11, 8, 6, 5, 4], k=1)[0]
    return datetime(selected.year, selected.month, selected.day, hour, random.randrange(60))


def build_requests(sla_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    service_weights = [(service[0], service[6]) for service in SERVICES]
    channel_weights = [(channel[0], channel[3]) for channel in CHANNELS]
    priority_weights = list(PRIORITY_WEIGHTS.items())
    sla_id = {(row["ServiceId"], row["Priority"]): row["SLAId"] for row in sla_rows}
    rows = []
    for index in range(1, REQUEST_COUNT + 1):
        service_id = weighted(service_weights)
        service = SERVICE_BY_ID[service_id]
        agency_id = service[5]
        agency = AGENCY_BY_ID[agency_id]
        channel_id = weighted(channel_weights)
        priority = weighted(priority_weights)
        submitted = pick_submission_datetime()
        target = SLA_TARGETS[priority]
        is_open = random.random() < {"Low": 0.12, "Normal": 0.17, "High": 0.20, "Urgent": 0.15}[priority]
        if is_open:
            status = random.choices(["New", "In Progress", "Pending Citizen"], weights=[20, 60, 20], k=1)[0]
            resolution_hours = ""
            resolved = None
            breached = False
            backlog = True
        else:
            pressure = 1.0
            if service_id in {"SVC004", "SVC006", "SVC010"}:
                pressure += 0.25
            if channel_id in {"CH003", "CH004"}:
                pressure += 0.15
            if channel_id in {"CH002", "CH005"}:
                pressure -= 0.10
            breach_probability = {"Low": 0.08, "Normal": 0.14, "High": 0.20, "Urgent": 0.24}[priority]
            if service_id in {"SVC004", "SVC006", "SVC010"}:
                breach_probability += 0.08
            breached = random.random() < breach_probability
            hours = random.uniform(target * 1.05, target * 2.2) * pressure if breached else random.uniform(target * 0.18, target * 0.95) * pressure
            resolution_hours = f"{hours:.2f}"
            resolved = submitted + timedelta(hours=hours)
            status = random.choices(["Resolved", "Closed"], weights=[72, 28], k=1)[0]
            backlog = False
        rows.append({
            "RequestId": f"REQ{index:06d}",
            "DateKey": date_key(submitted.date()),
            "ServiceId": service_id,
            "AgencyId": agency_id,
            "ChannelId": channel_id,
            "SLAId": sla_id[(service_id, priority)],
            "CitizenSegment": random.choice(SEGMENTS),
            "SubmittedDateTime": dt_text(submitted),
            "ResolvedDateTime": dt_text(resolved),
            "Status": status,
            "Priority": priority,
            "AssignedTeam": agency[3],
            "ResolutionHours": resolution_hours,
            "IsSLABreached": bool_text(breached),
            "BacklogFlag": bool_text(backlog),
        })
    return rows


def build_feedback(requests: list[dict[str, object]]) -> list[dict[str, object]]:
    closed = [row for row in requests if row["ResolvedDateTime"]]
    rows = []
    for index, request in enumerate(random.sample(closed, FEEDBACK_COUNT), start=1):
        breached = request["IsSLABreached"] == "True"
        weak_service = request["ServiceId"] in {"SVC004", "SVC006"}
        if breached or weak_service:
            rating = random.choices([1, 2, 3, 4, 5], weights=[8, 20, 36, 26, 10], k=1)[0]
        else:
            rating = random.choices([1, 2, 3, 4, 5], weights=[2, 7, 22, 42, 27], k=1)[0]
        sentiment = "Negative" if rating <= 2 else "Neutral" if rating == 3 else "Positive"
        resolved = parse_dt(request["ResolvedDateTime"])
        feedback_at = resolved + timedelta(minutes=random.randrange(15, 4320)) if resolved else None
        if feedback_at and feedback_at.date() > END_DATE:
            feedback_at = datetime(END_DATE.year, END_DATE.month, END_DATE.day, 17, random.randrange(60))
        rows.append({
            "FeedbackId": f"FB{index:06d}",
            "RequestId": request["RequestId"],
            "DateKey": date_key(feedback_at.date()) if feedback_at else request["DateKey"],
            "Rating": rating,
            "FeedbackCategory": "Wait Time" if breached and random.random() < 0.45 else random.choice(FEEDBACK_CATEGORIES),
            "Sentiment": sentiment,
            "FeedbackDateTime": dt_text(feedback_at),
        })
    return rows


def event_row(index: int, request: dict[str, object], event_at: datetime, event_type: str, status: str, duration: int, sla_elapsed: float) -> dict[str, object]:
    return {
        "EventId": f"EVT{index:06d}",
        "RequestId": request["RequestId"],
        "EventDateTime": dt_text(event_at),
        "ServiceId": request["ServiceId"],
        "AgencyId": request["AgencyId"],
        "ChannelId": request["ChannelId"],
        "EventType": event_type,
        "Status": status,
        "ProcessingDurationSeconds": duration,
        "SLAElapsedPercent": f"{sla_elapsed:.2f}",
    }


def build_events(requests: list[dict[str, object]], sla_rows: list[dict[str, object]]) -> list[dict[str, object]]:
    target_by_sla = {row["SLAId"]: int(row["TargetResolutionHours"]) * 3600 for row in sla_rows}
    rows = []
    event_index = 1
    for request in requests:
        submitted = parse_dt(request["SubmittedDateTime"])
        if submitted is None:
            continue
        target_seconds = target_by_sla[request["SLAId"]]
        rows.append(event_row(event_index, request, submitted, "Submitted", "New", 0, 0.0))
        event_index += 1
        assigned = submitted + timedelta(seconds=random.randrange(900, 7200))
        rows.append(event_row(event_index, request, assigned, "Assigned", "In Progress", int((assigned - submitted).total_seconds()), (assigned - submitted).total_seconds() / target_seconds * 100))
        event_index += 1
        current = assigned
        resolved = parse_dt(request["ResolvedDateTime"])
        if request["BacklogFlag"] == "True":
            follow_up = current + timedelta(seconds=random.randrange(7200, 86400))
            elapsed = (follow_up - submitted).total_seconds() / target_seconds * 100
            event_type = "Escalated" if elapsed >= 65 else "StatusChanged"
            rows.append(event_row(event_index, request, follow_up, event_type, str(request["Status"]), int((follow_up - current).total_seconds()), min(160, elapsed)))
            event_index += 1
            continue
        if resolved is None:
            continue
        if request["IsSLABreached"] == "True" or random.random() < 0.18:
            halfway = submitted + (resolved - submitted) * random.uniform(0.55, 0.85)
            if halfway > current:
                elapsed = (halfway - submitted).total_seconds() / target_seconds * 100
                rows.append(event_row(event_index, request, halfway, "Escalated", "In Progress", int((halfway - current).total_seconds()), min(160, elapsed)))
                event_index += 1
                current = halfway
        elapsed = (resolved - submitted).total_seconds() / target_seconds * 100
        rows.append(event_row(event_index, request, resolved, "Resolved", str(request["Status"]), max(60, int((resolved - current).total_seconds())), min(220, elapsed)))
        event_index += 1
    spike_start = datetime(2026, 5, 20, 10, 0)
    spike_requests = [row for row in requests if row["ServiceId"] in {"SVC004", "SVC009", "SVC012"}]
    event_types = [("Submitted", 42), ("Assigned", 18), ("StatusChanged", 22), ("Escalated", 10), ("Resolved", 8)]
    while len(rows) < EVENT_COUNT_TARGET:
        request = random.choice(spike_requests)
        event_at = spike_start + timedelta(minutes=random.randrange(120), seconds=random.randrange(60))
        rows.append(event_row(event_index, request, event_at, weighted(event_types), random.choice(["New", "In Progress", "Pending Citizen"]), random.randrange(30, 1800), random.uniform(5, 95)))
        event_index += 1
    rows.sort(key=lambda row: (row["EventDateTime"], row["EventId"]))
    for index, row in enumerate(rows, start=1):
        row["EventId"] = f"EVT{index:06d}"
    return rows


def main() -> None:
    agency_rows = [{"AgencyId": row[0], "AgencyName": row[1], "TeamId": row[2], "TeamName": row[3], "ServiceDomain": row[4], "Region": row[5]} for row in AGENCIES]
    service_rows = [{"ServiceId": row[0], "ServiceType": row[1], "ServiceCategory": row[2], "DigitalMaturityLevel": row[3], "IsCriticalService": bool_text(row[4])} for row in SERVICES]
    channel_rows = [{"ChannelId": row[0], "ChannelName": row[1], "ChannelType": row[2]} for row in CHANNELS]
    date_rows = build_dim_date()
    sla_rows = build_dim_sla()
    request_rows = build_requests(sla_rows)
    feedback_rows = build_feedback(request_rows)
    event_rows = build_events(request_rows, sla_rows)

    write_csv(DATA_DIR / "DimAgency.csv", agency_rows, ["AgencyId", "AgencyName", "TeamId", "TeamName", "ServiceDomain", "Region"])
    write_csv(DATA_DIR / "DimService.csv", service_rows, ["ServiceId", "ServiceType", "ServiceCategory", "DigitalMaturityLevel", "IsCriticalService"])
    write_csv(DATA_DIR / "DimChannel.csv", channel_rows, ["ChannelId", "ChannelName", "ChannelType"])
    write_csv(DATA_DIR / "DimDate.csv", date_rows, ["DateKey", "Date", "Year", "Quarter", "MonthNumber", "MonthName", "WeekdayName", "IsWeekend", "IsPublicHoliday"])
    write_csv(DATA_DIR / "DimSLA.csv", sla_rows, ["SLAId", "ServiceId", "Priority", "TargetResolutionHours", "EscalationThresholdHours"])
    write_csv(DATA_DIR / "FactServiceRequest.csv", request_rows, ["RequestId", "DateKey", "ServiceId", "AgencyId", "ChannelId", "SLAId", "CitizenSegment", "SubmittedDateTime", "ResolvedDateTime", "Status", "Priority", "AssignedTeam", "ResolutionHours", "IsSLABreached", "BacklogFlag"])
    write_csv(DATA_DIR / "FactCitizenFeedback.csv", feedback_rows, ["FeedbackId", "RequestId", "DateKey", "Rating", "FeedbackCategory", "Sentiment", "FeedbackDateTime"])
    write_csv(DATA_DIR / "FactServiceEventStream.csv", event_rows, ["EventId", "RequestId", "EventDateTime", "ServiceId", "AgencyId", "ChannelId", "EventType", "Status", "ProcessingDurationSeconds", "SLAElapsedPercent"])

    for name, rows in [
        ("DimAgency", agency_rows),
        ("DimService", service_rows),
        ("DimChannel", channel_rows),
        ("DimDate", date_rows),
        ("DimSLA", sla_rows),
        ("FactServiceRequest", request_rows),
        ("FactCitizenFeedback", feedback_rows),
        ("FactServiceEventStream", event_rows),
    ]:
        print(f"{name}: {len(rows)}")


if __name__ == "__main__":
    main()
