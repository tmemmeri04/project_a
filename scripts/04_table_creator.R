#~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!
# This script will create the table of histograms : - )

# ------------------------------------------------------------

library(ggplot2)

# Plot side-by-side panels
ggplot(long_data, aes(x = Dissolved_Oxygen, sample = Dissolved_Oxygen)) +
  geom_histogram( binwidth = 0.05 ) +
  facet_grid(Sampling.Location ~ Measurement) +
  theme_minimal() +
  labs(title = "Faceted Histograms of Dissolved Oxygen", x = "Dissolved Oxygen", y = "Count") 

ggplot(long_data, aes(sample = Dissolved_Oxygen)) +
  facet_grid(Sampling.Location ~ Measurement) +
  theme_minimal() +
  labs(title = "Faceted Q-Q of Dissolved Oxygen", x = "Dissolved Oxygen", y = "") +
  stat_qq() +
  stat_qq_line()

#log transform 
lnlong_data_DO <- log(long_data$Dissolved_Oxygen)
loglong_data <- long_data
loglong_data$Dissolved_Oxygen <- lnlong_data_DO


# Plotting lognormal
ggplot(loglong_data, aes(x = Dissolved_Oxygen)) +
  geom_histogram( binwidth = 0.05 ) +
  facet_grid(Sampling.Location ~ Measurement) +
  theme_minimal() +
  labs(title = "Faceted Histograms of Dissolved Oxygen", x = "Dissolved Oxygen", y = "Count")


ggplot(loglong_data, aes(sample = Dissolved_Oxygen)) +
  facet_grid(Sampling.Location ~ Measurement) +
  theme_minimal() +
  labs(title = "Faceted Q-Q of log(Dissolved Oxygen)", x = "Dissolved Oxygen", y = "") +
  stat_qq() +
  stat_qq_line()