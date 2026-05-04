#!/usr/bin/env bash
# run_tests.sh — Test runner for the dotfiles management system.
# Usage: ./run_tests.sh [unit|property|integration|all]
#
# Prerequisites: bats-core must be available (as submodule or system install).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTS_DIR="${SCRIPT_DIR}/tests"

# Locate bats executable
if command -v bats &>/dev/null; then
    BATS="bats"
elif [ -f "${SCRIPT_DIR}/bats-core/bin/bats" ]; then
    BATS="${SCRIPT_DIR}/bats-core/bin/bats"
else
    echo "ERROR: bats not found. Install bats-core or run: git submodule update --init"
    exit 2
fi

PROPERTY_ITERATIONS="${PROPERTY_ITERATIONS:-100}"
export PROPERTY_ITERATIONS

TARGET="${1:-all}"
EXIT_CODE=0

run_suite() {
    local suite="$1"
    local dir="${TESTS_DIR}/${suite}"
    local bats_files
    mapfile -t bats_files < <(find "$dir" -name '*.bats' 2>/dev/null)

    if [ "${#bats_files[@]}" -eq 0 ]; then
        echo "No .bats files found in $dir"
        return 0
    fi

    echo ""
    echo "========================================"
    echo " Running ${suite} tests"
    echo "========================================"

    if ! "$BATS" --tap "${bats_files[@]}"; then
        EXIT_CODE=1
    fi
}

case "$TARGET" in
    unit)
        run_suite "unit"
        ;;
    property)
        run_suite "property"
        ;;
    integration)
        run_suite "integration"
        ;;
    all)
        run_suite "unit"
        run_suite "property"
        run_suite "integration"
        ;;
    *)
        echo "Usage: $0 [unit|property|integration|all]"
        exit 2
        ;;
esac

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "All tests passed!"
else
    echo "Some tests FAILED."
fi

exit "$EXIT_CODE"
