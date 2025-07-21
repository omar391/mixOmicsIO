# mixOmicsIO Examples

This directory contains practical examples demonstrating the mixOmicsIO package functionality with realistic bioinformatics workflows.

## Quick Start

To run all examples:

```bash
make examples
```

To run a specific example:

```bash
make basic_workflow
make multiclass_example
make integration_workflow
make github_issue_347
```

## Example Descriptions

### 1. Basic Workflow (`01_basic_workflow.R`)

Demonstrates the fundamental conversion between SummarizedExperiment and mixOmics formats using synthetic gene expression data with binary group comparison.

**Key Features:**

- Simple two-group comparison
- Basic PLS-DA analysis
- Result integration back to SummarizedExperiment

### 2. Multi-class Analysis (`02_multiclass_example.R`)

Shows handling of multi-level categorical variables with more complex experimental designs.

**Key Features:**

- Three-group experimental design
- sPLS-DA analysis with component selection
- Variable importance visualization

### 3. Integration Workflow (`03_integration_workflow.R`)

Complete workflow from data preprocessing through analysis to result interpretation, mimicking real-world bioinformatics pipelines.

**Key Features:**

- Data normalization and filtering
- Multiple assay handling
- Comprehensive result storage and retrieval

### 4. GitHub Issue #347 Solution (`04_github_issue_347.R`)

Demonstrates how mixOmicsIO directly addresses the community feature request for SummarizedExperiment support in mixOmics.

**Key Features:**

- Realistic microbiome data scenario
- Multi-assay SummarizedExperiment handling
- Direct solution to GitHub issue #347
- Ecosystem integration demonstration

## Data Generation

All examples use synthetically generated data that mimics realistic biological patterns:

- Gene expression count matrices
- Appropriate overdispersion patterns
- Realistic sample sizes and feature counts
- Relevant metadata structures

## Requirements

The examples require the following R packages:

- mixOmicsIO (this package)
- mixOmics
- SummarizedExperiment
- BiocGenerics

Optional packages for enhanced examples:

- ggplot2 (for visualizations)
- dplyr (for data manipulation)

## Running Examples

Each example is self-contained and can be run independently:

```r
# From R console
source("examples/01_basic_workflow.R")
source("examples/02_multiclass_example.R")
source("examples/03_integration_workflow.R")
```

Or use the provided Makefile for automated execution and validation.
