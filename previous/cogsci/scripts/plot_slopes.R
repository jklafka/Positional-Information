library(tidyverse)
library(here)

data <- read_csv(here("../wiki_entropy/Wikipedia_relative5.csv")) %>%
  gather(position, slope, Slope1:Slope5) %>%
  mutate(position = gsub("[^0-9]","", position),
         position = as.numeric(position))

languages <- distinct(data, Language)

sub_data <- data %>%
  filter(Language %in% (slice(languages, 1:10) %>% pull(Language))) %>%
  spread(position, slope) %>%
  mutate(value0 = 0,
         value1 = value0 + `1`,
         value2 = value1 + `2`,
         value3 = value2 + `3`, 
         value4 = value3 + `4`,
         value5 = value4 + `5`) %>%
  select(-`1`:-`5`) %>%
  gather(position, value, value0:value5) %>%
  mutate(position = gsub("[^0-9]","", position),
         position = as.numeric(position)) %>%
  group_by(Language) %>%
  mutate(mid_value = value[3]) %>%
  mutate(centered_value = value - mid_value)


ggplot(sub_data,
       aes(x = position, y = centered_value, color = Language)) + 
  geom_line() + 
  theme_classic()
