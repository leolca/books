library(ggplot2)
library(dplyr)
library(tidyr)

# Função para calcular a divergência de KL com suavização de Laplace
kl_divergence <- function(counts, n, alphabet_size = 26) {
  # Suavização de Laplace
  probs <- (counts + 1) / (n + alphabet_size)
  uniform_prob <- 1 / alphabet_size
  # D_KL(P || Q) = sum P(x) log(P(x) / Q(x))
  kl <- sum(probs * log2(probs / uniform_prob), na.rm = TRUE)
  return(kl)
}

# Ler dados
ulysses <- read.csv("ulysses_processed.csv")$char
urandom <- read.csv("urandom_processed.csv")$char

# Tamanhos das amostras
#sample_sizes <- c(100, 1000, 10000, 100000)
sample_sizes <- 10^seq(2,6,length.out = 25)

# Calcular distribuições e KL para cada tamanho de amostra
results <- data.frame()
hist_data <- data.frame()

# Tamanhos para histogramas
hist_sizes <- c(100, 1000, 10000, 1000000)

for (n in sample_sizes) {
  # Ulysses
  ulysses_sample <- ulysses[1:min(n, length(ulysses))]
  ulysses_counts <- table(factor(ulysses_sample, levels = letters))
  ulysses_kl <- kl_divergence(ulysses_counts, min(n, length(ulysses)))
  
  # /dev/urandom
  urandom_sample <- urandom[1:min(n, length(urandom))]
  urandom_counts <- table(factor(urandom_sample, levels = letters))
  urandom_kl <- kl_divergence(urandom_counts, min(n, length(urandom)))
  
  # Armazenar resultados
  results <- rbind(results, 
                   data.frame(Source = "Ulysses", n = n, KL = ulysses_kl),
                   data.frame(Source = "/dev/urandom", n = n, KL = urandom_kl))
  
  # Dados para histogramas (apenas para hist_sizes, normalizado por n)
  if (n %in% hist_sizes) {
    hist_data <- rbind(hist_data,
                       data.frame(Source = "Ulysses", n = n, Letter = letters, 
                                  Prob = as.numeric(ulysses_counts) / min(n, length(ulysses))),
                       data.frame(Source = "/dev/urandom", n = n, Letter = letters, 
                                  Prob = as.numeric(urandom_counts) / min(n, length(urandom))))
  }
}

# Plotar histogramas
hist_plot <- ggplot(hist_data, aes(x = Letter, y = Prob, fill = Source)) +
  geom_bar(stat = "identity", position = "dodge") +
  facet_grid(Source ~ factor(n, levels = hist_sizes, labels = paste("n =", hist_sizes))) +
  theme_minimal() +
  labs(title = "Distribuição Empírica de Letras (MLE)", x = "Letra", y = "Probabilidade Estimada") +
  scale_fill_manual(values = c("Ulysses" = "blue", "/dev/urandom" = "red"))

# Plotar divergência de KL
kl_plot <- ggplot(results, aes(x = n, y = KL, color = Source)) +
  geom_line() +
  geom_point() +
  #scale_x_log10(breaks = sample_sizes, labels = sample_sizes) +
  scale_x_log10(breaks = c(100, 1000, 10000, 100000, 1000000), 
                labels = c("100", "1000", "10000", "100000", "1000000")) + 
  theme_minimal() +
  labs(title = "Divergência de KL em Função do Tamanho da Amostra",
       x = "Tamanho da Amostra (n)", y = "D(p||q)") +
  scale_color_manual(values = c("Ulysses" = "blue", "/dev/urandom" = "red"))

# Salvar gráficos
ggsave("hist_ulysses.pdf", plot = hist_plot %+% subset(hist_data, Source == "Ulysses"), width = 10, height = 4)
ggsave("hist_urandom.pdf", plot = hist_plot %+% subset(hist_data, Source == "/dev/urandom"), width = 10, height = 4)
ggsave("kld_plot.pdf", plot = kl_plot, width = 6, height = 4)

# Exibir resultados
print(results)
