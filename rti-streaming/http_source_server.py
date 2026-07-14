#!/usr/bin/env python3
"""Serve synthetic service events over HTTP for Fabric Eventstream HTTP source.

Fabric Eventstream HTTP source pulls JSON from a public HTTP endpoint at an
interval. This app exposes CSV rows from FactServiceEventStream.csv as JSON
batches so Fabric can ingest them without Azure Functions or Azure Event Hubs.
"""

from __future__ import annotations

import argparse
import csv
import json
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

DEFAULT_CSV = Path(__file__).resolve().parents[1] / "data" / "FactServiceEventStream.csv"


class EventStore:
    def __init__(self, csv_path: Path, default_batch_size: int, realtime_timestamps: bool) -> None:
        self.csv_path = csv_path
        self.default_batch_size = default_batch_size
        self.realtime_timestamps = realtime_timestamps
        self.rows = self._load_rows(csv_path)
        self.cursor = 0

    def _load_rows(self, csv_path: Path) -> list[dict[str, object]]:
        with csv_path.open(newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            return [self._normalize_row(row) for row in reader]

    def _normalize_row(self, row: dict[str, str]) -> dict[str, object]:
        return {
            "EventId": row["EventId"],
            "RequestId": row["RequestId"],
            "EventDateTime": row["EventDateTime"],
            "ServiceId": row["ServiceId"],
            "AgencyId": row["AgencyId"],
            "ChannelId": row["ChannelId"],
            "EventType": row["EventType"],
            "Status": row["Status"],
            "ProcessingDurationSeconds": int(row["ProcessingDurationSeconds"]),
            "SLAElapsedPercent": float(row["SLAElapsedPercent"]),
        }

    def next_batch(self, requested_batch_size: int | None = None) -> list[dict[str, object]]:
        if not self.rows:
            return []

        batch_size = requested_batch_size or self.default_batch_size
        batch: list[dict[str, object]] = []
        for _ in range(batch_size):
            row = dict(self.rows[self.cursor])
            if self.realtime_timestamps:
                row["EventDateTime"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
            batch.append(row)
            self.cursor = (self.cursor + 1) % len(self.rows)
        return batch

    def reset(self) -> None:
        self.cursor = 0

    def status(self) -> dict[str, object]:
        return {
            "csvPath": str(self.csv_path),
            "rowCount": len(self.rows),
            "cursor": self.cursor,
            "defaultBatchSize": self.default_batch_size,
            "realtimeTimestamps": self.realtime_timestamps,
        }


def make_handler(store: EventStore):
    class EventRequestHandler(BaseHTTPRequestHandler):
        def do_GET(self) -> None:  # noqa: N802 - required by BaseHTTPRequestHandler
            parsed = urlparse(self.path)
            if parsed.path == "/health":
                self._send_json({"status": "ok", **store.status()})
                return

            if parsed.path == "/reset":
                store.reset()
                self._send_json({"status": "reset", **store.status()})
                return

            if parsed.path == "/events":
                params = parse_qs(parsed.query)
                batch_size = None
                if "batchSize" in params:
                    try:
                        batch_size = max(1, min(1000, int(params["batchSize"][0])))
                    except ValueError:
                        self._send_json({"error": "batchSize must be an integer"}, status=400)
                        return
                self._send_json(store.next_batch(batch_size))
                return

            self._send_json({"error": "Not found", "paths": ["/health", "/events", "/reset"]}, status=404)

        def log_message(self, format: str, *args: object) -> None:
            print(f"{self.address_string()} - {format % args}")

        def _send_json(self, payload: object, status: int = 200) -> None:
            body = json.dumps(payload).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

    return EventRequestHandler


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Serve Fabric workshop events over HTTP.")
    parser.add_argument("--csv", default=str(DEFAULT_CSV), help="Path to FactServiceEventStream.csv")
    parser.add_argument("--host", default="0.0.0.0", help="Host interface to bind")
    parser.add_argument("--port", type=int, default=8000, help="HTTP port")
    parser.add_argument("--batch-size", type=int, default=25, help="Default events per /events response")
    parser.add_argument("--preserve-timestamps", action="store_true", help="Use CSV timestamps instead of current UTC time")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    csv_path = Path(args.csv)
    if not csv_path.exists():
        raise SystemExit(f"CSV file not found: {csv_path}")

    store = EventStore(
        csv_path=csv_path,
        default_batch_size=args.batch_size,
        realtime_timestamps=not args.preserve_timestamps,
    )
    server = ThreadingHTTPServer((args.host, args.port), make_handler(store))
    print(f"Serving {len(store.rows)} events from {csv_path}")
    print(f"Health: http://localhost:{args.port}/health")
    print(f"Events: http://localhost:{args.port}/events")
    print("Press Ctrl+C to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("Stopping server.")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
