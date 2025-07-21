library(testthat)
library(methods)

# Integration tests with real-world-like data patterns
# This file tests the mixOmicsIO package functions with realistic SummarizedExperiment objects

# Create more realistic test data that mimics real-world patterns
create_realistic_se <- function(n_samples = 50, n_features = 1000) {
  # Create more realistic gene expression data
  # Simulate different expression patterns for different conditions
  set.seed(123)  # For reproducibility
  
  # Create base expression levels
  base_expression <- rpois(n_features, lambda = 100)
  
  # Create sample groups
  n_per_group <- n_samples / 2
  group1_samples <- seq_len(n_per_group)
  group2_samples <- (n_per_group + 1):n_samples
  
  # Create expression matrix with realistic patterns
  counts_matrix <- matrix(0, nrow = n_features, ncol = n_samples)
  
  # Add realistic expression patterns
  for (i in seq_len(n_features)) {
    # Most genes have similar expression between groups
    if (i <= n_features * 0.8) {
      # Similar expression
      counts_matrix[i, ] <- rpois(n_samples, lambda = base_expression[i])
    } else if (i <= n_features * 0.9) {
      # Upregulated in group 2
      counts_matrix[i, group1_samples] <- rpois(n_per_group, lambda = base_expression[i])
      counts_matrix[i, group2_samples] <- rpois(n_per_group, lambda = base_expression[i] * 2)
    } else {
      # Downregulated in group 2
      counts_matrix[i, group1_samples] <- rpois(n_per_group, lambda = base_expression[i])
      counts_matrix[i, group2_samples] <- rpois(n_per_group, lambda = base_expression[i] * 0.5)
    }
  }
  
  # Add realistic row and column names
  rownames(counts_matrix) <- paste0("ENSG", sprintf("%08d", seq_len(n_features)))
  colnames(counts_matrix) <- paste0("Sample_", sprintf("%03d", seq_len(n_samples)))
  
  # Create realistic sample metadata
  col_data <- data.frame(
    condition = factor(rep(c("Control", "Treatment"), each = n_per_group)),
    patient_id = factor(paste0("Patient_", sprintf("%02d", rep(1:(n_samples/2), each = 2)))),
    age = sample(25:75, n_samples, replace = TRUE),
    sex = factor(sample(c("M", "F"), n_samples, replace = TRUE)),
    batch = factor(rep(c("Batch_A", "Batch_B", "Batch_C"), length.out = n_samples)),
    library_size = colSums(counts_matrix),
    rna_quality = runif(n_samples, min = 6.5, max = 9.5),
    row.names = colnames(counts_matrix)
  )
  
  # Create realistic feature metadata
  row_data <- data.frame(
    gene_symbol = paste0("Gene_", seq_len(n_features)),
    gene_type = factor(sample(c("protein_coding", "lncRNA", "miRNA", "pseudogene"), 
                              n_features, replace = TRUE, 
                              prob = c(0.7, 0.15, 0.05, 0.1))),
    chromosome = factor(sample(c(1:22, "X", "Y"), n_features, replace = TRUE)),
    start_position = sample(1000:500000000, n_features),
    gc_content = runif(n_features, min = 0.2, max = 0.8),
    length = sample(500:50000, n_features, replace = TRUE),
    row.names = rownames(counts_matrix)
  )
  
  # Add some metadata
  metadata_list <- list(
    experiment_name = "Realistic Gene Expression Study",
    platform = "RNA-seq",
    organism = "Homo sapiens",
    genome_build = "GRCh38",
    sequencing_depth = "30M reads per sample"
  )
  
  # Create SummarizedExperiment
  se <- SummarizedExperiment::SummarizedExperiment(
    assays = list(counts = counts_matrix),
    colData = col_data,
    rowData = row_data,
    metadata = metadata_list
  )
  
  return(se)
}

# Test with realistic gene expression patterns
test_that("functions work with realistic gene expression data", {
  se <- create_realistic_se(n_samples = 40, n_features = 500)
  
  # Basic validation
  expect_s4_class(se, "SummarizedExperiment")
  expect_equal(nrow(se), 500)
  expect_equal(ncol(se), 40)
  
  # Test conversion
  result <- se_to_mixomics(se, assay_name = "counts", design_variable = "condition")
  
  # Validate conversion results
  expect_type(result, "list")
  expect_named(result, c("X", "Y"))
  expect_true(is.matrix(result$X))
  expect_true(is.factor(result$Y))
  
  # Check dimensions
  expect_equal(nrow(result$X), 40)  # samples
  expect_equal(ncol(result$X), 500) # features
  expect_equal(length(result$Y), 40)
  expect_equal(nlevels(result$Y), 2)
  
  # Test data characteristics
  expect_true(all(result$X >= 0))  # Count data should be non-negative
  expect_true(all(is.finite(result$X)))  # No infinite values
  expect_equal(sum(is.na(result$X)), 0)  # No missing values
})

