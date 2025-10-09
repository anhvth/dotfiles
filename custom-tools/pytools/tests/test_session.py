"""Tests for session logging."""

import os
import tempfile
from datetime import datetime

from pytools.core.session import SessionLogger


def test_session_logger_creates_file():
    """Test that session logger creates a file."""
    # Use a temporary directory for testing
    with tempfile.TemporaryDirectory() as tmpdir:
        os.environ["PYTOOLS_CONFIG_DIR"] = tmpdir
        session_id = f"test-session-{datetime.now().isoformat()}"
        logger = SessionLogger(session_id)
        logger.log("test", foo="bar", num=42)

        # Check file was created
        assert logger.path.exists()

        # Read and verify content
        content = logger.path.read_text()
        assert "test" in content
        assert "foo" in content
        assert "bar" in content


def test_session_logger_multiple_events():
    """Test logging multiple events."""
    with tempfile.TemporaryDirectory() as tmpdir:
        os.environ["PYTOOLS_CONFIG_DIR"] = tmpdir
        session_id = f"test-multi-{datetime.now().isoformat()}"
        logger = SessionLogger(session_id)

        logger.log("event1", data="first")
        logger.log("event2", data="second")

        lines = logger.path.read_text().strip().split("\n")
        assert len(lines) == 2
        assert "event1" in lines[0]
        assert "event2" in lines[1]


def test_session_logger_info_helper():
    """Test info helper method."""
    with tempfile.TemporaryDirectory() as tmpdir:
        os.environ["PYTOOLS_CONFIG_DIR"] = tmpdir
        session_id = f"test-info-{datetime.now().isoformat()}"
        logger = SessionLogger(session_id)

        logger.info("Test message", extra_field="value")

        content = logger.path.read_text()
        assert "info" in content
        assert "Test message" in content
        assert "extra_field" in content
