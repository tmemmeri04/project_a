# Run from the project root: Rscript --vanilla tests/check_sample_matching.R
source('scripts/00_functions.R')

make_events <- function(sites, times) {
  tibble::tibble(
    Sample.Date = as.Date('2020-07-01'), Measurement = 'test_measurement',
    Sampling.Location = sites, Sample.Time = readr::parse_time(times),
    Dissolved_Oxygen = rep(4, length(sites))
  )
}

# Inclusive boundary; zero is a usable observation.
boundary <- make_events(c('NC1', 'NC2', 'NC3'), c('10:00:00', '10:15:00', '10:30:00'))
boundary$Dissolved_Oxygen[1] <- 0
stopifnot(nrow(match_sampling_times(boundary, 30)) == 1,
          nrow(match_sampling_times(boundary, 29)) == 0)

# The window limits earliest-to-latest span, not distance from NC1 alone.
wide <- make_events(c('NC1', 'NC2', 'NC3'), c('10:30:00', '10:00:00', '11:00:00'))
stopifnot(nrow(match_sampling_times(wide, 30)) == 0,
          nrow(match_sampling_times(wide, 60)) == 1)

# Skip an unmatched early visit rather than shifting all subsequent matches.
extra_visit <- make_events(c('NC1', 'NC1', 'NC2', 'NC3'),
                          c('08:00:00', '10:00:00', '10:10:00', '10:20:00'))
matched <- match_sampling_times(extra_visit, 30)
stopifnot(nrow(matched) == 1, matched$observation_id_NC1 == 2)

# No observation can participate in two events, even with repeated timestamps.
repeated <- make_events(c('NC1', 'NC1', 'NC2', 'NC3'),
                       c('10:00:00', '10:00:00', '10:10:00', '10:20:00'))
stopifnot(nrow(match_sampling_times(repeated, 30)) == 1)

# Unknown times/missing DO cannot form complete events; dates/methods never mix.
missing_time <- boundary; missing_time$Sample.Time[1] <- NA
missing_do <- boundary; missing_do$Dissolved_Oxygen[1] <- NA_real_
other_date <- boundary; other_date$Sample.Date[1] <- as.Date('2020-07-02')
other_method <- boundary; other_method$Measurement[1] <- 'another_measurement'
for (events in list(missing_time, missing_do, other_date, other_method)) {
  stopifnot(nrow(match_sampling_times(events, 30)) == 0)
}
all_missing <- boundary; all_missing$Sample.Time[] <- NA
stopifnot(nrow(match_sampling_times(all_missing, 30)) == 0)
cat('PASS: window boundaries, complete-event requirements, no reuse, extra visits, date/method separation.\n')
