# =============================================================================
# Glean + Python - Code Indexing & Navigation for Python Projects
# =============================================================================
#
# Extends the Glean base image with:
#   - Python 3 + pip
#   - scip-python (SCIP indexer for Python)
#
# Usage:
#   glean index python-scip /src --db-root /data/glean-db --db mydb/1
#
# =============================================================================

ARG BASE_IMAGE=ghcr.io/withakay/glean-docker/base:latest
FROM ${BASE_IMAGE}

# TODO: Install scip-python
# RUN pip3 install scip-python

RUN echo "python language support is not yet implemented" > /opt/glean/LANG_STATUS
