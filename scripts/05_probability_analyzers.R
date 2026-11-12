library(ggplot2)
library(dplyr)
library(tidyr)

# Retain missing rows for counts; negative measurements were removed in script 02.
seasonal_probabilities <- long_data |>
  filter(Season %in% c("Summer", "Winter")) |>
  group_by(Sampling.Location, Measurement, Season) |>
  summarise(
    total_rows = n(),
    missing_rows = sum(is.na(Dissolved_Oxygen)),
    nonmissing_rows = sum(!is.na(Dissolved_Oxygen)),
    low_oxygen_rows = sum(Dissolved_Oxygen <= 5, na.rm = TRUE),
    simple_fraction = if (nonmissing_rows > 0) low_oxygen_rows / nonmissing_rows else NA_real_,
    confidence_interval = list(
      if (nonmissing_rows > 0) {
        binom.test(low_oxygen_rows, nonmissing_rows, conf.level = 0.95)$conf.int
      } else c(NA_real_, NA_real_)
    ),
    assumed_normal = if (nonmissing_rows > 1 && sd(Dissolved_Oxygen, na.rm = TRUE) > 0) {
      pnorm(5, mean(Dissolved_Oxygen, na.rm = TRUE), sd(Dissolved_Oxygen, na.rm = TRUE))
    } else NA_real_,
    .groups = "drop"
  ) |>
  mutate(
    fraction_CI_lower = vapply(confidence_interval, function(interval) interval[1], numeric(1)),
    fraction_CI_upper = vapply(confidence_interval, function(interval) interval[2], numeric(1)),
    fraction_0.95_CI = if_else(
      is.na(fraction_CI_lower), NA_character_,
      sprintf("CI: [%.3f, %.3f]", fraction_CI_lower, fraction_CI_upper)
    )
  ) |>
  select(-confidence_interval)

seasonal_probability_plot <- ggplot(
  seasonal_probabilities, aes(x = Sampling.Location, y = simple_fraction, color = Season)
) +
  geom_point(position = position_dodge(width = 0.4), size = 3) +
  geom_errorbar(aes(ymin = fraction_CI_lower, ymax = fraction_CI_upper),
                position = position_dodge(width = 0.4), width = 0.15) +
  facet_wrap(~Measurement) +
  labs(title = "Observed low-oxygen fractions by location and season",
       subtitle = "95% binomial confidence intervals; independence assumed",
       x = "Sampling location", y = "Fraction of usable measurements with DO <= 5 mg/L") +
  theme_minimal()
export_plot(seasonal_probability_plot, "seasonal_probabilities")
export_table(seasonal_probabilities, "seasonal_probabilities",
             "Observed and fitted-normal probabilities of DO at or below 5 mg/L. Intervals are 95 percent binomial intervals for observed proportions, assuming independence.")

# Original date/order matching. No sampling-time window is applied yet.
# First number each site's readings chronologically within each date/measurement.
time_filtered_long_data <- long_data |>
  group_by(Sample.Date, Measurement, Sampling.Location) |>
  arrange(Sample.Time) |>
  mutate(sample_round = row_number()) |>
  ungroup()

# Pair first readings across sites, then second readings, and so on.
simultaneous_measurements <- time_filtered_long_data |>
  pivot_wider(
    id_cols = c(Measurement, Sample.Date, sample_round),
    names_from = Sampling.Location,
    values_from = Dissolved_Oxygen
  ) |>
  filter(!is.na(NC1), !is.na(NC2), !is.na(NC3))

# Denominator: complete date/order triplets, pooled across all seasons.
summarized_simultaneous_measurements <- simultaneous_measurements |>
  group_by(Measurement) |>
  summarise(
    total_complete_measurements = n(),
    all_three_fail = sum(NC1 <= 5 & NC2 <= 5 & NC3 <= 5) / n(),
    only_one_fails = sum(
      (NC1 <= 5 & NC2 > 5 & NC3 > 5) |
      (NC1 > 5 & NC2 <= 5 & NC3 > 5) |
      (NC1 > 5 & NC2 > 5 & NC3 <= 5)
    ) / n(),
    .groups = "drop"
  )

normality_results <- long_data |>
  filter(Season %in% c("Summer", "Winter")) |>
  group_by(Sampling.Location, Measurement, Season) |>
  summarise(
    usable_rows = sum(!is.na(Dissolved_Oxygen)),
    A = unname(nortest::ad.test(Dissolved_Oxygen)$statistic),
    p_value = nortest::ad.test(Dissolved_Oxygen)$p.value,
    pass_fail = ifelse(p_value > 0.05, "Pass", "Fail"),
    .groups = "drop"
  )

lognormality_results <- loglong_data |>
  filter(Season %in% c("Summer", "Winter")) |>
  group_by(Sampling.Location, Measurement, Season) |>
  summarise(
    usable_rows = sum(!is.na(Dissolved_Oxygen)),
    A = unname(nortest::ad.test(Dissolved_Oxygen)$statistic),
    p_value = nortest::ad.test(Dissolved_Oxygen)$p.value,
    pass_fail = ifelse(p_value > 0.05, "Pass", "Fail"),
    .groups = "drop"
  )

export_table(summarized_simultaneous_measurements, "provisional_joint_probabilities",
             "PROVISIONAL joint DO failure probabilities using original same-date/order matching. No time-window filter applied; all seasons pooled. Failure means DO at or below 5 mg/L.")
write_plain_csv(simultaneous_measurements,
                file.path("outputs", "tables", "matched_observations_date_order.csv"))
