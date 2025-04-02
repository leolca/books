# Load required libraries
library(ggplot2)
library(dplyr)
library(tidyr)

# Function to calculate entropy
calculate_entropy <- function(probs) {
  -sum(probs[probs > 0] * log2(probs[probs > 0]))
}

# Read and process the text file
process_text <- function(file_path) {
  # Read the text file
  text <- tolower(readLines(file_path, warn = FALSE))
  text <- paste(text, collapse = "")
  
  # Get individual characters
  chars <- strsplit(text, "")[[1]]
  chars <- chars[chars %in% letters]  # Keep only a-z
  
  # Calculate single character probabilities
  char_counts <- table(chars)
  total_chars <- sum(char_counts)
  char_probs <- char_counts / total_chars
  
  # Calculate single character entropy
  single_entropy <- calculate_entropy(char_probs)
  
  # Create character pairs
  pairs <- paste0(chars[1:(length(chars)-1)], chars[2:length(chars)])
  pairs <- pairs[grepl("^[a-z]{2}$", pairs)]  # Keep only pairs of letters
  
  # Calculate joint probabilities
  pair_counts <- table(pairs)
  total_pairs <- sum(pair_counts)
  pair_probs <- pair_counts / total_pairs
  
  # Calculate joint entropy
  joint_entropy <- calculate_entropy(pair_probs)
  
  # Create data frame for plotting
  pair_df <- as.data.frame(pair_probs) %>%
    rename(pair = pairs, probability = Freq) %>%
    mutate(char1 = substr(pair, 1, 1),
           char2 = substr(pair, 2, 2))
  
  # Plot using ggplot2
  p <- ggplot(pair_df, aes(x = char1, y = char2, fill = probability)) +
    geom_tile() +
    scale_fill_gradient(low = "white", high = "darkblue",
                       name = "Joint Probability") +
    theme_minimal() +
    labs(title = "Joint Probability of Character Pairs",
         x = "First Character",
         y = "Second Character",
         caption = paste("Single Character Entropy:", round(single_entropy, 4),
                        "\nJoint Entropy:", round(joint_entropy, 4))) +
    theme(legend.position = "right",
          plot.title = element_text(hjust = 0.5),
          panel.grid = element_blank()) +
    guides(fill = guide_colorbar(title = "Joint Probability"))
  
  # Print results
  cat("Single Character Probabilities:\n")
  print(char_probs)
  cat("\nSingle Character Entropy:", single_entropy, "\n")
  cat("Joint Entropy:", joint_entropy, "\n")
  
  # Return the plot
  return(p)
}

# Example usage
# Replace "your_file.txt" with your actual file path
file_path <- "/tmp/text.txt"
plot <- process_text(file_path)
print(plot)

# Save the plot if desired
# ggsave("joint_probability_plot.png", plot, width = 10, height = 8, dpi = 300)
# Save as PDF at 7x7 inches
ggsave("joint_probability.pdf", plot = plot, width = 7, height = 7, device = "pdf")
