library(testthat)
library(methods)

# Create mock SummarizedExperiment objects for testing
create_test_se <- function(n_samples = 10, n_features = 20, assay_name = "counts") {
  # Create synthetic data matrix
  counts_matrix <- matrix(
    rpois(n_samples * n_features, lambda = 10),
    nrow = n_features,
    ncol = n_samples,
    dimnames = list(
      paste0("feature_", seq_len(n_features)),
      paste0("sample_", seq_len(n_samples))
    )
  )
  
  # Create sample metadata
  col_data <- data.frame(
    condition = factor(rep(c("control", "treatment"), length.out = n_samples)),
    batch = factor(rep(c("batch1", "batch2"), each = n_samples / 2)),
    continuous_var = rnorm(n_samples),
    row.names = colnames(counts_matrix)
  )
  
  # Create feature metadata
  row_data <- data.frame(
    gene_type = factor(rep(c("protein_coding", "lncRNA"), length.out = n_features)),
    chromosome = factor(sample(1:22, n_features, replace = TRUE)),
    row.names = rownames(counts_matrix)
  )
  
  # Create SummarizedExperiment object
  se <- SummarizedExperiment::SummarizedExperiment(
    assays = setNames(list(counts_matrix), assay_name),
    colData = col_data,
    rowData = row_data
  )
  
  return(se)
}

# Create mock mixOmics result for testing
create_test_mixomics_result <- function(n_features = 20, n_components = 2) {
  # Create mock loadings
  loadings_X <- matrix(
    rnorm(n_features * n_components),
    nrow = n_features,
    ncol = n_components,
    dimnames = list(
      paste0("feature_", seq_len(n_features)),
      paste0("comp", seq_len(n_components))
    )
  )
  
  # Create mock result structure
  mock_result <- list(
    loadings = list(X = loadings_X),
    selected.var = list(X = sample(seq_len(n_features), 5)),
    explained_variance = c(0.3, 0.2),
    variates = list(X = matrix(rnorm(10 * n_components), ncol = n_components)),
    names = list(X = paste0("feature_", seq_len(n_features)))
  )
  
  class(mock_result) <- "mixo_pls"
  return(mock_result)
}

# Test se_to_mixomics function
test_that("se_to_mixomics works with valid input", {
  se <- create_test_se()
  
  result <- se_to_mixomics(se, assay_name = "counts", design_variable = "condition")
  
  expect_type(result, "list")
  expect_named(result, c("X", "Y"))
  expect_true(is.matrix(result$X))
  expect_true(is.factor(result$Y))
  
  # Check dimensions
  expect_equal(nrow(result$X), ncol(se))  # samples as rows
  expect_equal(ncol(result$X), nrow(se))  # features as columns
  expect_equal(length(result$Y), ncol(se))  # one Y value per sample
})

test_that("se_to_mixomics handles different assay names", {
  se <- create_test_se(assay_name = "normalized")
  
  result <- se_to_mixomics(se, assay_name = "normalized", design_variable = "condition")
  
  expect_type(result, "list")
  expect_named(result, c("X", "Y"))
})

test_that("se_to_mixomics validates input correctly", {
  se <- create_test_se()
  
  # Test invalid se_object
  expect_error(
    se_to_mixomics("not_a_se", "counts", "condition"),
    "se_object must be a SummarizedExperiment object"
  )
  
  # Test invalid assay_name
  expect_error(
    se_to_mixomics(se, c("counts", "extra"), "condition"),
    "assay_name must be a character string"
  )
  
  # Test invalid design_variable
  expect_error(
    se_to_mixomics(se, "counts", c("condition", "extra")),
    "design_variable must be a character string"
  )
  
  # Test non-existent assay
  expect_error(
    se_to_mixomics(se, "nonexistent", "condition"),
    "Assay 'nonexistent' not found"
  )
  
  # Test non-existent design variable
  expect_error(
    se_to_mixomics(se, "counts", "nonexistent"),
    "Design variable 'nonexistent' not found in colData"
  )
})

