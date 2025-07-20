# Workspace-Specific Rules and Guidelines

## Coding Standards

### R Package Development
- Follow R package development best practices using `devtools` and `usethis`
- Use roxygen2 for documentation with `@param`, `@return`, and `@examples`
- Follow tidyverse style guide for R code formatting
- Use snake_case for function names and parameter names
- Include comprehensive input validation with `stopifnot()` and informative error messages

### Function Design
- Favor pure functions with clear inputs and outputs
- Each function should have a single, well-defined responsibility
- Use descriptive parameter names and provide sensible defaults where applicable
- Always validate input object classes (`SummarizedExperiment`, etc.)

## Testing Requirements

### Unit Testing
- Use `testthat` framework for all tests
- Test both successful execution and error conditions
- Include edge cases in test scenarios
- Aim for comprehensive test coverage of core conversion functions
- Test with realistic sample data structures

### Integration Testing
- Test with real-world `SummarizedExperiment` objects
- Verify roundtrip conversions preserve data integrity
- Test with various assay configurations and metadata structures

## Package Structure

### File Organization
- One function per R file in the `R/` directory
- Match file names to primary function names (e.g., `se_to_mixomics.R`)
- Keep test files in `tests/testthat/` with descriptive names
- Use consistent naming: `test-[functionality].R`

### Dependencies
- Minimize external dependencies beyond core requirements
- Primary dependencies: `mixOmics`, `SummarizedExperiment`
- Use `@importFrom` rather than full package imports where possible
- Document all dependencies in DESCRIPTION file

## Documentation Standards

### README Requirements
- Clear installation instructions
- Basic usage example showing conversion workflow
- Brief description of package purpose and scope
- Links to relevant documentation and examples

### Function Documentation
- Complete roxygen2 documentation for all exported functions
- Include realistic examples that can be executed
- Document all parameters with expected types and constraints
- Explain return value structure and contents

## Error Handling

### Input Validation
- Always validate input object classes before processing
- Check for required columns/assays existence before access
- Provide clear, actionable error messages
- Use `stopifnot()` for critical preconditions

### Graceful Degradation
- Handle missing optional parameters gracefully
- Provide informative warnings for suboptimal conditions
- Ensure functions fail fast with clear error messages

## Git Workflow

### Commit Messages
- Use conventional commit format: `feat:`, `fix:`, `docs:`, etc.
- Include task ID references when applicable
- Write descriptive commit messages explaining the change

### Branch Strategy
- Work on feature branches for significant changes
- Use descriptive branch names reflecting the task
- Merge to main after testing and documentation completion

## Custom Rules

### Bioconductor Integration
- Follow Bioconductor standards for S4 object manipulation
- Preserve all metadata during conversions
- Use appropriate accessor functions (`assay()`, `colData()`, `rowData()`)
- Maintain data provenance through metadata preservation

### mixOmics Compatibility
- Ensure output formats match expected mixOmics input requirements
- Handle various mixOmics result object structures
- Test compatibility with major mixOmics analysis functions

### Performance Considerations
- Avoid unnecessary data copying during conversions
- Use efficient matrix operations where possible
- Consider memory usage for large datasets
- Profile performance with realistic data sizes
