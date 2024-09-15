#!/Users/anhvth/miniconda3/envs/py312/bin/python

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title format_prompt
# @raycast.mode silent

# Optional parameters:
# @raycast.icon 🤖

# Documentation:

import pyperclip
import os
import re
import pyautogui  # For simulating keyboard input and mouse actions
import pygetwindow as gw  # To get the active window
import time  # To add a short delay if needed

# Function to check for placeholders in the template
def has_placeholders(template, pattern):
    return re.search(pattern, template)

# Function to replace placeholders with file content
def replace_placeholders(template, placeholders, snippets_dir):
    for placeholder in placeholders:
        file_path = os.path.join(snippets_dir, placeholder)
        try:
            with open(file_path, 'r') as file:
                file_content = file.read()
            template = template.replace(placeholder, file_content)
        except FileNotFoundError:
            print(f"Error: File '{placeholder}' not found in directory '{snippets_dir}'.")
    return template

# Step 1: Get the directory containing the prompt files from environment variable
snippets_dir = os.getenv('SNIPETS', '/Users/anhvth/gitprojects/snippet_maganer/snippets')

# Step 2: Get the clipboard content once
template = pyperclip.paste()

# Step 3: Define the placeholder search pattern
pattern = r'\b(\w+\.prompt)\b'

# Step 4: Check if there are any placeholders before proceeding
if not has_placeholders(template, pattern):
    print("No placeholders found in the clipboard content. Exiting.")
else:
    # Find all placeholders
    placeholders = re.findall(pattern, template)

    # Step 5: Replace the placeholders in the template
    updated_template = replace_placeholders(template, placeholders, snippets_dir)

    # Step 6: Copy the updated template back to the clipboard
    pyperclip.copy(updated_template)

    # Step 7: Simulate a paste action if there is an active window
    time.sleep(0.1)  # Minimal delay just in case

    active_window = gw.getActiveWindow()

    if active_window:
        x, y, w, h = gw.getWindowGeometry(active_window)  # type: ignore
        pyautogui.click(x + w // 2, y + h // 2)

        # Simulate pressing "Command + V" for macOS or "Ctrl + V" for Windows/Linux
        if os.name == 'posix':  # macOS or Linux
            pyautogui.hotkey('command', 'v')
        else:  # Windows
            pyautogui.hotkey('ctrl', 'v')
    else:
        print("No active window detected. Unable to paste automatically.")

    print("Template has been updated and pasted.")