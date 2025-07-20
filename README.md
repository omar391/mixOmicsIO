# mixOmicsIO

[![R-CMD-check](https://github.com/username/mixOmicsIO/workflows/R-CMD-check/badge.svg)](https://github.com/username/mixOmicsIO/actions)

**mixOmicsIO** is a lightweight R package that provides seamless interoperability between the [mixOmics](http://mixomics.org/) multivariate analysis framework and Bioconductor's [SummarizedExperiment](https://bioconductor.org/packages/SummarizedExperiment/) objects. The package eliminates complex data wrangling steps for researchers who want to use both ecosystems together.

## Installation

You can install the development version of mixOmicsIO from GitHub:

```r
# Install devtools if you haven't already
if (!requireNamespace("devtools", quietly = TRUE)) {
    install.packages("devtools")
}

# Install mixOmicsIO
devtools::install_github("username/mixOmicsIO")
```

## Quick Start

The package provides two main functions for bidirectional conversion between data structures:

```r
library(mixOmicsIO)
library(SummarizedExperiment)
library(mixOmics)

# Convert SummarizedExperiment to mixOmics format
mixomics_data <- se_to_mixomics(se_object, 
                               assay_name = "counts", 
                               design_variable = "condition")

# Perform mixOmics analysis
pls_result <- mixOmics::pls(mixomics_data$X, mixomics_data$Y, ncomp = 2)

# Integrate results back into SummarizedExperiment
se_with_results <- mixomics_to_se(pls_result, se_object)
```

## Key Features

- **Bidirectional Conversion**: Convert between `SummarizedExperiment` and mixOmics formats
- **Metadata Preservation**: Maintains all sample and feature metadata throughout conversions
- **Flexible Assay Selection**: Choose which assay to extract from multi-assay objects
- **Result Integration**: Store mixOmics analysis results in the original data structure
- **Comprehensive Validation**: Robust input checking with informative error messages

## Core Functions

### `se_to_mixomics()`

Converts a `SummarizedExperiment` object to the list format required by mixOmics:

- Extracts specified assay matrix and transposes for mixOmics format (samples as rows)
- Extracts design variable from `colData` 
- Returns `list(X = matrix, Y = factor)` ready for mixOmics analysis

### `mixomics_to_se()`

Integrates mixOmics analysis results back into a `SummarizedExperiment` object:

- Stores complete results in the `metadata()` slot
- Adds feature-level results (loadings, variable selection) to `rowData()`
- Preserves original data structure while enriching with analysis outcomes

## Example Workflow

```r
# Load required libraries
library(mixOmicsIO)
library(SummarizedExperiment)
library(mixOmics)

# Assuming you have a SummarizedExperiment object 'se'
# with a "counts" assay and a "treatment" variable in colData

# Step 1: Convert to mixOmics format
mixomics_data <- se_to_mixomics(se, 
                               assay_name = "counts", 
                               design_variable = "treatment")

# Step 2: Perform mixOmics analysis (example with PLS)
pls_result <- pls(X = mixomics_data$X, 
                  Y = mixomics_data$Y, 
                  ncomp = 3)

# Step 3: Integrate results back
se_enhanced <- mixomics_to_se(pls_result, se)

# Access results
metadata(se_enhanced)$mixomics_result  # Complete results
rowData(se_enhanced)  # Feature-level results added as columns
```

## Requirements

- R (>= 4.0.0)
- [SummarizedExperiment](https://bioconductor.org/packages/SummarizedExperiment/)
- [mixOmics](http://mixomics.org/)

## Getting Help

- For questions about usage, please open an [issue](https://github.com/username/mixOmicsIO/issues)
- For bug reports, include a minimal reproducible example
- Check the [mixOmics documentation](http://mixomics.org/mixomics/) for analysis guidance

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
