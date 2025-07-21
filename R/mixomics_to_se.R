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
#' @importFrom methods is
#' @importFrom S4Vectors metadata "metadata<-"
#' @importFrom SummarizedExperiment rowData "rowData<-"
#' @importFrom mixOmics explained_variance
#' @export
mixomics_to_se <- function(mixomics_result, original_se) {
  # Input validation
  stopifnot(
    "original_se must be a SummarizedExperiment object" = methods::is(original_se, "SummarizedExperiment"),
    "mixomics_result cannot be NULL" = !is.null(mixomics_result)
  )
  
  # Enhanced SummarizedExperiment validation
  if (nrow(original_se) == 0) {
    stop("original_se has no features (rows). Cannot integrate mixOmics results without feature information.")
  }
  
  if (ncol(original_se) == 0) {
    stop("original_se has no samples (columns). Cannot integrate mixOmics results without sample information.")
  }
  
  # Enhanced mixOmics result validation
  if (!is.list(mixomics_result)) {
    result_class <- class(mixomics_result)[1]
    stop(sprintf("mixomics_result must be a list (typical mixOmics result structure). Found: %s\nTip: Ensure you're passing the complete result object from a mixOmics function.", result_class))
  }
  
  # More comprehensive mixOmics object validation
  if (length(mixomics_result) == 0) {
    stop("mixomics_result is an empty list. Cannot proceed with integration.")
  }
  
  # Validate that this looks like a mixOmics result object
  mixomics_classes <- c("mixo_pls", "mixo_plsda", "mixo_spls", "mixo_splsda",
                        "mixo_rcc", "mixo_pca", "mixo_ipca", "mixo_sipca",
                        "block.pls", "block.plsda", "block.spls", "block.splsda")
  
  obj_class <- class(mixomics_result)[1]
  is_recognized_mixomics <- obj_class %in% mixomics_classes || any(grepl("mixo|block", obj_class))
  
  if (!is_recognized_mixomics) {
    warning(sprintf("Object class '%s' is not a recognized mixOmics result class.\nExpected classes: %s\nTip: Ensure the result comes from a mixOmics analysis function.", obj_class, paste(mixomics_classes, collapse = ", ")))
  }
  
  # Check for common mixOmics result components with detailed feedback
  expected_components <- c("X", "Y", "ncomp", "mode", "call")
  missing_components <- setdiff(expected_components, names(mixomics_result))
  
  if (length(missing_components) == length(expected_components)) {
    stop(sprintf("mixomics_result appears to be invalid - none of the expected mixOmics components found.\nExpected components: %s\nFound components: %s\nTip: Ensure you're passing the complete result object from a mixOmics analysis function.", paste(expected_components, collapse = ", "), paste(names(mixomics_result), collapse = ", ")))
  }
  
  if (length(missing_components) > 3) {  # More strict validation
    warning(sprintf("mixomics_result may not be a valid mixOmics object. Missing several common components: %s\nFound components: %s\nTip: Some integration features may not work correctly with this object.", paste(missing_components, collapse = ", "), paste(names(mixomics_result), collapse = ", ")))
  }
  
  # Validate dimensions compatibility
  if ("X" %in% names(mixomics_result)) {
    X_data <- mixomics_result$X
    if (is.matrix(X_data)) {
      if (ncol(X_data) != nrow(original_se)) {
        stop(sprintf("Dimension mismatch: mixOmics X matrix has %d features but original_se has %d features.\nThis suggests the mixOmics result was not derived from the provided SummarizedExperiment object.\nTip: Ensure you're using the same SummarizedExperiment object that was used to generate the mixOmics results.", ncol(X_data), nrow(original_se)))
      }
      
      if (nrow(X_data) != ncol(original_se)) {
        stop(sprintf("Dimension mismatch: mixOmics X matrix has %d samples but original_se has %d samples.\nThis suggests the mixOmics result was not derived from the provided SummarizedExperiment object.\nTip: Ensure you're using the same SummarizedExperiment object that was used to generate the mixOmics results.", nrow(X_data), ncol(original_se)))
      }
    }
  }
  
  # Create a copy of the original SummarizedExperiment
  enhanced_se <- original_se
  
  # Store complete mixOmics result in metadata
  current_metadata <- S4Vectors::metadata(enhanced_se)
  current_metadata$mixomics_result <- mixomics_result
  S4Vectors::metadata(enhanced_se) <- current_metadata
  
  # Extract and integrate feature-level results into rowData
  current_rowdata <- SummarizedExperiment::rowData(enhanced_se)
  
  # Handle loadings (if available) - most common feature-level result
  if ("loadings" %in% names(mixomics_result)) {
    loadings_data <- mixomics_result$loadings
    
    # Handle different loading structures with enhanced validation
    if (is.list(loadings_data)) {
      # Multiple component loadings (e.g., from PLS, sPLS)
      for (comp_name in names(loadings_data)) {
        loading_matrix <- loadings_data[[comp_name]]
        
        # Enhanced loading matrix validation
        if (!is.matrix(loading_matrix)) {
          warning(sprintf("Loading component '%s' is not a matrix (found: %s). Skipping this component.", comp_name, class(loading_matrix)[1]))
          next
        }
        
        if (nrow(loading_matrix) != nrow(enhanced_se)) {
          warning(sprintf("Loading matrix '%s' has %d features but SummarizedExperiment has %d features. Skipping this component.\nTip: This may indicate a mismatch between the analysis input and the SummarizedExperiment object.", comp_name, nrow(loading_matrix), nrow(enhanced_se)))
          next
        }
        
        if (ncol(loading_matrix) == 0) {
          warning(sprintf("Loading matrix '%s' has no components. Skipping this component.", comp_name))
          next
        }
        
        # Check for problematic values in loadings
        if (any(is.infinite(loading_matrix))) {
          warning(sprintf("Loading matrix '%s' contains infinite values. These will be preserved but may cause issues downstream.", comp_name))
        }
        
        # Add each component as separate columns with improved naming
        for (col_idx in seq_len(ncol(loading_matrix))) {
          col_name <- paste0("mixomics_", comp_name, "_comp", col_idx)
          # Avoid column name conflicts
          if (col_name %in% colnames(current_rowdata)) {
            col_name <- paste0(col_name, "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
            warning(sprintf("Column name conflict detected. Using unique name: %s", col_name))
          }
          current_rowdata[[col_name]] <- loading_matrix[, col_idx]
        }
      }
    } else if (is.matrix(loadings_data)) {
      # Single loading matrix with enhanced validation
      if (nrow(loadings_data) != nrow(enhanced_se)) {
        warning(sprintf("Loading matrix dimensions do not match number of features in SummarizedExperiment (%d vs %d). Cannot integrate loading values.\nTip: Verify that the mixOmics result corresponds to the provided SummarizedExperiment.", nrow(loadings_data), nrow(enhanced_se)))
      } else {
        if (ncol(loadings_data) == 0) {
          warning("Loading matrix has no components. No loading values will be added.")
        } else {
          # Check for problematic values
          if (any(is.infinite(loadings_data))) {
            warning("Loading matrix contains infinite values. These will be preserved but may cause issues downstream.")
          }
          
          for (col_idx in seq_len(ncol(loadings_data))) {
            col_name <- paste0("mixomics_loading_comp", col_idx)
            # Avoid column name conflicts
            if (col_name %in% colnames(current_rowdata)) {
              col_name <- paste0(col_name, "_", format(Sys.time(), "%Y%m%d_%H%M%S"))
              warning(sprintf("Column name conflict detected. Using unique name: %s", col_name))
            }
            current_rowdata[[col_name]] <- loadings_data[, col_idx]
          }
        }
      }
    } else {
      warning(sprintf("Loadings data has unexpected structure (type: %s). Expected matrix or list of matrices.", class(loadings_data)[1]))
    }
  }
  
  # Handle variable selection results (if available) with enhanced validation
  if ("selected.var" %in% names(mixomics_result)) {
    selected_vars <- mixomics_result$selected.var
    
    # Initialize selection indicator
    current_rowdata$mixomics_selected <- FALSE
    
    # Handle different selection structures with validation
    if (is.list(selected_vars)) {
      # Multiple components selection
      all_selected_indices <- unique(unlist(selected_vars))
      
      if (length(all_selected_indices) == 0) {
        warning("Variable selection results are empty. No features will be marked as selected.")
      } else if (is.numeric(all_selected_indices)) {
        # Validate indices are within bounds
        invalid_indices <- all_selected_indices[all_selected_indices < 1 | all_selected_indices > nrow(enhanced_se)]
        if (length(invalid_indices) > 0) {
          warning(sprintf("Some selected variable indices are out of bounds: %s. These will be ignored.\nValid range: 1 to %d", paste(invalid_indices, collapse = ", "), nrow(enhanced_se)))
          all_selected_indices <- all_selected_indices[all_selected_indices >= 1 & all_selected_indices <= nrow(enhanced_se)]
        }
        
        if (length(all_selected_indices) > 0) {
          current_rowdata$mixomics_selected[all_selected_indices] <- TRUE
          message(sprintf("Marked %d features as selected by mixOmics analysis.", length(all_selected_indices)))
        }
      } else if (is.character(all_selected_indices)) {
        # Handle feature names
        feature_names <- rownames(enhanced_se)
        if (is.null(feature_names)) {
          warning("Cannot use feature names for selection - SummarizedExperiment has no rownames.")
        } else {
          valid_names <- all_selected_indices[all_selected_indices %in% feature_names]
          invalid_names <- setdiff(all_selected_indices, valid_names)
          
          if (length(invalid_names) > 0) {
            warning(sprintf("Some selected feature names not found in SummarizedExperiment: %s", paste(head(invalid_names, 10), collapse = ", ")))
          }
          
          if (length(valid_names) > 0) {
            selected_indices <- match(valid_names, feature_names)
            current_rowdata$mixomics_selected[selected_indices] <- TRUE
            message(sprintf("Marked %d features as selected by mixOmics analysis.", length(valid_names)))
          }
        }
      } else {
        warning(sprintf("Selected variables have unexpected data type: %s. Expected numeric indices or character names.", class(all_selected_indices)[1]))
      }
    } else if (is.numeric(selected_vars)) {
      # Direct indices validation
      invalid_indices <- selected_vars[selected_vars < 1 | selected_vars > nrow(enhanced_se)]
      if (length(invalid_indices) > 0) {
        warning(sprintf("Some selected variable indices are out of bounds: %s. These will be ignored.\nValid range: 1 to %d", paste(invalid_indices, collapse = ", "), nrow(enhanced_se)))
        selected_vars <- selected_vars[selected_vars >= 1 & selected_vars <= nrow(enhanced_se)]
      }
      
      if (length(selected_vars) > 0) {
        current_rowdata$mixomics_selected[selected_vars] <- TRUE
        message(sprintf("Marked %d features as selected by mixOmics analysis.", length(selected_vars)))
      }
    } else {
      warning(sprintf("Selected variables have unexpected structure: %s. Expected numeric indices, character names, or list thereof.", class(selected_vars)[1]))
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
  S4Vectors::metadata(enhanced_se) <- current_metadata
  
  # Return enhanced SummarizedExperiment
  enhanced_se
}
