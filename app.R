library(shiny)
library(quantmod)
library(TTR)
library(caret)
library(randomForest)
library(ggplot2)
library(dplyr)
library(plotly)


# ---------------------------
# DATA + MODEL FUNCTION
# ---------------------------
train_predict_model <- function(stock_symbol) {
  
  # Download stock data
  stock_symbol <- trimws(stock_symbol)
  getSymbols(stock_symbol, src = "yahoo", auto.assign = FALSE) -> stock_data
  
  df <- data.frame(
    Date = index(stock_data),
    coredata(stock_data)
  )
  
  colnames(df) <- c("Date", "Open", "High", "Low", "Close", "Volume", "Adjusted")
  
  # Technical Indicators
  df$SMA_10 <- SMA(df$Close, n = 10)
  df$SMA_20 <- SMA(df$Close, n = 20)
  df$EMA_10 <- EMA(df$Close, n = 10)
  
  # Remove NA values
  df <- na.omit(df)
  # Buy / Sell Signals
  df$Signal <- ifelse(df$Close > df$SMA_20, "BUY", "SELL")
  
  df$Buy  <- ifelse(df$Signal == "BUY", df$Close, NA)
  df$Sell <- ifelse(df$Signal == "SELL", df$Close, NA)
  
  
  # Train/Test Split
  set.seed(123)
  split <- createDataPartition(df$Close, p = 0.8, list = FALSE)
  
  train_data <- df[split, ]
  test_data  <- df[-split, ]
  
  # Random Forest Model
  model <- randomForest(
    Close ~ Open + High + Low + Volume + SMA_10 + SMA_20 + EMA_10,
    data = train_data,
    ntree = 200
  )
  
  # Predictions
  test_data$Predicted <- predict(model, test_data)
  test_data$Signal <- ifelse(test_data$Close > test_data$SMA_20, "BUY", "SELL")
  test_data$Buy  <- ifelse(test_data$Signal == "BUY", test_data$Close, NA)
  test_data$Sell <- ifelse(test_data$Signal == "SELL", test_data$Close, NA)
  
  return(list(
    model = model,
    full_data = df, 
    data = test_data
  ))
}
predict_next_week <- function(model, last_row) {
  
  future <- data.frame()
  current <- last_row
  
  for (i in 1:5) {  # 5 trading days
    
    pred_price <- predict(model, current)
    
    new_row <- current
    new_row$Close <- pred_price
    new_row$SMA_10 <- pred_price
    new_row$SMA_20 <- pred_price
    new_row$EMA_10 <- pred_price
    
    future <- rbind(future, data.frame(
      Day = paste("Day", i),
      Predicted_Close = as.numeric(pred_price),
      Signal = ifelse(pred_price > current$SMA_20, "BUY", "SELL")
    ))
    
    current$Close <- pred_price
  }
  
  return(future)
}
final_recommendation <- function(future_df) {
  
  buy_count <- sum(future_df$Signal == "BUY")
  
  if (buy_count >= 4) {
    return("STRONG BUY")
  } else if (buy_count >= 2) {
    return("HOLD")
  } else {
    return("SELL")
  }
}
backtest_strategy <- function(df) {
  
  position <- 0
  buy_price <- 0
  profit <- 0
  
  for (i in 1:nrow(df)) {
    
    if (df$Signal[i] == "BUY" && position == 0) {
      buy_price <- df$Close[i]
      position <- 1
    }
    
    if (df$Signal[i] == "SELL" && position == 1) {
      profit <- profit + (df$Close[i] - buy_price)
      position <- 0
    }
  }
  
  return(round(profit, 2))
}
backtest_with_metrics <- function(df, cost_rate = 0.001) {
  
  position <- 0
  buy_price <- 0
  profits <- c()
  equity <- 0
  equity_curve <- c()
  total_cost <- 0
  
  for (i in 1:nrow(df)) {
    
    if (df$Signal[i] == "BUY" && position == 0) {
      buy_price <- df$Close[i]
      total_cost <- total_cost + (buy_price * cost_rate)
      position <- 1
    }
    
    if (df$Signal[i] == "SELL" && position == 1) {
      sell_price <- df$Close[i]
      trade_profit <- sell_price - buy_price
      total_cost <- total_cost + (sell_price * cost_rate)
      
      net_trade <- trade_profit - (buy_price + sell_price) * cost_rate
      profits <- c(profits, net_trade)
      
      equity <- equity + net_trade
      equity_curve <- c(equity_curve, equity)
      
      position <- 0
    }
  }
  
  # Win Rate
  wins <- sum(profits > 0)
  total_trades <- length(profits)
  win_rate <- ifelse(total_trades > 0, 
                     round((wins / total_trades) * 100, 2), 0)
  
  # Max Drawdown
  peak <- cummax(equity_curve)
  drawdown <- equity_curve - peak
  max_drawdown <- ifelse(length(drawdown) > 0,
                         round(min(drawdown), 2), 0)
  
  return(list(
    net_profit = round(sum(profits), 2),
    win_rate = win_rate,
    max_drawdown = max_drawdown,
    trades = total_trades,
    total_cost = round(total_cost, 2)
  ))
}



