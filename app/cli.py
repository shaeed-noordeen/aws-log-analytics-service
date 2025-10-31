import argparse
import io
import json
import sys
from typing import Any, Iterable, Optional

import boto3
from botocore.exceptions import ClientError

from app.core.analyzer import analyze_logs


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Analyze JSONL log files for errors."
    )
    parser.add_argument(
        "--file",
        type=argparse.FileType("r"),
        help="Path to the local log file to analyze.",
    )
    parser.add_argument(
        "--bucket",
        help="S3 bucket name.",
    )
    parser.add_argument(
        "--prefix",
        help="S3 object prefix.",
    )
    parser.add_argument(
        "--threshold",
        type=int,
        default=3,
        help="Error count threshold for alerting.",
    )
    parser.add_argument(
        "--stream",
        action="store_true",
        help="Stream S3 object instead of downloading it into memory.",
    )
    return parser


def _print_no_logs_error() -> None:
    print("No logs found at the specified prefix.", file=sys.stderr)


def _handle_client_error(error: ClientError, bucket: str) -> None:
    if error.response["Error"]["Code"] == "NoSuchBucket":
        print(f"S3 bucket '{bucket}' not found.", file=sys.stderr)
    else:
        print(f"An S3 error occurred: {error}", file=sys.stderr)


def _find_latest_object(
    paginator: Any,
    bucket: str,
    prefix: Optional[str],
) -> Optional[dict]:
    latest_object = None
    for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
        for current in page.get("Contents", []):
            if (
                latest_object is None
                or current["LastModified"] > latest_object["LastModified"]
            ):
                latest_object = current
    return latest_object


def run(argv: Optional[Iterable[str]] = None) -> int:
    parser = _build_parser()
    args = parser.parse_args(argv)

    if args.file:
        try:
            result = analyze_logs(args.file, args.threshold)
            print(json.dumps(result, indent=2))
            return 0
        finally:
            args.file.close()

    if args.bucket:
        s3 = boto3.client("s3")
        try:
            paginator = s3.get_paginator("list_objects_v2")
            latest_object = _find_latest_object(
                paginator,
                bucket=args.bucket,
                prefix=args.prefix,
            )

            if latest_object is None:
                _print_no_logs_error()
                return 1

            obj_key = latest_object["Key"]
            s3_object = s3.get_object(Bucket=args.bucket, Key=obj_key)

            if args.stream:
                # Streaming: iterate lines from S3 directly
                log_iter = s3_object["Body"].iter_lines()
                result = analyze_logs(log_iter, args.threshold)
            else:
                # Old behaviour: load into memory
                log_stream = io.BytesIO(s3_object["Body"].read())
                result = analyze_logs(log_stream, args.threshold)

            print(json.dumps(result, indent=2))
            return 0
        except ClientError as error:
            _handle_client_error(error, args.bucket)
            return 1
        except Exception as error:  # noqa: broad-except
            print(f"An unexpected error occurred: {error}", file=sys.stderr)
            return 1

    parser.print_help()
    return 1


def main() -> None:
    sys.exit(run())


if __name__ == "__main__":
    main()
