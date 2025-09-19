#!/bin/bash

DATA_DIR="$HOME/capture/data"
CORRUPTED_OUTPUT="$HOME/capture/corrupted.csv"

# Clear previous corrupted output
> "$CORRUPTED_OUTPUT"

# Find all CSV files recursively
find "$DATA_DIR" -type f -name "*.csv" | while read -r file; do
  fullpath="$(realpath "$file")"

  # Get expected column count from header
  expected=$(head -n 1 "$file" | awk -F',' '{print NF}')

  # Create a temporary clean file
  tmp_clean="$(mktemp)"

  # Process each line
  awk -F',' -v cols="$expected" -v out="$CORRUPTED_OUTPUT" '
    NR == 1 { print $0 > "'"$tmp_clean"'"; next }
    NF == cols { print $0 >> "'"$tmp_clean"'" }
    NF != cols { print $0 >> out }
  ' "$file"

  # Replace original file with cleaned version
  mv "$tmp_clean" "$file"
done

echo "Corrupted lines saved to $CORRUPTED_OUTPUT and original files cleaned"
