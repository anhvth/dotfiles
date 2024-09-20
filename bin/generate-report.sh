#!/bin/bash

# Clear the report file if it exists
> report.readme

# Find all Python files and run pylint with --errors-only
for file in $(find . -name "*.py"); do
    echo "Running pylint on $file" >> report.readme
    pylint --errors-only "$file" >> report.readme
    echo -e "\n" >> report.readme
done

echo "Error report generated in report.readme"

