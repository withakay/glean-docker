# =============================================================================
# Glean + .NET - Code Indexing & Navigation for C#/F# Projects
# =============================================================================
#
# Extends the Glean base image with:
#   - .NET SDK
#   - scip-dotnet (SCIP indexer for C#/F#)
#
# Usage:
#   glean index scip-dotnet /src --db-root /data/glean-db --db mydb/1
#
# =============================================================================

ARG BASE_IMAGE=ghcr.io/withakay/glean-docker/base:latest
FROM ${BASE_IMAGE}

# TODO: Install .NET SDK and scip-dotnet
# RUN apt-get update && apt-get install -y dotnet-sdk-8.0
# RUN dotnet tool install --global scip-dotnet

RUN echo "dotnet language support is not yet implemented" > /opt/glean/LANG_STATUS
