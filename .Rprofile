# Activate renv for reproducible R packages
local({
  act <- "renv/activate.R"
  if (file.exists(act)) source(act)
})

# If running inside the container, set the project working dir
if (identical(Sys.getenv("IN_DOCKER"), "true")) {
  try(setwd("/paper"), silent = TRUE)
}

# Optional: if you rely on reticulate and want a fixed Python path
if (nzchar(Sys.getenv("RETICULATE_PYTHON"))) {
  tryCatch({
    library(reticulate)
    use_python(Sys.getenv("RETICULATE_PYTHON"), required = FALSE)
  }, error = function(e) {})
}
