library(dotenv)
library(fred)

load_dot_env()


fred_set_key(Sys.getenv("FRED_API"))


ids <- c(
  "STLFSI4",
  "NFCI",
  "VIXCLS",
  "BAMLH0A0HYM2",
  "T10Y2Y",
  "DRALACBS",
  "CPFF"
)
series <- fred_series(
  ids[c(1:5, 7)],
  frequency = "m",
  format = 'wide',
  from = "2000-01-01"
)

series_q <- fred_series(
  ids[6],
  frequency = "q",
  format = 'wide',
  from = "2000-01-01"
)

meta_list <- lapply(ids, fred_info)
names(meta_list) <- ids

save(ids, meta_list, series, series_q, file = 'fred_data.Rdata')
