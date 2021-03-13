from selenium.webdriver.firefox.options import Options
from glob import glob
from selenium import webdriver
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--link")

args = parser.parse_args()

browser = webdriver.Firefox()
browser.get(args.link)

