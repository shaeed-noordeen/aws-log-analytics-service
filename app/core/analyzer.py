import json
from collections import defaultdict
from typing import Any, Dict, Iterable, IO, Union

LogStream = Union[IO[Union[str, bytes]], Iterable[Union[str, bytes]]]


def _iter_lines(src: LogStream):
    if hasattr(src, "__next__") or hasattr(src, "__iter__"):
        for line in src:
            yield line
    else:
        raise TypeError("Unsupported log source")


def analyze_logs(log_stream: LogStream, threshold: int) -> Dict[str, Any]:
    error_counts = defaultdict(int)
    total_errors = 0

    for line in _iter_lines(log_stream):
        try:
            if isinstance(line, bytes):
                decoded = line.decode("utf-8")
            else:
                decoded = line
            decoded = decoded.strip()
            if not decoded:
                continue
            log_entry = json.loads(decoded)
            if log_entry.get("level") == "ERROR":
                total_errors += 1
                service = log_entry.get("service") or "unknown"
                error_counts[service] += 1
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue

    return {
        "total": total_errors,
        "byService": dict(error_counts),
        "alert": total_errors >= threshold,
    }
