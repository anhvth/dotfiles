#!/usr/bin/env python3
"""
Print IPv4 - Display the public IPv4 address of the current machine.

This tool fetches and displays the public IPv4 address using external services.
"""

import subprocess
import sys
import urllib.error
import urllib.request


def get_ip_via_curl():
    """Get IP address using curl command."""
    try:
        result = subprocess.run(
            ['curl', '-s', 'https://ipecho.net/plain'],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError):
        pass
    return None


def get_ip_via_urllib():
    """Get IP address using urllib (fallback method)."""
    try:
        with urllib.request.urlopen('https://ipecho.net/plain', timeout=10) as response:
            return response.read().decode('utf-8').strip()
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError):
        pass
    return None


def get_ip_via_alternative():
    """Get IP address using alternative service."""
    try:
        with urllib.request.urlopen('https://api.ipify.org', timeout=10) as response:
            return response.read().decode('utf-8').strip()
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError):
        pass
    return None


def main():
    """Main entry point for the print-ipv4 command."""
    # Try multiple methods to get the IP
    ip = get_ip_via_curl()

    if not ip:
        ip = get_ip_via_urllib()

    if not ip:
        ip = get_ip_via_alternative()

    if ip:
        print(ip)
        return 0
    else:
        print("Failed to retrieve IP address", file=sys.stderr)
        return 1


if __name__ == "__main__":
    exit(main())
