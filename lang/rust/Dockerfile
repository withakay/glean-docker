# =============================================================================
# Glean + Rust - Code Indexing & Navigation for Rust Projects
# =============================================================================
#
# Extends the Glean base image with:
#   - Rust stable toolchain (rustup)
#   - rust-analyzer (for LSIF/SCIP index generation)
#
# Supports both LSIF and SCIP indexing modes:
#   - LSIF (default): `glean index rust-lsif /src --db-root /data/glean-db --db mydb/1`
#   - SCIP: `glean index rust-scip /src --db-root /data/glean-db --db mydb/1`
#
# =============================================================================

ARG BASE_IMAGE=ghcr.io/withakay/glean-docker/base:latest
FROM ${BASE_IMAGE}

# Install Rust toolchain with rust-analyzer
ENV RUSTUP_HOME=/opt/rustup
ENV CARGO_HOME=/opt/cargo
ENV PATH="/opt/cargo/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain stable --component rust-analyzer && \
    rust-analyzer --version

# Copy Rust-specific helper scripts
COPY scripts/ /usr/local/share/glean/scripts/
RUN chmod +x /usr/local/share/glean/scripts/*.sh

ENTRYPOINT ["/usr/local/share/glean/scripts/entrypoint.sh"]
CMD ["lsp"]
