library(shiny)
library(shinychat)
library(bslib)
library(ellmer)
library(ggplot2)
library(tidyr)

# Load environment variables
if (file.exists("config.R")) {
  source("config.R")
}

# Load data
load("fred_data.Rdata")

ui <- page_fillable(
  # Custom CSS for floating chat button, chat window, and login
  tags$head(
    tags$style(HTML("
      .login-container {
        display: flex;
        justify-content: center;
        align-items: center;
        min-height: 100vh;
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      }

      .login-box {
        background: white;
        padding: 40px;
        border-radius: 12px;
        box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        width: 100%;
        max-width: 400px;
      }

      .login-box h2 {
        text-align: center;
        margin-bottom: 30px;
        color: #333;
      }

      .login-error {
        color: #dc3545;
        text-align: center;
        margin-top: 10px;
        font-size: 14px;
      }

      .chat-fab {
        position: fixed;
        bottom: 20px;
        right: 20px;
        width: 60px;
        height: 60px;
        border-radius: 50%;
        background-color: #007bff;
        color: white;
        border: none;
        box-shadow: 0 4px 8px rgba(0,0,0,0.3);
        cursor: pointer;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 24px;
        z-index: 1000;
        transition: transform 0.2s;
      }

      .chat-fab:hover {
        transform: scale(1.1);
        background-color: #0056b3;
      }

      .chat-window {
        position: fixed;
        bottom: 100px;
        right: 20px;
        width: 400px;
        height: 500px;
        background: white;
        border-radius: 12px;
        box-shadow: 0 8px 16px rgba(0,0,0,0.3);
        z-index: 999;
        display: none;
        flex-direction: column;
      }

      .chat-window.show {
        display: flex;
      }

      .chat-header {
        background-color: #007bff;
        color: white;
        padding: 15px;
        border-radius: 12px 12px 0 0;
        display: flex;
        justify-content: space-between;
        align-items: center;
      }

      .chat-close {
        background: none;
        border: none;
        color: white;
        font-size: 20px;
        cursor: pointer;
        padding: 0;
        width: 30px;
        height: 30px;
      }

      .chat-body {
        flex: 1;
        overflow: hidden;
        padding: 10px;
      }

      /* Make the chat UI fill the chat window */
      .chat-body > div {
        height: 100%;
      }
    "))
  ),

  # Dynamic UI - either login or dashboard
  uiOutput("main_content")
)

server <- function(input, output, session) {
  # Reactive value to track authentication
  authenticated <- reactiveVal(FALSE)
  login_error <- reactiveVal(FALSE)

  # Render login or dashboard based on authentication
  output$main_content <- renderUI({
    if (!authenticated()) {
      # Login UI
      tags$div(
        class = "login-container",
        tags$div(
          class = "login-box",
          h2("FRED Dashboard Login"),
          passwordInput("password", "Enter Password:", placeholder = "Password"),
          actionButton("login_btn", "Login", class = "btn btn-primary btn-block", style = "width: 100%;"),
          if (login_error()) {
            tags$div(class = "login-error", "Incorrect password. Please try again.")
          }
        )
      )
    } else {
      # Dashboard UI
      tagList(
        layout_columns(
          col_widths = c(12, 6, 6, 6, 6, 6, 6, 6),
          card(
            card_header("FRED Economic Data Dashboard"),
            card_body(
              p("This dashboard displays Federal Reserve Economic Data (FRED) time series."),
              p("Click the chat icon in the bottom right to ask questions about the data!")
            )
          ),
          # Monthly series plots
          card(
            card_header("STLFSI4"),
            plotOutput("plot_stlfsi4", height = "300px")
          ),
          card(
            card_header("NFCI"),
            plotOutput("plot_nfci", height = "300px")
          ),
          card(
            card_header("VIXCLS"),
            plotOutput("plot_vixcls", height = "300px")
          ),
          card(
            card_header("BAMLH0A0HYM2"),
            plotOutput("plot_bamlh0a0hym2", height = "300px")
          ),
          card(
            card_header("T10Y2Y"),
            plotOutput("plot_t10y2y", height = "300px")
          ),
          card(
            card_header("CPFF"),
            plotOutput("plot_cpff", height = "300px")
          ),
          # Quarterly series plot
          card(
            card_header("DRALACBS (Quarterly)"),
            plotOutput("plot_dralacbs", height = "300px")
          )
        ),
        # Floating chat button
        tags$button(
          class = "chat-fab",
          id = "chat_toggle",
          onclick = "toggleChat()",
          icon("comments")
        ),
        # Chat window (hidden by default)
        tags$div(
          class = "chat-window",
          id = "chat_window",
          tags$div(
            class = "chat-header",
            tags$span("Chat Assistant"),
            tags$button(
              class = "chat-close",
              onclick = "toggleChat()",
              "×"
            )
          ),
          tags$div(
            class = "chat-body",
            chat_ui(
              id = "chat",
              greeting = "**Hello! I'm your AI assistant.** How can I help you analyze the FRED economic data?

Here are some questions to get you started:

* <span class=\"suggestion submit\">What's the recent trend in NFCI?</span>
* <span class=\"suggestion submit\">Summarize the VIX over the last 3 years</span>
* <span class=\"suggestion submit\">Has the yield curve been inverted recently?</span>
* <span class=\"suggestion submit\">What does STLFSI4 measure?</span>
* <span class=\"suggestion submit\">Explain the high yield spread indicator</span>",
              height = "100%",
              show_history = FALSE
            )
          )
        ),
        # JavaScript for toggling chat and clearing storage
        tags$script(HTML("
          // Clear any stored chat history on page load
          document.addEventListener('DOMContentLoaded', function() {
            // Clear localStorage items related to chat
            for (let key in localStorage) {
              if (key.includes('chat') || key.includes('shinychat')) {
                localStorage.removeItem(key);
              }
            }
          });

          function toggleChat() {
            var chatWindow = document.getElementById('chat_window');
            chatWindow.classList.toggle('show');
          }
        "))
      )
    }
  })

  # Handle login button click
  observeEvent(input$login_btn, {
    if (input$password == "milan") {
      authenticated(TRUE)
      login_error(FALSE)
    } else {
      login_error(TRUE)
    }
  })

  # Only initialize chat and plots when authenticated
  observe({
    req(authenticated())

    # Build comprehensive system prompt with metadata
    metadata_context <- paste(
    sapply(names(meta_list), function(id) {
      meta <- meta_list[[id]]
      paste0(
        "## ", id, " - ", meta$title, "\n",
        meta$notes, "\n"
      )
    }),
    collapse = "\n"
  )

  system_prompt <- paste0(
    "You are a helpful AI assistant for a FRED (Federal Reserve Economic Data) dashboard.\n\n",
    "## Your Role\n",
    "Help users understand economic indicators and financial market trends displayed in this dashboard. ",
    "Be concise, friendly, and educational. Use clear explanations suitable for both experts and beginners.\n\n",
    "## Guardrails\n",
    "1. ONLY discuss the indicators present in this dashboard\n",
    "2. ALWAYS use the official FRED metadata provided below as your authoritative source\n",
    "3. DO NOT make up information or speculate about data not shown\n",
    "4. When interpreting trends, reference the specific indicator (e.g., 'STLFSI4', 'VIX')\n",
    "5. If asked about indicators not in the dashboard, politely explain they are not available\n",
    "6. Focus on education - explain what indicators measure and how to interpret them\n\n",
    "## Available Tools\n",
    "You have access to the following tools to analyze the actual data:\n",
    "1. get_series_summary(series_id, years) - Get statistics for any indicator\n",
    "2. get_series_trend(series_id, years) - Analyze trend direction and magnitude\n",
    "\n",
    "USE THESE TOOLS when users ask about:\n",
    "- Recent trends or patterns\n",
    "- Current values or levels\n",
    "- Historical comparisons\n",
    "- Statistical summaries\n",
    "\n",
    "Example: If asked 'What's the recent trend in NFCI?', call get_series_trend('NFCI', 3) to get actual data.\n\n",
    "## Available Indicators in Dashboard\n",
    "The following economic indicators are displayed with official FRED descriptions:\n\n",
    metadata_context,
    "\n## Guidelines for Interpretation\n",
    "- STLFSI4 and NFCI: Zero represents normal conditions; positive = tighter/stressed, negative = looser\n",
    "- VIX: Higher values = more volatility/market uncertainty\n",
    "- T10Y2Y (Yield Curve): Negative values (inversion) historically preceded recessions\n",
    "- High Yield Spreads (BAMLH0A0HYM2): Wider spreads indicate higher credit risk concerns\n",
    "- CPFF: Positive spread indicates commercial paper pricing above Fed funds rate"
  )

  # Initialize chat with Groq using comprehensive system prompt
  chat <- chat_groq(system_prompt = system_prompt)

  # Define tool functions for data analysis

  # Tool 1: Get series summary statistics
  get_series_summary_fn <- function(series_id, years = 3) {
    # Determine which dataset to use
    if (series_id %in% colnames(series)) {
      data <- series
    } else if (series_id %in% colnames(series_q)) {
      data <- series_q
    } else {
      return(paste("Error: Series", series_id, "not found in dashboard data."))
    }

    # Filter to last N years
    cutoff_date <- max(data$date) - (years * 365)
    recent_data <- data[data$date >= cutoff_date, c("date", series_id)]
    recent_data <- recent_data[!is.na(recent_data[[series_id]]), ]

    if (nrow(recent_data) == 0) {
      return(paste("No data available for", series_id, "in the last", years, "years."))
    }

    # Calculate statistics
    current_value <- tail(recent_data[[series_id]], 1)
    mean_value <- mean(recent_data[[series_id]], na.rm = TRUE)
    min_value <- min(recent_data[[series_id]], na.rm = TRUE)
    max_value <- max(recent_data[[series_id]], na.rm = TRUE)
    sd_value <- sd(recent_data[[series_id]], na.rm = TRUE)

    # Calculate changes
    one_year_ago <- recent_data[recent_data$date >= (max(recent_data$date) - 365), ]
    if (nrow(one_year_ago) > 1) {
      one_year_change <- current_value - one_year_ago[[series_id]][1]
    } else {
      one_year_change <- NA
    }

    # Format response
    result <- paste0(
      "Summary for ", series_id, " (last ", years, " years):\n",
      "- Current value: ", round(current_value, 3), "\n",
      "- Mean: ", round(mean_value, 3), "\n",
      "- Min: ", round(min_value, 3), "\n",
      "- Max: ", round(max_value, 3), "\n",
      "- Std Dev: ", round(sd_value, 3), "\n",
      if (!is.na(one_year_change)) paste0("- Change from 1 year ago: ", round(one_year_change, 3), "\n") else "",
      "- Number of observations: ", nrow(recent_data)
    )

    return(result)
  }

  # Tool 2: Get series trend analysis
  get_series_trend_fn <- function(series_id, years = 3) {
    # Determine which dataset to use
    if (series_id %in% colnames(series)) {
      data <- series
    } else if (series_id %in% colnames(series_q)) {
      data <- series_q
    } else {
      return(paste("Error: Series", series_id, "not found in dashboard data."))
    }

    # Filter to last N years
    cutoff_date <- max(data$date) - (years * 365)
    recent_data <- data[data$date >= cutoff_date, c("date", series_id)]
    recent_data <- recent_data[!is.na(recent_data[[series_id]]), ]

    if (nrow(recent_data) < 2) {
      return(paste("Insufficient data for trend analysis of", series_id))
    }

    # Fit linear trend
    recent_data$time_numeric <- as.numeric(recent_data$date)
    model <- lm(recent_data[[series_id]] ~ time_numeric, data = recent_data)
    slope <- coef(model)[2]

    # Determine trend direction and strength
    if (abs(slope) < 0.0001) {
      trend <- "stable (essentially flat)"
    } else if (slope > 0) {
      trend <- "increasing"
    } else {
      trend <- "decreasing"
    }

    # Calculate percentage change over period
    start_val <- recent_data[[series_id]][1]
    end_val <- tail(recent_data[[series_id]], 1)
    pct_change <- ((end_val - start_val) / abs(start_val)) * 100

    # Format response
    result <- paste0(
      "Trend analysis for ", series_id, " (last ", years, " years):\n",
      "- Overall trend: ", trend, "\n",
      "- Linear slope: ", format(slope, scientific = TRUE, digits = 3), " per day\n",
      "- Total change: ", round(end_val - start_val, 3), " (", round(pct_change, 1), "%)\n",
      "- Period start value: ", round(start_val, 3), "\n",
      "- Period end value: ", round(end_val, 3)
    )

    return(result)
  }

  # Register tools with the chat object
  chat$register_tool(
    tool(
      get_series_summary_fn,
      name = "get_series_summary",
      description = "Get summary statistics for a FRED economic indicator over a specified time period. Returns current value, mean, min, max, standard deviation, and recent changes.",
      arguments = list(
        series_id = type_string("The series ID (e.g., 'NFCI', 'VIXCLS', 'STLFSI4', 'T10Y2Y', 'CPFF', 'BAMLH0A0HYM2', 'DRALACBS')"),
        years = type_integer("Number of years to analyze (default: 3)")
      )
    )
  )

  chat$register_tool(
    tool(
      get_series_trend_fn,
      name = "get_series_trend",
      description = "Analyze the trend direction of a FRED economic indicator over a specified time period. Returns whether the series is increasing, decreasing, or stable, along with slope and percentage change.",
      arguments = list(
        series_id = type_string("The series ID (e.g., 'NFCI', 'VIXCLS', 'STLFSI4', 'T10Y2Y', 'CPFF', 'BAMLH0A0HYM2', 'DRALACBS')"),
        years = type_integer("Number of years to analyze (default: 3)")
      )
    )
  )

  # Use chat_server to handle the chat automatically
  # Note: show_history = FALSE in chat_ui() disables persistence
  chat_server("chat", client = chat)

  # Create plot for STLFSI4
  output$plot_stlfsi4 <- renderPlot({
    ggplot(series, aes(x = date, y = STLFSI4)) +
      geom_line(color = "#007bff", linewidth = 1) +
      theme_minimal() +
      labs(x = "Date", y = "Value", title = "St. Louis Fed Financial Stress Index") +
      theme(plot.title = element_text(size = 12, face = "bold"))
  })

  # Create plot for NFCI
  output$plot_nfci <- renderPlot({
    ggplot(series, aes(x = date, y = NFCI)) +
      geom_line(color = "#28a745", linewidth = 1) +
      theme_minimal() +
      labs(x = "Date", y = "Value", title = "National Financial Conditions Index") +
      theme(plot.title = element_text(size = 12, face = "bold"))
  })

  # Create plot for VIXCLS
  output$plot_vixcls <- renderPlot({
    ggplot(series, aes(x = date, y = VIXCLS)) +
      geom_line(color = "#dc3545", linewidth = 1) +
      theme_minimal() +
      labs(x = "Date", y = "Value", title = "CBOE Volatility Index (VIX)") +
      theme(plot.title = element_text(size = 12, face = "bold"))
  })

  # Create plot for BAMLH0A0HYM2
  output$plot_bamlh0a0hym2 <- renderPlot({
    ggplot(series, aes(x = date, y = BAMLH0A0HYM2)) +
      geom_line(color = "#ffc107", linewidth = 1) +
      theme_minimal() +
      labs(x = "Date", y = "Value", title = "ICE BofA US High Yield Index") +
      theme(plot.title = element_text(size = 12, face = "bold"))
  })

  # Create plot for T10Y2Y
  output$plot_t10y2y <- renderPlot({
    ggplot(series, aes(x = date, y = T10Y2Y)) +
      geom_line(color = "#17a2b8", linewidth = 1) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
      theme_minimal() +
      labs(x = "Date", y = "Value", title = "10-Year Treasury Minus 2-Year Treasury") +
      theme(plot.title = element_text(size = 12, face = "bold"))
  })

  # Create plot for CPFF
  output$plot_cpff <- renderPlot({
    ggplot(series, aes(x = date, y = CPFF)) +
      geom_line(color = "#6610f2", linewidth = 1) +
      theme_minimal() +
      labs(x = "Date", y = "Value", title = "3-Month Commercial Paper Minus Fed Funds Rate") +
      theme(plot.title = element_text(size = 12, face = "bold"))
  })

  # Create plot for DRALACBS (Quarterly)
  output$plot_dralacbs <- renderPlot({
    ggplot(series_q, aes(x = date, y = DRALACBS)) +
      geom_line(color = "#fd7e14", linewidth = 1) +
      theme_minimal() +
      labs(x = "Date", y = "Value", title = "Loan Loss Reserve to Total Loans") +
      theme(plot.title = element_text(size = 12, face = "bold"))
  })
  }) # Close observe block for authenticated content
}

shinyApp(ui, server)
