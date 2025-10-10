#!/usr/bin/env python3
"""Generate CLI.md documentation from the tool registry."""

from pytools.cli import build_registry


def generate_cli_docs():
    """Generate markdown documentation for all tools."""
    reg = build_registry()
    tools = reg.list()

    md = ["# PyTools CLI Reference\n"]
    md.append("This document provides a complete reference for all PyTools commands.\n")
    md.append("Generated from the tool registry.\n")
    md.append(f"\n**Total Tools:** {len(tools)}\n")

    # Group by tags
    tag_groups = {}
    for tool in tools:
        for tag in tool.tags:
            if tag not in tag_groups:
                tag_groups[tag] = []
            tag_groups[tag].append(tool)

    md.append("\n## Tools by Category\n")
    for tag in sorted(tag_groups.keys()):
        md.append(f"- **{tag}**: {', '.join(sorted(t.name for t in tag_groups[tag]))}")

    md.append("\n## All Tools\n")

    for tool in tools:
        md.append(f"\n### `{tool.name}`\n")
        md.append(f"**Summary:** {tool.summary}\n")
        md.append(f"\n**Usage:**\n```bash\n{tool.usage or tool.name}\n```\n")
        md.append(f"\n**Safety:** `{tool.safety}`\n")
        md.append(f"\n**Tags:** {', '.join(sorted(tool.tags))}\n")

        # Add examples based on tool name
        examples = get_examples(tool.name)
        if examples:
            md.append(f"\n**Examples:**\n```bash\n{examples}\n```\n")

        md.append("\n---\n")

    return "\n".join(md)


def get_examples(tool_name: str) -> str:
    """Get example usage for a tool."""
    examples_map = {
    "cat-projects": "# Snapshot Python project\npytools run cat-projects src/ --extensions .py\n\n# With AI summarization\npytools run cat-projects . --summarize",
        "pyinit": "# Create a new project\npytools run pyinit my-project\n\n# With virtual environment\npytools run pyinit my-project --venv",
        "organize-downloads": "# Preview organization\npytools run organize-downloads --dry-run\n\n# Organize by modified date\npytools run organize-downloads --by modified --yes\n\n# Organize only PDFs\npytools run organize-downloads --pattern '*.pdf'",
        "print-ipv4": "pytools run print-ipv4",
        "hf-down": "pytools run hf-down https://huggingface.co/username/model/resolve/main/file.bin",
        "lsh": "# Create commands file\necho 'python train.py --seed 1' > cmds.txt\necho 'python train.py --seed 2' >> cmds.txt\n\n# Run in parallel with a named session\npytools run lsh cmds.txt 2 --session-name training --gpus 0,1\n\n# Preview without launching tmux\npytools run lsh cmds.txt 2 --dry-run",
        "kill-process-grep": "pytools run kill-process-grep",
        "keep-ssh": "# Keep connection alive\npytools run keep-ssh user@server\n\n# Custom interval\npytools run keep-ssh user@server --interval 30 --verbose",
        "atv-select": "pytools run atv-select",
    "env-set": "pytools run env-set API_TOKEN secret",
    "env-unset": "pytools run env-unset API_TOKEN",
    "env-list": "pytools run env-list",
        "setup-typing": "# Setup with defaults\npytools run setup-typing\n\n# Custom Python version\npytools run setup-typing --python-version 3.11 --type-checking-mode strict",
        "report-error": "pytools run report-error src/main.py --output-file errors.json",
    }
    return examples_map.get(tool_name, "")


if __name__ == "__main__":
    docs = generate_cli_docs()
    output_path = "docs/CLI.md"
    with open(output_path, "w") as f:
        f.write(docs)
    print(f"Generated {output_path}")
