library(tidyverse)
library(tidytext)
library(directlabels)
# library(googlesheets)

extract_wiki_tokens <- function(min_length, max_length, utterances) {

  tokens <- utterances %>%
    mutate(gloss = str_trim(gloss)) %>%
    mutate(length = str_count(gloss, pattern = "[ +]+") + 1) %>%
    filter(length >= min_length) %>%
    filter(length <= max_length) %>%
    mutate(utterance_id = 1:n()) %>%
    unnest_tokens(word, gloss, token = stringr::str_split, pattern = "[ +]+") %>%
    group_by(utterance_id) %>%
    mutate(word_order = 1:n()) %>%
    group_by(length, word_order, word) %>%
    summarise(n = n()) %>%
    ungroup() %>%
    mutate(word = as.numeric(as.factor(word)))

  sups <- tokens %>%
    count(word) %>% 
    mutate(p = n/sum(n)) %>%
    mutate(s = -log(p)) %>%
    select(word, s)

  tokens %>%
    left_join(sups)
}

get_quantiles <- function(df, num_sections) {
  quantile(df$word_order, probs = seq(0, 1, 1/num_sections)) %>%
    round() %>%
    as_data_frame() %>%
    rename(word_order = value)
}

relative_slopes <- function(df_tokens, pos_list) {

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

    df_tokens %>%
      inner_join(selected_pos, by = c("length", "word_order")) %>%
      group_by(length, word_order) %>%
      summarise(s = mean(s)) %>%
      lm(s ~ length + I(length^2) + word_order, data  = .) %>%
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


NUM_SECTIONS = 5

NUM_SENTENCES <- 500000

LANGUAGE <- commandArgs(trailingOnly=TRUE)[1]

system(paste("python3 get_wiki_df.py", LANGUAGE, sep = " "))

# for_gs <- gs_title("wiki_surprisal_relative")

df <- read_csv("wiki_df.csv") 

if (nrow(df) > NUM_SENTENCES) {
  df <- df %>% 
    sample_n(NUM_SENTENCES)
}

df_tokens <- extract_wiki_tokens(6, 10, df)

pos_list <- df_tokens %>%
  group_by(length) %>%
  distinct(word_order) %>%
  split(.$length) %>%
  map(~get_quantiles(.x, NUM_SECTIONS)) %>%
  bind_rows(.id = "length") %>%
  mutate(length = as.numeric(length))

slopes <- relative_slopes(df_tokens, pos_list)

lang_slopes <- c(LANGUAGE, slopes$estimate) %>%
  t() %>%
  data.frame()

all_data <- read.csv(file = "relative_unigrams.csv") %>%
  select(-X)
names(lang_slopes) <- names(all_data)
all_data <- all_data %>%
  rbind(lang_slopes)
write.csv(all_data, file = "relative_unigrams.csv")

# wkpd <- gs_read(for_gs)
# nr <- nrow(wkpd)
#
# lang_slopes <- c(LANGUAGE, slopes$estimate)
# gs_edit_cells(for_gs, ws = "Sheet1", anchor = paste("A", nr + 2, sep=""), input = lang_slopes, byrow = TRUE)
system("rm wiki_df.csv")

# slopes %>%
#   mutate(lower = estimate - 1.96 * std.error,
#          upper = estimate + 1.96 * std.error) %>%
#   ggplot(aes(x = cut, y = estimate, group = 1)) + 
#   geom_pointrange(aes(ymin = lower, ymax = upper)) + 
#   geom_line()
