#' Integrate mixOmics Results into SummarizedExperiment
#'
#' This function takes mixOmics analysis results and integrates them back into
#' a SummarizedExperiment object, preserving the original data structure while
#' adding analysis results.
#'
#' @param mixomics_result Result object from a mixOmics analysis function
#' @param original_se The original SummarizedExperiment object used for analysis
#'
#' @return An enhanced SummarizedExperiment object with:
#' \describe{
#'   \item{metadata}{Complete mixOmics result object stored for reference}
#'   \item{rowData}{Feature-level results (e.g., loadings) added as columns}
#' }
#'
#' @examples
#' \dontrun{
#' # Example workflow
#' mixomics_data <- se_to_mixomics(se, "counts", "condition")
#' pls_result <- mixOmics::pls(mixomics_data$X, mixomics_data$Y)
#' se_with_results <- mixomics_to_se(pls_result, se)
#' }
#'
#' @export
mixomics_to_se <- function(mixomics_result, original_se) {
  # Input validation
  stopifnot(
    "original_se must be a SummarizedExperiment object" = methods::is(original_se, "SummarizedExperiment"),
    "mixomics_result cannot be NULL" = !is.null(mixomics_result)
  )
  
  # Check if mixomics_result has expected structure
  if (!is.list(mixomics_result)) {
    stop("mixomics_result must be a list (typical mixOmics result structure)")
  }
  
  # Create a copy of the original SummarizedExperiment
  enhanced_se <- original_se
  
  # Store complete mixOmics result in metadata
  current_metadata <- SummarizedExperiment::metadata(enhanced_se)
  current_metadata$mixomics_result <- mixomics_result
  SummarizedExperiment::metadata(enhanced_se) <- current_metadata
  
  # Extract and integrate feature-level results into rowData
  current_rowdata <- SummarizedExperiment::rowData(enhanced_se)
  
  # Handle loadings (if available) - most common feature-level result
  if ("loadings" %in% names(mixomics_result)) {
    loadings_data <- mixomics_result$loadings
    
    # Handle different loading structures
    if (is.list(loadings_data)) {
      # Multiple component loadings (e.g., from PLS, sPLS)
      for (comp_name in names(loadings_data)) {
        loading_matrix <- loadings_data[[comp_name]]
        
        # Check if loading matrix matches number of features
        if (is.matrix(loading_matrix) && nrow(loading_matrix) == nrow(enhanced_se)) {
          # Add each component as separate columns
          for (col_idx in seq_len(ncol(loading_matrix))) {
            col_name <- paste0("mixomics_", comp_name, "_comp", col_idx)
            current_rowdata[[col_name]] <- loading_matrix[, col_idx]
          }
        }
      }
    } else if (is.matrix(loadings_data)) {
      # Single loading matrix
      if (nrow(loadings_data) == nrow(enhanced_se)) {
        for (col_idx in seq_len(ncol(loadings_data))) {
          col_name <- paste0("mixomics_loading_comp", col_idx)
          current_rowdata[[col_name]] <- loadings_data[, col_idx]
        }
      } else {
        warning("Loading matrix dimensions do not match number of features in SummarizedExperiment")
      }
    }
  }
  
  # Handle variable selection results (if available)
  if ("selected.var" %in% names(mixomics_result)) {
    selected_vars <- mixomics_result$selected.var
    
    # Initialize selection indicator
    current_rowdata$mixomics_selected <- FALSE
    
    # Handle different selection structures
    if (is.list(selected_vars)) {
      # Multiple components selection
      selected_indices <- unique(unlist(selected_vars))
      if (is.numeric(selected_indices)) {
        current_rowdata$mixomics_selected[selected_indices] <- TRUE
      }
    } else if (is.numeric(selected_vars)) {
      # Direct indices
      current_rowdata$mixomics_selected[selected_vars] <- TRUE
    }
  }
  
  # Handle explained variance (if available)
  if ("explained_variance" %in% names(mixomics_result)) {
    current_metadata$mixomics_explained_variance <- mixomics_result$explained_variance
  } else if ("prop_expl_var" %in% names(mixomics_result)) {
    current_metadata$mixomics_explained_variance <- mixomics_result$prop_expl_var
  }
  
  # Update rowData with all modifications
  SummarizedExperiment::rowData(enhanced_se) <- current_rowdata
  
  # Add analysis metadata for provenance
  current_metadata$mixomics_analysis_date <- Sys.Date()
  current_metadata$mixomics_analysis_method <- class(mixomics_result)[1]
  SummarizedExperiment::metadata(enhanced_se) <- current_metadata
  
  # Return enhanced SummarizedExperiment
  enhanced_se
}
