#!/usr/bin/env bash
set -euo pipefail

GLEAN_DB_ROOT="${GLEAN_DB_ROOT:-/data/glean-db}"
GLEAN_SCHEMA="${GLEAN_SCHEMA:-/opt/glean/schema}"
GLEAN_PORT="${GLEAN_PORT:-12345}"
GLEAN_SRC_ROOT="${GLEAN_SRC_ROOT:-/src}"

case "${1:-server}" in
    server)
        printf "Starting Glean server on port %s\n" "$GLEAN_PORT"
        printf "  DB root: %s\n" "$GLEAN_DB_ROOT"
        printf "  Schema:  %s\n" "$GLEAN_SCHEMA"
        exec glean-server \
            --db-root "$GLEAN_DB_ROOT" \
            --schema "$GLEAN_SCHEMA" \
            --port "$GLEAN_PORT"
        ;;
    index)
        shift
        exec /usr/local/share/glean/scripts/index.sh "$@"
        ;;
    lsp)
        shift
        exec /usr/local/share/glean/scripts/lsp.sh "$@"
        ;;
    shell)
        shift
        if [ "${GLEAN_PORT:-}" ]; then
            exec glean shell --service "localhost:${GLEAN_PORT}" "$@"
        else
            exec glean shell --db-root "$GLEAN_DB_ROOT" "$@"
        fi
        ;;
    query)
        shift
        DB_NAME="${1:?Usage: query DB_NAME ANGLE_QUERY}"
        shift
        QUERY="$*"
        exec glean query --service "localhost:${GLEAN_PORT}" --db "$DB_NAME" "$QUERY"
        ;;
    *)
        exec "$@"
        ;;
esac
