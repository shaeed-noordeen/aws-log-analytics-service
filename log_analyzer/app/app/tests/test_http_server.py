import io
import unittest
from typing import List
from unittest.mock import MagicMock, patch

from botocore.exceptions import ClientError
from fastapi.testclient import TestClient

from app.http_server import app


class TestHTTPServer(unittest.TestCase):
    def setUp(self) -> None:
        self.client = TestClient(app)

    def tearDown(self) -> None:
        self.client.close()

    def _mock_s3_client(
        self,
        pages: List[dict],
        body: bytes = b'{"service":"api","level":"ERROR"}',
    ) -> MagicMock:
        paginator = MagicMock()
        paginator.paginate.return_value = pages

        s3_client = MagicMock()
        s3_client.get_paginator.return_value = paginator
        s3_client.get_object.return_value = {"Body": io.BytesIO(body)}
        return s3_client

    @patch("app.http_server.boto3.client")
    def test_healthz_endpoint(self, mock_client: MagicMock) -> None:
        response = self.client.get("/healthz")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"status": "ok"})
        mock_client.assert_not_called()

    @patch("app.http_server.boto3.client")
    def test_analyze_success(self, mock_client_factory: MagicMock) -> None:
        mock_client_factory.return_value = self._mock_s3_client(
            pages=[
                {
                    "Contents": [
                        {"Key": "logs/file1.jsonl", "LastModified": 1},
                        {"Key": "logs/file2.jsonl", "LastModified": 2},
                    ]
                }
            ],
            body=b'{"service":"api","level":"ERROR","msg":"boom"}',
        )

        response = self.client.get(
            "/analyze",
            params={"bucket": "demo", "prefix": "logs/", "threshold": 1},
        )

        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["total"], 1)
        self.assertEqual(payload["byService"], {"api": 1})
        self.assertTrue(payload["alert"])

    @patch("app.http_server.boto3.client")
    def test_analyze_no_logs_found(
        self,
        mock_client_factory: MagicMock,
    ) -> None:
        mock_client_factory.return_value = self._mock_s3_client(
            pages=[{"Contents": []}]
        )

        response = self.client.get(
            "/analyze",
            params={"bucket": "demo", "prefix": "logs/", "threshold": 1},
        )

        self.assertEqual(response.status_code, 404)
        self.assertIn("No logs found", response.json()["detail"])

    @patch("app.http_server.boto3.client")
    def test_analyze_bucket_not_found(
        self,
        mock_client_factory: MagicMock,
    ) -> None:
        error_response = {
            "Error": {
                "Code": "NoSuchBucket",
                "Message": "Bucket does not exist",
            }
        }
        s3_client = self._mock_s3_client(pages=[])
        s3_client.get_paginator.side_effect = ClientError(
            error_response,
            "ListObjectsV2",
        )
        mock_client_factory.return_value = s3_client

        response = self.client.get(
            "/analyze",
            params={"bucket": "missing", "prefix": "logs/", "threshold": 1},
        )

        self.assertEqual(response.status_code, 404)
        self.assertIn("not found", response.json()["detail"])

    @patch("app.http_server.boto3.client")
    def test_analyze_generic_s3_error(
        self,
        mock_client_factory: MagicMock,
    ) -> None:
        error_response = {
            "Error": {"Code": "Throttling", "Message": "Try again later"}
        }
        s3_client = self._mock_s3_client(pages=[])
        s3_client.get_paginator.side_effect = ClientError(
            error_response,
            "ListObjectsV2",
        )
        mock_client_factory.return_value = s3_client

        response = self.client.get(
            "/analyze",
            params={"bucket": "demo", "prefix": "logs/", "threshold": 1},
        )

        self.assertEqual(response.status_code, 500)
        self.assertIn("An S3 error occurred", response.json()["detail"])

    @patch("app.http_server.boto3.client")
    def test_analyze_streaming_true(
        self, mock_client_factory: MagicMock
    ) -> None:
        # paginator returns one object
        paginator = MagicMock()
        paginator.paginate.return_value = [
            {"Contents": [{"Key": "logs/file.jsonl", "LastModified": 1}]}
        ]

        # streaming body
        streaming_body = MagicMock()
        streaming_body.iter_lines.return_value = [
            b'{"service":"api","level":"ERROR"}',
            b'{"service":"billing","level":"INFO"}',
        ]

        s3_client = MagicMock()
        s3_client.get_paginator.return_value = paginator
        s3_client.get_object.return_value = {"Body": streaming_body}
        mock_client_factory.return_value = s3_client

        resp = self.client.get(
            "/analyze",
            params={
                "bucket": "demo",
                "prefix": "logs/",
                "threshold": 1,
                "stream": True,
            },
        )

        self.assertEqual(resp.status_code, 200)
        data = resp.json()
        self.assertEqual(data["total"], 1)
        self.assertEqual(data["byService"], {"api": 1})
        streaming_body.iter_lines.assert_called_once()
