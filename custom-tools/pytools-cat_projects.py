#!/usr/bin/env python3

import os
import argparse


from pydantic import BaseModel
from typing import List

# from openai import OpenAI

# client = OpenAI()


def summarize_python_file(python_file: str) -> str:
    is_no_line_with_def = all(
        [not line.strip().startswith("def ") for line in python_file.split("\n")]
    )
    is_no_line_with_class = all(
        [not line.strip().startswith("class ") for line in python_file.split("\n")]
    )
    if is_no_line_with_def and is_no_line_with_class:
        return python_file

    prompt = f"""You will be given a Python file content to summarize. Your task is to:
1. Read through the Python file provided in PYTHON_FILE_CONTENT.
2. For each **class** in the file:
    - Identify the class name.
    - Provide a brief summary of the class's purpose.
    - List and describe any attributes or special methods (e.g., __init__).
3. For each **method** in the file:
    - Identify the method name.
    - Summarize the method's purpose.
    - Describe the parameters it takes and the return type if available.
4. If the file does not contain any classes or methods, write "No classes or methods found."
5. Present the output in a structured list format, grouping the classes and their corresponding methods together.

Make sure the output is clear and concise.
<PYTHON_FILE_CONTENT>
{python_file}
</PYTHON_FILE_CONTENT>
Sumarize: """

    completion = client.chat.completions.create(
        model="gpt-4o-mini",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.0,
    )
    sumarize = completion.choices[0].message.content
    return sumarize


import os


def get_text2print(file, sumarize=False) -> str:
    """
    Given a file path, reads the file content and returns a formatted string with markup.
    """
    relative_path = os.path.relpath(file, os.getcwd())
    markup = []
    with open(file, "r", encoding="utf-8") as f:
        markup.append(f.read())

    content = "\n".join(markup)
    if sumarize:
        formatted_content = summarize_python_file(content)
    else:
        formatted_content = content
    formatted_content = f"<{relative_path}>\n{formatted_content}\n</{relative_path}>"
    return formatted_content

    # return "\n".join(markup)


def print_file_contents(inputs, file_extensions=".py", sumarize=False):
    """
    Prints the contents of files or files within directories specified in the inputs list,
    only if the files have valid extensions.
    """
    file_extensions = file_extensions.split(",")

    def is_valid_ext(file):
        ext = os.path.splitext(file)[1]
        return ext in file_extensions

    texts = []
    for input_path in inputs:

        if os.path.isdir(input_path):
            file_paths = []
            for root, dirs, files in os.walk(input_path):
                for file in files:
                    if is_valid_ext(file):
                        file_path = os.path.join(root, file)
                        file_paths.append(file_path)
            from speedy_utils import multi_thread  # type: ignore

            if sumarize:
                f = lambda file: get_text2print(file, sumarize=True)
            else:
                f = get_text2print
            ff = lambda x: f(x)
            print(file_paths[:3]+["..."]+file_paths[-3:])
            # ignore where contain ".FOLDER"
            ignore_keywords = [".venv", ".FOLDER", "__pycache__", ".git", ".mypy_cache"]
            def ignore_file(file):
                return not any(keyword in file for keyword in ignore_keywords)
            
            file_paths = [fp for fp in file_paths if ignore_file(fp)]
            texts = multi_thread(ff, file_paths, workers=32)
            # texts = [get_text2print(file) for file in file_paths]
            text = "\n".join(texts)
            print(text)

        elif os.path.isfile(input_path) and is_valid_ext(input_path):
            text = get_text2print(input_path)
            # texts.append()

        else:
            text = f"Error: {input_path} is not a valid file or directory, or it does not have a valid extension."

        print(text)


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
    parser.add_argument(
        "-s",
        "--sumarize",
        action="store_true",
        help="Sumarize the content of the files",
    )
    args = parser.parse_args()

    print_file_contents(args.inputs, args.extension, args.sumarize)