test_that("se_to_mixomics handles edge cases", {
  # Test with minimal dataset
  se_small <- create_test_se(n_samples = 2, n_features = 3)
  result <- se_to_mixomics(se_small, "counts", "condition")
  
  expect_equal(nrow(result$X), 2)
  expect_equal(ncol(result$X), 3)
  expect_equal(length(result$Y), 2)
})

test_that("se_to_mixomics converts design variable to factor", {
  se <- create_test_se()
  
  # Test with continuous variable
  result <- se_to_mixomics(se, "counts", "continuous_var")
  expect_true(is.factor(result$Y))
})

# Test mixomics_to_se function
test_that("mixomics_to_se works with valid input", {
  se <- create_test_se()
  mixomics_result <- create_test_mixomics_result()
  
  enhanced_se <- mixomics_to_se(mixomics_result, se)
  
  expect_s4_class(enhanced_se, "SummarizedExperiment")
  
  # Check metadata
  metadata <- SummarizedExperiment::metadata(enhanced_se)
  expect_true("mixomics_result" %in% names(metadata))
  expect_true("mixomics_analysis_date" %in% names(metadata))
  expect_true("mixomics_analysis_method" %in% names(metadata))
  
  # Check rowData additions
  rowdata <- SummarizedExperiment::rowData(enhanced_se)
  expect_true(any(grepl("mixomics_", colnames(rowdata))))
})

test_that("mixomics_to_se validates input correctly", {
  se <- create_test_se()
  mixomics_result <- create_test_mixomics_result()
  
  # Test invalid original_se
  expect_error(
    mixomics_to_se(mixomics_result, "not_a_se"),
    "original_se must be a SummarizedExperiment object"
  )
  
  # Test NULL mixomics_result
  expect_error(
    mixomics_to_se(NULL, se),
    "mixomics_result cannot be NULL"
  )
  
  # Test non-list mixomics_result
  expect_error(
    mixomics_to_se("not_a_list", se),
    "mixomics_result must be a list"
  )
})

test_that("mixomics_to_se preserves original data", {
  se <- create_test_se()
  mixomics_result <- create_test_mixomics_result()
  
  enhanced_se <- mixomics_to_se(mixomics_result, se)
  
  # Check that original assays are preserved
  expect_identical(
    SummarizedExperiment::assay(se, "counts"),
    SummarizedExperiment::assay(enhanced_se, "counts")
  )
  
  # Check that original colData is preserved
  expect_identical(
    SummarizedExperiment::colData(se),
    SummarizedExperiment::colData(enhanced_se)
  )
})

# Integration tests
test_that("roundtrip conversion preserves data integrity", {
  se <- create_test_se()
  
  # Convert to mixomics format
  mixomics_data <- se_to_mixomics(se, "counts", "condition")
  
  # Create mock analysis result
  mock_result <- create_test_mixomics_result(n_features = nrow(se))
  
  # Convert back to SummarizedExperiment
  enhanced_se <- mixomics_to_se(mock_result, se)
  
  # Check data integrity
  expect_identical(
    SummarizedExperiment::assay(se, "counts"),
    SummarizedExperiment::assay(enhanced_se, "counts")
  )
  
  expect_identical(
    SummarizedExperiment::colData(se),
    SummarizedExperiment::colData(enhanced_se)
  )
  
  # Check that analysis results were added
  expect_true("mixomics_result" %in% names(SummarizedExperiment::metadata(enhanced_se)))
})

test_that("functions work with different data types", {
  # Test with integer matrix
  se_int <- create_test_se()
  result_int <- se_to_mixomics(se_int, "counts", "condition")
  expect_true(is.numeric(result_int$X))
  
  # Test with different factor levels
  se <- create_test_se()
  # Modify colData to have 3 levels
  SummarizedExperiment::colData(se)$condition <- factor(
    rep(c("A", "B", "C"), length.out = ncol(se))
  )
  
  result <- se_to_mixomics(se, "counts", "condition")
  expect_equal(nlevels(result$Y), 3)
})
