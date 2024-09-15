#!/Users/anhvth/miniconda3/bin/python

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title sayit
# @raycast.mode fullOutput

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.description †

import requests
import pyperclip
import os
import sys

# API endpoint and key
API_URL = "https://api.openai.com/v1/audio/speech"

API_KEY=os.getenv("OPENAI_API_KEY")
def generate_speech(input_text: str, model: str = "tts-1", voice: str = "alloy", output_file: str = "speech.mp3"):
    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    data = {
        "model": model,
        "input": input_text,
        "voice": voice
    }

    response = requests.post(API_URL, headers=headers, json=data)

    if response.status_code == 200:
        with open(output_file, 'wb') as f:
            f.write(response.content)
        print(f"Speech saved to {output_file}")
    else:
        print(f"Error: {response.status_code} - {response.json()}")
import os
import hashlib
import pyperclip
from playsound import playsound

CACHE_DIR = os.path.expanduser('~/.cache/openai_speech/')

def process_input(input_text):
    # Strip, lower case and split the input
    input_text = input_text.strip().lower()
    
    words = input_text.split()
    if len(words) > 1000:
        return None
    
    # Hash the input
    hashed_input = hashlib.sha256(input_text.encode()).hexdigest()
    
    # Generate an output mp3 path in cache dir
    if not os.path.exists(CACHE_DIR):
        os.makedirs(CACHE_DIR)
    output_file_path = os.path.join(CACHE_DIR, f"{hashed_input}.mp3")
    
    # Check if the file exists, if not, generate it
    if not os.path.exists(output_file_path):
        generate_speech(input_text, output_file=output_file_path)
    
    # Play the generated speech file
    playsound(output_file_path)
    
if __name__ == '__main__':
    # Fetch input text from the clipboard
    input_text = pyperclip.paste()
    processed_result = process_input(input_text)
    if processed_result is None:
        print("Input ignored: more than 100 words.")
