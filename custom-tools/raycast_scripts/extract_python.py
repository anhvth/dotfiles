#!/usr/bin/env /Users/anhvth/miniconda3/bin/python

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Extract Python code from clipboard
# @raycast.mode silent
# @raycast.refreshTime 1h

# Optional parameters:
# @raycast.icon 🤖

import pyperclip
def get_clipboard_output():
    return pyperclip.paste()

def extract_python(text):
    # pattern: ```python\n...code...\n```
    import re
    pattern = r"```python\n(.*?)\n```"
    # find all the code blocks
    code_blocks = re.findall(pattern, text, re.DOTALL)
    # merge to a single string
    return "\n".join(code_blocks)

if __name__ == "__main__":
    text = get_clipboard_output()
    code = extract_python(text)
    # copy to cliipboard
    pyperclip.copy(code)
    print(f"Extracted python code: {code}")