library(knitr)
library(tidyverse)
library(directlabels)
library(dplyr)
library(tidytext)
library(entropy)
library(tidyboot)
library(tokenizers)
library(googlesheets)

### Begin Functions

extract_wiki_tokens <- function(min_length, max_length, utterances) {

  tokens <- utterances %>%
    mutate(gloss = str_trim(gloss)) %>%
    mutate(length = str_count(gloss, pattern = " +") + 1) %>%
    filter(length >= min_length) %>%
    filter(length <= max_length) %>%
    mutate(utterance_id = 1:n()) %>%
    unnest_tokens(word, gloss, token = stringr::str_split, pattern = " +") %>%
    group_by(utterance_id) %>%
    mutate(word_order = 1:n()) %>%
    group_by(length, word_order, word) %>%
    summarise(n = n())
}

get_quantiles <- function(df, num_sections) {
  quantile(df$word_order, probs = seq(0, 1, 1/num_sections)) %>%
    round() %>%
    as_data_frame() %>%
    rename(word_order = value)
}

relative_slopes <- function(df, pos_list) {

  get_slope <- function(x) {

    selected_pos <- pos_list %>%
      group_by(length) %>%
      slice(x:(x+1)) %>%
      group_by(length) %>%
      summarise(min = min(word_order),
                max = max(word_order)) %>%
      split(.$length) %>%
      map(~seq(.x$min, .x$max, 1) %>% as_data_frame) %>%
      bind_rows(.id = "length") %>%
      rename(word_order = value) %>%
      mutate(length = as.numeric(length))

    df %>%
      inner_join(selected_pos, by = c("length", "word_order")) %>%
      group_by(length, word_order) %>%
      summarise(entropy = entropy(n, unit = "log2")) %>%
      lm(entropy ~ length + I(length^2) + word_order, data  = .) %>%
      tidy() %>%
      filter(term == "word_order")
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

NUM_SECTIONS = 10

LANGUAGE <- commandArgs(trailingOnly=TRUE)[1]

system(paste("python3 get_wiki_df.py", LANGUAGE, sep = " "))

REPS <- 100
for_gs <- gs_title("Wikipedia_relative10")

df <- read_csv("wiki_df.csv")
df_tokens <- extract_wiki_tokens(6, 50, df)
pos_list <- df_tokens %>%
  group_by(length) %>%
  distinct(word_order) %>%
  split(.$length) %>%
  map(~get_quantiles(.x, NUM_SECTIONS)) %>%
  bind_rows(.id = "length") %>%
  mutate(length = as.numeric(length))

slopes <- relative_slopes(df_tokens, pos_list)
wkpd <- gs_read(for_gs)
nr <- nrow(wkpd)

lang_slopes <- c(LANGUAGE, slopes$estimate)
gs_edit_cells(for_gs, ws = "Sheet1", anchor = paste("A", nr + 2, sep=""), input = lang_slopes, byrow = TRUE)
system("rm wiki_df.csv")
