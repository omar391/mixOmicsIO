#!/usr/bin/env Rscript
# Multi-class Analysis Example - mixOmicsIO Package
# Demonstrates handling of multi-level categorical variables and sPLS-DA analysis

# Load required libraries
library(mixOmicsIO)
library(SummarizedExperiment)
library(mixOmics)

cat("=== mixOmicsIO Multi-class Analysis Example ===\n\n")

# Generate synthetic data with three groups
set.seed(456)
n_samples <- 60  # 20 per group
n_genes <- 300

# Create sample groups
groups <- rep(c("Healthy", "Stage1", "Stage2"), each = 20)

# Create synthetic count data
counts <- matrix(
  rnbinom(n_genes * n_samples, mu = 150, size = 8),
  nrow = n_genes, 
  ncol = n_samples,
  dimnames = list(
    genes = paste0("Gene_", 1:n_genes),
    samples = paste0("Sample_", 1:n_samples)
  )
)

# Add group-specific expression patterns
# Genes 1-75: Healthy-specific (higher in healthy)
healthy_genes <- 1:75
healthy_samples <- which(groups == "Healthy")
counts[healthy_genes, healthy_samples] <- counts[healthy_genes, healthy_samples] * 1.8

# Genes 76-150: Stage1-specific (higher in Stage1)
stage1_genes <- 76:150
stage1_samples <- which(groups == "Stage1")
counts[stage1_genes, stage1_samples] <- counts[stage1_genes, stage1_samples] * 1.6

# Genes 151-225: Stage2-specific (highest in Stage2)
stage2_genes <- 151:225
stage2_samples <- which(groups == "Stage2")
counts[stage2_genes, stage2_samples] <- counts[stage2_genes, stage2_samples] * 2.0

# Genes 226-300: Progressive pattern (Healthy < Stage1 < Stage2)
progressive_genes <- 226:300
for (i in progressive_genes) {
  counts[i, stage1_samples] <- counts[i, stage1_samples] * 1.3
  counts[i, stage2_samples] <- counts[i, stage2_samples] * 1.7
}

# Create comprehensive sample metadata
col_data <- DataFrame(
  condition = factor(groups, levels = c("Healthy", "Stage1", "Stage2")),
  batch = factor(rep(1:3, times = 20)),
  sex = factor(sample(c("M", "F"), n_samples, replace = TRUE)),
  age = c(
    rnorm(20, mean = 35, sd = 8),  # Healthy: younger
    rnorm(20, mean = 55, sd = 10), # Stage1: middle-aged  
    rnorm(20, mean = 65, sd = 12)  # Stage2: older
  ),
  severity_score = c(
    rep(0, 20),                    # Healthy: score 0
    rnorm(20, mean = 3, sd = 1),   # Stage1: mild symptoms
    rnorm(20, mean = 7, sd = 1.5)  # Stage2: severe symptoms
  ),
  row.names = colnames(counts)
)

# Create detailed gene metadata
row_data <- DataFrame(
  gene_type = sample(c("protein_coding", "lncRNA", "pseudogene"), n_genes, replace = TRUE, prob = c(0.7, 0.2, 0.1)),
  chromosome = sample(paste0("chr", 1:22), n_genes, replace = TRUE),
  pathway = sample(c("immune_response", "cell_cycle", "metabolism", "signaling", "other"), n_genes, replace = TRUE),
  expression_pattern = c(
    rep("healthy_specific", length(healthy_genes)),
    rep("stage1_specific", length(stage1_genes)),
    rep("stage2_specific", length(stage2_genes)),
    rep("progressive", length(progressive_genes)),
    rep("baseline", n_genes - length(c(healthy_genes, stage1_genes, stage2_genes, progressive_genes)))
  ),
  row.names = rownames(counts)
)

# Create SummarizedExperiment
se <- SummarizedExperiment(
  assays = list(counts = counts),
  colData = col_data,
  rowData = row_data
)

cat("Created SummarizedExperiment with:\n")
cat("- ", nrow(se), " genes\n")
cat("- ", ncol(se), " samples across 3 conditions\n")
cat("- Conditions: ", paste(unique(se$condition), collapse = ", "), "\n")
cat("- Sample distribution: ")
cat(paste(names(table(se$condition)), "=", table(se$condition), collapse = ", "), "\n\n")

# === STEP 1: Convert to mixOmics format ===
cat("STEP 1: Converting to mixOmics format for multi-class analysis...\n")

mixomics_data <- se_to_mixomics(
  se_object = se,
  assay_name = "counts",
  design_variable = "condition"
)

cat("Conversion successful!\n")
cat("- Data matrix: ", dim(mixomics_data$X)[1], " samples × ", dim(mixomics_data$X)[2], " features\n")
cat("- Multi-class response: ", length(levels(mixomics_data$Y)), " levels (", paste(levels(mixomics_data$Y), collapse = ", "), ")\n\n")

