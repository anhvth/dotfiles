#!/usr/bin/env python3
import requests
from bs4 import BeautifulSoup

# Request URL
url = 'https://ip4.me/'

# Send GET request
response = requests.get(url)

# Check if the request was successful
if response.status_code == 200:
    # Parse content with BeautifulSoup
    soup = BeautifulSoup(response.text, 'html.parser')
    
    # Find the table cell that contains the IPv4
    ip_cell = soup.find('font', face="Arial, Monospace")
    
    # Extract and print the IPv4 address if the cell is found
    if ip_cell:
        ipv4_address = ip_cell.get_text(strip=True)
        print(ipv4_address)
    else:
        print("Could not find the IPv4 address in the HTML.")
else:
    print('Failed to retrieve the page. Status code:', response.status_code)

