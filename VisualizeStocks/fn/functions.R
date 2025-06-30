
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
  plot <- chartSeries(df, name=sym, subset = time, theme=chartTheme("white"))
  # chartSeries contains many objs - @call for chart
  return(plot@call)
}

add_constructs <- function(data){
  data %>% 
    group_by(stock) %>% 
    mutate(
      # --- Volume Calculations --- 
      diff_vol  = Volume- lag(Volume),
      dod_vol   = diff_vol/lag(diff_vol),
      
      ema_vol = TTR::EMA(Volume, n = 7),
      
      # --- Price Averages --- EMA 7
      ema_close = TTR::EMA(Close, n = 7),
      pct_emavg = (ema_close/lag(ema_close, 7) - 1) * 100,
      
      # --- Price Changes ---
      # Daily 
      diff_prev  = Close- lag(Close) ,
      DoD = (diff_prev/abs(lag(Close))),
      
      # Weekly
      diff_week     = Close- lag(Close, 5) ,
      WoW  = (diff_week/abs(lag(Close, 5))),
      
      # Monthly
      diff_month     = Close- lag(Close, 30) ,
      MoM = (diff_month/abs(lag(Close, 30))),
      
      # Yearly
      diff_year      = Close- lag(Close, 252) ,
      YoY = (diff_month/abs(lag(Close, 252)))
      
    )  %>% 
    ungroup() %>% 
    mutate(group = rleid(DoD > 0 & !is.na(DoD))) %>% 
    group_by(group) %>% 
    mutate(consecutive = ifelse(is.na(DoD), NA, row_number())) %>% 
    ungroup() %>% 
    select(-group) %>% 
    mutate(trend = ifelse(DoD > 0, paste0(consecutive, "+ increase"), ifelse(DoD < 0, paste0(consecutive, "- decrease"), "")))
}


plotly_stock <- function(data, sym){
  data <- data[[sym]]
  data %>% 
    plot_ly(x = ~date, type="candlestick",
                 open = ~Open, close = ~Close,
                 high = ~High, low = ~Low) %>% 
    layout(title = paste0(sym, "Chart"))
  
}

plot_sd <- function(data, sym){
  data <- data[[sym]] %>% 
    filter(date >= today()-252)
    
  ggplot(data, aes(x = date)) +
    geom_line(aes(y = Close), color = "black", alpha = 0.6) +
    geom_line(aes(y = ema), color = "blue", size = 1.2) +
    geom_ribbon(aes(ymin = lower, ymax = upper), fill = "lightblue", alpha = 0.2) +
    geom_point(aes(y = Close, color = signal_color), size = 2) +
    scale_color_identity() +
    labs(
      title = "EMA Standard Deviation Indicator",
      subtitle = paste("EMA Length:", ema_length, " | SD Length:", sd_length, " | Multiplier:", multiplier),
      y = "Price",
      x = "Date"
    ) +
    theme_minimal()
  
}

get_inflections <- function(sym, df){
  data <- df[[sym]]
  updn <- c(0, diff(sign(data[["pct_emavg"]])))
  ix <- which(updn != 0)
  # date of inflection points
  data$date[ix]
}


