# Run from the project root: Rscript --vanilla scripts/000_runtime.R
required_packages <- c("here", "readr", "dplyr", "tidyr", "ggplot2", "knitr", "nortest")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Install required packages first: ", paste(missing_packages, collapse = ", "))
}
library(here)
setwd(here())
dir.create(file.path("outputs", "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path("outputs", "figures"), recursive = TRUE, showWarnings = FALSE)
source(here("scripts", "00_functions.R"))
source(here("scripts", "01_create_filtered_data.r"))
source(here("scripts", "02_wide_long_converter.r"))
source(here("scripts", "03_data_sumarrizer.r"))
source(here("scripts", "04_table_creator.R"))
source(here("scripts", "05_probability_analyzers.R"))
source(here("scripts", "07_top_water_probabilities.R"))
source(here("scripts", "08_bottom_water_probabilities.R"))
source(here("scripts", "09_depth_distribution_diagnostics.R"))
message("Workflow complete. CSV/LaTeX tables: outputs/tables; PNG/PDF figures: outputs/figures.")
message("Joint probabilities are finalized using same-day/order matching without a time filter; exact simultaneity is not established.")
