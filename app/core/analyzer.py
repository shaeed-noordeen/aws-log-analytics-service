"""
Core analytics logic shared by CLI and HTTP entry points.
"""

import json
from collections import defaultdict
from typing import Any, Dict, IO, Union


def analyze_logs(
    log_stream: IO[Union[str, bytes]],
    threshold: int,
) -> Dict[str, Any]:
    """
    Analyze JSON Lines data and return error statistics.

    Parameters
    ----------
    log_stream:
        File-like object yielding JSONL records as bytes.
    threshold:
        Error count threshold used to flip the `alert` flag.
    """

    error_counts = defaultdict(int)
    total_errors = 0

    for line in log_stream:
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
