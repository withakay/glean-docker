# =============================================================================
# Glean + C/C++ - Code Indexing & Navigation for C/C++ Projects
# =============================================================================
#
# Extends the Glean base image with:
#   - Clang/LLVM toolchain
#   - glean-clang (Glean's native C/C++ indexer)
#
# Note: glean-clang is built from the Glean source tree and requires a
# compile_commands.json (from CMake, Bear, etc.) for indexing.
#
# Usage:
#   glean index cpp-cmake /src --db-root /data/glean-db --db mydb/1 --cdb-dir /src/build
#
# =============================================================================

ARG BASE_IMAGE=ghcr.io/withakay/glean-docker/base:latest
FROM ${BASE_IMAGE}

# TODO: Install clang and build glean-clang from source
# The C++ indexer requires building glean-clang from the Glean source,
# which needs the full LLVM/Clang development libraries.

RUN echo "cpp language support is not yet implemented" > /opt/glean/LANG_STATUS
