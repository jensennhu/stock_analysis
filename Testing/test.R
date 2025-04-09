library(quantmod)
library(dplyr)
library(purrr)
library(here)
library(TTR)
library(ggplot2)

source(file.path(here(), "fn", "functions.R"))

symbols <- c("COST",
             "AAPL",
             "GOOGL",
             "AMZN",
             "JPM",
             "MSFT",
             "NVDA",
             "NET",
             "BYDDY",
             "BABA",
             "VYM",
             "V",
             "VDE",
             "VOO",
             "QQQM",
             "QQQ",
             "O",
             "TSM",
             "GELYF",
             "NBIS",
             "BA",
             "EL",
             "TCMD")

# gather list of stocks 
stock_df <- map(symbols, ~getSymbols(.x, src='yahoo', auto.assign=FALSE))
names(stock_df) <- symbols

# stack data
main_df <- map_df(
  symbols,
  ~clean_data(.x, data = stock_df)
) 

constructs <-  main_df %>% 
  group_by(stock) %>% 
  mutate(
    # SMA
    sma_50  = TTR::SMA(Close, n = 50),
    sma_100 = TTR::SMA(Close, n = 100),
    
    # EMA
    ema_63  = TTR::EMA(Close, n = 63),
    
    
    pct_mavg = (sma_50/lag(sma_50, n = 50) - 1) * 100,
    pct_emavg = (ema_63/lag(ema_63, n = 63) - 1) * 100
    
  ) %>% ungroup()

get_inflections <- function(sym, df){
  data <- df[[sym]]
  updn <- c(0, diff(sign(data[["pct_emavg"]])))
  ix <- which(updn != 0)
  # date of inflection points
  data$date[ix]
  return(ix)
}
split_df <- split(constructs, constructs$stock)
list_infl <- map(symbols, ~get_inflections(.x, df = split_df))
names(list_infl) <- symbols

# plot_stock("VYM")
# for (i in list_infl[["VYM"]]){
#   addLines(v = i)
# }
# plot all symbols
walk(symbols, ~plot_stock(.x, data = stock_data, time = "last 6 months"))

