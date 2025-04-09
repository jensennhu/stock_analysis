
clean_data <- function(sym, data){
  
  # convert xts obj to df
  df <- data.frame(
    date = index(data[[sym]]), 
    data[[sym]]
  ) %>% 
    mutate(stock = sym)
  
  # removes all string values before period in var names 
  names(df) <- sub(".*\\.", "", names(df))
  return(df)
}

plot_stock <- function(data, sym, time = ""){
  df <- data[[sym]]
  chartSeries(df, name=sym, subset = time, theme=chartTheme("white"))
}

get_inflections <- function(sym, df){
  data <- df[[sym]]
  updn <- c(0, diff(sign(data[["pct_emavg"]])))
  ix <- which(updn != 0)
  # date of inflection points
  data$date[ix]
}
