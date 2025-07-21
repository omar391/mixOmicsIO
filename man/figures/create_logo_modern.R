
# Load necessary libraries
library(ggplot2)
library(ggforce)
library(showtext)

# It's good practice to check if the font is already loaded
font_add_google("Poppins", "poppins")
showtext_auto()

# Define a modern color palette
colors <- c("#4A90E2", "#D0021B")

# Create data for two overlapping hexagons
hex_data <- data.frame(
  x = c(0, 1, 1, 0, -1, -1, 0.8, 1.8, 1.8, 0.8, -0.2, -0.2),
  y = c(1.15, 0.58, -0.58, -1.15, -0.58, 0.58, 1.15, 0.58, -0.58, -1.15, -0.58, 0.58),
  group = rep(c("A", "B"), each = 6)
)

# Create the plot
p <- ggplot() +
  # Hexagon for SummarizedExperiment
  geom_shape(data = subset(hex_data, group == 'A'),
             aes(x = x, y = y),
             fill = colors[1], alpha = 0.7, radius = unit(0.1, 'cm')) +
  # Hexagon for mixOmics
  geom_shape(data = subset(hex_data, group == 'B'),
             aes(x = x, y = y),
             fill = colors[2], alpha = 0.7, radius = unit(0.1, 'cm')) +
  # Text for the package name
  annotate("text", x = 0.4, y = 0, label = "mixOmicsIO",
           family = "poppins", size = 14, color = "white", fontface = "bold") +
  # Text for the components
  annotate("text", x = -0.5, y = 0, label = "SE", family = "poppins", size = 10, color = "white", alpha = 0.9) +
  annotate("text", x = 1.3, y = 0, label = "MO", family = "poppins", size = 10, color = "white", alpha = 0.9) +
  theme_void() +
  theme(
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  )

# Save the plot
ggsave(
  filename = "/Volumes/Projects/business/AstronLab/omar391/research/mixOmicsIO/man/figures/logo_modern.png",
  plot = p,
  width = 6,
  height = 3,
  dpi = 300,
  bg = "transparent"
)

cat("Modern logo created successfully at man/figures/logo_modern.png\n")