# Test with multiple design variables
test_that("functions work with different design variables", {
  se <- create_realistic_se(n_samples = 60, n_features = 200)
  
  # Test with condition (2 levels)
  result_condition <- se_to_mixomics(se, "counts", "condition")
  expect_equal(nlevels(result_condition$Y), 2)
  
  # Test with batch (3 levels)
  result_batch <- se_to_mixomics(se, "counts", "batch")
  expect_equal(nlevels(result_batch$Y), 3)
  expect_true(all(levels(result_batch$Y) %in% c("Batch_A", "Batch_B", "Batch_C")))
  
  # Test with sex (2 levels)
  result_sex <- se_to_mixomics(se, "counts", "sex")
  expect_equal(nlevels(result_sex$Y), 2)
  expect_true(all(levels(result_sex$Y) %in% c("F", "M")))
  
  # Test with continuous variable (age) - should be converted to factor
  expect_message(
    result_age <- se_to_mixomics(se, "counts", "age"),
    "Converting design variable"
  )
  expect_true(is.factor(result_age$Y))
  expect_gt(nlevels(result_age$Y), 5)  # Age should have many levels
})

# Test with multiple assay types
test_that("functions work with multiple assay types", {
  se <- create_realistic_se(n_samples = 30, n_features = 300)
  
  # Add normalized counts
  raw_counts <- SummarizedExperiment::assay(se, "counts")
  
  # Simple normalization (library size normalization)
  lib_sizes <- colSums(raw_counts)
  norm_factors <- lib_sizes / mean(lib_sizes)
  normalized_counts <- t(t(raw_counts) / norm_factors)
  
  # Add log-transformed counts
  log_counts <- log2(raw_counts + 1)
  
  # Create multi-assay SummarizedExperiment
  SummarizedExperiment::assays(se) <- list(
    counts = raw_counts,
    normalized = normalized_counts,
    log2_counts = log_counts
  )
  
  # Test with each assay type
  result_raw <- se_to_mixomics(se, "counts", "condition")
  result_norm <- se_to_mixomics(se, "normalized", "condition")
  result_log <- se_to_mixomics(se, "log2_counts", "condition")
  
  # All should work but give different results
  expect_true(all(dim(result_raw$X) == dim(result_norm$X)))
  expect_true(all(dim(result_raw$X) == dim(result_log$X)))
  expect_identical(result_raw$Y, result_norm$Y)
  expect_identical(result_raw$Y, result_log$Y)
  
  # Data values should be different
  expect_false(identical(result_raw$X, result_norm$X))
  expect_false(identical(result_raw$X, result_log$X))
  
  # Log-transformed data should have different range
  expect_true(max(result_log$X) < max(result_raw$X))
  expect_true(min(result_log$X) >= 0)  # log2(x+1) should be non-negative
})

# Test integration with realistic mixOmics results
test_that("integration preserves complex metadata and annotations", {
  se <- create_realistic_se(n_samples = 50, n_features = 400)
  
  # Convert to mixomics format
  mixomics_data <- se_to_mixomics(se, "counts", "condition")
  
  # Create comprehensive mock mixOmics result
  mock_result <- list(
    X = mixomics_data$X,
    Y = mixomics_data$Y,
    ncomp = 3,
    mode = "regression",
    call = call("pls", X = quote(X), Y = quote(Y), ncomp = 3),
    loadings = list(
      X = matrix(rnorm(400 * 3), 
                 nrow = 400, 
                 ncol = 3,
                 dimnames = list(rownames(se), paste0("comp", 1:3)))
    ),
    selected.var = list(
      X = sort(sample(1:400, 80))  # Select 20% of features
    ),
    explained_variance = c(0.35, 0.22, 0.15),
    variates = list(
      X = matrix(rnorm(50 * 3), ncol = 3, dimnames = list(colnames(se), paste0("comp", 1:3)))
    ),
    prop_expl_var = list(X = c(0.35, 0.22, 0.15)),
    names = list(
      X = rownames(se),
      sample = colnames(se)
    )
  )
  class(mock_result) <- "mixo_pls"
  
  # Test integration
  enhanced_se <- mixomics_to_se(mock_result, se)
  
  # Validate enhanced object structure
  expect_s4_class(enhanced_se, "SummarizedExperiment")
  expect_identical(dim(enhanced_se), dim(se))
  
  # Check original data preservation
  expect_identical(
    SummarizedExperiment::assay(se, "counts"),
    SummarizedExperiment::assay(enhanced_se, "counts")
  )
  expect_identical(
    SummarizedExperiment::colData(se),
    SummarizedExperiment::colData(enhanced_se)
  )
  
  # Check original metadata preservation
  original_metadata <- S4Vectors::metadata(se)
  enhanced_metadata <- S4Vectors::metadata(enhanced_se)
  
  for (name in names(original_metadata)) {
    expect_identical(original_metadata[[name]], enhanced_metadata[[name]])
  }
  
  # Check new metadata additions
  expect_true("mixomics_result" %in% names(enhanced_metadata))
  expect_true("mixomics_analysis_date" %in% names(enhanced_metadata))
  expect_true("mixomics_analysis_method" %in% names(enhanced_metadata))
  expect_true("mixomics_explained_variance" %in% names(enhanced_metadata))
  
  # Check rowData additions
  original_rowdata <- SummarizedExperiment::rowData(se)
  enhanced_rowdata <- SummarizedExperiment::rowData(enhanced_se)
  
  # Original columns should be preserved
  for (name in colnames(original_rowdata)) {
    expect_true(name %in% colnames(enhanced_rowdata))
    expect_identical(original_rowdata[[name]], enhanced_rowdata[[name]])
  }
  
  # New columns should be added
  expect_true("mixomics_selected" %in% colnames(enhanced_rowdata))
  expect_true(any(grepl("mixomics_X_comp", colnames(enhanced_rowdata))))
  
  # Check selection results
  selected_features <- enhanced_rowdata$mixomics_selected
  expect_true(is.logical(selected_features))
  expect_equal(sum(selected_features), 80)  # 80 features selected
  
  # Check loading values
  comp1_loadings <- enhanced_rowdata$mixomics_X_comp1
  expect_true(is.numeric(comp1_loadings))
  expect_equal(length(comp1_loadings), nrow(se))
  expect_true(all(is.finite(comp1_loadings)))
})

