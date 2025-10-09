"""Session logging for pytools."""

from __future__ import annotations

import json
import os
from datetime import datetime
from pathlib import Path
from typing import Any


class SessionLogger:
    """Logger for tracking tool execution sessions."""

    def __init__(self, session_id: str | None = None) -> None:
        """Initialize session logger with optional session ID."""
        if session_id is None:
            session_id = f"session-{datetime.now().isoformat()}"

        self.session_id = session_id

        # Determine log directory
        config_dir = os.getenv("PYTOOLS_CONFIG_DIR")
        if config_dir:
            log_dir = Path(config_dir) / "logs"
        else:
            log_dir = Path.home() / ".config" / "pytools" / "logs"

        log_dir.mkdir(parents=True, exist_ok=True)

        # Create session log file
        self.path = log_dir / f"{session_id}.jsonl"

    def log(self, event_type: str, **kwargs: Any) -> None:
        """Log an event with arbitrary metadata."""
        entry = {
            "timestamp": datetime.now().isoformat(),
            "event": event_type,
            **kwargs,
        }

        with self.path.open("a") as f:
            f.write(json.dumps(entry) + "\n")

    def info(self, message: str, **kwargs: Any) -> None:
        """Log an info message."""
        self.log("info", message=message, **kwargs)
