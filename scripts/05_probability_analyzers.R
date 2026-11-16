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

# Final date/order matching method. No sampling-time window is applied.
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

# Question 2 figure: both joint events, with top/bottom readings kept separate.
joint_probability_plot_data <- summarized_simultaneous_measurements |>
  pivot_longer(c(all_three_fail, only_one_fails),
               names_to = "Event", values_to = "probability") |>
  mutate(
    Method = if_else(grepl("CTD", Measurement), "CTD", "Winkler"),
    Depth = factor(if_else(grepl("_top$", Measurement), "Top", "Bottom"),
                   levels = c("Top", "Bottom")),
    Event = factor(Event, levels = c("all_three_fail", "only_one_fails"),
      labels = c("All three sites at or below 5 mg/L", "Exactly one site at or below 5 mg/L"))
  ) |>
  rowwise() |>
  mutate(
    event_count = round(probability * total_complete_measurements),
    interval = list(binom.test(event_count, total_complete_measurements)$conf.int),
    lower = interval[1], upper = interval[2]
  ) |>
  ungroup() |>
  select(-interval)

joint_probability_plot <- ggplot(
  joint_probability_plot_data,
  aes(x = Method, y = probability, color = Depth, shape = Depth)
) +
  geom_errorbar(aes(ymin = lower, ymax = upper),
    position = position_dodge(width = 0.4), width = 0.12, linewidth = 0.6) +
  geom_point(position = position_dodge(width = 0.4), size = 3) +
  facet_wrap(~Event, ncol = 2) +
  scale_color_manual(values = c(Top = "#0072CE", Bottom = "#78BE20")) +
  scale_y_continuous(limits = c(0, 1), breaks = seq(0, 1, 0.2),
    labels = function(x) paste0(round(100 * x), "%")) +
  labs(
    title = "Joint low-oxygen probabilities across NC1, NC2 and NC3",
    subtitle = "All seasons pooled; observed fractions with 95% Clopper-Pearson intervals",
    x = NULL, y = "Probability",
    caption = paste("Same-day/order matching; no time-window filter. Sampling times may differ.",
      "Intervals assume independent matched events with a common event probability; temporal dependence is not modeled.",
      sep = "\n")
  ) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(), strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold"), plot.caption = element_text(hjust = 0))

export_plot(joint_probability_plot, "joint_probabilities", width = 12, height = 7)

# Question 3: match each pair separately, without requiring the third site.
# Existing missing Season values identify spring/fall; no new date rules.
paired_site_measurements <- time_filtered_long_data |>
  mutate(Season = ifelse(is.na(Season), "Spring/Fall", Season)) |>
  pivot_wider(
    id_cols = c(Measurement, Sample.Date, sample_round, Season),
    names_from = Sampling.Location,
    values_from = Dissolved_Oxygen
  )

NC1_NC2_pairs <- paired_site_measurements |>
  filter(!is.na(NC1), !is.na(NC2)) |>
  transmute(Pair = "NC1-NC2", Season, Measurement, Sample.Date, first_site = NC1, second_site = NC2)

NC2_NC3_pairs <- paired_site_measurements |>
  filter(!is.na(NC2), !is.na(NC3)) |>
  transmute(Pair = "NC2-NC3", Season, Measurement, Sample.Date, first_site = NC2, second_site = NC3)

NC1_NC3_pairs <- paired_site_measurements |>
  filter(!is.na(NC1), !is.na(NC3)) |>
  transmute(Pair = "NC1-NC3", Season, Measurement, Sample.Date, first_site = NC1, second_site = NC3)

paired_site_data <- bind_rows(NC1_NC2_pairs, NC2_NC3_pairs, NC1_NC3_pairs)

#QUESTION 4
# Average change per elapsed day, then descriptive correlations across all seasons.
daily_changes<- simultaneous_measurements |>
  group_by(Measurement) |>
  arrange(Sample.Date) |>
     mutate(
         NC1_change = (NC1 - lag(NC1))/as.numeric((Sample.Date - lag(Sample.Date))),
         NC2_change = (NC2 - lag(NC2))/as.numeric((Sample.Date - lag(Sample.Date))),
         NC3_change = (NC3 - lag(NC3))/as.numeric((Sample.Date - lag(Sample.Date)))
     )

corr_coeff_btwn_sites <- daily_changes |>
  summarize(
    NC1_NC2 = cor(NC1_change, NC2_change, use = "complete.obs"),
    NC2_NC3 = cor(NC2_change, NC3_change, use = "complete.obs"),
    NC1_NC3 = cor(NC1_change, NC3_change, use = "complete.obs")
    )

