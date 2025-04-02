# Load required library
library(ggplot2)

# Create a sequence of z values (avoiding z <= 0 since ln is undefined there)
z <- seq(0.01, 3, by = 0.01)

# Calculate the two functions
ln_z <- log(z)  # natural log in R is log()
z_minus_1 <- z - 1

# Create data frame for plotting
data <- data.frame(z = z, ln_z = ln_z, z_minus_1 = z_minus_1)

# Create the base plot
p <- ggplot(data, aes(x = z)) +
  geom_line(aes(y = ln_z, color = "ln(z)"), linewidth = 1) +
  geom_line(aes(y = z_minus_1, color = "z - 1"), linewidth = 1) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray50") +
  labs(x = "z",
       y = "f(z)",
       color = "função") +
  scale_color_manual(values = c("ln(z)" = "#0072B2", "z - 1" = "#D55E00"))

# Apply theme separately
p <- p + theme_minimal() +
  theme(
    plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
    axis.title = element_text(size = 12),
    axis.text = element_text(size = 10),
    legend.position = "top",
    legend.title = element_text(size = 11),
    legend.text = element_text(size = 10),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(color = "gray90")
  )

# Display the plot
print(p)

# Save the plot (optional)
# ggsave("inequality_plot.png", plot = p, width = 8, height = 6, dpi = 300)

# Save as PDF at 7x7 inches
ggsave("lnzzm1.pdf", plot = p, width = 7, height = 7, device = "pdf")
