#!/usr/bin/env python3

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
    except subprocess.CalledProcessError as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Usage: ./download_with_wget.py <URL> [SAVE_NAME]")
        sys.exit(1)
    
    url = sys.argv[1]
    url = url.split("?")[0]
    save_name = sys.argv[2] if len(sys.argv) == 3 else None
    download_file(url, save_name)

