# Run after script 05. Pool reading counts, rather than averaging probabilities.
library(dplyr)

bottom_method_counts <- seasonal_probabilities |>
  filter(Measurement %in% c(
    "Dissolved_Oxygen_CTD_bottom", "Dissolved_Oxygen_winkler_bottom"
  )) |>
  select(Sampling.Location, Measurement, Season,
         total_rows, missing_rows, nonmissing_rows, low_oxygen_rows)

# Six rows: both bottom-water methods combined within each site and season.
bottom_site_counts <- bottom_method_counts |>
  group_by(Sampling.Location, Season) |>
  summarise(
    across(c(total_rows, missing_rows, nonmissing_rows, low_oxygen_rows), sum),
    .groups = "drop"
  ) |>
  mutate(Measurement = "Combined bottom methods")

# Two rows: both bottom-water methods and all three sites combined by season.
bottom_season_counts <- bottom_site_counts |>
  group_by(Season) |>
  summarise(
    across(c(total_rows, missing_rows, nonmissing_rows, low_oxygen_rows), sum),
    .groups = "drop"
  ) |>
  mutate(Sampling.Location = "All sites", Measurement = "Combined bottom methods")

# Fit the normal calculation to the actual readings in each of the 20 groups.
bottom_readings <- long_data |>
  filter(Season %in% c("Summer", "Winter"), Measurement %in% c(
    "Dissolved_Oxygen_CTD_bottom", "Dissolved_Oxygen_winkler_bottom"
  ))

bottom_normal_probabilities <- bind_rows(
  bottom_readings,
  bottom_readings |> mutate(Measurement = "Combined bottom methods"),
  bottom_readings |> mutate(Sampling.Location = "All sites", Measurement = "Combined bottom methods")
) |>
  group_by(Sampling.Location, Measurement, Season) |>
  summarise(
    assumed_normal = if (sum(!is.na(Dissolved_Oxygen)) > 1 &&
                         sd(Dissolved_Oxygen, na.rm = TRUE) > 0) {
      pnorm(5, mean(Dissolved_Oxygen, na.rm = TRUE), sd(Dissolved_Oxygen, na.rm = TRUE))
    } else NA_real_,
    .groups = "drop"
  )

# Retain zeros in the numerator and denominator; exclude missing DO from both.
bottom_seasonal_probabilities <- bind_rows(
  bottom_method_counts, bottom_site_counts, bottom_season_counts
) |>
  mutate(
    simple_fraction = if_else(
      nonmissing_rows > 0, low_oxygen_rows / nonmissing_rows, NA_real_
    )
  ) |>
  rowwise() |>
  mutate(
    confidence_interval = list(
      if (nonmissing_rows > 0) {
        binom.test(low_oxygen_rows, nonmissing_rows, conf.level = 0.95)$conf.int
      } else c(NA_real_, NA_real_)
    ),
    fraction_CI_lower = confidence_interval[1],
    fraction_CI_upper = confidence_interval[2]
  ) |>
  ungroup() |>
  select(-confidence_interval) |>
  left_join(bottom_normal_probabilities, by = c("Sampling.Location", "Measurement", "Season"))

export_table(
  bottom_seasonal_probabilities, "bottom_seasonal_probabilities",
  paste(
    "Bottom-water observed and fitted-normal probabilities of DO at or below 5 mg/L.",
    "Methods and sites are pooled by reading counts where indicated.",
    "Fitted-normal probabilities use each group's mean and sample SD, including pooled readings.",
    "95 percent binomial intervals assume independent readings;",
    "paired methods and repeated sampling may violate this assumption."
  )
)
print(bottom_seasonal_probabilities, n = Inf, width = Inf)

library(ggplot2)

bottom_probability_plot_data <- bottom_seasonal_probabilities |>
  mutate(
    panel = case_when(
      Measurement == "Dissolved_Oxygen_CTD_bottom" ~ "CTD bottom",
      Measurement == "Dissolved_Oxygen_winkler_bottom" ~ "Winkler bottom",
      Sampling.Location == "All sites" ~ "Both methods: all sites pooled",
      TRUE ~ "Both methods: by site"
    ),
    panel = factor(panel, levels = c(
      "CTD bottom", "Winkler bottom", "Both methods: by site",
      "Both methods: all sites pooled"
    )),
    Season = factor(Season, levels = c("Summer", "Winter"))
  )

bottom_seasonal_probability_plot <- ggplot(
  bottom_probability_plot_data,
  aes(x = Sampling.Location, y = simple_fraction, color = Season, shape = Season)
) +
  geom_errorbar(
    aes(ymin = fraction_CI_lower, ymax = fraction_CI_upper),
    position = position_dodge(width = 0.4), width = 0.12, linewidth = 0.6
  ) +
  geom_point(position = position_dodge(width = 0.4), size = 3) +
  facet_wrap(~panel, ncol = 2, scales = "free_x") +
  scale_color_manual(values = c(Summer = "#78BE20", Winter = "#0072CE")) +
  scale_y_continuous(
    limits = c(0, 1), breaks = seq(0, 1, 0.2),
    labels = function(x) paste0(round(100 * x), "%")
  ) +
  labs(
    title = "Seasonal low-oxygen probabilities: creek bottom",
    subtitle = "Observed fractions with 95% binomial confidence intervals",
    x = NULL, y = "Probability of DO <= 5 mg/L",
    caption = paste(
      "Confidence intervals assume independent readings.",
      sep = "\n"
    )
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold"),
    plot.caption = element_text(hjust = 0)
  )

export_plot(bottom_seasonal_probability_plot, "bottom_seasonal_probabilities", width = 12, height = 8)
