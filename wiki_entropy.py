import regex as re 
import numpy as np
import pandas as pd 
import csv
import sys

def extract_texts(upper_bound):
	rs = ""
	for i in range(upper_bound):
		if i < 10:
			number = "0" + str(i)
		else:
			number = str(i)
		f = open("../misc/text/AA/wiki_" + number, 'r')
		text = f.read()
		rs += text
	return rs


def get_sen_dict(text):
	text = re.sub("<doc.+>|</doc>|http:\S+|[-%,;:–'&*#/—“»]|\d+|\(|\)|\[|\]", "", text) 
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
	sd = get_sen_dict(text)
	s = pd.Series(sd, name = "length")
	del sd
	s.index.name = "gloss"
	df = s.reset_index() #gives a dataframe with columns "sentence" and "length" containing the sentence 
					 	  #and the setence length respectively
	return df
	
def main(upper_bound, lang_name):
	text = extract_texts(upper_bound)
	df = get_sen_df(text)
	df.to_csv(lang_name + "_df.csv")


if __name__ == "__main__":
	main(int(sys.argv[1]), sys.argv[2])
