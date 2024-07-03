#!/usr/bin/env python3

import os
import sys

def print_file_contents(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.py'):
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, directory)
                print(f"----")
                print(f"File: {relative_path}")
                print(f"Content: ```")
                with open(file_path, 'r', encoding='utf-8') as f:
                    print(f.read())
                print("```")
                print("----")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python script.py <directory_path>")
        sys.exit(1)
    
    project_directory = sys.argv[1]
    
    if not os.path.isdir(project_directory):
        print(f"Error: {project_directory} is not a valid directory.")
        sys.exit(1)
    
    print_file_contents(project_directory)

