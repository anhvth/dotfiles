import os
import shutil
from datetime import datetime

def organize_downloads(download_folder):
    try:
        # List all items in the downloads folder
        items = os.listdir(download_folder)
        
        for item in items:
            item_path = os.path.join(download_folder, item)
            
            # Skip if it is a directory
            if os.path.isdir(item_path):
                continue
            
            # Get the creation date of the file
            creation_time = os.path.getctime(item_path)
            creation_date = datetime.fromtimestamp(creation_time).strftime('%Y-%m-%d')
            
            # Create a directory named after the creation date
            date_folder = os.path.join(download_folder, creation_date)
            if not os.path.exists(date_folder):
                os.makedirs(date_folder)
            
            # Move the file to the date directory
            shutil.move(item_path, os.path.join(date_folder, item))
        
        print("Downloads organized successfully.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    download_folder = os.path.expanduser("~/Downloads")
    organize_downloads(download_folder)

