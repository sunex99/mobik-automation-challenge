#!/bin/bash

DATA_DIR="$HOME/capture/data"
LOG_FILE="corrupted_files.txt"

# Clear previous log
> "$LOG_FILE"

# Find all CSV files recursively
find "$DATA_DIR" -type f -name "*.csv" | while read -r file; do
  fullpath="$(realpath "$file")"

  # Get expected column count from header
  expected_columns=$(head -n 1 "$file" | awk -F',' '{print NF}')

  # Check for inconsistent column count (excluding header)
  if awk -F',' -v cols="$expected_columns" '
    NR > 1 && NF != cols { print FILENAME " - inconsistent columns at line " NR; exit 1 }
  ' "$file" >> /dev/null; then
    : # File is OK
  else
    echo "$fullpath - inconsistent column count" >> "$LOG_FILE"
  fi
done

# Append summary to log
echo "" >> "$LOG_FILE"
