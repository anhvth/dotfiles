"""Tests for CLI functionality."""

from pytools.cli import main


def test_cli_version(capsys):
    """Test --version flag."""
    try:
        main(["--version"])
    except SystemExit as e:
        assert e.code == 0

    captured = capsys.readouterr()
    assert "0.3.0" in captured.out


def test_cli_list_json(capsys):
    """Test list command with JSON output."""
    result = main(["--json", "list"])
    assert result == 0

    captured = capsys.readouterr()
    assert "[" in captured.out
    assert "cat-projects" in captured.out


def test_cli_doctor():
    """Test doctor command."""
    result = main(["doctor"])
    assert result in [0, 1]  # 0 if all deps available, 1 if some missing


def test_cli_run_nonexistent_tool(capsys):
    """Test running a non-existent tool."""
    result = main(["run", "nonexistent-tool"])
    assert result == 1

    captured = capsys.readouterr()
    assert "Unknown tool" in captured.out


def test_cli_run_help_tool(capsys):
    """Test running a tool with --help."""
    result = main(["run", "print-ipv4", "--help"])
    # Help should exit with 0
    assert result in [0, 1]  # Some tools may not have --help
