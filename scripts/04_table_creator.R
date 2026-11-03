#~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!
# This script will create the table of histograms : - )

# ------------------------------------------------------------

library(ggplot2)

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

#log transform 
lnlong_data_DO <- log(long_data$Dissolved_Oxygen)
loglong_data <- long_data
loglong_data$Dissolved_Oxygen <- lnlong_data_DO


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


