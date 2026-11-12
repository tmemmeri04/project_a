# Match chronological, nonoverlapping triplets within each date/measurement.
# If the earliest triplet spans too long, discard its earliest observation:
# it cannot match the later observations currently available at the other sites.
match_sampling_times <- function(data, max_span_minutes) {
  stopifnot(length(max_span_minutes) == 1, is.finite(max_span_minutes), max_span_minutes >= 0)
  eligible <- data |>
    dplyr::ungroup() |>
    dplyr::mutate(observation_id = seq_len(nrow(data))) |>
    dplyr::filter(
      Sampling.Location %in% c("NC1", "NC2", "NC3"),
      !is.na(Sample.Date), !is.na(Sample.Time), !is.na(Dissolved_Oxygen)
    )

  match_one_day <- function(day_data) {
    matches <- tibble::tibble(
      sample_round = integer(), NC1 = double(), NC2 = double(), NC3 = double(),
      time_NC1 = character(), time_NC2 = character(), time_NC3 = character(),
      observation_id_NC1 = integer(), observation_id_NC2 = integer(),
      observation_id_NC3 = integer(), span_minutes = double()
    )
    site_data <- lapply(c("NC1", "NC2", "NC3"), function(site) {
      observations <- day_data[day_data$Sampling.Location == site, ]
      observations[order(observations$Sample.Time, observations$observation_id), ]
    })
    positions <- c(1L, 1L, 1L)
    site_sizes <- vapply(site_data, nrow, integer(1))
    while (all(positions <= site_sizes)) {
      times <- vapply(seq_len(3), function(site) {
        as.numeric(site_data[[site]]$Sample.Time[positions[site]], units = "secs")
      }, numeric(1))
      span_minutes <- (max(times) - min(times)) / 60
      if (span_minutes <= max_span_minutes) {
        selected <- lapply(seq_len(3), function(site) site_data[[site]][positions[site], ])
        matches <- dplyr::bind_rows(matches, tibble::tibble(
          sample_round = nrow(matches) + 1L,
          NC1 = selected[[1]]$Dissolved_Oxygen,
          NC2 = selected[[2]]$Dissolved_Oxygen,
          NC3 = selected[[3]]$Dissolved_Oxygen,
          time_NC1 = as.character(selected[[1]]$Sample.Time),
          time_NC2 = as.character(selected[[2]]$Sample.Time),
          time_NC3 = as.character(selected[[3]]$Sample.Time),
          observation_id_NC1 = selected[[1]]$observation_id,
          observation_id_NC2 = selected[[2]]$observation_id,
          observation_id_NC3 = selected[[3]]$observation_id,
          span_minutes = span_minutes
        ))
        positions <- positions + 1L
      } else {
        earliest_site <- which.min(times)
        positions[earliest_site] <- positions[earliest_site] + 1L
      }
    }
    matches
  }

  eligible |>
    dplyr::group_by(Sample.Date, Measurement) |>
    dplyr::group_modify(~ match_one_day(.x)) |>
    dplyr::ungroup()
}
