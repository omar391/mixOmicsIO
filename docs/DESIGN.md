# Design Document: `mixOmicsIO`

## 1. Architecture Overview

The `mixOmicsIO` package will be a lightweight R package with a functional, not object-oriented, initial design to ensure rapid development. It will contain a set of utility functions for data conversion. The core logic will focus on mapping data between the `SummarizedExperiment` S4 object structure and the standard R `list` and `matrix` objects used by `mixOmics`.

## 2. Core Functions (MVP)

### `se_to_mixomics(se_object, assay_name = "counts", design_variable)`

- **Purpose:** Converts a `SummarizedExperiment` object to a `mixOmics`-ready list.
- **Parameters:**
  - `se_object`: A `SummarizedExperiment` object.
  - `assay_name`: A string specifying which assay to extract (e.g., "counts", "logcpm"). Defaults to the first assay if not provided.
  - `design_variable`: A string naming the column in `colData(se_object)` that contains the experimental design (e.g., "treatment_group"). This will become the `Y` vector.
- **Returns:** A `list` with two elements:
  - `X`: The data matrix (genes x samples).
  - `Y`: The design factor vector.
- **Logic:**
  1. Validate that `se_object` is a `SummarizedExperiment`.
  2. Extract the specified assay matrix and transpose it to get the `X` matrix (samples as rows).
  3. Extract the specified `design_variable` from `colData` to create the `Y` factor.
  4. Return `list(X = X, Y = Y)`.

### `mixomics_to_se(mixomics_result, original_se)`

- **Purpose:** Adds `mixOmics` results to a `SummarizedExperiment` object.
- **Parameters:**
  - `mixomics_result`: The output object from a `mixOmics` function (e.g., `plsda`).
  - `original_se`: The original `SummarizedExperiment` object used for the analysis, to provide context and metadata.
- **Returns:** An updated `SummarizedExperiment` object.
- **Logic:**
  1. Validate inputs.
  2. Store the `mixomics_result` object itself in the `metadata` slot of the `SummarizedExperiment` object.
  3. Extract key results like variable loadings (`loadings.star`) and add them to the `rowData` of the `SummarizedExperiment` object.
  4. Return the modified `SummarizedExperiment` object.

## 3. Data Structures

- **Input:** `SummarizedExperiment` S4 object.
- **Internal:** Standard R `matrix` and `factor`.
- **Output:** A `list` for `se_to_mixomics` and a `SummarizedExperiment` for `mixomics_to_se`.

## 4. Error Handling

- Functions will include `stopifnot()` checks for common errors:
  - Input object is not of the correct class (`SummarizedExperiment`).
  - Specified `assay_name` or `design_variable` does not exist.
  - Dimensions of data do not match.

## 5. Package Structure

```
mixOmicsIO/
├── R/
│   ├── se_to_mixomics.R
│   └── mixomics_to_se.R
├── man/
├── tests/
│   └── testthat/
│       └── test-conversions.R
├── DESCRIPTION
├── NAMESPACE
└── README.md
```
