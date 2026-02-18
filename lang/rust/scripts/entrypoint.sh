#!/usr/bin/env bash
set -euo pipefail

GLEAN_DB_ROOT="${GLEAN_DB_ROOT:-/data/glean-db}"
GLEAN_DB_NAME="${GLEAN_DB_NAME:-project}"
GLEAN_DB_INSTANCE="${GLEAN_DB_INSTANCE:-1}"
GLEAN_SRC_ROOT="${GLEAN_SRC_ROOT:-/src}"

case "${1:-lsp}" in
    index)
        exec /usr/local/share/glean/scripts/index.sh
        ;;
    lsp)
        exec /usr/local/share/glean/scripts/lsp.sh
        ;;
    shell)
        exec glean shell --db-root "$GLEAN_DB_ROOT"
        ;;
    *)
        exec "$@"
        ;;
esac
