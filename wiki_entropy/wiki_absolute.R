library(knitr)
library(tidyverse)
library(directlabels)
library(dplyr)
library(tidytext)
library(entropy)
library(tidyboot)
library(tokenizers)
library(googlesheets)

### BEGIN FUNCTIONS

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

start_slope <- function(df) {

 df %>%
    filter(word_order %in% c(1,2)) %>%
    sample_frac(1, replace = T) %>%
    group_by(length, word_order) %>%
    summarise(entropy = entropy(n, unit = "log2")) %>%
    spread(word_order, entropy) %>%
    ungroup() %>%
    mutate(diff = `2` - `1`) %>%
    summarise(diff = mean(diff)) %>%
    pull(diff)

}

second_slope <- function(df) {

 df %>%
    ungroup() %>%
    mutate(word_order %in% c(2, 3)) %>%
    filter(word_order > 0) %>%
    sample_frac(1, replace = T) %>%
    group_by(length, word_order) %>%
    summarise(entropy = entropy(n, unit = "log2")) %>%
    spread(word_order, entropy) %>%
    ungroup() %>%
    mutate(diff = `3` - `2`) %>%
    summarise(diff = mean(diff)) %>%
    pull(diff)

}

#note this measurement only makes sense if utterance length is at least 6
mid_slope <- function(df) {

 df %>%
    ungroup() %>%
    mutate(word_order = if_else(word_order == length-2, 2,
                                if_else(word_order == 3, 1,
                                        0))) %>%
    filter(word_order > 0) %>%
    group_by(length, word_order) %>%
    sample_frac(1, replace = T) %>%
    group_by(length, word_order) %>%
    summarise(entropy = entropy(n, unit = "log2")) %>%
    spread(word_order, entropy) %>%
    ungroup() %>%
    mutate(diff = `2` - `1`) %>%
    summarise(diff = mean(diff)) %>%
    pull(diff)

}

penult_slope <- function(df) {

 df %>%
    ungroup() %>%
    mutate(word_order = if_else(word_order == length-1, 2,
                                if_else(word_order == length -2, 1,
                                        0))) %>%
    filter(word_order > 0) %>%
    group_by(length, word_order) %>%
    sample_frac(1, replace = T) %>%
    group_by(length, word_order) %>%
    summarise(entropy = entropy(n, unit = "log2")) %>%
    spread(word_order, entropy) %>%
    ungroup() %>%
    mutate(diff = `2` - `1`) %>%
    summarise(diff = mean(diff)) %>%
    pull(diff)

}

end_slope <- function(df) {

 df %>%
    ungroup() %>%
    mutate(word_order = if_else(word_order == length, 2,
                                if_else(word_order == length -1 , 1,
                                        0))) %>%
    filter(word_order > 0) %>%
    group_by(length, word_order) %>%
    sample_frac(1, replace = T) %>%
    group_by(length, word_order) %>%
    summarise(entropy = entropy(n, unit = "log2")) %>%
    spread(word_order, entropy) %>%
    ungroup() %>%
    mutate(diff = `2` - `1`) %>%
    summarise(diff = mean(diff)) %>%
    pull(diff)

}


get_wiki_slopes <- function(min_length, max_length, utterances, REPS) {

  tokens <- extract_wiki_tokens(min_length, max_length, utterances)

  start_slopes <- replicate(REPS, start_slope(tokens)) %>%
    as_data_frame() %>%
    summarise(mean = mean(value), ci_upper = quantile(value, .975),
              ci_lower = quantile(value, .025))

  second_slopes <- replicate(REPS, second_slope(tokens)) %>%
    as_data_frame() %>%
    summarise(mean = mean(value), ci_upper = quantile(value, .975),
              ci_lower = quantile(value, .025))

  mid_slopes <- replicate(REPS, mid_slope(tokens)) %>%
    as_data_frame() %>%
    summarise(mean = mean(value), ci_upper = quantile(value, .975),
              ci_lower = quantile(value, .025))

  penult_slopes <- replicate(REPS, penult_slope(tokens)) %>%
    as_data_frame() %>%
    summarise(mean = mean(value), ci_upper = quantile(value, .975),
              ci_lower = quantile(value, .025))

  end_slopes <- replicate(REPS, end_slope(tokens)) %>%
    as_data_frame() %>%
    summarise(mean = mean(value), ci_upper = quantile(value, .975),
              ci_lower = quantile(value, .025))

  rbind(start_slopes, second_slopes, mid_slopes, penult_slopes, end_slopes)
}

### END FUNCTIONS

LANGUAGE <- commandArgs(trailingOnly=TRUE)[1]

system(paste("python3 get_wiki_df.py", LANGUAGE, sep = " "))

REPS <- 100
for_gs <- gs_title("Wikipedia_absolute")

df <- read_csv("wiki_df.csv")
slopes <- get_wiki_slopes(min_length = 6, max_length = 50, utterances=df, REPS)
wkpd <- gs_read(for_gs)
nr <- nrow(wkpd)

lang_slopes <- c(LANGUAGE, slopes$mean)
gs_edit_cells(for_gs, ws = "Sheet1", anchor = paste("A", nr + 2, sep=""), input = lang_slopes, byrow = TRUE)
system("rm wiki_df.csv")
