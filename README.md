# FRED Economic Dashboard

A prototype of an interactive Shiny dashboard for visualizing Federal Reserve Economic Data (FRED) with an AI-powered chat assistant.

## Live App

🚀 **[View Dashboard](https://szabomilan.shinyapps.io/fred-dashboard/)** (pswd is my name or just look into @app.R)

## Features

- **Economic Indicators Visualization**: Real-time charts for key financial stress and market indicators
  - St. Louis Fed Financial Stress Index (STLFSI4)
  - National Financial Conditions Index (NFCI)
  - CBOE Volatility Index (VIX)
  - ICE BofA US High Yield Index (BAMLH0A0HYM2)
  - 10-Year Treasury Minus 2-Year Treasury Spread (T10Y2Y)
  - 3-Month Commercial Paper Minus Fed Funds Rate (CPFF)
  - Loan Loss Reserve to Total Loans (DRALACBS)

- **AI Chat Assistant**: Powered by Groq's LLM technology
  - Ask questions about economic indicators
  - Get trend analysis and statistical summaries
  - Interactive data exploration with natural language

- **Secure Access**: Password-protected dashboard

## Technologies

- **R Shiny**: Interactive web application framework
- **bslib**: Modern UI components
- **ggplot2**: Data visualization
- **ellmer & shinychat**: AI chat integration
- **Groq API**: Fast LLM inference

## Local Development

1. Clone the repository
2. Install dependencies with `renv::restore()`
3. Create a `config.R` file with your API keys:
   ```r
   Sys.setenv(
     GROQ_API_KEY = "your_groq_api_key_here"
   )
   ```
4. Run the app with `shiny::runApp()`

## Deployment

Deployed on shinyapps.io using `rsconnect` package.

## License

Private project

---

Built with [R Shiny](https://shiny.posit.co/)
