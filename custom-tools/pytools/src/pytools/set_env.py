#!/usr/bin/env python3
"""Dead stub left on purpose.

`set-env` was the old CLI entry point. Now it just screams at you and exits.
"""

from __future__ import annotations

import sys


def main(argv: list[str] | None = None) -> int:  # noqa: ARG001 - legacy shim
    sys.stderr.write(
        "set-env is dead. Use env-set/env-unset/env-list. No mercy.\n"
    )
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
