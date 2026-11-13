# Optional final Question 1 check across the 20 top-water groups.
# Run from the project root. Main empirical tables remain unchanged.
library(dplyr)
library(tidyr)
library(ggplot2)
source("scripts/00_functions.R")

top_fit_source <- readr::read_csv(
  "data/processed/long_data.csv",
  col_types = readr::cols(
    Sample.Date = readr::col_date(), Sample.Time = readr::col_time(),
    Sample.Time.raw = readr::col_character()
  )
) |>
  filter(Season %in% c("Summer", "Winter"), Measurement %in% c(
    "Dissolved_Oxygen_CTD_top", "Dissolved_Oxygen_winkler_top"
  ))

# Each reading contributes once to each relevant aggregation level.
top_fit_data <- bind_rows(
  top_fit_source |> mutate(aggregation = "Individual methods"),
  top_fit_source |> mutate(Measurement = "Combined top methods",
                          aggregation = "Methods pooled"),
  top_fit_source |> mutate(Sampling.Location = "All sites",
                          Measurement = "Combined top methods",
                          aggregation = "Sites and methods pooled")
) |>
  filter(!is.na(Dissolved_Oxygen)) |>
  mutate(group_id = paste(Sampling.Location, Measurement, Season, sep = " | "))

fit_top_group <- function(data) {
  x <- data$Dissolved_Oxygen
  positive <- x[x > 0]
  n <- length(x)
  zeros <- sum(x == 0)
  p0 <- zeros / n
  stopifnot(all(is.finite(x)), all(x >= 0), length(positive) > 2,
            sd(positive) > 0)

  fits <- list(
    Normal = MASS::fitdistr(x, "normal"),
    Lognormal = MASS::fitdistr(positive, "lognormal"),
    Gamma = MASS::fitdistr(positive, "gamma", lower = c(0.000001, 0.000001))
  )
  positive_cdfs <- list(
    Lognormal = function(q) plnorm(q,
      meanlog = fits$Lognormal$estimate[["meanlog"]],
      sdlog = fits$Lognormal$estimate[["sdlog"]]),
    Gamma = function(q) pgamma(q,
      shape = fits$Gamma$estimate[["shape"]],
      rate = fits$Gamma$estimate[["rate"]])
  )
  cdfs <- list(Normal = function(q) pnorm(q,
    mean = fits$Normal$estimate[["mean"]], sd = fits$Normal$estimate[["sd"]]))
  for (model in names(positive_cdfs)) {
    cdfs[[model]] <- local({
      positive_cdf <- positive_cdfs[[model]]
      function(q) ifelse(q < 0, 0, p0 + (1 - p0) * positive_cdf(q))
    })
  }

  values <- sort(unique(x))
  empirical_right <- ecdf(x)(values)
  empirical_left <- empirical_right - tabulate(match(x, values), length(values)) / n
  grid <- sort(unique(c(seq(0, max(x) * 1.05, length.out = 500), 5)))
  metadata <- data |> select(group_id, Sampling.Location, Measurement, Season,
                            aggregation) |> slice(1)

  comparison <- bind_rows(lapply(names(fits), function(model) {
    right <- cdfs[[model]](values)
    left <- right
    if (model != "Normal") left[values == 0] <- 0
    # Gamma/lognormal share a zero mass and a positive continuous component.
    mixture_loglik <- as.numeric(logLik(fits[[model]]))
    if (model != "Normal" && zeros > 0) {
      mixture_loglik <- mixture_loglik + zeros * log(p0) + length(positive) * log1p(-p0)
    }
    comparable <- !(model == "Normal" && zeros > 0)
    parameter_count <- 2L + as.integer(model != "Normal" && zeros > 0)
    bind_cols(metadata, tibble(
      model = model, usable_rows = n, positive_rows = length(positive),
      zero_rows = zeros, zero_fraction = p0,
      zero_model = ifelse(model != "Normal" && zeros > 0,
                         "Separate zero probability", "Ordinary continuous"),
      empirical_probability = mean(x <= 5), fitted_probability = cdfs[[model]](5),
      difference_percentage_points = 100 * (cdfs[[model]](5) - mean(x <= 5)),
      # Do not rank a continuous normal likelihood against mixed likelihoods.
      AIC = if (comparable) -2 * mixture_loglik + 2 * parameter_count else NA_real_,
      AIC_comparable = comparable,
      maximum_CDF_gap = max(abs(empirical_right - right), abs(empirical_left - left)),
      probability_below_zero = if (model == "Normal") cdfs[[model]](0) else 0
    ))
  })) |>
    mutate(delta_AIC = AIC - min(AIC, na.rm = TRUE))

  parameters <- bind_rows(lapply(names(fits), function(model) {
    estimates <- fits[[model]]$estimate
    bind_cols(metadata[rep(1, length(estimates)), ], tibble(
      model = model, parameter = names(estimates), estimate = unname(estimates)
    ))
  }))
  curves <- bind_rows(lapply(names(cdfs), function(model) {
    # Include a point just below zero to display the mixture's jump at zero.
    plot_grid <- c(-0.000001, grid)
    bind_cols(metadata[rep(1, length(plot_grid)), ], tibble(
      Dissolved_Oxygen = plot_grid, probability = cdfs[[model]](plot_grid), model = model
    ))
  }))
  list(comparison = comparison, parameters = parameters, curves = curves)
}

