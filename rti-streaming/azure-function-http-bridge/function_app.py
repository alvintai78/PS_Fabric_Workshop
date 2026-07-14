import json
import os
import random
import time
from datetime import datetime, timezone

import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)

SERVICES = [
    ("SVC001", "AGY003"),
    ("SVC002", "AGY001"),
    ("SVC003", "AGY006"),
    ("SVC004", "AGY002"),
    ("SVC005", "AGY004"),
    ("SVC006", "AGY005"),
    ("SVC007", "AGY007"),
    ("SVC008", "AGY008"),
    ("SVC009", "AGY001"),
    ("SVC010", "AGY006"),
    ("SVC011", "AGY002"),
    ("SVC012", "AGY004"),
]
CHANNELS = ["CH001", "CH002", "CH003", "CH004", "CH005"]
EVENT_TYPES = ["Submitted", "Assigned", "StatusChanged", "Escalated", "Resolved"]
STATUSES = ["New", "In Progress", "Pending Citizen", "Resolved", "Closed"]


def generate_event() -> dict[str, object]:
    service_id, agency_id = random.choice(SERVICES)
    event_type = random.choices(EVENT_TYPES, weights=[40, 20, 20, 8, 12], k=1)[0]
    status = "New" if event_type == "Submitted" else random.choice(STATUSES)
    request_number = random.randint(1, 10_000)
    event_suffix = int(time.time() * 1000) % 1_000_000_000
    return {
        "EventId": f"EVTHTTP{event_suffix}{random.randint(100, 999)}",
        "RequestId": f"REQ{request_number:06d}",
        "EventDateTime": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "ServiceId": service_id,
        "AgencyId": agency_id,
        "ChannelId": random.choice(CHANNELS),
        "EventType": event_type,
        "Status": status,
        "ProcessingDurationSeconds": random.randint(0, 7200),
        "SLAElapsedPercent": round(random.uniform(0, 120), 2),
    }


def requested_batch_size(req: func.HttpRequest) -> int:
    default_batch_size = int(os.getenv("DEFAULT_BATCH_SIZE", "25"))
    raw_value = req.params.get("batchSize")
    if raw_value is None:
        return default_batch_size
    try:
        return max(1, min(1000, int(raw_value)))
    except ValueError:
        return default_batch_size


@app.function_name(name="HttpToFabricEventstream")
@app.route(route="events", methods=["GET"])
def http_to_fabric_eventstream(req: func.HttpRequest) -> func.HttpResponse:
    """Return generated service events for Fabric Eventstream HTTP source."""
    batch_size = requested_batch_size(req)
    events = [generate_event() for _ in range(batch_size)]
    return func.HttpResponse(
        json.dumps(events),
        mimetype="application/json",
        status_code=200,
    )


@app.function_name(name="Health")
@app.route(route="health", methods=["GET"])
def health(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse(
        json.dumps({"status": "ok", "defaultBatchSize": os.getenv("DEFAULT_BATCH_SIZE", "25")}),
        mimetype="application/json",
        status_code=200,
    )
