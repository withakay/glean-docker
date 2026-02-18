# =============================================================================
# Glean + TypeScript - Code Indexing & Navigation for TS/JS Projects
# =============================================================================
#
# Extends the Glean base image with:
#   - Node.js + npm
#   - scip-typescript (SCIP indexer for TypeScript/JavaScript)
#
# Usage:
#   glean index lsif-typescript /src --db-root /data/glean-db --db mydb/1
#
# =============================================================================

ARG BASE_IMAGE=ghcr.io/withakay/glean-docker/base:latest
FROM ${BASE_IMAGE}

# TODO: Install Node.js and scip-typescript
# RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
# RUN apt-get install -y nodejs
# RUN npm install -g @sourcegraph/scip-typescript

RUN echo "typescript language support is not yet implemented" > /opt/glean/LANG_STATUS
