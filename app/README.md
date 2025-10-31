# Application README

The `app/` directory contains the Python implementation of the Log Analytics Service. It provides a shared analytics core that powers both the CLI and the FastAPI HTTP server.

## Directory Structure

```
app/
├── cli.py              # CLI entry point (installed as `analyze`)
├── http_server.py      # FastAPI application (uvicorn-compatible)
├── core/
│   ├── __init__.py
│   └── analyzer.py     # Shared analytics logic
└── tests/
    ├── __init__.py
    └── test_analyzer.py
```

`log_analyzer/main.py` and `setup.py` wire the package for editable installs and console scripts.

## Installation

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# Optional: lint tooling
pip install flake8
```

Editable installs expose the `analyze` CLI and allow live code changes without reinstalling.

## CLI Usage

```bash
analyze --file testdata/sample.jsonl --threshold 5
analyze --bucket devops-assignment-logs-430957 --prefix 2025-09-15T16-00.jsonl
```

The CLI pages through S3 listings to pick the most recently modified object. AWS credentials are resolved via the standard SDK chain (profile, environment variables, IAM role).

## HTTP API

```bash
uvicorn app.http_server:app --host 0.0.0.0 --port 8080
```

- `GET /healthz` – returns `{"status": "ok"}`
- `GET /analyze?bucket=<name>&prefix=<prefix>&threshold=3`

## Testing & Linting

```bash
flake8 app
python -m unittest discover app/tests
```

`test_analyzer.py` includes fixtures for typical and malformed log lines to ensure robustness.

## Design Notes

- JSON lines are processed streamingly; malformed entries are skipped rather than failing the request.
- The analytics core (`analyzer.py`) runs on any file-like object, keeping it reusable across interfaces.
- The S3 paginator ensures correct behaviour when prefixes contain more than 1000 objects.
- Threshold alerting is handled in-process; consider pushing to CloudWatch or another system for richer alerting in the future.
