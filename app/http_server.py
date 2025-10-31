import io

import boto3
from botocore.exceptions import ClientError
from fastapi import FastAPI, HTTPException, Query

from app.core.analyzer import analyze_logs

app = FastAPI()


@app.get("/healthz")
def health_check():
    return {"status": "ok"}


@app.get("/analyze")
def analyze_s3_logs(
    bucket: str,
    prefix: str,
    threshold: int = Query(3, ge=0),
    stream: bool = Query(False),
):
    s3 = boto3.client("s3")
    try:
        paginator = s3.get_paginator("list_objects_v2")
        latest_object = None

        for page in paginator.paginate(Bucket=bucket, Prefix=prefix):
            for obj in page.get("Contents", []):
                if (
                    latest_object is None
                    or obj["LastModified"] > latest_object["LastModified"]
                ):
                    latest_object = obj

        if latest_object is None:
            raise HTTPException(
                status_code=404,
                detail="No logs found at the specified prefix.",
            )

        obj_key = latest_object["Key"]
        s3_object = s3.get_object(Bucket=bucket, Key=obj_key)

        if stream:
            log_source = s3_object["Body"].iter_lines()
        else:
            log_source = io.BytesIO(s3_object["Body"].read())

        return analyze_logs(log_source, threshold)

    except HTTPException as http_error:
        raise http_error
    except ClientError as error:
        if error.response["Error"]["Code"] == "NoSuchBucket":
            raise HTTPException(
                status_code=404,
                detail=f"S3 bucket '{bucket}' not found.",
            )
        raise HTTPException(
            status_code=500,
            detail=f"An S3 error occurred: {error}",
        ) from error
    except Exception as error:  # noqa: broad-except
        raise HTTPException(
            status_code=500,
            detail=f"An unexpected error occurred: {error}",
        ) from error
