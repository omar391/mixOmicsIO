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
#' @export
se_to_mixomics <- function(se_object, assay_name = "counts", design_variable) {
  # Input validation
  stopifnot(
    "se_object must be a SummarizedExperiment object" = methods::is(se_object, "SummarizedExperiment"),
    "assay_name must be a character string" = is.character(assay_name) && length(assay_name) == 1,
    "design_variable must be a character string" = is.character(design_variable) && length(design_variable) == 1
  )
  
  # Check if specified assay exists
  available_assays <- SummarizedExperiment::assayNames(se_object)
  if (length(available_assays) == 0) {
    stop("SummarizedExperiment object contains no assays")
  }
  
  if (!assay_name %in% available_assays) {
    stop(sprintf("Assay '%s' not found. Available assays: %s", 
                 assay_name, paste(available_assays, collapse = ", ")))
  }
  
  # Check if design variable exists in colData
  col_data <- SummarizedExperiment::colData(se_object)
  if (!design_variable %in% colnames(col_data)) {
    stop(sprintf("Design variable '%s' not found in colData. Available columns: %s",
                 design_variable, paste(colnames(col_data), collapse = ", ")))
  }
  
  # Extract assay matrix
  assay_matrix <- SummarizedExperiment::assay(se_object, assay_name)
  
  # Check for valid matrix data
  if (!is.numeric(assay_matrix)) {
    stop("Assay data must be numeric for mixOmics compatibility")
  }
  
  if (any(is.na(assay_matrix))) {
    warning("Assay matrix contains NA values. mixOmics functions may not handle these correctly.")
  }
  
  # Transpose matrix for mixOmics format (samples as rows, features as columns)
  # SummarizedExperiment has features as rows, samples as columns
  X <- t(assay_matrix)
  
  # Extract design variable and convert to factor
  Y <- col_data[[design_variable]]
  
  # Ensure Y is a factor for mixOmics compatibility
  if (!is.factor(Y)) {
    Y <- as.factor(Y)
    message(sprintf("Converting design variable '%s' to factor", design_variable))
  }
  
  # Check for missing values in design variable
  if (any(is.na(Y))) {
    stop("Design variable contains missing values (NA)")
  }
  
  # Verify dimensions match
  if (nrow(X) != length(Y)) {
    stop("Number of samples in assay matrix and design variable do not match")
  }
  
  # Return list in mixOmics format
  list(
    X = X,
    Y = Y
  )
}
