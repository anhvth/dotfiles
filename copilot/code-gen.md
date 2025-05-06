# LLM Coding‑Generation Standards

These instructions apply **every time** you (the LLM) are asked to write or modify code.
Your output will be evaluated against them.

---

## 0. Output Contract (Read **first**)

1. **Silence is golden** – respond *only* with the requested artefacts (code blocks, file-tree, etc.).  No extra commentary unless explicitly asked.
2. Wrap each file in a triple‑backtick block annotated with its relative path, e.g.

   ```python title="src/my_package/core.py"
   # code here
   ```
3. If multiple files are needed, include a **single** ASCII tree at the top:

   ```text
   your_project/
   ├── pyproject.toml
   └── src/...
   ```

---

## 1. Language & Environment

* **Python 3.10**, target 3.12 if feature-set undisputed.
* Purely standard library unless the user requests a dependency; if so, list it in `pyproject.toml` under `[project.dependencies]`.

---

## 2. Functional Bias

* Prefer **pure functions**; minimise I/O or mutation.
* Default to **immutable** containers (`tuple`, `frozenset`, `MappingProxyType`).
* Embrace first‑class & higher‑order functions (`map`, `functools`, `itertools`).
* If mutability is unavoidable, encapsulate it behind a clear API and document side‑effects.

---

## 3. Static Typing

* Provide **complete type hints** for *all* public and private symbols.
* Introduce reusable aliases with `TypeAlias`, generics with `TypeVar`, structural contracts with `Protocol`.
* Enable *mypy* **strict** mode; assume `mypy.ini` contains `strict = True`.

---

## 4. Code Structure

* Keep each function ≤ 50 LOC and do *one thing*.
* Favour composition over inheritance; when OOP is needed, use **@dataclass(frozen=True)** to preserve immutability.
* Separate

  * **src/** – importable code
  * **tests/** – unit tests (pytest)
  * **docs/** – documentation assets
* Never place application logic at the top level of a module; guard with `if __name__ == "__main__":`.

---

## 5. Naming

| Category               | Convention       | Example                          |
| ---------------------- | ---------------- | -------------------------------- |
| Classes & Type Aliases | **PascalCase**   | `UserProfile`, `ResponseType`    |
| Functions, Variables   | **snake\_case**  | `get_user_data`, `current_value` |
| Constants              | **UPPER\_SNAKE** | `MAX_RETRIES`, `API_KEY`         |
| Private names          | Prefix `_`       | `_internal_cache`                |

---

## 6. Error Management

* Raise **specific** exceptions; never use bare `except:`.
* Preserve traceback with `from e` when re‑raising.
* Log context (`logger.exception`) at point of failure – assume `logging.basicConfig(level=logging.INFO)`.
* Declare expected exceptions in the docstring’s *Raises* section.

---

## 7. Documentation

* **Default:** Provide a *single‑line* docstring (≤ 72 chars) that starts with an imperative verb and ends with a period.
* When more detail is genuinely helpful, choose **one** extended format:

  * **Google style**

    ```python
    def foo(bar: int) -> str:
        """Return a human‑readable label for *bar*.

        Args:
            bar: A numeric code.

        Returns:
            A descriptive string.
        """
    ```
  * **reStructuredText / Sphinx style**

    ```python
    def foo(bar: int) -> str:
        """Return a human‑readable label for *bar*.

        :param bar: A numeric code
        :type  bar: int
        :returns:   A descriptive string
        :rtype:     str
        """
    ```
* Avoid verbose narrative; rely on type hints to convey intent.
* Keep inline comments minimal; clean code should tell the story.

## 8. Tooling Footprint Tooling Footprint

* Auto‑format with **black** (`line-length = 88`).
* Lint with **flake8** (respect `setup.cfg`); address *all* warnings E‑, F‑, W‑, C‑.
* Provide a minimal `pyproject.toml` with `[build-system]` (`hatchling` or `setuptools`), `[project]`, and tool sections for black, flake8, mypy.

---

## 9. Test‑Driven Development (TDD)

* **Start with failure**: for every new feature or bug fix, first write or modify a **failing** pytest test that captures the required behaviour.
* **Red → Green → Refactor loop**:

  1. **Red:** commit the failing test.
  2. **Green:** implement the *minimal* production code to make *all* tests pass.
  3. **Refactor:** clean up code and tests while retaining a green suite.
* **Answer order:** when generating code, output the `tests/` files *before* the implementation so reviewers see the intent first.
* Use `@pytest.mark.xfail` with a clear reason for tests that describe *future* behaviour the user has acknowledged is not yet implemented.
* Maintain ≥ 90 % branch coverage; include an example `pytest --cov` command or a `nox`/`Makefile` task.
* Tests must import the public package (from **src/**), never tweak `sys.path`.
* Keep each test atomic: one assertion of behaviour per function and a descriptive name (`test_<behaviour>`).

## 10. Source‑Layout Reminder Source‑Layout Reminder

```
your_project/
├── pyproject.toml
├── src/
│   └── your_package/
│       └── __init__.py
└── tests/
```

Place *all* importable code under **src/**.  Tests must import the package, never reach into implementation files via path hacks.

---

Follow these rules **exactly** unless the user explicitly overrides a point.
