# Optional single-group check. Run from the project root; not part of the runner.
library(dplyr)
library(ggplot2)
source("scripts/00_functions.R")

gamma_check_data <- readr::read_csv(
  "data/processed/long_data.csv",
  col_types = readr::cols(
    Sample.Date = readr::col_date(), Sample.Time = readr::col_time(),
    Sample.Time.raw = readr::col_character()
  )
) |>
  filter(
    Sampling.Location == "NC3", Measurement == "Dissolved_Oxygen_CTD_top",
    Season == "Summer", !is.na(Dissolved_Oxygen)
  )

# Selected for its strong right skew, not for its eventual model fit.
# Stop rather than silently discard any zeros from this comparison.
gamma_check_readings <- gamma_check_data$Dissolved_Oxygen
stopifnot(length(gamma_check_readings) > 2, all(is.finite(gamma_check_readings)),
          all(gamma_check_readings > 0))

# All three likelihoods use the same original-scale DO readings.
gamma_check_fits <- list(
  Normal = MASS::fitdistr(gamma_check_readings, "normal"),
  Lognormal = MASS::fitdistr(gamma_check_readings, "lognormal"),
  Gamma = MASS::fitdistr(gamma_check_readings, "gamma", lower = c(0.000001, 0.000001))
)

gamma_check_cdfs <- list(
  Normal = function(q) pnorm(q,
    mean = gamma_check_fits$Normal$estimate[["mean"]],
    sd = gamma_check_fits$Normal$estimate[["sd"]]),
  Lognormal = function(q) plnorm(q,
    meanlog = gamma_check_fits$Lognormal$estimate[["meanlog"]],
    sdlog = gamma_check_fits$Lognormal$estimate[["sdlog"]]),
  Gamma = function(q) pgamma(q,
    shape = gamma_check_fits$Gamma$estimate[["shape"]],
    rate = gamma_check_fits$Gamma$estimate[["rate"]])
)

gamma_check_empirical <- mean(gamma_check_readings <= 5)
ordered_readings <- sort(gamma_check_readings)
sample_size <- length(ordered_readings)

gamma_fit_comparison <- bind_rows(lapply(names(gamma_check_fits), function(model) {
  fitted_cdf <- gamma_check_cdfs[[model]]
  fitted_at_readings <- fitted_cdf(ordered_readings)
  tibble(
    model = model, usable_rows = sample_size,
    empirical_probability = gamma_check_empirical,
    fitted_probability = fitted_cdf(5),
    difference_percentage_points = 100 * (fitted_cdf(5) - gamma_check_empirical),
    AIC = AIC(gamma_check_fits[[model]]),
    # Descriptive maximum CDF gap; not a calibrated goodness-of-fit p-value.
    maximum_CDF_gap = max(
      seq_len(sample_size) / sample_size - fitted_at_readings,
      fitted_at_readings - (seq_len(sample_size) - 1) / sample_size
    ),
    probability_below_zero = fitted_cdf(0)
  )
})) |>
  mutate(delta_AIC = AIC - min(AIC))

gamma_fit_parameters <- bind_rows(lapply(names(gamma_check_fits), function(model) {
  estimates <- gamma_check_fits[[model]]$estimate
  tibble(model = model, parameter = names(estimates), estimate = unname(estimates))
}))

export_table(gamma_fit_comparison, "gamma_fit_check_comparison",
  "Exploratory fits to NC3 summer CTD top DO. Same positive observations for all models; original-scale maximum likelihood. In-sample comparisons only.")
export_table(gamma_fit_parameters, "gamma_fit_check_parameters",
  "Maximum-likelihood parameter estimates for the single-group distribution check. Gamma uses shape and rate.")

cdf_grid <- sort(unique(c(seq(0, max(gamma_check_readings) * 1.05, length.out = 1000), 5)))
gamma_check_curves <- bind_rows(lapply(names(gamma_check_cdfs), function(model) {
  tibble(Dissolved_Oxygen = cdf_grid,
         probability = gamma_check_cdfs[[model]](cdf_grid), model = model)
}))

gamma_fit_check_plot <- ggplot() +
  stat_ecdf(data = gamma_check_data, aes(x = Dissolved_Oxygen, color = "Empirical"),
            geom = "step", linewidth = 0.85, pad = FALSE) +
  geom_line(data = gamma_check_curves,
            aes(x = Dissolved_Oxygen, y = probability, color = model), linewidth = 0.8) +
  geom_vline(xintercept = 5, linetype = "dashed", color = "#777777") +
  geom_point(aes(x = 5, y = gamma_check_empirical), size = 2.5) +
  scale_color_manual(values = c(Empirical = "#222222", Normal = "#0072CE",
                               Lognormal = "#B45B16", Gamma = "#528500")) +
  scale_y_continuous(limits = c(0, 1), labels = function(x) paste0(100 * x, "%")) +
  labs(title = "Does gamma capture the right-skewed DO distribution?",
       subtitle = paste0("NC3 | CTD top | Summer | n = ", sample_size,
                         " | no recorded zeros"),
       x = "Dissolved oxygen (mg/L)", y = "Cumulative probability", color = NULL,
       caption = "Dashed line: 5 mg/L. Fits and comparisons use the same observations.\nExploratory in-sample assessment; repeated sampling and rounding are not modeled.") +
  theme_minimal(base_size = 12) +
  theme(legend.position = "top", panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"), plot.caption = element_text(hjust = 0))

export_plot(gamma_fit_check_plot, "gamma_fit_check_cdf", width = 10, height = 7)
print(gamma_fit_comparison, width = Inf)
print(gamma_fit_parameters)
