#!/usr/bin/env bash
set -euo pipefail

# Configuration via environment variables or arguments
DB_ROOT="${GLEAN_DB_ROOT:-/data/glean-db}"
DB_NAME="${1:-${GLEAN_DB_NAME:-project}}"
DB_INSTANCE="${GLEAN_DB_INSTANCE:-1}"
SRC_ROOT="${GLEAN_SRC_ROOT:-/src}"
INDEX_MODE="${GLEAN_INDEX_MODE:-lsif}"
SERVICE="${GLEAN_SERVICE:-}"

DB="${DB_NAME}/${DB_INSTANCE}"

# Build connection args (prefer server if available)
CONN_ARGS=()
if [ -n "$SERVICE" ]; then
    CONN_ARGS=(--service "$SERVICE")
else
    CONN_ARGS=(--db-root "$DB_ROOT")
fi

printf "================================================================\n"
printf "Glean Rust Indexer\n"
printf "================================================================\n"
printf "  DB Name:    %s\n" "$DB"
printf "  Source:     %s\n" "$SRC_ROOT"
printf "  Mode:       %s\n" "$INDEX_MODE"
if [ -n "$SERVICE" ]; then
    printf "  Server:     %s\n" "$SERVICE"
else
    printf "  DB Root:    %s\n" "$DB_ROOT"
fi
printf "================================================================\n"

# Remove existing DB if present
if glean list "${CONN_ARGS[@]}" 2>/dev/null | grep -q "^${DB_NAME}/"; then
    printf "Removing existing database %s...\n" "$DB_NAME"
    glean delete "${CONN_ARGS[@]}" --db "$DB" 2>/dev/null || true
fi

# Run the indexer
cd "$SRC_ROOT"
case "$INDEX_MODE" in
    scip|rust-scip)
        printf "Indexing with rust-scip (SCIP format)...\n"
        glean index rust-scip "$SRC_ROOT" \
            "${CONN_ARGS[@]}" \
            --db "$DB"
        ;;
    lsif|rust-lsif|*)
        printf "Indexing with rust-lsif (LSIF format)...\n"
        glean index rust-lsif "$SRC_ROOT" \
            "${CONN_ARGS[@]}" \
            --db "$DB"
        ;;
esac

printf "\n================================================================\n"
printf "Indexing complete. Database: %s\n" "$DB"
printf "================================================================\n"

# Print stats
glean stats "${CONN_ARGS[@]}" --db "$DB" 2>/dev/null || true

# Quick sanity check
FILE_COUNT=$(glean query "${CONN_ARGS[@]}" --db "$DB" --limit 0 'src.File _' 2>/dev/null | grep -c "^{" || echo "?")
printf "\nFiles indexed: %s\n" "$FILE_COUNT"
printf "================================================================\n"
