# R script to estimate English entropy from a text file (e.g., ulysses.txt)
# Character-based and word-based entropy using plug-in, Laplace, Miller, and Laplace+Miller estimators

# Required libraries
library(stringr)

# Function to preprocess text
preprocess_text <- function(text) {
  # Convert to lowercase
  text <- tolower(text)
  # Replace all characters not in [a-z'-] with spaces
  text <- gsub("[^a-z'-]", " ", text)
  return(text)
}

# Function to compute plug-in entropy
plug_in_entropy <- function(prob) {
  # Filter out zero probabilities to avoid log(0)
  prob <- prob[prob > 0]
  entropy <- -sum(prob * log2(prob))
  return(entropy)
}

# Function to compute Laplace-smoothed probabilities
laplace_prob <- function(counts, total, alphabet_size) {
  (counts + 1) / (total + alphabet_size)
}

# Function to compute Miller estimator
miller_entropy <- function(plug_in, observed_symbols, sample_size) {
  plug_in + (observed_symbols - 1) / (2 * sample_size)
}

# Read text file (adjust path as needed)
file_path <- "ulysses.txt"  # Replace with actual path
text <- readLines(file_path, warn = FALSE)
text <- paste(text, collapse = " ")  # Combine lines into single string

# Preprocess text
text <- preprocess_text(text)

# --- Character-Based Entropy ---
# Split into characters
chars <- strsplit(text, "")[[1]]
chars <- chars[chars %in% c(letters, "'", "-")]  # Keep only [a-z'-]

# MLE probabilities
char_counts <- table(chars)
M <- length(chars)  # Sample size
char_prob_mle <- char_counts / M

# Plug-in entropy
char_entropy_plug_in <- plug_in_entropy(char_prob_mle)

# Laplace smoothing
alphabet_size <- 28  # 26 letters + ' + -
char_prob_laplace <- laplace_prob(char_counts, M, alphabet_size)
char_entropy_laplace <- plug_in_entropy(char_prob_laplace)

# Miller estimator (on MLE plug-in)
observed_symbols <- length(char_counts)  # Number of unique characters
char_entropy_miller <- miller_entropy(char_entropy_plug_in, observed_symbols, M)

# Laplace+Miller estimator
char_entropy_laplace_miller <- miller_entropy(char_entropy_laplace, observed_symbols, M)

# --- Word-Based Entropy ---
# Split into words
words <- strsplit(text, "\\s+")[[1]]
words <- words[words != ""]  # Remove empty words

# MLE probabilities
word_counts <- table(words)
M_words <- length(words)  # Number of words
word_prob_mle <- word_counts / M_words

# Expected word length
word_lengths <- nchar(names(word_counts))
expected_length <- sum(word_prob_mle * word_lengths)

# Plug-in word entropy
word_entropy_plug_in <- plug_in_entropy(word_prob_mle)

# Character entropy (word entropy / expected length)
char_entropy_word_plug_in <- word_entropy_plug_in / expected_length

# Laplace smoothing for words
word_alphabet_size <- length(word_counts)  # Assume observed words as alphabet
word_prob_laplace <- laplace_prob(word_counts, M_words, word_alphabet_size)
word_entropy_laplace <- plug_in_entropy(word_prob_laplace)
char_entropy_word_laplace <- word_entropy_laplace / expected_length

# Miller estimator for words (on MLE plug-in)
observed_words <- length(word_counts)
word_entropy_miller <- miller_entropy(word_entropy_plug_in, observed_words, M_words)
char_entropy_word_miller <- word_entropy_miller / expected_length

# Laplace+Miller estimator for words
word_entropy_laplace_miller <- miller_entropy(word_entropy_laplace, observed_words, M_words)
char_entropy_word_laplace_miller <- word_entropy_laplace_miller / expected_length

# Output results
cat("=== Character-Based Entropy (bits/char) ===\n")
cat(sprintf("Plug-in: %.4f\n", char_entropy_plug_in))
cat(sprintf("Laplace: %.4f\n", char_entropy_laplace))
cat(sprintf("Miller: %.4f\n", char_entropy_miller))
cat(sprintf("Laplace+Miller: %.4f\n", char_entropy_laplace_miller))
cat("\n=== Word-Based Entropy ===\n")
cat(sprintf("Expected word length: %.4f chars\n", expected_length))
cat(sprintf("Word entropy (plug-in): %.4f bits/word\n", word_entropy_plug_in))
cat(sprintf("Char entropy (plug-in): %.4f bits/char\n", char_entropy_word_plug_in))
cat(sprintf("Word entropy (Laplace): %.4f bits/word\n", word_entropy_laplace))
cat(sprintf("Char entropy (Laplace): %.4f bits/char\n", char_entropy_word_laplace))
cat(sprintf("Word entropy (Miller): %.4f bits/word\n", word_entropy_miller))
cat(sprintf("Char entropy (Miller): %.4f bits/char\n", char_entropy_word_miller))
cat(sprintf("Word entropy (Laplace+Miller): %.4f bits/word\n", word_entropy_laplace_miller))
cat(sprintf("Char entropy (Laplace+Miller): %.4f bits/char\n", char_entropy_word_laplace_miller))
