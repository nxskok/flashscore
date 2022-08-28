library(tidyverse)
library(rvest)
library(RSelenium)
library(glue)

remDr <- remoteDriver(port = 4445L)
remDr$open(silent = TRUE)

remDr$navigate("http://www.flashscore.com")
remDr$getTitle()


my_url <- "https://www.flashscore.com/match/88v5tRlc/#/match-summary"
my_url <- "https://www.flashscore.com/match/hhOIjZMS/#/match-summary"
remDr$navigate(my_url)

my_html <- remDr$getPageSource()[[1]][1]
my_html %>% read_html() -> h
h

# make a function

goal_string <- function(h) {
  h %>% html_nodes("div") -> divs
  divs %>% html_attr("class") -> classes
  divs %>% html_text() -> texts
  
  # tibble(classes, texts) %>% View()
  
  i_want <- tribble(
    ~site_class, ~my_class,
    "smv__timeBox", "time",
    "smv__incidentHomeScore", "score",
    "smv__incidentAwayScore", "score"
  )
  
  tibble(classes, texts) %>% 
    filter(classes %in% i_want$site_class) %>% 
    left_join(i_want, by = c("classes"="site_class")) %>% 
    select(-classes) %>% 
    mutate(row = cumsum(my_class == "time")) %>% 
    pivot_wider(names_from = my_class, values_from = texts) -> d
  if (!("score" %in% names(d))) return("")
  d %>% drop_na(score) %>% 
    mutate(score = str_remove_all(score, " ")) %>% 
    mutate(goal = str_c(time, " ", score)) %>% 
    pull(goal) %>% 
    glue_collapse(sep = "; ")
}

goal_string(h)
