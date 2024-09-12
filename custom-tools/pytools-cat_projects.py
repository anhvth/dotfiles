#!/usr/bin/env python3

import os
import argparse

def print_file_contents(inputs, file_extensions=".py"):
    """
    Prints the contents of files or files within directories specified in the inputs list.
    """
    file_extensions = file_extensions.split(",")

    def is_valid_ext(file):
        ext = os.path.splitext(file)[1]
        return ext in file_extensions

    for input_path in inputs:
        if os.path.isdir(input_path):
            for root, dirs, files in os.walk(input_path):
                for file in files:
                    if is_valid_ext(file):
                        file_path = os.path.join(root, file)
                        relative_path = os.path.relpath(file_path, input_path)
                        print(f"----")
                        print(f"<{relative_path}>")

                        with open(file_path, "r", encoding="utf-8") as f:
                            print(f.read())

                        print(f"</{relative_path}>")  # Moved inside the valid file check

        elif os.path.isfile(input_path):
            relative_path = os.path.relpath(input_path, os.getcwd())
            print(f"----")
            print(f"<{relative_path}>")

            with open(input_path, "r", encoding="utf-8") as f:
                print(f.read())

            print(f"</{relative_path}>")
        else:
            print(f"Error: {input_path} is not a valid file or directory, or it does not have a valid extension.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Prints the contents of specified files or files within directories."
    )
    parser.add_argument(
        "inputs", nargs="+", help="List of files or directories to scan."
    )
    parser.add_argument(
        "-e",
        "--extension",
        default=".py",
        help="File extension to look for (default: .py)",
    )
    args = parser.parse_args()

    print_file_contents(args.inputs, args.extension)
