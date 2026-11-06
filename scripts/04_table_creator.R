#~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!
# This script will create the table of histograms : - )

# ------------------------------------------------------------

library(ggplot2)

#log transform 
lnlong_data_DO <- log(long_data$Dissolved_Oxygen)
loglong_data <- long_data
loglong_data$Dissolved_Oxygen <- lnlong_data_DO


# plotting histograms of original data
ggplot(long_data, aes(x = Dissolved_Oxygen, sample = Dissolved_Oxygen)) +
  geom_histogram( binwidth = 0.05 ) +
  facet_grid(Sampling.Location ~ Measurement) +
  theme_minimal() +
  labs(title = "Faceted Histograms of Dissolved Oxygen", x = "Dissolved Oxygen", y = "Count") 

#Q-Q plot of original data
ggplot(long_data, aes(sample = Dissolved_Oxygen)) +
  facet_grid(Sampling.Location ~ Measurement) +
  theme_minimal() +
  labs(title = "Faceted Histograms of Dissolved Oxygen", x = "Dissolved Oxygen", y = "Count") +
  stat_qq() +
  stat_qq_line()


# Plotting logtransformed 
ggplot(loglong_data, aes(x = Dissolved_Oxygen)) +
  geom_histogram( binwidth = 0.05 ) +
  facet_grid(Sampling.Location ~ Measurement) +
  theme_minimal() +
  labs(title = "Faceted Histograms of Dissolved Oxygen", x = "Dissolved Oxygen", y = "Count")

#Q-Q logtransformed
ggplot(loglong_data, aes(sample = Dissolved_Oxygen)) +
  facet_grid(Sampling.Location ~ Measurement) +
  theme_minimal() +
  labs(title = "Faceted Histograms of Dissolved Oxygen", x = "Dissolved Oxygen", y = "Count") +
  stat_qq() +
  stat_qq_line()

ggplot(long_data, aes(x = Sample.Date, y = Dissolved_Oxygen)) +
  facet_grid(Sampling.Location ~ Measurement) +
  theme_minimal() +
  labs(title = "Dissolved Oxygen over time per location and method", x = "date", y = "Dissolved Oxygen") +
  geom_point() +
  geom_line()

filtered_long_data_NC1 <- filter(long_data, Sampling.Location == "NC1" & Measurement == "Dissolved_Oxygen_winkler_top")
ggplot(filtered_long_data_NC1, aes(x = Sample.Date, y = Dissolved_Oxygen)) +
  theme_minimal() +
  labs(title = "Dissolved Oxygen over time for NC1 with Winkler Top Method", x = "date", y = "Dissolved Oxygen") +
  geom_point() 

ggplot((filtered_long_data_NC1 |> filter(Sample.Date > "2010-01-01")), aes(x = Sample.Date, y = Dissolved_Oxygen)) +
  theme_minimal() +
  labs(title = "Dissolved Oxygen over time for NC1 with Winkler Top Method after 2010", x = "date", y = "Dissolved Oxygen") +
  geom_point()

  doublefiltered_long_data_NC1 <- filtered_long_data_NC1 |> filter(Sample.Date > "2010-01-01")
  lm(Dissolved_Oxygen ~ Sample.Date, data = doublefiltered_long_data_NC1)
  summary(lm(Dissolved_Oxygen ~ Sample.Date, data = doublefiltered_long_data_NC1))
  plot(doublefiltered_long_data_NC1$Sample.Date, doublefiltered_long_data_NC1$Dissolved_Oxygen)
  abline(lm(Dissolved_Oxygen ~ Sample.Date, data = doublefiltered_long_data_NC1), col = "red")