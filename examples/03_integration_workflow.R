#!/usr/bin/env Rscript
# Integration Workflow Example - mixOmicsIO Package  
# Complete workflow from preprocessing through analysis to interpretation

# Load required libraries
library(mixOmicsIO)
library(SummarizedExperiment)
library(mixOmics)

cat("=== mixOmicsIO Integration Workflow Example ===\n\n")

# This example simulates a complete real-world bioinformatics workflow
cat("Simulating a complete bioinformatics pipeline:\n")
cat("Raw Data → Preprocessing → Normalization → Analysis → Results → Interpretation\n\n")

# === STAGE 1: Simulate "Raw Data" Processing ===
cat("STAGE 1: Generating and preprocessing raw data...\n")

set.seed(789)
n_samples <- 50
n_genes <- 500

# Simulate raw count data with batch effects and technical variation
raw_counts <- matrix(
  rnbinom(n_genes * n_samples, mu = 80, size = 5),
  nrow = n_genes,
  ncol = n_samples,
  dimnames = list(
    genes = paste0("Gene_", sprintf("%04d", 1:n_genes)),
    samples = paste0("Sample_", sprintf("%03d", 1:n_samples))
  )
)

# Add batch effects (common in real data)
batch_factor <- rep(1:5, each = 10)
for (batch in 1:5) {
  batch_samples <- which(batch_factor == batch)
  # Each batch has slightly different baseline expression
  batch_effect <- rnorm(1, mean = 1, sd = 0.2)
  raw_counts[, batch_samples] <- raw_counts[, batch_samples] * batch_effect
}

# Create experimental design
treatment_groups <- rep(c("Control", "Low_Dose", "High_Dose"), length.out = n_samples)

# Add treatment effects
control_samples <- which(treatment_groups == "Control")
low_dose_samples <- which(treatment_groups == "Low_Dose") 
high_dose_samples <- which(treatment_groups == "High_Dose")

# Genes 1-100: Dose-responsive genes
dose_responsive_genes <- 1:100
raw_counts[dose_responsive_genes, low_dose_samples] <- 
  raw_counts[dose_responsive_genes, low_dose_samples] * 1.3
raw_counts[dose_responsive_genes, high_dose_samples] <- 
  raw_counts[dose_responsive_genes, high_dose_samples] * 1.8

# Genes 101-200: High-dose specific
high_dose_genes <- 101:200
raw_counts[high_dose_genes, high_dose_samples] <- 
  raw_counts[high_dose_genes, high_dose_samples] * 2.0

cat("Raw data generated:\n")
cat("- ", n_genes, " genes across ", n_samples, " samples\n")
cat("- 5 batches with technical variation\n")  
cat("- 3 treatment groups with biological effects\n\n")

# === STAGE 2: Data Quality Assessment and Preprocessing ===
cat("STAGE 2: Data quality assessment and preprocessing...\n")

# Filter low-expression genes (common preprocessing step)
gene_means <- rowMeans(raw_counts)
expressed_genes <- gene_means > 10  # Keep genes with mean count > 10
filtered_counts <- raw_counts[expressed_genes, ]

cat("Quality filtering:\n")
cat("- Removed ", sum(!expressed_genes), " low-expression genes\n")
cat("- Retained ", sum(expressed_genes), " well-expressed genes\n\n")

# Log-transform for downstream analysis (common for mixOmics)
log_counts <- log2(filtered_counts + 1)

# Create comprehensive metadata
col_data <- DataFrame(
  treatment = factor(treatment_groups, levels = c("Control", "Low_Dose", "High_Dose")),
  batch = factor(batch_factor),
  processing_date = rep(as.Date("2025-01-01") + 0:4, each = 10),
  rna_quality = rnorm(n_samples, mean = 8.5, sd = 0.5),
  library_size = colSums(filtered_counts),
  row.names = colnames(filtered_counts)
)

# Create detailed gene annotations
gene_names <- rownames(filtered_counts)
row_data <- DataFrame(
  gene_category = sample(c("metabolic", "signaling", "immune", "structural", "regulatory"), 
                        nrow(filtered_counts), replace = TRUE),
  chromosome = sample(paste0("chr", c(1:22, "X", "Y")), nrow(filtered_counts), replace = TRUE),
  gene_length = sample(500:5000, nrow(filtered_counts), replace = TRUE),
  is_dose_responsive = gene_names %in% rownames(raw_counts)[dose_responsive_genes],
  is_high_dose_specific = gene_names %in% rownames(raw_counts)[high_dose_genes],
  baseline_expression = rowMeans(log_counts),
  expression_variance = apply(log_counts, 1, var),
  row.names = gene_names
)

