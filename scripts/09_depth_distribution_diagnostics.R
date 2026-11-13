# Run after scripts 07 and 08. Use their same 20 groupings at each depth.
library(dplyr)
library(ggplot2)

depth_distribution_diagnostics <- function(depth, probability_table) {
  keys <- c("Sampling.Location", "Measurement", "Season")
  combined_label <- paste("Combined", depth, "methods")
  method_data <- long_data |>
    filter(Season %in% c("Summer", "Winter"), Measurement %in% c(
      paste0("Dissolved_Oxygen_CTD_", depth),
      paste0("Dissolved_Oxygen_winkler_", depth)
    ))

  # Pool the underlying readings, using exactly the probability-table groupings.
  grouped_data <- bind_rows(
    method_data,
    method_data |> mutate(Measurement = combined_label),
    method_data |> mutate(Sampling.Location = "All sites", Measurement = combined_label)
  )
  group_labels <- probability_table |>
    select(all_of(keys)) |>
    mutate(
      panel = paste(Sampling.Location,
        case_when(
          grepl("CTD", Measurement) ~ "CTD",
          grepl("winkler", Measurement) ~ "Winkler",
          TRUE ~ "Both methods"
        ), Season, sep = " | "),
      panel = factor(panel, levels = panel)
    )
  grouped_data <- grouped_data |> left_join(group_labels, by = keys)
  usable_data <- grouped_data |> filter(!is.na(Dissolved_Oxygen))
  positive_data <- usable_data |> filter(Dissolved_Oxygen > 0)

  run_ad <- function(values) {
    values <- values[!is.na(values)]
    if (length(values) < 8 || sd(values) == 0) {
      return(tibble(usable_rows = length(values), A = NA_real_, p_value = NA_real_,
                    pass_fail = "Not tested"))
    }
    test <- nortest::ad.test(values)
    tibble(usable_rows = length(values), A = unname(test$statistic),
           p_value = test$p.value,
           pass_fail = ifelse(test$p.value > 0.05, "Pass", "Fail"))
  }

  ranges <- usable_data |>
    group_by(across(all_of(keys))) |>
    summarise(minimum = min(Dissolved_Oxygen), maximum = max(Dissolved_Oxygen),
              zero_rows = sum(Dissolved_Oxygen == 0), .groups = "drop")
  normal_results <- usable_data |>
    group_by(across(all_of(keys))) |>
    group_modify(~run_ad(.x$Dissolved_Oxygen)) |>
    ungroup() |>
    left_join(ranges, by = keys)
  lognormal_results <- positive_data |>
    group_by(across(all_of(keys))) |>
    group_modify(~run_ad(log(.x$Dissolved_Oxygen))) |>
    ungroup() |>
    left_join(ranges |> select(all_of(keys), excluded_zero_rows = zero_rows), by = keys)

  # Script 06's comparison: only groups with no recorded zeros.
  comparison <- ranges |>
    filter(minimum > 0) |>
    left_join(normal_results |>
      select(all_of(keys), normal_test = pass_fail), by = keys) |>
    left_join(lognormal_results |>
      select(all_of(keys), lognormal_test = pass_fail), by = keys)

  # Preserve the 12 + 6 + 2 ordering used by each probability table.
  normal_results <- group_labels |> select(all_of(keys)) |>
    left_join(normal_results, by = keys)
  lognormal_results <- group_labels |> select(all_of(keys)) |>
    left_join(lognormal_results, by = keys)
  comparison <- group_labels |> select(all_of(keys)) |>
    inner_join(comparison, by = keys)

  export_table(normal_results, paste0(depth, "_normality_results"),
    paste("Anderson-Darling normality tests for", depth,
      "DO in the 20 probability-table groups. Zeros retained. Pass means failure to reject at 0.05, not proof of normality. Group dependence and multiplicity are not adjusted."))
  export_table(lognormal_results, paste0(depth, "_lognormality_results"),
    paste("Anderson-Darling normality tests of logged positive", depth,
      "DO in the 20 probability-table groups. Zeros excluded from this diagnostic only. Pass means failure to reject at 0.05. Group dependence and multiplicity are not adjusted."))
  export_table(comparison, paste0(depth, "_distribution_test_comparison"),
    paste("Normal and lognormal AD labels for zero-free", depth,
      "probability-table groups. Pass means failure to reject at 0.05, not proof of the model."))

  make_histograms <- function(logged = FALSE) {
    data <- if (logged) positive_data else usable_data
    if (logged) data <- data |> mutate(Dissolved_Oxygen = log(Dissolved_Oxygen))
    counts <- data |> count(panel, name = "sample_size")
    ggplot(data, aes(x = Dissolved_Oxygen, fill = Season)) +
      geom_histogram(binwidth = if (logged) 0.2 else 0.5, boundary = 0,
        closed = "left", color = "white", linewidth = 0.2) +
      geom_vline(xintercept = if (logged) log(5) else 5,
        linetype = "dashed", color = "#a0473b", linewidth = 0.5) +
      geom_text(data = counts, aes(x = Inf, y = Inf, label = paste0("n = ", sample_size)),
        inherit.aes = FALSE, hjust = 1.1, vjust = 1.5, size = 3, color = "#52616b") +
      facet_wrap(~panel, ncol = 4, scales = "free_y") +
      scale_fill_manual(values = c(Summer = "#78BE20", Winter = "#0072CE")) +
      scale_y_continuous(expand = expansion(mult = c(0, 0.18))) +
      histogram_theme +
      theme(strip.text = element_text(size = 10)) +
      labs(
        title = paste(if (logged) "Log DO:" else "Dissolved oxygen:", depth, "water"),
        subtitle = paste(
          "Same 20 groups as the probability table; shared x-axis, separate count axes",
          if (logged) "Positive readings only; 0.2 log-unit bins; dashed line marks DO = 5 mg/L"
          else "Zeros retained; 0.5 mg/L bins; dashed line marks DO = 5 mg/L", sep = "\n"),
        x = if (logged) "ln(DO / (1 mg/L))" else "Dissolved oxygen (mg/L)",
        y = "Number of observations",
        caption = "Pooled panels reuse readings from individual panels; groups overlap."
      )
  }

  histograms <- make_histograms()
  log_histograms <- make_histograms(TRUE)
  export_plot(histograms, paste0(depth, "_grouped_histograms"), width = 16, height = 15)
  export_plot(log_histograms, paste0(depth, "_grouped_positive_log_histograms"),
              width = 16, height = 15)
  print(comparison, n = Inf, width = Inf)
  list(grouped_data = grouped_data, normality_results = normal_results,
       lognormality_results = lognormal_results, comparison = comparison,
       histograms = histograms, log_histograms = log_histograms)
}

top_distribution_diagnostics <- depth_distribution_diagnostics("top", top_seasonal_probabilities)
bottom_distribution_diagnostics <- depth_distribution_diagnostics("bottom", bottom_seasonal_probabilities)

top_normality_results <- top_distribution_diagnostics$normality_results
top_lognormality_results <- top_distribution_diagnostics$lognormality_results
top_distribution_test_comparison <- top_distribution_diagnostics$comparison
bottom_normality_results <- bottom_distribution_diagnostics$normality_results
bottom_lognormality_results <- bottom_distribution_diagnostics$lognormality_results
bottom_distribution_test_comparison <- bottom_distribution_diagnostics$comparison
