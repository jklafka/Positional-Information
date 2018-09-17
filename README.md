# Positional-Information
## A Project on the Distribution of Information across Sentences in Speech and Text (crosslinguistic)

<strong>english_unigram&ce&mi.Rmd</strong> - produces unigram entropy, conditional information and mutual information estimates for English-language CHILDES corpora, in particular the Brown and Providence corpora. 

<strong>non-english_entropies.Rmd</strong> - produces unigram entropy estimates for non-English CHILDES corpora, in particular the Spanish Shiro corpus, the German Wagner corpus, the Japanese Okayama corpus and the Chinese Zhou corpus. 

<strong>non-english_ce&mi.Rmd</strong> - produces conditional information and mutual information estimates for non-English CHILDES corpora, in particular the same corpora as listed above. 

<strong>LDP_entropy.Rmd</strong> - produces unigram entropy estimates for individual subjects from the Language Development Project. 

<strong>wiki_entropy.Rmd</strong> - produces unigram entropy estimates for a selection of several thousand random articles from the Wikipedia corpus of a given language. 
To use the wiki_entropy program, you should use Giuseppe Attardi's wikiextractor (https://github.com/attardi/wikiextractor), specifically the cirrus-extract.py program, on the Cirrus Wikipedia dump in the language you want to examine. The current Cirrus dumps are located at (https://dumps.wikimedia.org/other/cirrussearch/current/). This will produce at least one folder of between 1 and 100 .txt files containing stripped-down Wikipedia articles, with only the text, hyperlinks and basic item information (between <doc> tags) remaining. You can now run the wiki_entropy.Rmd program, which depending on how large the text folder is, may take up to 30 minutes. 
