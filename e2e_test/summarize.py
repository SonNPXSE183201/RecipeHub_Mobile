"""Aggregate actual case outcomes, including Python assertions and fixture failures."""
from __future__ import annotations

import csv
import json
from pathlib import Path
from typing import Any

RESULTS = Path(__file__).resolve().parent / "results"


def markdown(value: Any) -> str:
    return str(value or "–").replace("|", "\\|").replace("\r", " ").replace("\n", "<br>")


def main() -> None:
    RESULTS.mkdir(exist_ok=True)
    groups: dict[str, list[dict[str, Any]]] = {f"TC-{n:02}": [] for n in range(1, 25)}
    sources = sorted(RESULTS.glob("*.jsonl"), key=lambda path: (path.stat().st_mtime_ns, path.name))
    for source in sources:
        for number, line in enumerate(source.read_text(encoding="utf-8").splitlines(), 1):
            if not line.strip():
                continue
            try:
                row = json.loads(line)
                if not isinstance(row, dict) or row.get("tc_id") not in groups:
                    raise ValueError("unknown or missing tc_id")
                if type(row.get("succeeded")) is not bool:
                    raise ValueError("succeeded must be boolean")
                float(row["duration_s"])
            except (ValueError, KeyError, TypeError) as exc:
                # Do not echo raw lines: results may have been produced by another tool.
                raise ValueError(f"Invalid record: {source.name}:{number}") from exc
            groups[row["tc_id"]].append(row)

    fields = ["tc_id", "runs", "pass_rate", "avg_duration_s", "last_trace_id", "latest_error", "skipped"]
    summary: list[dict[str, Any]] = []
    for tc_id, records in groups.items():
        attempts = [row for row in records if row.get("status") != "skipped"]
        failures = [row for row in records if row.get("error")]
        traces = [row["trace_id"] for row in records if row.get("trace_id")]
        summary.append({
            "tc_id": tc_id,
            "runs": len(attempts),
            "pass_rate": f"{sum(row['succeeded'] for row in attempts) / len(attempts):.1%}" if attempts else "Chưa chạy",
            "avg_duration_s": f"{sum(float(row['duration_s']) for row in attempts) / len(attempts):.3f}" if attempts else "",
            "last_trace_id": traces[-1] if traces else "",
            "latest_error": failures[-1]["error"] if failures else "",
            "skipped": len(records) - len(attempts),
        })
    with (RESULTS / "results.csv").open("w", encoding="utf-8-sig", newline="") as stream:
        writer = csv.DictWriter(stream, fieldnames=fields)
        writer.writeheader()
        writer.writerows(summary)
    lines = ["# Kết quả E2E RecipeHub", "",
             "Tổng hợp JSONL thực tế; skip không tính vào số lần/pass rate. Lần cuối theo thứ tự file được cập nhật, rồi thứ tự dòng. Không có dữ liệu được ghi là Chưa chạy.", "",
             "| Test ID | Số lần | Pass rate | Thời gian TB (s) | Trace ID cuối | Lỗi gần nhất | Skip |",
             "| :--- | ---: | ---: | ---: | :--- | :--- | ---: |"]
    for row in summary:
        lines.append("| " + " | ".join(markdown(row[field]) if row[field] != 0 else "0" for field in fields) + " |")
    (RESULTS / "summary.md").write_text("\n".join(lines) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
