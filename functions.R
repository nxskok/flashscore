open_remdr <- function() {
  remDr <- remoteDriver(port = 4445L)
  remDr$open(silent = TRUE)
  my_url <- "https://livescores.com"
  remDr$navigate(my_url)
  title <- remDr$getTitle()
  print(title)
  if (length(title) == 0) stop("no title") 
  remDr$addCookie(name = "ls.tz", value = "-5") # set a cookie to get timezone
  remDr$navigate(my_url)
  remDr
}

get_html <- function(remdr) {
  my_html <- remdr$getPageSource()[[1]][1]
  # fname <- str_c("h", Sys.time(), ".rds")
  # fname %>% str_replace_all(" ", "_") -> fname
  # write_rds(my_html, fname)
  my_html
}

make_game_df <- function(htmlcode) {
  htmlcode %>% read_html -> h
  # return(h)
  h %>% html_nodes("span.Pg.Lg") %>% html_text() -> statuses
  h %>% html_nodes("span.ch") %>% html_text() -> homes
  h %>% html_nodes("span.dh") %>% html_text() -> aways
  h %>% html_nodes("span.Zg") %>% html_text() -> scores
  tibble(status = statuses, home = homes, score = scores, away = aways) %>% 
    mutate(key = str_c(home, ":", away))
}

