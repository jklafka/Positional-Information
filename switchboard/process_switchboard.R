library(tidyverse)
library(stringr)
library(feather)

files <- list.files("switchboard", "*.txt", full.names = T)



txt <- map(files, read_lines) %>%
  unlist() %>%
  as_tibble() %>%
  mutate(value = str_trim(value)) %>%
  filter(value != "")

write_feather(txt, "switchboard/switchboard.feather")
