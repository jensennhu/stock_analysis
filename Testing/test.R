library(quantmod)
library(dplyr)
library(purrr)


apple_df <- getSymbols('AAPL', src='yahoo', auto.assign=FALSE)
chartSeries(apple_df, name="AAPL", subset="last 6 months", theme=chartTheme("white"))