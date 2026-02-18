#!/usr/bin/env bash
set -euo pipefail

DB_ROOT="${GLEAN_DB_ROOT:-/data/glean-db}"
DB_NAME="${1:-${GLEAN_DB_NAME:-project}}"
SERVICE="${GLEAN_SERVICE:-}"

# Build connection args
CONN_ARGS=()
LSP_ARGS=()
if [ -n "$SERVICE" ]; then
    CONN_ARGS=(--service "$SERVICE")
    LSP_ARGS=(--service "$SERVICE" --repo "$DB_NAME")
else
    CONN_ARGS=(--db-root "$DB_ROOT")
    LSP_ARGS=(--db-root "$DB_ROOT" --repo "$DB_NAME")
fi

# Verify database exists
if ! glean list "${CONN_ARGS[@]}" 2>/dev/null | grep -q "^${DB_NAME}/"; then
    echo "ERROR: No database found for '${DB_NAME}'" >&2
    echo "Run: gleanctl index PATH --db ${DB_NAME}" >&2
    exit 1
fi

exec glean-lsp "${LSP_ARGS[@]}"
