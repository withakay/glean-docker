#!/usr/bin/env bash
set -euo pipefail

DB_ROOT="${GLEAN_DB_ROOT:-/data/glean-db}"
DB_NAME="${GLEAN_DB_NAME:-project}"

# Verify database exists
if ! glean list --db-root "$DB_ROOT" 2>/dev/null | grep -q "^${DB_NAME}/"; then
    echo "ERROR: No database found for '${DB_NAME}' in ${DB_ROOT}" >&2
    echo "Run the indexer first: docker compose run --rm glean-index" >&2
    exit 1
fi

exec glean-lsp --db-root "$DB_ROOT" --repo "$DB_NAME"
