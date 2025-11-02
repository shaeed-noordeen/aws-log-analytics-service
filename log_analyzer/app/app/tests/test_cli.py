import io
import json
import tempfile
import unittest
from contextlib import redirect_stderr, redirect_stdout
from pathlib import Path
from typing import List
from unittest.mock import MagicMock, patch

from botocore.exceptions import ClientError

from app import cli


class TestCLI(unittest.TestCase):
    def _run_cli(self, argv: List[str]) -> tuple[int, str, str]:
        stdout = io.StringIO()
        stderr = io.StringIO()
        with redirect_stdout(stdout), redirect_stderr(stderr):
            exit_code = cli.run(argv)
        return exit_code, stdout.getvalue(), stderr.getvalue()

    def test_run_with_local_file(self) -> None:
        payload = '\n{"service":"api","level":"ERROR"}\n'
        with tempfile.NamedTemporaryFile(
            mode="w+",
            delete=False,
            encoding="utf-8",
        ) as temp_file:
            temp_file.write(payload)
            temp_file.flush()
            file_path = Path(temp_file.name)
        exit_code, stdout, stderr = self._run_cli(
            ["--file", str(file_path), "--threshold", "1"]
        )
        file_path.unlink(missing_ok=True)
        self.assertEqual(exit_code, 0)
        self.assertEqual(stderr, "")
        result = json.loads(stdout)
        self.assertEqual(result["total"], 1)

    @patch("app.cli.boto3.client")
    def test_run_with_s3_success(self, mock_client_factory: MagicMock) -> None:
        paginator = MagicMock()
        paginator.paginate.return_value = [
            {"Contents": [{"Key": "logs/file.jsonl", "LastModified": 1}]}
        ]
        s3_client = MagicMock()
        s3_client.get_paginator.return_value = paginator
        s3_client.get_object.return_value = {
            "Body": io.BytesIO(b'{"service":"api","level":"ERROR"}')
        }
        mock_client_factory.return_value = s3_client

        exit_code, stdout, stderr = self._run_cli(
            ["--bucket", "demo", "--prefix", "logs/"]
        )
        self.assertEqual(exit_code, 0)
        self.assertEqual(stderr, "")
        result = json.loads(stdout)
        self.assertEqual(result["byService"], {"api": 1})

    @patch("app.cli.boto3.client")
    def test_run_with_s3_no_logs(self, mock_client_factory: MagicMock) -> None:
        paginator = MagicMock()
        paginator.paginate.return_value = [{"Contents": []}]
        s3_client = MagicMock()
        s3_client.get_paginator.return_value = paginator
        mock_client_factory.return_value = s3_client

        exit_code, stdout, stderr = self._run_cli(
            ["--bucket", "demo", "--prefix", "logs/"]
        )
        self.assertEqual(exit_code, 1)
        self.assertEqual(stdout, "")
        self.assertIn("No logs found", stderr)

    @patch("app.cli.boto3.client")
    def test_run_with_s3_client_error(
        self,
        mock_client_factory: MagicMock,
    ) -> None:
        error_response = {
            "Error": {
                "Code": "NoSuchBucket",
                "Message": "Bucket does not exist",
            }
        }
        s3_client = MagicMock()
        s3_client.get_paginator.side_effect = ClientError(
            error_response,
            "ListObjectsV2",
        )
        mock_client_factory.return_value = s3_client

        exit_code, stdout, stderr = self._run_cli(
            ["--bucket", "missing", "--prefix", "logs/"]
        )
        self.assertEqual(exit_code, 1)
        self.assertEqual(stdout, "")
        self.assertIn("not found", stderr)

    def test_run_without_arguments(self) -> None:
        exit_code, stdout, stderr = self._run_cli([])
        self.assertEqual(exit_code, 1)
        combined = f"{stdout}\n{stderr}".lower()
        self.assertIn("usage:", combined)

    @patch("app.cli.boto3.client")
    def test_run_with_s3_streaming(
        self, mock_client_factory: MagicMock
    ) -> None:
        paginator = MagicMock()
        paginator.paginate.return_value = [
            {"Contents": [{"Key": "logs/file.jsonl", "LastModified": 1}]}
        ]

        streaming_body = MagicMock()
        streaming_body.iter_lines.return_value = [
            b'{"service":"api","level":"ERROR"}',
            b'{"service":"billing","level":"INFO"}',
        ]

        s3_client = MagicMock()
        s3_client.get_paginator.return_value = paginator
        s3_client.get_object.return_value = {"Body": streaming_body}
        mock_client_factory.return_value = s3_client

        exit_code, stdout, stderr = self._run_cli(
            [
                "--bucket",
                "demo",
                "--prefix",
                "logs/",
                "--stream",
                "--threshold",
                "1",
            ]
        )

        self.assertEqual(exit_code, 0)
        self.assertEqual(stderr, "")
        result = json.loads(stdout)
        self.assertEqual(result["total"], 1)
        self.assertEqual(result["byService"], {"api": 1})
        streaming_body.iter_lines.assert_called_once()
