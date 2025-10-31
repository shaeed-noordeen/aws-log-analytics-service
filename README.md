# Application README

The `app/` directory contains the Python implementation of the Log Analytics Service. It exposes a **shared analytics core** that powers:

- the **CLI** (`analyze`)
- the **FastAPI HTTP server** (`/healthz`, `/analyze`)
- and now **S3 streaming** for large log objects

## Directory Structure

```text
app/
├── cli.py              # CLI entry point (installed as `analyze`)
├── http_server.py      # FastAPI application (uvicorn-compatible)
├── core/
│   ├── __init__.py
│   └── analyzer.py     # Shared analytics logic (file-like OR iterables)
└── tests/
    ├── __init__.py
    └── test_analyzer.py
```

The root-level `setup.py` wires the package for **editable installs** and exposes the `analyze` console script.

## Installation

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -e .

# Optional: lint tooling
pip install flake8
```

Using `pip install -e .` is important — it means changes to `app/` are picked up immediately by the `analyze` CLI.

## CLI Usage

Basic local file:

```bash
analyze --file testdata/sample.jsonl --threshold 5
```

S3 (download whole object into memory):

```bash
analyze \
  --bucket devops-assignment-logs-430957 \
  --prefix 2025-09-15T16-00.jsonl \
  --threshold 3
```

S3 **streaming** (new):

```bash
analyze \
  --bucket devops-assignment-logs-430957 \
  --prefix 2025-09-15T16-00.jsonl \
  --threshold 3 \
  --stream
```

Notes:

- CLI **paginates** S3 to find the **most recently modified** object under the prefix.
- `--stream` tells the CLI **not** to read the whole S3 object into RAM; instead it iterates over `Body.iter_lines()` and feeds that straight into the analyzer.
- AWS credentials are resolved via the normal boto3 chain (env, shared config, IAM role).

Run `analyze --help` to see all flags.

## HTTP API

Run locally:

```bash
uvicorn app.http_server:app --host 0.0.0.0 --port 8080
```

Endpoints:

- `GET /healthz`

  Returns:

  ```json
  { "status": "ok" }
  ```

- `GET /analyze?bucket=<name>&prefix=<prefix>&threshold=3`

  Default: downloads the latest S3 object and analyzes it.

- `GET /analyze?bucket=<name>&prefix=<prefix>&threshold=3&stream=true`

  **Streaming mode** – same as CLI `--stream`, reads the S3 object line-by-line without buffering the whole file.

This is the same code the ECS task runs behind the ALB/CloudFront path.

## Testing & Linting

```bash
python -m unittest discover app/tests
flake8 app
```

You can add the streaming tests we discussed for:

- CLI (`--stream`)
- HTTP (`stream=true`)
- analyzer with an iterable source

## Design Notes

- **One analytics core**: `app.core.analyzer.analyze_logs(...)` is the single place that knows how to walk JSONL, count errors, and apply the threshold.
- **Accepts file-like _and_ iterables**: the analyzer will process `io.BytesIO(...)`, real files, and iterators like `s3_object["Body"].iter_lines()`. That’s what enables S3 streaming.
- **Graceful on bad data**: malformed JSON lines are skipped so a single bad record doesn’t kill the whole analysis.
- **Pagination for S3**: both CLI and HTTP use an S3 paginator to ensure we always pick the **actual** latest object when there are more than 1000 keys under a prefix.
- **Threshold is app-level**: alerting is calculated in-process and returned in the response. In a fuller system we’d push this to CloudWatch / EventBridge.

## Notes for ECS / CloudFront users

If you’re hitting this through the deployed stack (CloudFront → ALB → ECS), you can test the streaming path with:

```bash
curl "https://<your-cloudfront-domain>/analyze?bucket=devops-assignment-logs-430957&prefix=2025-09-15T16-00.jsonl&threshold=3&stream=true"
```

The response shape is the same — only the way we read S3 changes.
