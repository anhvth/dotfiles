from selenium import webdriver
from selenium.webdriver.chrome.options import Options
import os
import time
import pyperclip
from glob import glob

options = webdriver.ChromeOptions()
# os.makedirs('../drivers/user_data', exist_ok=True)
options.add_experimental_option("debuggerAddress", "127.0.0.1:9223")
driver = webdriver.Chrome(options=options)
web = driver.get('chrome-extension://bhghoamapcdpbohphigoooaddinpkbai/view/popup.html')
from selenium.webdriver.common.by import By
elem = driver.find_element(By.XPATH, r'//*[@id="codes"]/div[3]/a/div[5]')
output = "127747"+elem.text
print(output)
pyperclip.copy(output)