# === STEP 2: Perform sPLS-DA with feature selection ===
cat("STEP 2: Performing sparse PLS-DA (sPLS-DA) analysis...\n")

# First, run PLS-DA to determine optimal number of components
plsda_result <- plsda(
  X = mixomics_data$X,
  Y = mixomics_data$Y,
  ncomp = 5  # Test up to 5 components
)

# Perform cross-validation to select components
cat("Running cross-validation to select optimal components...\n")
cv_result <- perf(
  plsda_result, 
  validation = "Mfold", 
  folds = 3, 
  nrepeat = 5,
  progressBar = FALSE
)

# Select optimal number of components (based on overall error rate)
optimal_ncomp <- cv_result$choice.ncomp$WeightedVote["Overall.ER", "centroids.dist"]
cat("Optimal number of components: ", optimal_ncomp, "\n\n")

# Run sPLS-DA with feature selection
cat("Running sPLS-DA with feature selection...\n")
splsda_result <- splsda(
  X = mixomics_data$X,
  Y = mixomics_data$Y,
  ncomp = optimal_ncomp,
  keepX = c(50, 30)  # Select top 50 and 30 features for components 1 and 2
)

cat("sPLS-DA analysis complete!\n")
cat("- Components: ", splsda_result$ncomp, "\n")
cat("- Selected features per component: ", paste(splsda_result$keepX, collapse = ", "), "\n\n")

# === STEP 3: Integrate results back to SE ===
cat("STEP 3: Integrating sPLS-DA results back to SummarizedExperiment...\n")

se_with_results <- mixomics_to_se(
  mixomics_result = splsda_result,
  original_se = se
)

cat("Integration successful!\n")
cat("- Results stored in metadata\n")
cat("- Feature loadings added to rowData\n\n")

# === STEP 4: Analyze variable importance ===
cat("STEP 4: Analyzing variable importance and feature selection...\n")

# Get variable importance
vip_scores <- vip(splsda_result)

# Show top features for each component
for (comp in 1:splsda_result$ncomp) {
  cat(sprintf("\nTop 10 most important features - Component %d:\n", comp))
  
  # Get VIP scores for this component
  comp_vip <- vip_scores[, comp]
  top_features <- names(sort(comp_vip, decreasing = TRUE))[1:10]
  
  for (i in 1:10) {
    feature_name <- top_features[i]
    vip_score <- comp_vip[feature_name]
    pattern <- row_data[feature_name, "expression_pattern"]
    cat(sprintf("  %s: VIP=%.3f (%s)\n", feature_name, vip_score, pattern))
  }
}

# === STEP 5: Examine group separation ===
cat("\n\nSTEP 5: Examining group separation in component space...\n")

# Get sample projections
sample_projections <- splsda_result$variates$X

# Calculate group centroids for each component
for (comp in 1:splsda_result$ncomp) {
  cat(sprintf("\nComponent %d - Group centroids:\n", comp))
  
  comp_scores <- sample_projections[, comp]
  for (group in levels(mixomics_data$Y)) {
    group_samples <- which(mixomics_data$Y == group)
    centroid <- mean(comp_scores[group_samples])
    cat(sprintf("  %s: %.3f\n", group, centroid))
  }
}

# === STEP 6: Validate feature selection patterns ===
cat("\n\nSTEP 6: Validating feature selection patterns...\n")

# Get selected features across all components
selected_features <- selectVar(splsda_result, comp = 1:splsda_result$ncomp)

# Count features by expression pattern
selected_feature_names <- unique(unlist(lapply(selected_features, function(x) rownames(x$X))))
selected_patterns <- row_data[selected_feature_names, "expression_pattern"]
pattern_counts <- table(selected_patterns)

cat("Selected features by expression pattern:\n")
for (pattern in names(pattern_counts)) {
  cat(sprintf("  %s: %d features\n", pattern, pattern_counts[pattern]))
}

# Calculate enrichment for each pattern
total_pattern_counts <- table(row_data$expression_pattern)
cat("\nPattern enrichment in selected features:\n")
for (pattern in names(pattern_counts)) {
  observed <- pattern_counts[pattern]
  expected <- (total_pattern_counts[pattern] / n_genes) * length(selected_feature_names)
  enrichment <- observed / expected
  cat(sprintf("  %s: %.2fx enriched\n", pattern, enrichment))
}

cat("\n=== Multi-class Analysis Example Complete! ===\n")
cat("This example demonstrated:\n")
cat("✓ Multi-class experimental design handling\n")
cat("✓ Cross-validation for component selection\n") 
cat("✓ Sparse PLS-DA with feature selection\n")
cat("✓ Variable importance analysis\n")
cat("✓ Group separation assessment\n")
cat("✓ Feature selection pattern validation\n\n")
