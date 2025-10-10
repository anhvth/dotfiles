# PyTools MCP Server Guide

PyTools ships with an experimental [Model Context Protocol](https://modelcontextprotocol.io) (MCP) server that exposes the safe, non-interactive portion of the tool registry to MCP-compatible assistants (for example Claude Desktop, mcp-cli, or other orchestration layers).

This guide covers how to launch the server, what it can do, and how to validate the integration locally.

## Prerequisites

- Python 3.8+ with the PyTools repo available (`uv pip install -e .` or similar)
- `PYTHONPATH` pointing at `src/` when running from a cloned repo (handled automatically when using the helper script below)
- An MCP-capable client (optional, but required for real-world use)

## Starting the Server

Run the stdio server with:

```bash
PYTHONPATH=src python -m pytools.mcp.server
# or, if installed, simply:
pytools-mcp
```

When launched from an interactive shell, the server now keeps running and prints a helpful banner:

```text
$ pytools-mcp --session-id claude-desktop
[pytools-mcp] Waiting for Model Context Protocol client on stdin/stdout.
Connect an MCP-compatible assistant or run: python scripts/mcp_client_example.py
Press Ctrl+C to exit.
```

Key behaviour:

- The server speaks JSON-RPC 2.0 framed with `Content-Length` headers (per the MCP spec)
- Only tools marked `safety != "destructive"` and `passthrough=False` are exposed
- Each invocation is logged via `SessionLogger` under `~/.config/pytools/logs/`
- Pass `--session-id <name>` to make log files easier to locate

Example:

```bash
pytools-mcp --session-id claude-desktop
```

## Tool Exposure

`pytools-mcp` advertises the same metadata you see with `pytools list`, minus interactive/destructive commands (`lsh`, `keep-ssh`, `organize-downloads`, etc.). For each tool you get:

- `name` and `description`
- JSON schema describing the `args` array (positional arguments)
- Metadata block containing original usage string, tags, and safety level

Calls are executed through the shared `execute_tool_capture` helper, so stdout/stderr are captured and returned to the client. Exit codes other than zero mark the call as an error, with stderr embedded in the response metadata.

## Local Smoke Test

A helper script is provided to verify the full handshake without relying on an external MCP client:

```bash
python scripts/mcp_client_example.py
```

The script will:

1. Launch `pytools.mcp.server` over stdio (setting `PYTHONPATH` automatically)
2. Send the `initialize` request and print the server’s `initialized` notification
3. Call `tools/list` to show the exported commands
4. Invoke `env-list` as a representative safe tool
5. Send `shutdown` to terminate the session cleanly

Inspect the printed JSON to confirm the server returns the expected payloads. Any stderr emitted by the server is surfaced after shutdown for easy debugging.

## Integrating with Claude Desktop (example)

1. Ensure `pytools-mcp` is on your `PATH` (install the project or add the repo’s `bin` directory).
2. Add a tool definition to Claude’s MCP config, e.g.:

   ```jsonc
   {
     "servers": {
       "pytools": {
         "command": "pytools-mcp",
         "args": ["--session-id", "claude-desktop"]
       }
     }
   }
   ```

3. Restart Claude Desktop; it will negotiate with the server and list the available tools.

## Troubleshooting

- **No tools listed:** confirm the server has access to `pytools` on `PYTHONPATH`. Running `python -m pytools.mcp.server` from the repo root should work once `PYTHONPATH=src` is set.
- **Tool invocation fails:** check `~/.config/pytools/logs/<session>.jsonl` for the recorded stdout/stderr and return code.
- **Interactive tool requested:** the server rejects `passthrough` (interactive) tools with a clear error; choose another command or run it manually via `pytools`.

For deeper inspection, open the helper script (`scripts/mcp_client_example.py`) or the server implementation (`src/pytools/mcp/server.py`) to see the exact JSON exchanged.
