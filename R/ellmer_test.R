library(ellmer)
library(dotenv)


load_dot_env()

chat <- chat_groq(
  system_prompt = NULL,
  base_url = "https://api.groq.com/openai/v1",
  credentials = NULL,
  model = NULL,
  params = NULL,
  api_args = list(),
  echo = NULL,
  api_headers = character()
)
chat$chat("Tell me three jokes about statisticians")