# Readable Question 4 table; retain the original coefficients above at full precision.
daily_change_correlations <- corr_coeff_btwn_sites |>
  ungroup() |>
  mutate(
    Method = if_else(grepl("CTD", Measurement), "CTD", "Winkler"),
    Depth = factor(if_else(grepl("_top$", Measurement), "Top", "Bottom"),
                   levels = c("Top", "Bottom"))
  ) |>
  arrange(Depth, Method) |>
  select(Depth, Method, `NC1-NC2` = NC1_NC2, `NC2-NC3` = NC2_NC3, `NC1-NC3` = NC1_NC3)

export_table(
  daily_change_correlations, "daily_change_correlations",
  paste("Pearson correlation coefficients (r) between sites' average DO changes per elapsed day.",
    "All seasons pooled; methods and depths kept separate. Values shown to three decimal places.",
    "Rates use consecutive complete three-site matched events. Temporal dependence is not modeled."),
  digits = 3
)

# Put the three site pairs into the same columns for plotting.
correlation_plot_data <- bind_rows(
  daily_changes |>
    transmute(Measurement, Pair = "NC1 (x), NC2 (y)", x_change = NC1_change, y_change = NC2_change),
  daily_changes |>
    transmute(Measurement, Pair = "NC2 (x), NC3 (y)", x_change = NC2_change, y_change = NC3_change),
  daily_changes |>
    transmute(Measurement, Pair = "NC1 (x), NC3 (y)", x_change = NC1_change, y_change = NC3_change)
) |>
  ungroup() |>
  filter(is.finite(x_change), is.finite(y_change)) |>
  mutate(Pair = factor(Pair, levels = c(
    "NC1 (x), NC2 (y)", "NC2 (x), NC3 (y)", "NC1 (x), NC3 (y)"
  )))

daily_change_regression_plot <- ggplot(correlation_plot_data, aes(x_change, y_change)) +
  geom_point(alpha = 0.35, size = 1, color = "#52616b") +
  geom_smooth(method = "lm", formula = y ~ x, se = FALSE, color = "#0072CE") +
  facet_grid(Measurement ~ Pair, labeller = labeller(Measurement = measurement_labels)) +
  labs(
    title = "Association between sites' average daily DO changes",
    subtitle = "Three site pairs; methods and depths kept separate; all seasons pooled",
    x = "Average daily DO change at x site (mg/L/day)",
    y = "Average daily DO change at y site (mg/L/day)",
    caption = "Lines are descriptive linear fits. Temporal dependence is not modeled."
  ) +
  theme_minimal()

export_plot(daily_change_regression_plot, "daily_change_regressions", width = 14, height = 11)


# Add all-year copies so each pair also gets a test using every season.
# "All year" pools all sampled years, rather than testing each calendar year.
t_test_mean_diff <- bind_rows(
  paired_site_data,
  paired_site_data |> mutate(Season = "All year")
) |>
  group_by(Pair, Season, Measurement) |>
  summarise(
    p_value = signif(t.test(first_site, second_site, paired = TRUE)$p.value, digits = 3),
    .groups = "drop"
  ) |>
  mutate(
    Measurement = recode(Measurement,
      Dissolved_Oxygen_CTD_top = "CTD top",
      Dissolved_Oxygen_CTD_bottom = "CTD bottom",
      Dissolved_Oxygen_winkler_top = "Winkler top",
      Dissolved_Oxygen_winkler_bottom = "Winkler bottom"
    ),
    Pair = factor(Pair, levels = c("NC1-NC2", "NC2-NC3", "NC1-NC3")),
    Season = factor(Season, levels = c("Winter", "Summer", "Spring/Fall", "All year"))
  ) |>
  pivot_wider(names_from = Measurement, values_from = p_value) |>
  arrange(Season == "All year", Pair, Season)

print(t_test_mean_diff, n = Inf, width = Inf)
export_table(
  t_test_mean_diff, "paired_site_t_tests",
  paste(
    "Two-sided paired t-test p-values, rounded to three significant figures, for same-day/order matched DO readings.",
    "Each pair requires only its own two readings; no time-window filter is applied.",
    "All year pools all seasons and sampled years. P-values are unadjusted for multiple tests;",
    "independence between matched occasions is assumed."
  ),
  digits = Inf, significant_digits = 3
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

export_table(summarized_simultaneous_measurements, "joint_probabilities",
             "Joint DO failure probabilities from same-day/order matched observations, approximating simultaneous conditions. Sampling times may differ; no time-window filter is applied. All seasons pooled. Failure means DO at or below 5 mg/L.")
write_plain_csv(simultaneous_measurements,
                file.path("outputs", "tables", "matched_observations_date_order.csv"))
