library(tidyverse)
library(tidytext)

# a1 <- c("a", "cup", "broke")
# a2 <- c("the", "cup", "broke")
# a3 <- c("a", "cup", "smashed")
# a4 <- c("the", "glass", "broke")
# a5 <- c("a", "glass", "broke")
# tiny_corpus <- as.data.frame(rbind(a1, a2, a3, a4, a5))
# row.names(tiny_corpus) <- 1:5
# names(tiny_corpus) <- c("first", "second", "third")

a1 <- c("a cup broke")
a2 <- c("the cup broke")
a3 <- c("a cup smashed")
a4 <- c("the glass broke")
a5 <- c("a glass broke")
tiny_corpus <- as.data.frame(rbind(a1, a2, a3, a4, a5))
names(tiny_corpus) <- c("text")
tiny_corpus$text <- as.character(tiny_corpus$text)
row.names(tiny_corpus) <- 1:5
tiny_corpus <- tiny_corpus %>%
  unnest_tokens(word, text, drop=F)

tiny_surprisals <- tiny_corpus %>% 
  group_by(word) %>% 
  count() %>% 
  ungroup() %>% 
  mutate(p = n / sum(n)) %>% 
  mutate(s = -log(p)) 

tiny_means <- tiny_corpus %>% 
  group_by(text) %>%
  mutate(word_order = 1:n()) %>%
  ungroup() %>%
  left_join(tiny_surprisals) %>% 
  group_by(word_order) %>%
  summarise(mean_s = mean(s)) 

tiny_means %>% 
  ggplot(aes(x = word_order, y = mean_s)) + 
    geom_point() + 
    geom_line() +
    xlab("Word order") + 
    ylab("Mean surprisal") + 
    ylim(0, 5)



tiny_bigrams_prep <- tiny_corpus %>% 
  group_by(text) %>%
  mutate(lag_word = lag(word)) %>%
  group_by(lag_word, word) %>%
  count() %>%
  filter(!is.na(lag_word)) %>%
  ungroup() %>%
  mutate(p = n/sum(n)) %>%
  left_join(tiny_surprisals, by = c("lag_word" = "word")) %>%
  mutate(cond_p = n.x / n.y) %>%
  select(lag_word, word, cond_p)

tiny_bigram_means <- tiny_corpus %>%
  group_by(text) %>%
  mutate(word_order = 1:n()) %>%
  mutate(lag_word = lag(word)) %>%
  left_join(tiny_surprisals) %>%
  left_join(tiny_bigrams_prep) %>%
  mutate(s = ifelse(is.na(lag_word), s, -log(cond_p))) %>%
  group_by(word_order) %>%
  summarise(mean_s = mean(s)) 


tiny_bigram_means %>%
  ggplot(aes(x = word_order, y = mean_s)) + 
  geom_point() + 
  geom_line() + 
  xlab("Word order") + 
  ylab("Mean surprisal") + 
  ylim(0, 5)
