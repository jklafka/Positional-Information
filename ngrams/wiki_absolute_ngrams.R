library(tidyverse)
library(directlabels)
library(tidytext)
library(entropy)
library(tidyboot)
library(tokenizers)
library(googlesheets)

### BEGIN FUNCTIONS

extract_wiki_tokens <- function(min_length, max_length, utterances, N) {

  tokens <- utterances %>%
    mutate(length = str_count(words, pattern = "[ +]+") + 1) %>%
    filter(length >= min_length) %>%
    filter(length <= max_length) %>%
    mutate(utterance_id = 1:n()) %>%
    unnest_tokens(gram, words, token = stringr::str_split, pattern = "[ +]+") %>%
    group_by(utterance_id) %>%
    mutate(gram_order = 1:n())


  lags <- expand.grid(lag_n = 1:(N-1),
                      utterance_id = unique(tokens$utterance_id))

  tokens %>%
    left_join(lags, by = "utterance_id") %>%
    arrange(utterance_id, lag_n, gram_order) %>%
    mutate(lag = lag(gram, n = first(lag_n))) %>%
    drop_na() %>%
    mutate(gram = str_c(lag, gram, sep = " ")) %>%
    rename(gram_order = gram_order) %>%
    group_by(length, gram_order, gram) %>%
    summarise(n = n())

}

start_slope <- function(df) {

 df %>%
    filter(gram_order %in% c(2,3)) %>%
    sample_frac(1, replace = T) %>%
    group_by(length, gram_order) %>%
    summarise(entropy = entropy(n, unit = "log2")) %>%
    spread(gram_order, entropy) %>%
    ungroup() %>%
    mutate(diff = `3` - `2`) %>%
    summarise(diff = mean(diff)) %>%
    pull(diff)

}

second_slope <- function(df) {

 df %>%
    ungroup() %>%
    mutate(gram_order %in% c(3, 4)) %>%
    filter(gram_order > 0) %>%
    sample_frac(1, replace = T) %>%
    group_by(length, gram_order) %>%
    summarise(entropy = entropy(n, unit = "log2")) %>%
    spread(gram_order, entropy) %>%
    ungroup() %>%
    mutate(diff = `4` - `3`) %>%
    summarise(diff = mean(diff)) %>%
    pull(diff)

}

#note this measurement only makes sense if utterance length is at least 6
mid_slope <- function(df) {

 df %>%
    ungroup() %>%
    mutate(gram_order = if_else(gram_order == length-2, 3,
                                if_else(gram_order == 3, 2,
                                        0))) %>%
    filter(gram_order > 0) %>%
    group_by(length, gram_order) %>%
    sample_frac(1, replace = T) %>%
    group_by(length, gram_order) %>%
    summarise(entropy = entropy(n, unit = "log2")) %>%
    spread(gram_order, entropy) %>%
    ungroup() %>%
    mutate(diff = `3` - `2`) %>%
    summarise(diff = mean(diff)) %>%
    pull(diff)

}

penult_slope <- function(df) {

 df %>%
    ungroup() %>%
    mutate(gram_order = if_else(gram_order == length-1, 3,
                                if_else(gram_order == length -2, 2,
                                        0))) %>%
    filter(gram_order > 0) %>%
    group_by(length, gram_order) %>%
    sample_frac(1, replace = T) %>%
    group_by(length, gram_order) %>%
    summarise(entropy = entropy(n, unit = "log2")) %>%
    spread(gram_order, entropy) %>%
    ungroup() %>%
    mutate(diff = `3` - `2`) %>%
    summarise(diff = mean(diff)) %>%
    pull(diff)

}

end_slope <- function(df) {

 df %>%
    ungroup() %>%
    mutate(gram_order = if_else(gram_order == length, 3,
                                if_else(gram_order == length -1 , 2,
                                        0))) %>%
    filter(gram_order > 0) %>%
    group_by(length, gram_order) %>%
    sample_frac(1, replace = T) %>%
    group_by(length, gram_order) %>%
    summarise(entropy = entropy(n, unit = "log2")) %>%
    spread(gram_order, entropy) %>%
    ungroup() %>%
    mutate(diff = `3` - `2`) %>%
    summarise(diff = mean(diff)) %>%
    pull(diff)

}


get_wiki_slopes <- function(tokens, REPS) {

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
NGRAMS <- as.numeric(commandArgs(trailingOnly=TRUE)[2])

system(paste("python3 get_wiki_df.py", LANGUAGE, sep = " "))

REPS <- 100

df <- read_csv("wiki_df.csv")

tokens <- extract_wiki_tokens(NGRAMS + 5, 50, df, NGRAMS)
slopes <- get_wiki_slopes(tokens, REPS)

for_gs <- gs_title(paste0("Wikipedia_absolute_", NGRAMS, "grams"))
wkpd <- gs_read(for_gs)
nr <- nrow(wkpd)

lang_slopes <- c(LANGUAGE, slopes$mean)
gs_edit_cells(for_gs, ws = "Sheet1", anchor = paste("A", nr + 2, sep=""), input = lang_slopes, byrow = TRUE)
system("rm wiki_df.csv")