# Test performance with larger realistic datasets
test_that("functions handle larger datasets efficiently", {
  # Test with moderately large dataset
  se_large <- create_realistic_se(n_samples = 100, n_features = 2000)
  
  # Time the conversion
  start_time <- Sys.time()
  result <- se_to_mixomics(se_large, "counts", "condition")
  conversion_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  
  # Should be reasonably fast
  expect_lt(conversion_time, 5)  # Less than 5 seconds
  
  # Validate result structure
  expect_equal(nrow(result$X), 100)
  expect_equal(ncol(result$X), 2000)
  expect_equal(length(result$Y), 100)
  
  # Test memory efficiency - check that data is properly structured
  object_size <- object.size(result)
  expected_size <- object.size(matrix(0, 100, 2000)) + object.size(factor(rep("A", 100)))
  
  # Result should not be dramatically larger than expected
  expect_lt(as.numeric(object_size), as.numeric(expected_size * 1.5))
})

# Test edge cases with realistic data
test_that("functions handle realistic edge cases", {
  se <- create_realistic_se(n_samples = 20, n_features = 100)
  
  # Test with unbalanced groups (common in real studies)
  se_unbalanced <- se
  se_unbalanced$condition <- factor(c(rep("Control", 5), rep("Treatment", 15)))
  
  # This should produce a warning about unbalanced groups
  result_unbalanced <- se_to_mixomics(se_unbalanced, "counts", "condition")
  expect_equal(nlevels(result_unbalanced$Y), 2)
  
  # Test with low-count genes (realistic scenario)
  low_count_se <- se
  assay_data <- SummarizedExperiment::assay(low_count_se, "counts")
  
  # Set half the genes to have very low counts
  low_genes <- 1:(nrow(se)/2)
  assay_data[low_genes, ] <- matrix(rpois(length(low_genes) * ncol(se), lambda = 0.5),
                                    nrow = length(low_genes))
  
  SummarizedExperiment::assay(low_count_se, "counts") <- assay_data
  
  # Should work without errors
  result_low <- se_to_mixomics(low_count_se, "counts", "condition")
  expect_type(result_low, "list")
  
  # Many zeros should be present (realistic for RNA-seq)
  expect_true(sum(result_low$X == 0) > 0)
})

# Test with different data distribution patterns
test_that("functions work with different data distributions", {
  se <- create_realistic_se(n_samples = 40, n_features = 300)
  
  # Create overdispersed count data (common in real RNA-seq)
  raw_counts <- SummarizedExperiment::assay(se, "counts")
  
  # Add overdispersion using negative binomial
  overdispersed_counts <- matrix(0, nrow = nrow(se), ncol = ncol(se))
  for (i in seq_len(nrow(se))) {
    mu <- mean(raw_counts[i, ])
    size_param <- mu / 2  # Moderate overdispersion
    overdispersed_counts[i, ] <- rnbinom(ncol(se), size = size_param, mu = mu)
  }
  
  rownames(overdispersed_counts) <- rownames(raw_counts)
  colnames(overdispersed_counts) <- colnames(raw_counts)
  
  SummarizedExperiment::assay(se, "counts") <- overdispersed_counts
  
  # Test conversion
  result <- se_to_mixomics(se, "counts", "condition")
  
  expect_type(result, "list")
  expect_true(all(result$X >= 0))
  expect_true(var(as.vector(result$X)) > mean(as.vector(result$X)))  # Overdispersed
  
  # Test with log-normal distributed data (after log transformation)
  log_data <- log2(overdispersed_counts + 1)
  SummarizedExperiment::assays(se)$log2_counts <- log_data
  
  result_log <- se_to_mixomics(se, "log2_counts", "condition")
  expect_true(all(result_log$X >= 0))  # log2(x+1) non-negative
  expect_true(all(is.finite(result_log$X)))
})
