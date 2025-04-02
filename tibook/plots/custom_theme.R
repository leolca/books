# Custom ggplot2 theme
custom_theme <- function() {
  theme(
    # Remove the full panel border (box) and use axis lines instead
    panel.border = element_blank(),
    axis.line = element_line(color = "black", linewidth = 0.5),
    
    # Ensure tick marks are visible
    axis.ticks = element_line(color = "black", linewidth = 0.5),
    
    # Remove grid lines
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    
    # Minimal background
    panel.background = element_blank(),
    
    # Optional: Customize text if desired (e.g., size, font)
    axis.text = element_text(size = 10, color = "black"),
    axis.title = element_text(size = 12, color = "black"),
    plot.title = element_text(size = 14, hjust = 0.5)
  )
}