# ---------------------------
# SHINY UI
# ---------------------------
ui <- fluidPage(
  
  titlePanel("📈 Stock Price Prediction App (R + ML)"),
  
  sidebarLayout(
    
    sidebarPanel(
      textInput("stock", "Enter Stock Symbol", value = "AAPL"),
      actionButton("predict", "Predict Stock Price"),
      helpText("Example: AAPL, MSFT, TSLA, INFY.NS")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Candlestick Chart", plotlyOutput("candlePlot")),
        tabPanel("Prediction Plot", plotOutput("pricePlot")),
        tabPanel("Data Table", tableOutput("dataTable")),
        tabPanel("📅 Next Week Forecast", tableOutput("futureTable"))
      ),
#      h3("📌 Final Recommendation"),
#      textOutput("finalRec")
       uiOutput("finalRecUI"),
       h4(textOutput("profitText")),
       h4(textOutput("winRateText")),
       h4(textOutput("drawdownText"))


    )
  )
)

# ---------------------------
# SHINY SERVER
# ---------------------------
server <- function(input, output) {
  
  stock_result <- eventReactive(input$predict, {
    train_predict_model(input$stock)
  })
  metrics_result <- reactive({
    req(stock_result())
    backtest_with_metrics(stock_result()$full_data)
  })
  
  
  output$candlePlot <- renderPlotly({
    
    df <- stock_result()$full_data
    
    # Candlestick trace
    candle <- plot_ly(
      data = df,
      x = ~Date,
      type = "candlestick",
      open = ~Open,
      close = ~Close,
      high = ~High,
      low = ~Low,
      name = "Price"
    )
    
    # BUY markers
    buy_markers <- plot_ly(
      data = df,
      x = ~Date,
      y = ~Buy,
      type = "scatter",
      mode = "markers",
      marker = list(color = "green", size = 8),
      name = "BUY"
    )
    
    # SELL markers
    sell_markers <- plot_ly(
      data = df,
      x = ~Date,
      y = ~Sell,
      type = "scatter",
      mode = "markers",
      marker = list(color = "red", size = 8),
      name = "SELL"
    )
    
    # Combine all traces
    candle %>%
      add_trace(buy_markers) %>%
      add_trace(sell_markers) %>%
      layout(
        title = paste("Candlestick Chart with Buy/Sell Signals:", input$stock),
        xaxis = list(title = "Date"),
        yaxis = list(title = "Price")
      )
  })
  
 
  
  output$pricePlot <- renderPlot({
    
    result <- stock_result()
    df <- result$data
    
    ggplot(df, aes(Date)) +
      geom_line(aes(y = Close), color = "blue", size = 1) +
      geom_line(aes(y = Predicted), color = "red", linetype = "dashed") +
      
      # BUY points
      geom_point(aes(y = Buy), color = "green", size = 3, na.rm = TRUE) +
      
      # SELL points
      geom_point(aes(y = Sell), color = "red", size = 3, na.rm = TRUE) +
      
      labs(
        title = paste("Actual vs Predicted Price with Buy/Sell Signals:", input$stock),
        y = "Stock Price",
        x = "Date"
      ) +
      theme_minimal()
  })
  
  output$dataTable <- renderTable({
    head(stock_result()$data, 10)
  })
  future_result <- reactive({
    
    result <- stock_result()
    
    model <- result$model
    last_row <- tail(result$full_data, 1)
    
    predict_next_week(model, last_row)
  })
  output$futureTable <- renderTable({
    future_result()
  })
  
  recommendation <- reactive({
    
    future_df <- future_result()
    final_recommendation(future_df)
  })
  output$finalRecUI <- renderUI({
    
    rec <- recommendation()
    
    color <- if (rec == "STRONG BUY") {
      "green"
    } else if (rec == "HOLD") {
      "orange"
    } else {
      "red"
    }
    
    tags$h3(
      paste("📌 Final Recommendation:", rec),
      style = paste("color:", color, "; font-weight:bold; margin-top:15px;")
    )
  })
  backtest_profit <- reactive({
    backtest_strategy(stock_result()$full_data)
  })
  output$profitText <- renderText({
    paste("📊 Backtesting Profit (Historical):", backtest_profit())
  })
  output$winRateText <- renderText({
    paste("✅ Win Rate:", metrics_result()$win_rate, "%")
  })
  
  output$drawdownText <- renderText({
    paste("📉 Max Drawdown:", metrics_result()$max_drawdown)
  })
  
  
#  output$finalRec <- renderText({
#  
#  rec <- recommendation()
#  
#  paste("Based on next week's prediction:", rec)
#})

}

# ---------------------------
# RUN APP
# ---------------------------
shinyApp(ui = ui, server = server)