# === STAGE 3: Create Multi-Assay SummarizedExperiment ===
cat("STAGE 3: Creating multi-assay SummarizedExperiment...\n")

# Create SE with multiple assays (common in real workflows)
se <- SummarizedExperiment(
  assays = list(
    raw_counts = filtered_counts,
    log_counts = log_counts,
    normalized = t(scale(t(log_counts)))  # Gene-wise z-score normalization
  ),
  colData = col_data,
  rowData = row_data,
  metadata = list(
    experiment_info = "Dose-response study",
    processing_date = Sys.Date(),
    filtering_criteria = "mean_count > 10",
    normalization = "log2(counts + 1) with z-score scaling"
  )
)

cat("SummarizedExperiment created with:\n")
cat("- ", length(assayNames(se)), " assay types: ", paste(assayNames(se), collapse = ", "), "\n")
cat("- ", ncol(se), " samples with comprehensive metadata\n")
cat("- ", nrow(se), " genes with detailed annotations\n\n")

# === STAGE 4: Multiple Analysis Strategies ===
cat("STAGE 4: Comparing different analysis strategies...\n")

analysis_results <- list()

# Analysis 1: Using raw counts
cat("Analysis 1: Using raw counts...\n")
mixomics_raw <- se_to_mixomics(se, assay_name = "raw_counts", design_variable = "treatment")
plsda_raw <- plsda(mixomics_raw$X, mixomics_raw$Y, ncomp = 2)
analysis_results$raw_counts <- plsda_raw

# Analysis 2: Using log-transformed counts  
cat("Analysis 2: Using log-transformed counts...\n")
mixomics_log <- se_to_mixomics(se, assay_name = "log_counts", design_variable = "treatment")
plsda_log <- plsda(mixomics_log$X, mixomics_log$Y, ncomp = 2)
analysis_results$log_counts <- plsda_log

# Analysis 3: Using normalized data
cat("Analysis 3: Using normalized (z-score) data...\n")
mixomics_norm <- se_to_mixomics(se, assay_name = "normalized", design_variable = "treatment")
plsda_norm <- plsda(mixomics_norm$X, mixomics_norm$Y, ncomp = 2)
analysis_results$normalized <- plsda_norm

cat("All analyses complete!\n\n")

# === STAGE 5: Comprehensive Results Integration ===
cat("STAGE 5: Integrating all analysis results...\n")

# Store all results in the SE object
se_final <- se

# Add each analysis result to metadata
metadata(se_final)$mixomics_analyses <- analysis_results

# Add analysis-specific information to rowData
for (analysis_name in names(analysis_results)) {
  result <- analysis_results[[analysis_name]]
  
  # Add loadings for each component
  for (comp in 1:result$ncomp) {
    col_name <- paste0(analysis_name, "_loading_comp", comp)
    rowData(se_final)[[col_name]] <- result$loadings$X[, comp]
  }
  
  # Add variable importance if available
  if (analysis_name == "normalized") {  # Use normalized for VIP calculation
    vip_scores <- vip(result)
    for (comp in 1:result$ncomp) {
      col_name <- paste0("VIP_comp", comp)
      rowData(se_final)[[col_name]] <- vip_scores[, comp]
    }
  }
}

cat("Results integration complete:\n")
cat("- ", length(names(analysis_results)), " analysis strategies stored\n")
cat("- ", ncol(rowData(se_final)) - ncol(rowData(se)), " new columns added to rowData\n")
cat("- All original data and metadata preserved\n\n")

# === STAGE 6: Cross-Analysis Comparison ===
cat("STAGE 6: Comparing analysis strategies...\n")

# Compare explained variance across methods
cat("Explained variance by analysis method:\n")
for (analysis_name in names(analysis_results)) {
  result <- analysis_results[[analysis_name]]
  explained_var <- result$explained_variance$X
  cat(sprintf("  %s: Comp1=%.1f%%, Comp2=%.1f%%\n", 
              analysis_name, explained_var[1]*100, explained_var[2]*100))
}

