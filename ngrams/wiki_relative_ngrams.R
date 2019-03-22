library(tidyverse)
library(directlabels)
library(dplyr)
library(tidytext)
library(entropy)
library(tidyboot)
library(tokenizers)
library(googlesheets)
library(stringr)
### Begin Functions

extract_wiki_tokens <- function(min_length, max_length, utterances, N) {

tokens <- utterances %>%
  mutate(length = str_count(words, pattern = "[ +]+") + 1) %>%
  filter(length >= min_length) %>%
  filter(length <= max_length) %>%
  mutate(utterance_id = 1:n()) %>%
  unnest_tokens(word, words, token = stringr::str_split, pattern = " +") %>%
  group_by(utterance_id) %>%
  mutate(word_order = 1:n())


lags <- expand.grid(lag_n = 1:(N-1),
                    utterance_id = unique(tokens$utterance_id))

grams <- tokens %>%
  left_join(lags, by = "utterance_id") %>%
  arrange(utterance_id, lag_n, word_order) %>%
  mutate(lag = lag(word, n = first(lag_n))) %>%
  drop_na() %>%
  mutate(gram = str_c(lag, word, sep = " ")) %>%
  rename(gram_order = word_order) %>%
  group_by(length, gram_order, gram) %>%
  summarise(n = n())

}

get_quantiles <- function(df, num_sections) {

  quantile(df$gram_order, probs = seq(0, 1, 1/num_sections)) %>%
    round() %>%
    as_data_frame() %>%
    rename(gram_order = value)
}

relative_slopes <- function(df, pos_list) {

  get_slope <- function(x) {

    selected_pos <- pos_list %>%
      group_by(length) %>%
      slice(x:(x+1)) %>%
      group_by(length) %>%
      summarise(min = min(gram_order),
                max = max(gram_order)) %>%
      split(.$length) %>%
      map(~seq(.x$min, .x$max, 1) %>% as_data_frame) %>%
      bind_rows(.id = "length") %>%
      rename(gram_order = value) %>%
      mutate(length = as.numeric(length))

    df %>%
      inner_join(selected_pos, by = c("length", "gram_order")) %>%
      group_by(length, gram_order) %>%
      summarise(entropy = entropy(n, unit = "log2")) %>%
      lm(entropy ~ length + I(length^2) + gram_order, data  = .) %>%
      tidy() %>%
      filter(term == "gram_order")
  }

  divides <- pos_list %>%
    group_by(length) %>%
    summarise(n = n()) %>%
    summarise(n = mean(n)) %>%
    pull()

  map(1:((divides)-1), get_slope) %>%
    bind_rows(.id = "cut")

}

### End Functions

NUM_SECTIONS = 5

LANGUAGE <- commandArgs(trailingOnly=TRUE)[1]
NGRAMS <- as.numeric(commandArgs(trailingOnly=TRUE)[2])

system(paste("python3 get_wiki_df.py", LANGUAGE, sep = " "))

df <- read_csv("wiki_df.csv")
df_tokens <- extract_wiki_tokens(7, 50, df, NGRAMS)
pos_list <- df_tokens %>%
  group_by(length) %>%
  distinct(gram_order) %>%
  split(.$length) %>%
  map(~get_quantiles(.x, NUM_SECTIONS)) %>%
  bind_rows(.id = "length") %>%
  mutate(length = as.numeric(length))
print("pos list made")
slopes <- relative_slopes(df_tokens, pos_list)
for_gs <- gs_title(paste0("Wikipedia_relative_", NGRAMS, "grams"))
wkpd <- gs_read(for_gs)
nr <- nrow(wkpd)

lang_slopes <- c(LANGUAGE, slopes$estimate)
gs_edit_cells(for_gs, ws = "Sheet1", anchor = paste("A", nr + 2, sep=""), input = lang_slopes, byrow = TRUE)
system("rm wiki_df.csv")
