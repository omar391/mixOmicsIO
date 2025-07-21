#!/usr/bin/env Rscript
# Basic Workflow Example - mixOmicsIO Package
# Demonstrates fundamental conversion between SummarizedExperiment and mixOmics

# Load required libraries
library(mixOmicsIO)
library(SummarizedExperiment)
library(mixOmics)

cat("=== mixOmicsIO Basic Workflow Example ===\n\n")

# Generate synthetic data that mimics gene expression
set.seed(123)
n_samples <- 40
n_genes <- 200

# Create synthetic count data with realistic patterns
counts <- matrix(
  rnbinom(n_genes * n_samples, mu = 100, size = 10),
  nrow = n_genes, 
  ncol = n_samples,
  dimnames = list(
    genes = paste0("Gene_", 1:n_genes),
    samples = paste0("Sample_", 1:n_samples)
  )
)

# Add some differential expression between groups
group_indicator <- rep(c("Control", "Treatment"), each = n_samples/2)
# Make genes 1-50 differentially expressed
diff_genes_idx <- 1:50
for (i in diff_genes_idx) {
  treatment_samples <- which(group_indicator == "Treatment")
  # Increase expression in treatment group
  counts[i, treatment_samples] <- counts[i, treatment_samples] * 2
}

# Create sample metadata
col_data <- DataFrame(
  group = factor(group_indicator),
  batch = factor(rep(1:4, each = 10)),
  age = rnorm(n_samples, mean = 45, sd = 10),
  row.names = colnames(counts)
)

# Create gene metadata
row_data <- DataFrame(
  gene_type = sample(c("protein_coding", "lncRNA", "miRNA"), n_genes, replace = TRUE),
  chromosome = sample(paste0("chr", 1:22), n_genes, replace = TRUE),
  is_differential = 1:n_genes %in% diff_genes_idx,
  row.names = rownames(counts)
)

# Create SummarizedExperiment object
se <- SummarizedExperiment(
  assays = list(counts = counts),
  colData = col_data,
  rowData = row_data
)

cat("Created SummarizedExperiment with:\n")
cat("- ", nrow(se), " genes\n")
cat("- ", ncol(se), " samples\n")
cat("- Groups: ", paste(unique(se$group), collapse = ", "), "\n\n")

# === STEP 1: Convert SE to mixOmics format ===
cat("STEP 1: Converting SummarizedExperiment to mixOmics format...\n")

mixomics_data <- se_to_mixomics(
  se_object = se,
  assay_name = "counts", 
  design_variable = "group"
)

cat("Conversion successful!\n")
cat("- Data matrix X: ", dim(mixomics_data$X)[1], " samples × ", dim(mixomics_data$X)[2], " features\n")
cat("- Response vector Y: ", length(mixomics_data$Y), " samples with levels: ", paste(levels(mixomics_data$Y), collapse = ", "), "\n\n")

# === STEP 2: Perform mixOmics analysis ===
cat("STEP 2: Performing PLS-DA analysis with mixOmics...\n")

# Run PLS-DA analysis
plsda_result <- plsda(
  X = mixomics_data$X, 
  Y = mixomics_data$Y, 
  ncomp = 2
)

cat("PLS-DA analysis complete!\n")
cat("- Components: ", plsda_result$ncomp, "\n")
cat("- Features per component: ", nrow(plsda_result$loadings$X), "\n\n")

# === STEP 3: Integrate results back to SE ===
cat("STEP 3: Integrating mixOmics results back to SummarizedExperiment...\n")

se_with_results <- mixomics_to_se(
  mixomics_result = plsda_result,
  original_se = se
)

cat("Integration successful!\n")
cat("- Original SE preserved: ", identical(assay(se), assay(se_with_results)), "\n")
cat("- Results stored in metadata: ", "mixomics_result" %in% names(metadata(se_with_results)), "\n")
cat("- Additional rowData columns: ", ncol(rowData(se_with_results)) - ncol(rowData(se)), "\n\n")

# === STEP 4: Verify roundtrip integrity ===
cat("STEP 4: Verifying data integrity through conversion roundtrip...\n")

# Convert back to mixOmics format
roundtrip_data <- se_to_mixomics(
  se_object = se_with_results,
  assay_name = "counts",
  design_variable = "group"
)

# Check if data is identical
data_identical <- identical(mixomics_data$X, roundtrip_data$X)
response_identical <- identical(mixomics_data$Y, roundtrip_data$Y)

cat("Roundtrip validation:\n")
cat("- Data matrix preserved: ", data_identical, "\n")
cat("- Response vector preserved: ", response_identical, "\n\n")

# === STEP 5: Access and display results ===
cat("STEP 5: Accessing stored results...\n")

# Get the stored mixOmics result
stored_result <- metadata(se_with_results)$mixomics_result

# Show some key results
cat("Top 10 features by loading magnitude (Component 1):\n")
loadings_comp1 <- abs(stored_result$loadings$X[, 1])
top_features <- names(sort(loadings_comp1, decreasing = TRUE))[1:10]
for (i in 1:10) {
  feature_name <- top_features[i]
  loading_value <- stored_result$loadings$X[feature_name, 1]
  cat(sprintf("  %s: %.3f\n", feature_name, loading_value))
}

cat("\n=== Basic Workflow Example Complete! ===\n")
cat("This example demonstrated:\n")
cat("✓ SE → mixOmics conversion\n") 
cat("✓ mixOmics PLS-DA analysis\n")
cat("✓ Result integration back to SE\n")
cat("✓ Data integrity validation\n")
cat("✓ Result access and interpretation\n\n")
