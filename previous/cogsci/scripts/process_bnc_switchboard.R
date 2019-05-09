library(here)
library(feather)
library(tidyverse)
library(tidyboot)
library(entropy)
library(stringr)
library(tidytext)

sb_tokens <- read_feather(here("../switchboard/switchboard.feather")) %>%
  mutate(length = str_count(value, pattern = " +") + 1) %>% 
  mutate(utterance_id = 1:n()) %>%
  unnest_tokens(word, value, token = stringr::str_split, pattern = " +") %>%
  group_by(utterance_id) %>%
  mutate(word_order = 1:n()) 

bnc10_tokens <- read_feather(here("../bnc/bnc10.feather")) %>%
  mutate(word = as.numeric(as.factor(word)))
bnc20_tokens <- read_feather(here("../bnc/bnc20.feather")) %>%
  mutate(word = as.numeric(as.factor(word)))
bnc30_tokens <- read_feather(here("../bnc/bnc30.feather")) %>%
  mutate(word = as.numeric(as.factor(word)))

unigram_entropy <- function(sen_length, tokens) {
  tokens %>%
    filter(length == sen_length) %>%
    group_by(word_order, word) %>%
    summarise(n = n()) %>%
    tidyboot(summary_function = function(x) x %>% 
               summarise(entropy = entropy(n, unit = "log2")),
             statistics_functions = function(x) x %>%
               summarise_at(vars(entropy), funs(ci_upper, ci_lower))) %>%
    mutate(length = sen_length)
}

switchboard_entropies <- map_df(2:10, ~unigram_entropy(.x, sb_tokens)) 

bnc10_entropies <- unigram_entropy(10, bnc10_tokens)
bnc20_entropies <- unigram_entropy(20, bnc20_tokens)
bnc30_entropies <- unigram_entropy(30, bnc30_tokens)

bnc_entropies <- bind_rows(bnc10_entropies, bnc20_entropies, bnc30_entropies)

write_csv(bnc_entropies, here("data/bnc_entropies.csv"))
write_csv(switchboard_entropies, here("data/switchboard_entropies.csv"))
