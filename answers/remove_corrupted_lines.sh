#!/bin/bash

DATA_DIR="$HOME/capture/data"
CORRUPTED_OUTPUT="$HOME/capture/corrupted.csv"
LOG_FILE="$HOME/capture/logs/cleanup.log"

# Create logs directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Start log entry
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting cleanup" >> "$LOG_FILE"

# Clear previous corrupted output
> "$CORRUPTED_OUTPUT"

# Find all CSV files recursively
find "$DATA_DIR" -type f -name "*.csv" | while read -r file; do
  fullpath="$(realpath "$file")"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Processing $fullpath" >> "$LOG_FILE"

  # Get expected column count from header
  expected=$(head -n 1 "$file" | awk -F',' '{print NF}')
  if [ -z "$expected" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Could not read header from $fullpath" >> "$LOG_FILE"
    continue
  fi

  # Create a temporary clean file
  tmp_clean="$(mktemp)"

  # Process each line
  awk -F',' -v cols="$expected" -v out="$CORRUPTED_OUTPUT" '
    NR == 1 { print $0 > "'"$tmp_clean"'"; next }
    NF == cols { print $0 >> "'"$tmp_clean"'" }
    NF != cols { print $0 >> out }
  ' "$file"

  # Replace original file with cleaned version
  if mv "$tmp_clean" "$file"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Cleaned $fullpath successfully" >> "$LOG_FILE"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ERROR: Failed to replace $fullpath" >> "$LOG_FILE"
  fi
done

echo "$(date '+%Y-%m-%d %H:%M:%S') - Cleanup complete. Corrupted lines saved to $CORRUPTED_OUTPUT" >> "$LOG_FILE"
