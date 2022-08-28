## ---------------------------------------------------------------------------------
library(RSelenium)
library(tidyverse)
library(rvest)


## ---------------------------------------------------------------------------------
# my_url <- "https://www.flashscore.com/rugby-league/"
# my_url <- "https://www.flashscore.com/rugby-union/"
my_url <- "https://www.flashscore.com/" # soccer


## cd ~/Downloads

## java -jar selenium-server-standalone-3.9.1.jar &
# docker run -d -p 4445:4444 selenium/standalone-firefox


print("open remote driver")
## ---------------------------------------------------------------------------------
# remDr <- remoteDriver(
#   remoteServerAddr = "localhost",
#   port = 4444L,
#   browserName = "firefox"
# )

print("open driver and client")

## ---------------------------------------------------------------------------------
remDr <- remoteDriver(port = 4445L)
remDr$open(silent = TRUE)

print("navigate to page")

## ---------------------------------------------------------------------------------
remDr$navigate(my_url)
print(remDr$getTitle())
Sys.sleep(1)
tryCatch(
  expr = {
    webElem <- remDr$findElement(using = "css", value = "#onetrust-accept-btn-handler")
    webElem$clickElement()
    print(remDr$getCurrentUrl())
    message("done successfully")
  },
  error = function(e) {
    message("Caught an error")
    print(e)
  },
  finally = {
    message("All done")
  }
)

print("process html")

## ---------------------------------------------------------------------------------
my_html <- remDr$getPageSource()[[1]][1]
my_html %>% read_html() -> h
to_keep <- tribble(
  ~class, ~class_me,
  "event__stage", "stage",
  "event__time", "ko",
  "event__participant event__participant--home", "home_team",
  "event__participant event__participant--home fontExtraBold", "home_team",
  "event__participant event__participant--away", "away_team",
  "event__participant event__participant--away fontExtraBold", "away_team",
  "event__score event__score--home", "home_score",
  "event__score event__score--away", "away_score"
  )
h %>% html_elements("#live-table > section > div > div") %>% 
  html_elements("div") -> divs
divs %>% html_attr("class") -> classes
divs %>% html_text() -> texts
divs %>% html_attr("id") -> ids
length(ids)
tibble(class = classes, id = ids, text = texts) %>% 
  fill(id) %>% 
  mutate(league = ifelse(class == "event__titleBox", text, NA)) %>% 
  fill(league) %>% 
  mutate(keep_row = ifelse(class %in% to_keep$class, "yes", "no")) %>% 
  filter(keep_row == "yes") %>% 
  left_join(to_keep) %>% 
  select(league, id, class_me, text) %>% 
  pivot_wider(names_from = class_me, values_from = text) -> d
d_names <- names(d)
st <- ("stage" %in% d_names)
k <- ("ko" %in% d_names)
if (st & k) {
    d$status <- with(d, coalesce(stage, ko))
} else if (st) {
    d$status <- d$stage
} else if (k) {
    d$status <- d$ko
} else {
    d$status <- ""
}
d %>% select(league, id, status, home_team, away_team, home_score, away_score) %>% 
  replace_na(list(home_score = "-", away_score = "-"))  -> dd

# View(dd)
## ---------------------------------------------------------------------------------
nrow(dd)
f_name <- str_c(my_url, "_", Sys.time(),".rds")
f_name <- janitor::make_clean_names(f_name)
write_rds(dd, f_name)
remDr$close()
# rD$server$stop()

