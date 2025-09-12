#!/usr/bin/env python3
"""
Hugging Face Downloader - Download files from Hugging Face Hub with URL transformation.

This tool downloads files from Hugging Face Hub, automatically transforming
'blob' URLs to 'resolve' URLs for direct download access.
"""

import subprocess
import sys


def transform_url(url):
    """
    Transform the Hugging Face URL to use the 'resolve' endpoint instead of 'blob'.
    """
    if "blob" in url:
        url = url.replace("blob", "resolve")
    return url


def download_file(url, save_name=None):
    """Download a file from the given URL using wget."""
    try:
        # Transform the URL if necessary
        url = transform_url(url)
        
        # Construct the wget command
        command = ['wget', url]
        
        # If save_name is provided, add the '-O' option to the command
        if save_name:
            command += ['-O', save_name]
        
        # Execute the command
        subprocess.run(command, check=True)
        print(f"Download completed: {url}")
        return 0
    except subprocess.CalledProcessError as e:
        print(f"An error occurred: {e}")
        return 1
    except FileNotFoundError:
        print("Error: wget is not installed or not in PATH")
        return 1


def main():
    """Main entry point for the hf-down command."""
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: hf-down <URL> [SAVE_NAME]")
        print("Download files from Hugging Face Hub")
        return 1
    
    url = sys.argv[1]
    # Remove query parameters if present
    url = url.split("?")[0]
    save_name = sys.argv[2] if len(sys.argv) == 3 else None
    
    return download_file(url, save_name)


if __name__ == "__main__":
    exit(main())