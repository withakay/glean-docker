#!/usr/bin/env bash
set -euo pipefail

# Configuration via environment variables
DB_ROOT="${GLEAN_DB_ROOT:-/data/glean-db}"
DB_NAME="${GLEAN_DB_NAME:-project}"
DB_INSTANCE="${GLEAN_DB_INSTANCE:-1}"
SRC_ROOT="${GLEAN_SRC_ROOT:-/src}"
INDEX_MODE="${GLEAN_INDEX_MODE:-lsif}"

DB="${DB_NAME}/${DB_INSTANCE}"

printf "================================================================\n"
printf "Glean Rust Indexer\n"
printf "================================================================\n"
printf "  DB Root:    %s\n" "$DB_ROOT"
printf "  DB Name:    %s\n" "$DB"
printf "  Source:     %s\n" "$SRC_ROOT"
printf "  Mode:       %s\n" "$INDEX_MODE"
printf "================================================================\n"

# Remove existing DB if present
if glean list --db-root "$DB_ROOT" 2>/dev/null | grep -q "^${DB_NAME}/"; then
    printf "Removing existing database %s...\n" "$DB_NAME"
    glean delete --db-root "$DB_ROOT" --db "$DB" 2>/dev/null || true
fi

# Run the indexer
cd "$SRC_ROOT"
case "$INDEX_MODE" in
    scip|rust-scip)
        printf "Indexing with rust-scip (SCIP format)...\n"
        glean index rust-scip "$SRC_ROOT" \
            --db-root "$DB_ROOT" \
            --db "$DB"
        ;;
    lsif|rust-lsif|*)
        printf "Indexing with rust-lsif (LSIF format)...\n"
        glean index rust-lsif "$SRC_ROOT" \
            --db-root "$DB_ROOT" \
            --db "$DB"
        ;;
esac

printf "\n================================================================\n"
printf "Indexing complete. Database: %s\n" "$DB"
printf "================================================================\n"

# Print stats
glean stats --db-root "$DB_ROOT" --db "$DB" 2>/dev/null || true

# Quick sanity check
FILE_COUNT=$(glean query --db-root "$DB_ROOT" --db "$DB" --limit 0 'src.File _' 2>/dev/null | grep -c "^{" || echo "?")
printf "\nFiles indexed: %s\n" "$FILE_COUNT"
printf "================================================================\n"