top_fit_groups <- split(top_fit_data, top_fit_data$group_id)
top_fit_results <- lapply(top_fit_groups, fit_top_group)
top_distribution_comparison <- bind_rows(lapply(top_fit_results, `[[`, "comparison"))
top_distribution_parameters <- bind_rows(lapply(top_fit_results, `[[`, "parameters"))
top_distribution_curves <- bind_rows(lapply(top_fit_results, `[[`, "curves"))

top_distribution_probabilities <- top_distribution_comparison |>
  select(Sampling.Location, Measurement, Season, usable_rows, zero_rows,
         zero_fraction, empirical_probability, model, fitted_probability) |>
  pivot_wider(names_from = model, values_from = fitted_probability,
              names_prefix = "probability_")

top_distribution_ranking <- top_distribution_comparison |>
  group_by(Sampling.Location, Measurement, Season, aggregation) |>
  summarise(
    zero_rows = first(zero_rows),
    lowest_AIC_model = model[which.min(AIC)],
    models_within_2_AIC = paste(model[!is.na(delta_AIC) & delta_AIC < 2], collapse = ", "),
    .groups = "drop"
  )

export_table(top_distribution_comparison, "top_distribution_comparison",
  "Exploratory top-water distribution fits. AIC is only compared within a group; normal AIC is omitted where separate zero masses are used. CDF gaps are descriptive, not test p-values.")
export_table(top_distribution_parameters, "top_distribution_parameters",
  "Top-water maximum-likelihood parameters. Gamma uses shape and rate. Positive-component fits exclude zeros; zero fractions are retained in the comparison table.")
export_table(top_distribution_probabilities, "top_distribution_probabilities",
  "Top-water empirical and fitted probabilities of DO at or below 5 mg/L. Gamma and lognormal include separate observed zero fractions where present; normal is an ordinary continuous benchmark.")
export_table(top_distribution_ranking, "top_distribution_ranking",
  "Within-group exploratory AIC rankings. Normal is excluded from AIC ranking where zeros are modeled separately. Aggregated groups overlap and are not independent replications.")

plot_top_distribution_cdfs <- function(individual) {
  chosen <- top_distribution_ranking |>
    filter((aggregation == "Individual methods") == individual) |>
    mutate(panel = paste(Sampling.Location,
      recode(Measurement, Dissolved_Oxygen_CTD_top = "CTD top",
             Dissolved_Oxygen_winkler_top = "Winkler top"), Season, sep = " | ")) |>
    select(Sampling.Location, Measurement, Season, panel)
  keys <- c("Sampling.Location", "Measurement", "Season")
  ggplot() +
    stat_ecdf(data = inner_join(top_fit_data, chosen, by = keys),
      aes(x = Dissolved_Oxygen, color = "Empirical"), geom = "step", pad = FALSE) +
    geom_line(data = inner_join(top_distribution_curves, chosen, by = keys),
      aes(x = Dissolved_Oxygen, y = probability, color = model), linewidth = 0.65) +
    geom_vline(xintercept = 5, linetype = "dashed", color = "#888888") +
    facet_wrap(~panel, ncol = 3, scales = "free_x") +
    scale_color_manual(values = c(Empirical = "#222222", Normal = "#0072CE",
                                  Lognormal = "#B45B16", Gamma = "#528500")) +
    scale_y_continuous(limits = c(0, 1), labels = function(x) paste0(100 * x, "%")) +
    labs(title = if (individual) "Top-water distribution fits: individual methods"
         else "Top-water distribution fits: pooled readings",
         subtitle = "Empirical CDF and maximum-likelihood fits; dashed line marks 5 mg/L",
         x = "Dissolved oxygen (mg/L)", y = "Cumulative probability", color = NULL,
         caption = paste("Gamma/lognormal retain recorded zeros as a separate probability component.",
           "Normal is an ordinary continuous benchmark. In-sample comparison; repeated sampling is not modeled.", sep = "\n")) +
    theme_minimal(base_size = 11) +
    theme(legend.position = "top", strip.text = element_text(face = "bold"),
          panel.grid.minor = element_blank(), plot.caption = element_text(hjust = 0))
}

export_plot(plot_top_distribution_cdfs(TRUE), "top_distribution_individual_cdfs",
            width = 15, height = 14)
export_plot(plot_top_distribution_cdfs(FALSE), "top_distribution_pooled_cdfs",
            width = 15, height = 11)
print(top_distribution_probabilities, n = Inf, width = Inf)
print(top_distribution_ranking |> count(aggregation, lowest_AIC_model), n = Inf)
