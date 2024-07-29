#!/usr/bin/env python3

import os
import argparse

def print_file_contents(directory, file_extension=".py"):
    """
    Recursively prints the contents of files with the specified extension in the given directory.
    """
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(file_extension):
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, directory)
                print(f"----")
                print(f"File: {relative_path}")
                print(f"Content: ```")
                with open(file_path, "r", encoding="utf-8") as f:
                    print(f.read())
                print("```")
                print("----")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Prints the contents of files in a directory.")
    parser.add_argument("directory", help="Path to the directory to scan.")
    parser.add_argument("-e", "--extension", default=".py", help="File extension to look for (default: .py)")
    args = parser.parse_args()

    if not os.path.isdir(args.directory):
        print(f"Error: {args.directory} is not a valid directory.")
    else:
        print_file_contents(args.directory, args.extension)