# Identify consistently important features across analyses
cat("\nIdentifying consistently important features...\n")

# Get top 20 features from each analysis (Component 1)
top_features_per_analysis <- list()
for (analysis_name in names(analysis_results)) {
  result <- analysis_results[[analysis_name]]
  loadings_comp1 <- abs(result$loadings$X[, 1])
  top_20 <- names(sort(loadings_comp1, decreasing = TRUE))[1:20]
  top_features_per_analysis[[analysis_name]] <- top_20
}

# Find features that appear in all analyses
consensus_features <- Reduce(intersect, top_features_per_analysis)
cat("Features consistently important across all methods: ", length(consensus_features), "\n")

if (length(consensus_features) > 0) {
  cat("Top consensus features:\n")
  for (i in seq_len(min(10, length(consensus_features)))) {
    feature <- consensus_features[i]
    category <- rowData(se_final)[feature, "gene_category"]
    is_known_responsive <- rowData(se_final)[feature, "is_dose_responsive"]
    cat(sprintf("  %s (%s) - Known responsive: %s\n", feature, category, is_known_responsive))
  }
}

# === STAGE 7: Biological Interpretation ===
cat("\n\nSTEP 7: Biological interpretation of results...\n")

# Analyze feature categories in top results
top_features_all <- unique(unlist(top_features_per_analysis))
selected_categories <- rowData(se_final)[top_features_all, "gene_category"]
category_enrichment <- table(selected_categories)

cat("Gene category representation in top features:\n")
total_categories <- table(rowData(se_final)$gene_category)
for (category in names(category_enrichment)) {
  observed <- category_enrichment[category]
  expected <- (total_categories[category] / nrow(se_final)) * length(top_features_all)
  enrichment <- observed / expected
  cat(sprintf("  %s: %d features (%.1fx enriched)\n", category, observed, enrichment))
}

# Validate against known biology
known_responsive_in_top <- sum(rowData(se_final)[top_features_all, "is_dose_responsive"])
cat("\nBiological validation:\n")
cat(sprintf("- Known dose-responsive genes in top features: %d/%d (%.1f%%)\n", 
    known_responsive_in_top, length(top_features_all),
    100 * known_responsive_in_top / length(top_features_all)))

expected_responsive <- sum(rowData(se_final)$is_dose_responsive) / nrow(se_final) * length(top_features_all)
cat("- Expected by chance: %.1f genes\n", expected_responsive)
cat("- Enrichment: %.1fx\n", known_responsive_in_top / expected_responsive)

# === STAGE 8: Export and Documentation ===
cat("\n\nSTEP 8: Final documentation and export preparation...\n")

# Add comprehensive analysis summary to metadata
metadata(se_final)$analysis_summary <- list(
  total_analyses_performed = length(analysis_results),
  assay_types_tested = names(analysis_results),
  consensus_features_identified = length(consensus_features),
  biological_validation_success = known_responsive_in_top > expected_responsive,
  processing_complete = TRUE,
  analysis_date = Sys.Date()
)

cat("Analysis workflow complete and documented!\n")
cat("Final SummarizedExperiment contains:\n")
cat("- Original data: ", length(assayNames(se_final)), " assay types\n")
cat("- Analysis results: ", length(metadata(se_final)$mixomics_analyses), " stored analyses\n") 
cat("- Feature annotations: ", ncol(rowData(se_final)), " total columns\n")
cat("- Metadata entries: ", length(metadata(se_final)), " comprehensive records\n")

cat("\n=== Integration Workflow Example Complete! ===\n")
cat("This comprehensive example demonstrated:\n")
cat("✓ Raw data simulation and preprocessing\n")
cat("✓ Quality filtering and normalization strategies\n") 
cat("✓ Multi-assay SummarizedExperiment creation\n")
cat("✓ Multiple analysis strategy comparison\n")
cat("✓ Comprehensive result integration\n")
cat("✓ Cross-analysis consensus identification\n")
cat("✓ Biological interpretation and validation\n")
cat("✓ Complete workflow documentation\n\n")
cat("This workflow represents a production-ready bioinformatics pipeline\n")
cat("suitable for real-world computational biology applications.\n")
