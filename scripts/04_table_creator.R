# Seasonal distribution diagnostics and exploratory time plots.
library(ggplot2)
library(dplyr)

plot_data <- long_data |> filter(!is.na(Dissolved_Oxygen))
seasonal_plot_data <- plot_data |> filter(Season %in% c("Summer", "Winter"))

# Positive component only: zeros remain in every original-scale analysis.
loglong_data <- plot_data |> filter(Dissolved_Oxygen > 0)
lnlong_data_DO <- log(loglong_data$Dissolved_Oxygen)
loglong_data$Dissolved_Oxygen <- lnlong_data_DO
seasonal_log_data <- loglong_data |> filter(Season %in% c("Summer", "Winter"))

# Shared histogram styling; short labels affect display only.
measurement_labels <- c(
  Dissolved_Oxygen_CTD_bottom = "CTD bottom",
  Dissolved_Oxygen_CTD_top = "CTD top",
  Dissolved_Oxygen_winkler_bottom = "Winkler bottom",
  Dissolved_Oxygen_winkler_top = "Winkler top"
)
histogram_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 20, face = "bold", color = "#203544"),
    plot.subtitle = element_text(size = 11, color = "#52616b", margin = margin(b = 16)),
    plot.title.position = "plot",
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.major.y = element_line(color = "#e4e9ed"),
    panel.spacing = grid::unit(1, "lines"),
    strip.background = element_rect(fill = "#edf2f5", color = NA),
    strip.text = element_text(face = "bold", color = "#203544", size = 11),
    axis.title = element_text(color = "#203544", margin = margin(t = 10, r = 10)),
    axis.text = element_text(color = "#52616b"),
    legend.position = "none",
    plot.margin = margin(20, 20, 20, 20)
  )
histogram_counts <- seasonal_plot_data |>
  count(Sampling.Location, Season, Measurement, name = "sample_size")
log_histogram_counts <- seasonal_log_data |>
  count(Sampling.Location, Season, Measurement, name = "sample_size")

seasonal_histograms <- ggplot(seasonal_plot_data, aes(x = Dissolved_Oxygen, fill = Season)) +
  geom_histogram(binwidth = 0.5, boundary = 0, closed = "left", color = "white", linewidth = 0.2) +
  geom_vline(xintercept = 5, linetype = "dashed", color = "#a0473b", linewidth = 0.5) +
  geom_text(data = histogram_counts,
            aes(x = Inf, y = Inf, label = paste0("n = ", sample_size)),
            inherit.aes = FALSE, hjust = 1.15, vjust = 1.5, size = 3, color = "#52616b") +
  facet_grid(Sampling.Location + Season ~ Measurement,
             labeller = labeller(Measurement = measurement_labels)) +
  scale_fill_manual(values = c(Summer = "#78BE20", Winter = "#0072CE")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  histogram_theme +
  labs(title = "Dissolved oxygen by site and season",
       subtitle = "Shared axes and 0.5 mg/L bins; dashed line marks the 5 mg/L threshold",
       x = "Dissolved oxygen (mg/L)", y = "Number of observations")

seasonal_qq <- ggplot(seasonal_plot_data, aes(sample = Dissolved_Oxygen)) +
  stat_qq() + stat_qq_line() +
  facet_grid(Sampling.Location + Season ~ Measurement) +
  theme_minimal() +
  labs(title = "Seasonal normal Q-Q plots",
       x = "Theoretical standard-normal quantile", y = "Observed dissolved oxygen (mg/L)")

seasonal_log_histograms <- ggplot(seasonal_log_data, aes(x = Dissolved_Oxygen, fill = Season)) +
  geom_histogram(binwidth = 0.2, boundary = 0, closed = "left", color = "white", linewidth = 0.2) +
  geom_vline(xintercept = log(5), linetype = "dashed", color = "#a0473b", linewidth = 0.5) +
  geom_text(data = log_histogram_counts,
            aes(x = Inf, y = Inf, label = paste0("n = ", sample_size)),
            inherit.aes = FALSE, hjust = 1.15, vjust = 1.5, size = 3, color = "#52616b") +
  facet_grid(Sampling.Location + Season ~ Measurement,
             labeller = labeller(Measurement = measurement_labels)) +
  scale_fill_manual(values = c(Summer = "#78BE20", Winter = "#0072CE")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  histogram_theme +
  labs(title = "Log dissolved oxygen by site and season",
       subtitle = "Positive readings only; 0.2 log-unit bins and shared axes\nDashed line marks DO = 5 mg/L",
       x = "ln(DO / (1 mg/L))", y = "Number of observations")

seasonal_log_qq <- ggplot(seasonal_log_data, aes(sample = Dissolved_Oxygen)) +
  stat_qq() + stat_qq_line() +
  facet_grid(Sampling.Location + Season ~ Measurement) +
  theme_minimal() +
  labs(title = "Seasonal lognormal Q-Q diagnostics: positive observations only",
       subtitle = "These plots do not assess a lognormal model for the recorded zeros",
       x = "Theoretical standard-normal quantile", y = "Observed ln(DO / (1 mg/L))")

export_plot(seasonal_histograms, "seasonal_histograms", height = 14)
export_plot(seasonal_qq, "seasonal_normal_qq", height = 14)
export_plot(seasonal_log_histograms, "seasonal_positive_log_histograms", height = 14)
export_plot(seasonal_log_qq, "seasonal_positive_log_qq", height = 14)

# Full-year exploratory plots: these do not answer mean-comparison or daily-change questions.
oxygen_time_plot <- ggplot(plot_data, aes(x = Sample.Date, y = Dissolved_Oxygen)) +
  geom_point() + geom_line() +
  facet_grid(Sampling.Location ~ Measurement) +
  theme_minimal() +
  labs(title = "Exploratory dissolved oxygen over time: all seasons",
       x = "Date", y = "Dissolved oxygen (mg/L)")
export_plot(oxygen_time_plot, "exploratory_oxygen_over_time")

filtered_long_data_NC1 <- plot_data |>
  filter(Sampling.Location == "NC1", Measurement == "Dissolved_Oxygen_winkler_top")
nc1_time_plot <- ggplot(filtered_long_data_NC1, aes(Sample.Date, Dissolved_Oxygen)) +
  geom_point() + theme_minimal() +
  labs(title = "Exploratory NC1 Winkler top DO: all seasons",
       x = "Date", y = "Dissolved oxygen (mg/L)")
export_plot(nc1_time_plot, "exploratory_nc1_winkler_top")

doublefiltered_long_data_NC1 <- filtered_long_data_NC1 |>
  filter(Sample.Date > as.Date("2010-01-01"))
exploratory_nc1_model <- lm(Dissolved_Oxygen ~ Sample.Date, data = doublefiltered_long_data_NC1)
exploratory_nc1_model_summary <- summary(exploratory_nc1_model)
nc1_trend_plot <- ggplot(doublefiltered_long_data_NC1, aes(Sample.Date, Dissolved_Oxygen)) +
  geom_point() + geom_smooth(method = "lm", formula = y ~ x, se = FALSE, color = "red") +
  theme_minimal() +
  labs(title = "Exploratory NC1 Winkler top trend after 2010: all seasons",
       x = "Date", y = "Dissolved oxygen (mg/L)")
export_plot(nc1_trend_plot, "exploratory_nc1_winkler_top_after_2010")
