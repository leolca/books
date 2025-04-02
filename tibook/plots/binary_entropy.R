# Load required library
library(ggplot2)

# Source the custom theme
source("custom_theme.R")

# Create data frame with probability values from 0 to 1
p <- seq(0, 1, by = 0.01)
entropy <- - (p * log2(p) + (1-p) * log2(1-p))
entropy[is.nan(entropy)] <- 0  # Replace NaN at boundaries with 0
data <- data.frame(p = p, entropy = entropy)

# Create the plot
plot <- ggplot(data, aes(x = p, y = entropy)) +
  geom_line(color = "black", linewidth = 1) +
  labs(
    x = expression("Probabilidade (" * theta * ")"),
    y = "Entropia (bits)"
  ) +
  custom_theme() +
  theme(
    aspect.ratio = 1  # Ensures the plotting area is square
  ) +
  scale_x_continuous(breaks = seq(0, 1, 0.2)) +
  scale_y_continuous(breaks = seq(0, 1, 0.2)) +
  coord_fixed(ratio = 1)  # Ensures 1:1 mapping of data units

# Save as PDF at 7x7 inches
ggsave("binary_entropy.pdf", plot = plot, width = 7, height = 7, device = "pdf")
