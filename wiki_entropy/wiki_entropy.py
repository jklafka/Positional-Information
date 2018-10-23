import regex as re 
import numpy as np
import pandas as pd 
import csv
import sys
import json
import subprocess
import urllib.request


with open("language_dict.json", 'r') as f:
	file = f.read()
LANG_DICT = json.loads(file) #maps languages to their wikipedia url prefixes


def extract_texts(upper_bound):
	'''
	Given an upper_bound on file numbers, extracts the raw text from the files
	in the text/AA folder. That folder is given as output by the cirrus_extract
	program. 
	'''
	rs = ""
	for i in range(upper_bound):
		if i < 10:
			number = "0" + str(i)
		else:
			number = str(i)
		f = open("text/AA/wiki_" + number, 'r')
		text = f.read()
		rs += text
	return rs


def get_sen_dict(text):
	'''
	Given the output of extract_texts as a string, constructs a 
	dictionary mapping each sentence in the string to its length in words.
	'''
	text = re.sub("<doc.+>|</doc>|http:\S+|[-%,;:–'&*#/—“»]|\d+|\(|\)|\[|\]", \
		"", text) 
	text = re.sub('"', '', text)
	#just the words from the articles
	text = text.replace('\n', " ")
	sens = re.split("[.!?]", text.lower())
	sen_dict = {}
	for sen in sens:
		length = len(re.findall("\w+", sen))
		if length > 0:
			sen_dict[sen] = length
	return sen_dict


def get_sen_df(text):
	'''
	Given the output of extract_texts as a string, returns a Pandas dataframe
	of the output of get_sen_dict. 
	'''
	sd = get_sen_dict(text)
	s = pd.Series(sd, name = "length")
	del sd
	s.index.name = "gloss"
	df = s.reset_index() #gives a dataframe with columns "sentence" and "length" containing the sentence 
					 	  #and the setence length respectively
	return df
	

def main(lang_name):
	lang_prefix = LANG_DICT[lang_name] #gets the wikipedia url prefix for lang_name
	url = "https://dumps.wikimedia.org/other/cirrussearch/current/" \
		+ lang_prefix + "wiki-20181008-cirrussearch-content.json.gz"	
	urllib.request.urlretrieve(url, "datafile") #downloads the dump for that language
	
	subprocess.call(["wikiextractor/cirrus_extract.py", "datafile"])

	directory = subprocess.check_output(["ls", "text/AA"]).decode("utf-8")
	highest_filenum = int(max(re.findall("\d\d", directory)))
	upper_bound = min(highest_filenum, 50)

	text = extract_texts(upper_bound)
	df = get_sen_df(text)
	df.to_csv(lang_prefix + "_df.csv")

	del df
	subprocess.call(["rm", "-r", "text"])
	subprocess.call(["rm", "datafile"])


if __name__ == "__main__":
	main(sys.argv[1])
	