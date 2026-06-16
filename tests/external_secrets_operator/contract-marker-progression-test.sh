#!/bin/sh
set -eu

# Script: contract-marker-progression-test.sh
# Purpose: Verify that contract marker annotation changes when applying sequential configuration files
# for each contract-marker-* folder in tests/external_secrets_operator/success/
#
# Behavior:
# - For each contract-marker-* folder, find all _N.yaml files (ordered by number)
# - Generate templates using values-base.yaml + each _N.yaml overlay
# - Extract contract marker annotation and compute hash
# - Verify hash changes between consecutive generations
# - Report results for each folder

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_VALUES="${SCRIPT_DIR}/values-base.yaml"
SUCCESS_DIR="${SCRIPT_DIR}/success"
CHART_DIR="${SCRIPT_DIR}/../../charts/interop-eks-microservice-chart"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validate prerequisites
if [ ! -f "$BASE_VALUES" ]; then
    printf "%bERROR: Base values file not found: %s%b\n" "$RED" "$BASE_VALUES" "$NC"
    exit 1
fi

if [ ! -d "$CHART_DIR" ]; then
    printf "%bERROR: Chart directory not found: %s%b\n" "$RED" "$CHART_DIR" "$NC"
    exit 1
fi

if [ ! -d "$SUCCESS_DIR" ]; then
    printf "%bERROR: Success directory not found: %s%b\n" "$RED" "$SUCCESS_DIR" "$NC"
    exit 1
fi

# Function: Extract secret-applied-hash annotation from ExternalSecret template output
extract_contract_marker() {
    local template_output="$1"
    echo "$template_output" | grep 'secret-applied-hash:' | sed 's/.*secret-applied-hash:[[:space:]]*//;s/[[:space:]]*$//'
}

# Function: Compute hash of a string
compute_hash() {
    echo -n "$1" | md5sum | awk '{print $1}'
}

# Function: Get first 8 characters of string
first_8_chars() {
    echo "$1" | cut -c1-8
}

# Function: Test a single contract-marker folder
test_contract_marker_folder() {
    local folder_path="$1"
    local folder_name
    folder_name="$(basename "$folder_path")"

    printf "%b=== Testing folder: %s ===%b\n" "$BLUE" "$folder_name" "$NC"

    # Find all _N.yaml files and sort by number
    local files
    files="$(find "$folder_path" -maxdepth 1 -name '*_[0-9]*.yaml' -type f | sort -V)"

    # Count files
    local file_count
    file_count="$(echo "$files" | grep -c . || echo 0)"

    if [ "$file_count" -eq 0 ]; then
        printf "%b⚠ No test files found in folder%b\n" "$YELLOW" "$NC"
        return 1
    fi

    printf "Found %d test file(s)\n" "$file_count"

    local prev_hash=""
    local all_passed=true
    local current_step=0

    # Iterate over files
    echo "$files" | while IFS= read -r file; do
        current_step=$((current_step + 1))
        local file_name
        file_name="$(basename "$file")"

        # Check if file has "no-change" marker
        local expect_no_change=false
        if grep -q "# no-change:" "$file" 2>/dev/null; then
            expect_no_change=true
        fi

        # Generate template with values-base + current values file
        local template_output
        if ! template_output=$(helm template test "$CHART_DIR" \
            -f "$BASE_VALUES" \
            -f "$file" 2>&1); then
            printf "%b✗ Step %d (%s): Template generation FAILED%b\n" "$RED" "$current_step" "$file_name" "$NC"
            printf "  Error: %s\n" "$template_output"
            return 1
        fi

        # Extract contract marker annotation
        local marker
        marker=$(extract_contract_marker "$template_output")

        if [ -z "$marker" ]; then
            printf "%b✗ Step %d (%s): Contract marker annotation NOT FOUND%b\n" "$RED" "$current_step" "$file_name" "$NC"
            return 1
        fi

        # Compute hash
        local current_hash
        current_hash=$(compute_hash "$marker")

        if [ $current_step -eq 1 ]; then
            # First file - establish baseline
            local hash_short
            hash_short=$(first_8_chars "$current_hash")
            printf "%b✓ Step %d (%s): Marker hash = %s...%b\n" "$GREEN" "$current_step" "$file_name" "$hash_short" "$NC"
            prev_hash="$current_hash"
        else
            # Subsequent files - verify hash behavior based on marker
            if [ "$expect_no_change" = true ]; then
                # Hash should NOT change
                if [ "$current_hash" = "$prev_hash" ]; then
                    local hash_short
                    hash_short=$(first_8_chars "$current_hash")
                    printf "%b✓ Step %d (%s): Marker hash unchanged (as expected: %s...)%b\n" "$GREEN" "$current_step" "$file_name" "$hash_short" "$NC"
                else
                    local prev_short curr_short
                    prev_short=$(first_8_chars "$prev_hash")
                    curr_short=$(first_8_chars "$current_hash")
                    printf "%b✗ Step %d (%s): Marker hash CHANGED but should NOT have (was %s... now %s...)%b\n" "$RED" "$current_step" "$file_name" "$prev_short" "$curr_short" "$NC"
                    return 1
                fi
            else
                # Hash SHOULD change (default behavior)
                if [ "$current_hash" != "$prev_hash" ]; then
                    local hash_short
                    hash_short=$(first_8_chars "$current_hash")
                    printf "%b✓ Step %d (%s): Marker hash CHANGED (%s...) ✓%b\n" "$GREEN" "$current_step" "$file_name" "$hash_short" "$NC"
                else
                    local hash_short
                    hash_short=$(first_8_chars "$current_hash")
                    printf "%b✗ Step %d (%s): Marker hash DID NOT CHANGE (still %s...)%b\n" "$RED" "$current_step" "$file_name" "$hash_short" "$NC"
                    return 1
                fi
            fi
            prev_hash="$current_hash"
        fi
    done

    printf "%bResult: PASSED%b\n" "$GREEN" "$NC"
    return 0
}

# Main execution
printf "%bContract Marker Progression Test%b\n" "$BLUE" "$NC"
printf "Base values: %s\n" "$BASE_VALUES"
printf "Chart: %s\n\n" "$CHART_DIR"

# Find all contract-marker-* folders
folders="$(find "$SUCCESS_DIR" -maxdepth 1 -type d -name 'contract-marker-*' | sort)"

if [ -z "$folders" ]; then
    printf "%bNo contract-marker-* folders found in %s%b\n" "$YELLOW" "$SUCCESS_DIR" "$NC"
    exit 1
fi

# Count folders
folder_count="$(echo "$folders" | grep -c . || echo 0)"
printf "Found %d contract-marker folder(s)\n\n" "$folder_count"

# Run tests for each folder
all_tests_passed=true
echo "$folders" | while IFS= read -r folder; do
    if ! test_contract_marker_folder "$folder"; then
        all_tests_passed=false
    fi
done

# Summary
printf "\n%b=== Summary ===%b\n" "$BLUE" "$NC"
printf "Total folders tested: %d\n" "$folder_count"

# Check if all tests passed by running validation pass
test_failed=0
echo "$folders" | while IFS= read -r folder; do
    if ! test_contract_marker_folder "$folder" >/dev/null 2>&1; then
        test_failed=1
    fi
done

if [ "$test_failed" -eq 0 ]; then
    printf "\n%bAll contract marker progression tests PASSED ✓%b\n" "$GREEN" "$NC"
    exit 0
else
    printf "\n%bSome contract marker progression tests FAILED ✗%b\n" "$RED" "$NC"
    exit 1
fi
