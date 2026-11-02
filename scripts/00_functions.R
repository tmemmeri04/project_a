skewness <- function(vec, na.rm = TRUE) {
  if (na.rm) {
    vec <- vec[!is.na(vec)]
  }
  
  mean_vec <- mean(vec)
  sd_vec <- sd(vec)
  skew <- (sum((vec-mean_vec)^3))/(length(vec)*sd_vec^3)
  
  return(skew)
}