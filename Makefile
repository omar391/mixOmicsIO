# mixOmicsIO Package Makefile
# Automates example execution, testing, and package operations

.PHONY: all examples basic_workflow multiclass_example integration_workflow test check install clean help

# Default target
all: help

# Package information
PACKAGE_NAME := mixOmicsIO
R := Rscript

# Colors for output
GREEN := \033[0;32m
BLUE := \033[0;34m
YELLOW := \033[0;33m
NC := \033[0m # No Color

help: ## Display this help message
	@echo "$(BLUE)mixOmicsIO Package Makefile$(NC)"
	@echo "=============================="
	@echo ""
	@echo "Available targets:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "Example workflow:"
	@echo "  make install    # Install package dependencies"
	@echo "  make examples   # Run all examples"
	@echo "  make test       # Run package tests"
	@echo ""

install: ## Install package and dependencies
	@echo "$(YELLOW)Installing package dependencies...$(NC)"
	$(R) -e "if(!require('devtools')) install.packages('devtools')"
	$(R) -e "devtools::install_deps('.')"
	@echo "$(YELLOW)Installing current package...$(NC)"
	$(R) -e "devtools::install('.')"
	@echo "$(GREEN)Installation complete!$(NC)"

examples: basic_workflow multiclass_example integration_workflow github_issue_347 ## Run all examples

basic_workflow: install ## Run basic workflow example
	@echo "$(YELLOW)Running Basic Workflow Example...$(NC)"
	$(R) --vanilla examples/01_basic_workflow.R
	@echo "$(GREEN)Basic workflow completed successfully!$(NC)"
	@echo ""

multiclass_example: install ## Run multiclass analysis example
	@echo "$(YELLOW)Running Multi-class Analysis Example...$(NC)"
	$(R) --vanilla examples/02_multiclass_example.R
	@echo "$(GREEN)Multi-class example completed successfully!$(NC)"
	@echo ""

integration_workflow: install ## Run integration workflow example
	@echo "$(YELLOW)Running Integration Workflow Example...$(NC)"
	$(R) --vanilla examples/03_integration_workflow.R
	@echo "$(GREEN)Integration workflow completed successfully!$(NC)"
	@echo ""

github_issue_347: install ## Run GitHub issue #347 solution example
	@echo "$(YELLOW)Running GitHub Issue #347 Solution Example...$(NC)"
	$(R) --vanilla examples/04_github_issue_347.R
	@echo "$(GREEN)GitHub issue #347 solution completed successfully!$(NC)"
	@echo ""

test: ## Run package tests
	@echo "$(YELLOW)Running package tests...$(NC)"
	$(R) -e "devtools::test()"
	@echo "$(GREEN)Tests completed!$(NC)"

check: ## Run R CMD check on package
	@echo "$(YELLOW)Running R CMD check...$(NC)"
	$(R) -e "devtools::check()"
	@echo "$(GREEN)Package check completed!$(NC)"

lint: ## Run lintr on package code
	@echo "$(YELLOW)Running code linting...$(NC)"
	$(R) -e "if(!require('lintr')) install.packages('lintr'); lintr::lint_package()"
	@echo "$(GREEN)Linting completed!$(NC)"

document: ## Generate package documentation
	@echo "$(YELLOW)Generating package documentation...$(NC)"
	$(R) -e "devtools::document()"
	@echo "$(GREEN)Documentation updated!$(NC)"

build: ## Build package tarball
	@echo "$(YELLOW)Building package...$(NC)"
	$(R) -e "devtools::build()"
	@echo "$(GREEN)Package built successfully!$(NC)"

quick_test: ## Run examples with minimal output for CI
	@echo "$(YELLOW)Running quick test suite...$(NC)"
	$(R) --slave -e "source('examples/01_basic_workflow.R')" > /dev/null 2>&1
	$(R) --slave -e "source('examples/02_multiclass_example.R')" > /dev/null 2>&1  
	$(R) --slave -e "source('examples/03_integration_workflow.R')" > /dev/null 2>&1
	$(R) -e "devtools::test()" > /dev/null 2>&1
	@echo "$(GREEN)Quick test suite passed!$(NC)"

validate: test check ## Run comprehensive validation (tests + check)
	@echo "$(GREEN)Package validation completed successfully!$(NC)"

clean: ## Clean temporary files
	@echo "$(YELLOW)Cleaning temporary files...$(NC)"
	rm -f *.tar.gz
	rm -rf *.Rcheck
	rm -f .RData .Rhistory
	@echo "$(GREEN)Cleanup completed!$(NC)"

dev_setup: ## Setup development environment  
	@echo "$(YELLOW)Setting up development environment...$(NC)"
	$(R) -e "if(!require('devtools')) install.packages('devtools')"
	$(R) -e "if(!require('usethis')) install.packages('usethis')"
	$(R) -e "if(!require('testthat')) install.packages('testthat')"
	$(R) -e "if(!require('lintr')) install.packages('lintr')"
	$(R) -e "devtools::install_deps('.')"
	@echo "$(GREEN)Development environment ready!$(NC)"

# Continuous Integration targets
ci: quick_test ## Continuous integration workflow

# Show package status
status: ## Show package status and information
	@echo "$(BLUE)Package Status$(NC)"
	@echo "=============="
	@echo "Package: $(PACKAGE_NAME)"
	@echo "R Version: $$($(R) --slave -e 'cat(R.version.string)')"
	@echo "Working Directory: $$(pwd)"
	@echo "Examples Available: $$(ls examples/*.R | wc -l)"
	@echo "Tests Available: $$(find tests -name '*.R' | wc -l)"
	@echo "Documentation Files: $$(ls man/*.Rd 2>/dev/null | wc -l)"
