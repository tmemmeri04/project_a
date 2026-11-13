# Run after script 05. "Pass" means normality was not rejected at 0.05.
library(dplyr)

distribution_test_comparison <- long_data |>
  filter(Season %in% c("Summer", "Winter"), !is.na(Dissolved_Oxygen)) |>
  group_by(Sampling.Location, Measurement, Season) |>
  summarise(
    minimum = min(Dissolved_Oxygen),
    maximum = max(Dissolved_Oxygen),
    .groups = "drop"
  ) |>
  filter(minimum > 0) |>
  left_join(
    normality_results |>
      select(Sampling.Location, Measurement, Season, normal_test = pass_fail),
    by = c("Sampling.Location", "Measurement", "Season")
  ) |>
  left_join(
    lognormality_results |>
      select(Sampling.Location, Measurement, Season, lognormal_test = pass_fail),
    by = c("Sampling.Location", "Measurement", "Season")
  )

print(distribution_test_comparison, n = Inf, width = Inf)
