# Project Overview

**mixOmicsIO** is a lightweight R package designed to provide seamless interoperability between the `mixOmics` multivariate analysis framework and Bioconductor's `SummarizedExperiment` objects. The package aims to bridge the gap between upstream data processing in Bioconductor and downstream multivariate analysis in `mixOmics`, eliminating complex data wrangling steps for researchers.

## Requirements Evolution

### Initial Requirements (MVP)
- **Primary Goal**: Create bidirectional conversion functions between `SummarizedExperiment` and `mixOmics` data structures
- **Target Users**: Bioinformaticians using Bioconductor for upstream processing who want to leverage `mixOmics` for analysis
- **Core Functions**: 
  - `se_to_mixomics()`: Convert `SummarizedExperiment` to `mixOmics`-ready format
  - `mixomics_to_se()`: Store `mixOmics` results back in `SummarizedExperiment`
- **Key Requirement**: Preserve metadata integrity throughout conversions

### Future Scope Considerations
- Extension to `MultiAssayExperiment` for multi-omics integration
- Implementation of formal S4 methods for more robust interface
- Comprehensive vignette with complete workflow examples

## Architecture

### Design Philosophy
- **Functional Approach**: Initial implementation uses pure functions rather than object-oriented design for rapid development
- **Lightweight**: Minimize dependencies beyond core requirements (`mixOmics`, `SummarizedExperiment`)
- **Data Integrity**: Preserve all sample and feature metadata during conversions
- **Error Handling**: Robust input validation with clear, actionable error messages

### Core Components

#### Data Conversion Pipeline
```
SummarizedExperiment -> [se_to_mixomics] -> list(X, Y) -> [mixOmics Analysis] -> [mixomics_to_se] -> Updated SummarizedExperiment
```

#### Function Specifications

**`se_to_mixomics(se_object, assay_name, design_variable)`**
- Extracts specified assay matrix and transposes for `mixOmics` format (samples as rows)
- Extracts design variable from `colData` to create response vector
- Returns `list(X = data_matrix, Y = design_factor)`

**`mixomics_to_se(mixomics_result, original_se)`**
- Stores complete `mixOmics` result object in `metadata` slot
- Extracts key results (loadings, etc.) and adds to `rowData`
- Returns enriched `SummarizedExperiment` with analysis results

## Technology Stack

### Core Dependencies
- **R** (>= 4.0.0)
- **mixOmics**: Multivariate analysis framework
- **SummarizedExperiment**: Bioconductor data structure
- **methods**: S4 object system support

### Development Tools
- **devtools**: Package development workflow
- **usethis**: Package setup utilities  
- **testthat**: Unit testing framework
- **roxygen2**: Documentation generation

### Optional Dependencies
- **BiocStyle**: Documentation styling (for vignettes)
- **knitr**: Vignette generation
- **rmarkdown**: Documentation formatting

## Design Patterns

### Functional Programming
- Pure functions with clear input/output contracts
- No side effects in core conversion functions
- Predictable behavior for testing and maintenance

### Input Validation Pattern
```r
# Consistent validation approach across functions
stopifnot(
  "Input must be SummarizedExperiment" = is(se_object, "SummarizedExperiment"),
  "Assay name must exist" = assay_name %in% assayNames(se_object),
  "Design variable must exist in colData" = design_variable %in% colnames(colData(se_object))
)
```

### Metadata Preservation Pattern
- Always preserve original metadata through conversions
- Use structured approach to storing analysis results
- Maintain data provenance information

## Development Environment

### Package Structure
```
mixOmicsIO/
├── R/
│   ├── se_to_mixomics.R      # Core conversion function
│   └── mixomics_to_se.R      # Result integration function
├── man/                      # Generated documentation
├── tests/
│   └── testthat/
│       └── test-conversions.R # Unit tests
├── vignettes/                # Future: detailed workflows
├── DESCRIPTION               # Package metadata
├── NAMESPACE                 # Exported functions
└── README.md                # Package overview
```

### Setup Requirements
1. R development environment with Bioconductor installed
2. Required packages: `devtools`, `usethis`, `testthat`
3. Access to sample `SummarizedExperiment` objects for testing
4. `mixOmics` package for integration testing

## API Documentation

### Core Functions

#### `se_to_mixomics(se_object, assay_name = "counts", design_variable)`
- **Purpose**: Convert `SummarizedExperiment` to `mixOmics` format
- **Returns**: `list(X = matrix, Y = factor)` where X is samples×features, Y is design factor
- **Validation**: Input class, assay existence, design variable availability

#### `mixomics_to_se(mixomics_result, original_se)`
- **Purpose**: Integrate `mixOmics` analysis results into `SummarizedExperiment`
- **Returns**: Enhanced `SummarizedExperiment` with results in metadata and rowData
- **Integration**: Preserves original structure while adding analysis outcomes

## Implementation Notes

### Critical Design Decisions

1. **Matrix Orientation**: `mixOmics` expects samples as rows, `SummarizedExperiment` stores features as rows
   - Solution: Transpose matrix during conversion with clear documentation

2. **Metadata Storage**: `mixOmics` results need structured storage in `SummarizedExperiment`
   - Solution: Use `metadata()` slot for complete results, `rowData()` for feature-level outcomes

3. **Error Handling Strategy**: Balance between informative errors and execution speed
   - Solution: Front-load validation with `stopifnot()`, provide context in error messages

4. **Assay Selection**: Handle multiple assays gracefully
   - Solution: Default to first assay, allow explicit specification, validate availability

### Testing Strategy

1. **Unit Tests**: Test individual function components with synthetic data (33 tests)
   - Basic functionality validation
   - Input validation and error handling
   - Edge cases with small datasets
   - Roundtrip conversion integrity

2. **Integration Tests**: Use realistic data patterns with comprehensive scenarios (75 tests)
   - Realistic gene expression patterns with differential expression
   - Multiple assay types (raw counts, normalized, log-transformed)
   - Various design variables (binary, multi-level categorical, continuous)
   - Performance testing with larger datasets (up to 2000 features, 100 samples)
   - Metadata and annotation preservation
   - Edge cases with real-world data characteristics
   - Overdispersed count data and different distributions

3. **Real-World Data Tests**: Optional tests with public datasets
   - Tests gracefully skip when packages like `airway`, `DESeq2` not available
   - Validates compatibility with actual Bioconductor datasets when available

4. **Test Coverage**: Complete test suite covers all major functionality paths
   - All 108 tests passing with comprehensive validation
   - Helpful warnings for suboptimal data conditions
   - Robust error messages for invalid inputs

### Performance Considerations

- Avoid unnecessary data copying during matrix operations
- Use efficient accessor functions from SummarizedExperiment
- Consider memory usage for large genomics datasets
- Profile performance with realistic data sizes (10k+ features, 100+ samples)
