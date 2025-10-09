#!/usr/bin/env python3
"""
Organize Downloads - Organize files in Downloads folder by date.

This tool organizes files in the Downloads folder by moving them into
subdirectories named after their modification or creation date (YYYY-MM-DD format).
"""

import argparse
import shutil
import sys
from datetime import datetime
from pathlib import Path


def get_file_date(file_path: Path, by: str = "modified") -> datetime:
    """Get the date of a file based on the specified method."""
    stat = file_path.stat()
    if by == "created":
        # Note: st_ctime is "change time" on Linux, not creation time
        # On Windows and macOS, it's creation time
        timestamp = stat.st_ctime
    else:  # modified
        timestamp = stat.st_mtime
    return datetime.fromtimestamp(timestamp)


def should_include_file(
    file_path: Path,
    include_hidden: bool,
    pattern: str | None = None,
    exclude: str | None = None,
) -> bool:
    """Check if a file should be included based on filters."""
    # Skip hidden files unless explicitly included
    if not include_hidden and file_path.name.startswith("."):
        return False

    # Pattern matching (simple glob)
    if pattern and not file_path.match(pattern):
        return False

    # Exclusion pattern
    if exclude and file_path.match(exclude):
        return False

    return True


def organize_downloads(
    download_folder: str,
    dry_run: bool = False,
    by: str = "modified",
    include_hidden: bool = False,
    pattern: str | None = None,
    exclude: str | None = None,
    yes: bool = False,
):
    """Organize files in the downloads folder by date."""
    download_path = Path(download_folder).expanduser()

    if not download_path.exists():
        sys.stderr.write(f"Error: Download folder '{download_folder}' does not exist\n")
        return 1

    if not download_path.is_dir():
        sys.stderr.write(f"Error: '{download_folder}' is not a directory\n")
        return 1

    try:
        # Collect files to organize
        items = []
        for item in download_path.iterdir():
            # Skip directories
            if item.is_dir():
                continue

            if not should_include_file(item, include_hidden, pattern, exclude):
                continue

            file_date = get_file_date(item, by)
            date_str = file_date.strftime("%Y-%m-%d")
            date_folder = download_path / date_str
            destination = date_folder / item.name

            # Handle naming conflicts
            counter = 1
            original_dest = destination
            while destination.exists() and destination != item:
                stem = original_dest.stem
                suffix = original_dest.suffix
                destination = date_folder / f"{stem}_{counter}{suffix}"
                counter += 1

            items.append((item, date_folder, destination))

        if not items:
            print("No files to organize.")
            return 0

        # Preview
        print(f"Found {len(items)} file(s) to organize:")
        print()
        for item, date_folder, destination in items[:10]:
            print(f"  {item.name} -> {date_folder.name}/{destination.name}")
        if len(items) > 10:
            print(f"  ... and {len(items) - 10} more files")
        print()

        # Calculate total size
        total_size = sum(item.stat().st_size for item, _, _ in items)
        size_mb = total_size / (1024 * 1024)
        print(f"Total size: {size_mb:.2f} MB")

        if dry_run:
            print("\n[DRY RUN] No files were moved.")
            return 0

        # Confirmation
        if not yes:
            try:
                response = input("\nProceed with organizing? [y/N]: ").strip().lower()
                if response not in ("y", "yes"):
                    print("Cancelled.")
                    return 0
            except (EOFError, KeyboardInterrupt):
                print("\nCancelled.")
                return 0

        # Perform organization
        organized_count = 0
        for item, date_folder, destination in items:
            try:
                date_folder.mkdir(exist_ok=True)
                shutil.move(str(item), str(destination))
                print(f"Moved: {item.name} -> {date_folder.name}/{destination.name}")
                organized_count += 1
            except Exception as e:
                sys.stderr.write(f"Error moving {item.name}: {e}\n")

        print(f"\nSuccessfully organized {organized_count} file(s).")
        return 0

    except Exception as e:
        sys.stderr.write(f"An error occurred: {e}\n")
        return 1


def main():
    """Main entry point for the organize-downloads command."""
    parser = argparse.ArgumentParser(
        description="Organize files in download folder by date",
        epilog="Files are organized into YYYY-MM-DD folders based on modification or creation time.",
    )
    parser.add_argument(
        "folder",
        nargs="?",
        default="~/Downloads",
        help="Download folder to organize (default: ~/Downloads)",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without making changes",
    )
    parser.add_argument(
        "--by",
        choices=["modified", "created"],
        default="modified",
        help="Sort by modification time (default) or creation time",
    )
    parser.add_argument(
        "--include-hidden",
        action="store_true",
        help="Include hidden files (starting with .)",
    )
    parser.add_argument(
        "--pattern",
        help="Only include files matching this pattern (e.g., '*.pdf')",
    )
    parser.add_argument(
        "--exclude",
        help="Exclude files matching this pattern",
    )
    parser.add_argument(
        "--yes",
        "-y",
        action="store_true",
        help="Skip confirmation prompt",
    )

    args = parser.parse_args()

    return organize_downloads(
        args.folder,
        dry_run=args.dry_run,
        by=args.by,
        include_hidden=args.include_hidden,
        pattern=args.pattern,
        exclude=args.exclude,
        yes=args.yes,
    )


if __name__ == "__main__":
    sys.exit(main())
