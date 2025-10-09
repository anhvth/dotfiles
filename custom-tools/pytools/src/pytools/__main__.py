"""Allow running pytools as a module with python -m pytools."""

from .cli import main

if __name__ == "__main__":
    raise SystemExit(main())
