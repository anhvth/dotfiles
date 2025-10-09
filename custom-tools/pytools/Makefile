.PHONY: help install test lint fmt docs clean

help:  ## Show this help message
	@echo "PyTools Development Commands"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

install:  ## Install package in development mode
	uv pip install -e .

install-dev:  ## Install with dev dependencies
	uv pip install -e ".[dev]"

test:  ## Run tests
	pytest tests/ -v

test-cov:  ## Run tests with coverage
	pytest tests/ --cov=src/pytools --cov-report=term-missing --cov-report=html

lint:  ## Run linters (ruff)
	ruff check src/pytools tests

fmt:  ## Format code (ruff)
	ruff format src/pytools tests
	ruff check --fix src/pytools tests

docs:  ## Generate documentation
	python scripts/generate_docs.py

clean:  ## Clean up generated files
	rm -rf build dist *.egg-info
	rm -rf htmlcov .coverage .pytest_cache
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete

doctor:  ## Check system dependencies
	python -m pytools doctor

version:  ## Show version
	python -m pytools --version

list:  ## List all tools
	python -m pytools list
