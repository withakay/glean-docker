# =============================================================================
# Glean + Go - Code Indexing & Navigation for Go Projects
# =============================================================================
#
# Extends the Glean base image with:
#   - Go toolchain
#   - scip-go (SCIP indexer for Go)
#
# Usage:
#   glean index lsif-go /src --db-root /data/glean-db --db mydb/1
#
# =============================================================================

ARG BASE_IMAGE=ghcr.io/withakay/glean-docker/base:latest
FROM ${BASE_IMAGE}

# TODO: Install Go and scip-go
# RUN curl -fsSL https://go.dev/dl/go1.22.linux-$(dpkg --print-architecture).tar.gz | tar -C /usr/local -xz
# ENV PATH="/usr/local/go/bin:${PATH}"
# RUN go install github.com/sourcegraph/scip-go/cmd/scip-go@latest

RUN echo "go language support is not yet implemented" > /opt/glean/LANG_STATUS