backtest_strategy <- function(data, ema_length = 14, sd_length = 35, multiplier = 1, initial_capital = 10000) {
  tryCatch({
    # Calculate indicators
    data <- data %>%
      mutate(
        ema = EMA(Close, n = ema_length),
        sd = runSD(Close, n = sd_length),
        upper = ema + multiplier * sd,
        lower = ema - multiplier * sd,
        signal = case_when(
          Close > upper ~ "Sell",
          Close < lower ~ "Buy",
          TRUE          ~ "Neutral"
        )
      ) %>%
      # Remove rows with missing values
      #na.omit() %>%
      # Lag signals to avoid look-ahead bias
      mutate(signal_lag = lag(signal))
    
    # Initialize backtest columns
    data$position <- 0
    data$cash <- initial_capital
    data$shares <- 0
    data$portfolio_value <- initial_capital
    data$execute <- 0
    data$saved <- 0
    
    # Backtesting loop
    for(i in 2:nrow(data)) {
      # Carry forward previous values
      data$cash[i] <- data$cash[i-1]
      data$shares[i] <- data$shares[i-1]
      data$position[i] <- data$position[i-1]
      data$saved[i] <- data$saved[i-1]
      
      # Execute trades at open
      if(!is.na(data$signal_lag[i])) {
        # Buy signal execution
        if(data$signal_lag[i] == "Buy" && data$position[i] == 0 && data$Open[i] <= data$lower[i] ) {
          data$shares[i] <- data$cash[i] / data$Open[i]
          data$cash[i] <- 0
          data$position[i] <- 1
          data$execute[i] <- 1
          data$saved[i] <- i
        }
        # Sell signal execution
        if(data$signal_lag[i] == "Sell" && data$position[i] == 1 && data$Open[i] >= data$upper[i]) {
          
          # Calculate what portfolio value would be if we sell now 
          potential_cash <- data$shares[i] * data$Open[i]
          potential_portfolio_value <- potential_cash
          
          # Only sell if portfolio value will not decrease from previous buy- Capital preservation
          if(potential_portfolio_value >= data$portfolio_value[data$saved[i-1]]) {
            data$cash[i] <- potential_cash
            data$shares[i] <- 0
            data$position[i] <- 0
            data$execute[i] <- 1
          }
          # Otherwise, skip the sell (hold position)
        }
      }
      
      # Update portfolio value (cash + shares value at close)
      data$portfolio_value[i] <- data$cash[i] + (data$shares[i] * data$Close[i])
    }
    
    # Calculate returns
    data <- data %>%
      mutate(
        strategy_return = portfolio_value / lag(portfolio_value) - 1,
        buy_hold_return = Close / lag(Close) - 1
      )
    
    return(data)}, error = function(msg){
      return(NA)
    })
}

# Performance metrics
performance_metrics <- function(returns) {
  metrics <- list(
    Total_Return = Return.cumulative(returns, geometric = TRUE),
    Annualized_Return = Return.annualized(returns, scale = 252)
  )
  return(as.data.frame(metrics))
}

eval_strategy <- function(results){
  tryCatch({
    initial_capital <- 10000
    # Generate reports
    strategy_perf <- performance_metrics(as.vector(na.omit(results$strategy_return)))
    bh_perf <- performance_metrics(as.vector(na.omit(results$buy_hold_return)))
    # Calculate number of shares bought at the first available open price
    shares_bought <- initial_capital / results$Open[1]
    
    # Final capital is value of those shares at the last close price
    final_bh_capital <- shares_bought * tail(results$Close, 1)
    final_capital <- tail(results$portfolio_value, 1)
    capital_col <- data.frame(
      "Final_Capital" = c(final_capital, final_bh_capital),
      "Number_of_Trades" = c(sum(results$execute), 1)
      )
    
    # Print performance comparison
    knitr::kable(
      cbind(rbind(Strategy = strategy_perf, Buy_Hold = bh_perf),  capital_col),
      caption = "Performance Comparison"
    )}, error = function(msg){
      return(NA)
    })
    
}

plot_strategy <- function(data){
  plt <- tryCatch({
    # Visualization: Trading Signals
    data %>% 
      #na.omit() %>%
      mutate(execute = as.character(ifelse(execute == 0, NA, execute))) %>% 
      # Remove rows with missing values
      ggplot(aes(x = date)) +
      geom_line(aes(y = Close), size = 1) +
      geom_line(aes(y = ema), color = "blue", linetype = "dashed") +
      geom_ribbon(aes(ymin = lower, ymax = upper), fill = "gray", alpha = 0.3) +
      geom_point(aes(y = Close, color = signal_lag), size = 2) +
      scale_color_manual(values = c("Buy" = "green", "Sell" = "red", "Neutral" = "gray")) +
      geom_point(aes(y = Close, shape = execute), size = 4) +
      scale_shape_manual(values=c(4))+
      labs(title = "Price with Trading Signals", y = "Price") +
      theme_minimal()}, error = function(msg){
        return(NA)
    })
  return(plt)
}
