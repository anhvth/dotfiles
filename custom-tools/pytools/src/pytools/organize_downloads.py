#!/usr/bin/env python3
"""
Organize Downloads - Organize files in Downloads folder by creation date.

This tool organizes files in the Downloads folder by moving them into
subdirectories named after their creation date (YYYY-MM-DD format).
"""

import os
import shutil
import sys
from datetime import datetime
from pathlib import Path


def organize_downloads(download_folder):
    """Organize files in the downloads folder by creation date."""
    download_path = Path(download_folder).expanduser()
    
    if not download_path.exists():
        print(f"Error: Download folder '{download_folder}' does not exist")
        return 1
    
    if not download_path.is_dir():
        print(f"Error: '{download_folder}' is not a directory")
        return 1
    
    try:
        # List all items in the downloads folder
        items = list(download_path.iterdir())
        organized_count = 0
        
        for item in items:
            # Skip if it is a directory
            if item.is_dir():
                continue
            
            # Get the creation date of the file
            creation_time = item.stat().st_ctime
            creation_date = datetime.fromtimestamp(creation_time).strftime('%Y-%m-%d')
            
            # Create a directory named after the creation date
            date_folder = download_path / creation_date
            date_folder.mkdir(exist_ok=True)
            
            # Move the file to the date directory
            destination = date_folder / item.name
            
            # Handle naming conflicts
            counter = 1
            original_dest = destination
            while destination.exists():
                stem = original_dest.stem
                suffix = original_dest.suffix
                destination = date_folder / f"{stem}_{counter}{suffix}"
                counter += 1
            
            shutil.move(str(item), str(destination))
            print(f"Moved: {item.name} -> {date_folder.name}/{destination.name}")
            organized_count += 1
        
        print(f"Successfully organized {organized_count} files.")
        return 0
        
    except Exception as e:
        print(f"An error occurred: {e}")
        return 1


def main():
    """Main entry point for the organize-downloads command."""
    # Allow custom download folder as argument, default to ~/Downloads
    if len(sys.argv) > 2:
        print("Usage: organize-downloads [DOWNLOAD_FOLDER]")
        print("Organize files in download folder by creation date")
        return 1
    
    download_folder = sys.argv[1] if len(sys.argv) == 2 else "~/Downloads"
    return organize_downloads(download_folder)


if __name__ == "__main__":
    exit(main())