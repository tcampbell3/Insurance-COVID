#To run the python script, type the following line into the command prompt:
#python "C:\Users\travi\Dropbox\Covid Medicare\Do Files\file_names.py"
# Python program to rename all file
# names in your directory 
import os
  
os.chdir('C:/Users/travi/Dropbox/Covid Medicare/Data/Webscrape')
print(os.getcwd())
COUNT = 1
  
# Function to increment count 
# to make the files sorted.
def increment():
    global COUNT
    COUNT = COUNT + 1
  
  
for f in os.listdir():
    f_name, f_ext = os.path.splitext(f)
    f_name = "county" + str(COUNT)
    increment()
  
    new_name = '{} {}'.format(f_name, f_ext)
    os.rename(f, new_name)