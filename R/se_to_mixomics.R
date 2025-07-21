#' Convert SummarizedExperiment to mixOmics Format
#'
#' This function converts a SummarizedExperiment object to the list format
#' required by mixOmics multivariate analysis functions.
#'
#' @param se_object A SummarizedExperiment object
#' @param assay_name Character string specifying which assay to extract (default: "counts")
#' @param design_variable Character string specifying the column name in colData 
#'   to use as the response variable
#'
#' @return A list with components:
#' \describe{
#'   \item{X}{A numeric matrix with samples as rows and features as columns}
#'   \item{Y}{A factor vector with the design variable for each sample}
#' }
#'
#' @examples
#' \dontrun{
#' # Example with a SummarizedExperiment object
#' mixomics_data <- se_to_mixomics(se, assay_name = "counts", design_variable = "condition")
#' }
#'
#' @importFrom methods is
#' @importFrom SummarizedExperiment assay assayNames colData
#' @importFrom mixOmics pls
#' @export
se_to_mixomics <- function(se_object, assay_name = "counts", design_variable) {
  # Input validation
  stopifnot(
    "se_object must be a SummarizedExperiment object" = methods::is(se_object, "SummarizedExperiment"),
    "assay_name must be a character string" = is.character(assay_name) && length(assay_name) == 1,
    "design_variable must be a character string" = is.character(design_variable) && length(design_variable) == 1
  )
  
  # Validate SummarizedExperiment is not empty
  if (nrow(se_object) == 0) {
    stop("SummarizedExperiment object has no features (rows). Cannot proceed with conversion.")
  }
  
  if (ncol(se_object) == 0) {
    stop("SummarizedExperiment object has no samples (columns). Cannot proceed with conversion.")
  }
  
  # Check if specified assay exists
  available_assays <- SummarizedExperiment::assayNames(se_object)
  if (length(available_assays) == 0) {
    stop("SummarizedExperiment object contains no assays. Please add at least one assay matrix.")
  }
  
  if (!assay_name %in% available_assays) {
    stop(sprintf("Assay '%s' not found. Available assays: %s\nTip: Use SummarizedExperiment::assayNames(se_object) to list available assays.",
                 assay_name, paste(available_assays, collapse = ", ")))
  }
  
  # Check if design variable exists in colData
  col_data <- SummarizedExperiment::colData(se_object)
  if (ncol(col_data) == 0) {
    stop("SummarizedExperiment object has no colData. Design variables must be stored in colData.")
  }
  
  if (!design_variable %in% colnames(col_data)) {
    available_columns <- colnames(col_data)
    stop(sprintf("Design variable '%s' not found in colData.\nAvailable columns: %s\nTip: Use SummarizedExperiment::colData(se_object) to view sample metadata.",
                 design_variable, paste(available_columns, collapse = ", ")))
  }
  
  # Extract assay matrix
  assay_matrix <- SummarizedExperiment::assay(se_object, assay_name)
  
  # Enhanced matrix validation
  if (!is.numeric(assay_matrix)) {
    matrix_class <- class(assay_matrix)[1]
    stop(sprintf("Assay data must be numeric for mixOmics compatibility. Found: %s\nTip: Convert your data to numeric matrix before creating the SummarizedExperiment.", matrix_class))
  }
  
  # Check for problematic numeric values
  if (any(is.infinite(assay_matrix))) {
    stop("Assay matrix contains infinite values (Inf or -Inf). mixOmics functions cannot handle these.\nTip: Replace infinite values with NA or appropriate finite values before conversion.")
  }
  
  # Check matrix dimensions are reasonable
  if (nrow(assay_matrix) > 100000) {
    warning(sprintf("Large feature count detected (%d features). This may cause memory issues with mixOmics functions.\nTip: Consider feature selection or dimensionality reduction before analysis.", nrow(assay_matrix)))
  }
  
  if (ncol(assay_matrix) > 10000) {
    warning(sprintf("Large sample count detected (%d samples). This may cause performance issues with some mixOmics functions.\nTip: Consider subsetting samples for initial analysis.", ncol(assay_matrix)))
  }
  
  # More detailed NA handling
  na_count <- sum(is.na(assay_matrix))
  if (na_count > 0) {
    na_percentage <- round(100 * na_count / length(assay_matrix), 2)
    if (na_percentage > 10) {
      stop(sprintf("Assay matrix contains %d NA values (%.2f%% of data). Most mixOmics functions cannot handle this level of missing data.\nTip: Impute missing values or filter features/samples with excessive NAs before conversion.", na_count, na_percentage))
    } else {
      warning(sprintf("Assay matrix contains %d NA values (%.2f%% of data). Some mixOmics functions may not handle these correctly.\nTip: Consider imputing missing values for optimal results.", na_count, na_percentage))
    }
  }
  
  # Transpose matrix for mixOmics format (samples as rows, features as columns)
  # SummarizedExperiment has features as rows, samples as columns
  X <- t(assay_matrix)
  
  # Extract design variable and convert to factor
  Y <- col_data[[design_variable]]
  
  # Enhanced design variable validation
  if (all(is.na(Y))) {
    stop(sprintf("Design variable '%s' contains only missing values (NA). Cannot proceed with analysis.", design_variable))
  }
  
  if (any(is.na(Y))) {
    na_samples <- sum(is.na(Y))
    stop(sprintf("Design variable '%s' contains %d missing values (NA). mixOmics functions require complete design variables.\nTip: Remove samples with missing design variables or impute the missing values.", design_variable, na_samples))
  }
  
  # Validate design variable content
  if (is.numeric(Y)) {
    unique_values <- length(unique(Y))
    if (unique_values == length(Y)) {
      warning(sprintf("Design variable '%s' appears to be continuous with unique values for each sample. Most mixOmics functions expect categorical groupings.\nTip: Consider discretizing continuous variables or using appropriate regression methods.", design_variable))
    }
  }
  
  # Ensure Y is a factor for mixOmics compatibility
  if (!is.factor(Y)) {
    Y <- as.factor(Y)
    message(sprintf("Converting design variable '%s' to factor with %d levels: %s", design_variable, nlevels(Y), paste(levels(Y), collapse = ", ")))
  }
  
  # Enhanced factor level validation
  if (nlevels(Y) == 1) {
    stop(sprintf("Design variable '%s' has only one level ('%s'). mixOmics functions require multiple groups for comparison.\nTip: Check your experimental design or choose a different design variable.", design_variable, levels(Y)[1]))
  }
  
  if (nlevels(Y) > 10) {
    warning(sprintf("Design variable '%s' has many levels (%d). Some mixOmics functions may not perform well with highly categorical variables.\nTip: Consider grouping similar categories or using numerical encoding for ordinal variables.", design_variable, nlevels(Y)))
  }
  
  # Check for balanced design
  level_counts <- table(Y)
  min_count <- min(level_counts)
  max_count <- max(level_counts)
  if (min_count < 3) {
    warning(sprintf("Some groups in design variable '%s' have very few samples (minimum: %d). This may cause issues with statistical analysis.\nGroup sizes: %s\nTip: Consider combining small groups or collecting more samples.", design_variable, min_count, paste(paste(names(level_counts), level_counts, sep = "="), collapse = ", ")))
  }
  
  if (max_count > 5 * min_count && nlevels(Y) > 2) {
    warning(sprintf("Design variable '%s' has unbalanced groups (range: %d-%d samples). This may affect analysis results.\nGroup sizes: %s\nTip: Consider balancing your design or using appropriate statistical adjustments.", design_variable, min_count, max_count, paste(paste(names(level_counts), level_counts, sep = "="), collapse = ", ")))
  }
  
  # Verify dimensions match
  if (nrow(X) != length(Y)) {
    stop(sprintf("Dimension mismatch: Number of samples in assay matrix (%d) and design variable (%d) do not match.\nThis indicates a structural problem with the SummarizedExperiment object.", nrow(X), length(Y)))
  }
  
  # Enhanced mixOmics compatibility validation
  if (nrow(X) < 3) {
    stop(sprintf("Insufficient samples for analysis: only %d samples available. Most mixOmics functions require at least 3 samples.\nTip: Collect more samples or consider alternative analysis methods.", nrow(X)))
  }
  
  if (ncol(X) < 2) {
    stop(sprintf("Insufficient features for multivariate analysis: only %d features available. mixOmics functions require at least 2 features.\nTip: Include more features in your analysis or check your data filtering.", ncol(X)))
  }
  
  # Check for reasonable sample-to-feature ratio
  sample_feature_ratio <- nrow(X) / ncol(X)
  if (sample_feature_ratio < 0.1 && ncol(X) > 100) {
    warning(sprintf("Sample-to-feature ratio is very low (%.3f, %d samples vs %d features). This may lead to overfitting in mixOmics analysis.\nTip: Consider feature selection, dimensionality reduction, or collecting more samples.", sample_feature_ratio, nrow(X), ncol(X)))
  }
  
  # Validate matrix values for common analysis issues
  if (any(assay_matrix < 0) && all(assay_matrix >= 0, na.rm = TRUE) == FALSE) {
    negative_count <- sum(assay_matrix < 0, na.rm = TRUE)
    warning(sprintf("Data matrix contains %d negative values. Some mixOmics functions assume non-negative data (e.g., count data).\nTip: Check if your data type is appropriate for the intended analysis.", negative_count))
  }
  
  # Return list in mixOmics format
  list(
    X = X,
    Y = Y
  )
}
