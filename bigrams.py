import re

file = open("counts.txt", 'r')
s = file.read()
counts = re.findall(r'\d+', s)
counts = [int(num) for num in counts]

file = open("bigram_words.txt", 'r')
s = file.read()
bigrams = re.split(r',', s)

word_dict = {}

for i in range(len(bigrams)):
    words = re.split(' ', bigrams[i])
    if words[0] not in word_dict:
        word_dict[words[0]] = {}
        word_dict[words[0]]["TOTAL"] = 0
    if words[1] not in word_dict[words[0]]:
        word_dict[words[0]][words[1]] = 0
    word_dict[words[0]][words[1]] += counts[i]
    word_dict[words[0]]["TOTAL"] += counts[i]

for key in word_dict:
    div = word_dict[key]["TOTAL"]
    for val in word_dict[key]:
        word_dict[key][val] /= div