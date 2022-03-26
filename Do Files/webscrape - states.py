#To run the python script, type the following line into the command prompt:
#python "C:\Users\travi\Dropbox\Covid Medicare\Do Files\webscrape - states.py"

# import packages
import time
import itertools 
import csv
from csv import reader
import codecs
from bs4 import BeautifulSoup
from selenium  import webdriver
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.chrome.options import Options
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.select import Select
from time import sleep
import os, glob
 
# Delete downloads
dir = 'C:/Users/travi/Downloads'
filelist = glob.glob(os.path.join(dir, "*"))
for f in filelist:
	os.remove(f)

# access website through automated chrome
chrome_path=r"C:\Users\travi\Anaconda3\Lib\site-packages\selenium\chromedriver.exe"
driver = webdriver.Chrome(chrome_path)
driver.get('https://covid.cdc.gov/covid-data-tracker/#county-view')
sleep(10)

# Number of states
select = Select(driver.find_element_by_xpath("""//*[@id="list_select_state"]"""))
state_count =len(select.options)+1

# loop states
for x in range(2, state_count):	
	print("We're on state %d" % (x))
	# Click state
	xpath = '//*[@id="list_select_state"]/option['+str(x)+']'
	driver.find_element_by_xpath(xpath).click()
	# Washington DC is weird
	if x!=10:
		driver.find_element_by_xpath("""//*[@id="list_select_county"]/option[2]""").click()
	sleep(30)
	# Download file 1
	driver.find_element_by_xpath("""//*[@id="vaccinations-table-toggle"]""").click()
	pre = len(glob.glob(os.path.join(dir, "*")))
	post = len(glob.glob(os.path.join(dir, "*")))
	while pre >= post:
		sleep(3)
		try:
			driver.find_element_by_xpath("""//*[@id="btnVaccinationsExport"]""").click()
		except:
			ddriver.find_element_by_xpath("""//*[@id="vaccinations-table-toggle"]""").click()
		post = len(glob.glob(os.path.join(dir, "*")))
	# Download file 2
	driver.find_element_by_xpath("""//*[@id="county-level-latest-table-toggle"]""").click()
	pre = len(glob.glob(os.path.join(dir, "*")))
	post = len(glob.glob(os.path.join(dir, "*")))
	while pre >= post:
		sleep(3)
		try:
			driver.find_element_by_xpath("""//*[@id="btnCountyLevelLatestExport"]""").click()
		except:
			driver.find_element_by_xpath("""//*[@id="county-level-latest-table-toggle"]""").click()
		post = len(glob.glob(os.path.join(dir, "*")))	

# close browser
driver.quit()

# close csv file
f.close()