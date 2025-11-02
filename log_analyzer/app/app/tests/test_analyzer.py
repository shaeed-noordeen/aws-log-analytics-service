import io
import textwrap
import unittest

from app.core.analyzer import analyze_logs


class TestAnalyzer(unittest.TestCase):
    def _make_stream(self, lines: str) -> io.BytesIO:
        payload = textwrap.dedent(lines).strip().encode("utf-8")
        return io.BytesIO(payload)

    def test_analyze_logs_with_errors_below_threshold(self) -> None:
        log_stream = self._make_stream(
            """
            {"service":"api","level":"ERROR"}
            {"service":"orders","level":"INFO"}
            {"service":"api","level":"ERROR"}
            """
        )
        result = analyze_logs(log_stream, threshold=3)
        self.assertEqual(result["total"], 2)
        self.assertEqual(result["byService"], {"api": 2})
        self.assertFalse(result["alert"])

    def test_analyze_logs_with_errors_at_threshold(self) -> None:
        log_stream = self._make_stream(
            """
            {"service":"api","level":"ERROR"}
            {"service":"orders","level":"ERROR"}
            {"service":"billing","level":"ERROR"}
            """
        )
        result = analyze_logs(log_stream, threshold=3)
        self.assertEqual(result["total"], 3)
        self.assertEqual(
            result["byService"],
            {"api": 1, "orders": 1, "billing": 1},
        )
        self.assertTrue(result["alert"])

    def test_analyze_logs_with_no_errors(self) -> None:
        log_stream = self._make_stream(
            """
            {"service":"orders","level":"INFO"}
            {"service":"api","level":"DEBUG"}
            """
        )
        result = analyze_logs(log_stream, threshold=3)
        self.assertEqual(result["total"], 0)
        self.assertEqual(result["byService"], {})
        self.assertFalse(result["alert"])

    def test_analyze_logs_with_malformed_json(self) -> None:
        log_stream = self._make_stream(
            """
            {"service":"api","level":"ERROR"}
            not-json
            {"service":"billing","level":"ERROR"}
            """
        )
        result = analyze_logs(log_stream, threshold=3)
        self.assertEqual(result["total"], 2)
        self.assertEqual(
            result["byService"],
            {"api": 1, "billing": 1},
        )
        self.assertFalse(result["alert"])

    def test_analyze_logs_default_service_name(self) -> None:
        log_stream = self._make_stream(
            """
            {"level":"ERROR"}
            {"service":null,"level":"ERROR"}
            """
        )
        result = analyze_logs(log_stream, threshold=10)
        self.assertEqual(result["total"], 2)
        self.assertEqual(result["byService"], {"unknown": 2})
        self.assertFalse(result["alert"])

    def test_analyze_logs_with_unicode_payload(self) -> None:
        payload = ' {"service":"api","level":"ERROR","msg":"¡Hola!"}\n'
        log_stream = io.BytesIO(payload.encode("utf-8"))
        result = analyze_logs(log_stream, threshold=1)
        self.assertEqual(result["total"], 1)
        self.assertEqual(result["byService"], {"api": 1})
        self.assertTrue(result["alert"])

    def test_analyze_logs_threshold_zero(self) -> None:
        log_stream = self._make_stream(
            """
            {"service":"api","level":"ERROR"}
            """
        )
        result = analyze_logs(log_stream, threshold=0)
        self.assertTrue(result["alert"])

    def test_analyze_logs_with_empty_lines(self) -> None:
        log_stream = self._make_stream(
            """

            {"service":"api","level":"ERROR"}

            """
        )
        result = analyze_logs(log_stream, threshold=5)
        self.assertEqual(result["total"], 1)


if __name__ == "__main__":
    unittest.main()
