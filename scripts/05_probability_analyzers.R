
# sort by winter and summer seasons
seasonal_fractions <- long_data |> 
    filter(Season %in% c("Summer", "Winter")) |>
    group_by(Sampling.Location, Measurement, Season) |>
    summarize(
        nonmissing_rows = sum(!is.na(Dissolved_Oxygen)),
        low_oxygen_rows = sum(Dissolved_Oxygen <= 5, na.rm = TRUE),
        fraction = ifelse(
            nonmissing_rows >0,
            low_oxygen_rows / nonmissing_rows,
            NA_real_
        ),
        .groups = "drop"
    )
    
ggplot2::ggplot(seasonal_fractions, aes(x=Sampling.Location, y=fraction)) +
    geom_point(aes(color=Season), size=3) +
    facet_wrap(~Measurement) +
    labs(
        title = "Fraction of Low Oxygen Measurements by Location and Season",
        x = "Sampling Location",
        y = "Fraction of Measurements <= 5 mg/L"
    ) +
    theme_minimal()