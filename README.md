# 📈 Project Title

**Stock Price Prediction and Trading Decision Support System Using Machine Learning in R**

---

# 📝 Project Description

Stock market prediction plays a crucial role in modern financial decision-making, but it is inherently complex due to market volatility and uncertainty. This project aims to design and develop an **end-to-end stock price prediction and trading decision support system** using **R programming**, **machine learning**, and **technical analysis**, implemented as an **interactive Shiny web application**.

The system automatically retrieves **real-time historical stock price data** from Yahoo Finance using the `quantmod` package. It applies multiple **technical indicators** such as **Simple Moving Average (SMA)** and **Exponential Moving Average (EMA)** to analyze market trends. Based on these indicators, **Buy and Sell signals** are generated to assist trading decisions.

A **Random Forest regression model** is trained on historical stock data to predict future stock prices. The trained model is used to generate **next-week price forecasts**, providing short-term market insight. The application visually represents stock movement through **interactive candlestick charts**, overlaid with **Buy/Sell markers**, improving interpretability for users.

To ensure realism, the project incorporates a **backtesting framework with transaction cost modeling**, simulating actual trading conditions. Performance metrics such as **net profit, win rate, number of trades, and maximum drawdown** are computed to evaluate both profitability and risk. Based on the predicted future signals, the system provides a **Final Recommendation** classified as **Strong Buy, Hold, or Sell**.

The entire solution is deployed as a **user-friendly Shiny GUI**, allowing users to input any stock symbol and instantly view predictions, analytics, and trading insights. This project demonstrates the practical application of **machine learning, data visualization, and financial analytics** using R, making it suitable for academic evaluation and real-world learning.

---

# 🎯 Key Objectives

* To predict stock prices using **machine learning techniques**
* To generate **Buy/Sell trading signals** using technical indicators
* To visualize stock behavior using **interactive candlestick charts**
* To perform **backtesting with transaction cost modeling**
* To evaluate strategy performance using **win rate and max drawdown**
* To provide a **final trading recommendation** for decision support

---

# 🧠 Technologies & Tools Used

* **Programming Language:** R
* **IDE:** RStudio
* **Web Framework:** Shiny
* **Machine Learning:** Random Forest
* **Data Source:** Yahoo Finance (quantmod)
* **Visualization:** ggplot2, plotly
* **Technical Indicators:** TTR package

---

# 📊 Output Features

* Interactive candlestick chart with Buy/Sell markers
* Actual vs Predicted price comparison
* Next-week stock price forecast
* Final trading recommendation (Strong Buy / Hold / Sell)
* Backtesting profit with transaction cost
* Win rate and maximum drawdown analysis

---

# 🎓 Academic Value

This project bridges the gap between **theoretical machine learning concepts** and **practical financial applications**. It demonstrates how data-driven models can support investment decisions while accounting for real-world constraints such as transaction costs and risk exposure.


