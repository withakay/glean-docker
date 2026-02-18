# =============================================================================
# Glean Base Image - Code Indexing & Navigation Core
# =============================================================================
#
# Multi-stage build that produces a minimal runtime image containing:
#   - glean (CLI + indexer driver)
#   - glean-server (Thrift API server)
#   - glean-lsp (Language Server Protocol server)
#   - Angle schema files for all supported indexers
#
# This base image is language-agnostic. Language-specific images (Rust, Python,
# etc.) build FROM this image and add their respective toolchains and indexers.
#
# Build time: ~30 minutes (mostly C++ deps: folly, hsthrift)
# Image size: ~800 MB (runtime stage)
#
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: Build Glean from source
# ---------------------------------------------------------------------------
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Core build toolchain + all system deps required by folly/hsthrift/glean
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    binutils-dev \
    bison \
    build-essential \
    ca-certificates \
    cmake \
    curl \
    flex \
    g++ \
    gcc \
    git \
    libaio-dev \
    libboost-all-dev \
    libbz2-dev \
    libdouble-conversion-dev \
    libevent-dev \
    libfmt-dev \
    libgflags-dev \
    libgmock-dev \
    libgmp-dev \
    libgoogle-glog-dev \
    libgtest-dev \
    libiberty-dev \
    libjemalloc-dev \
    liblz4-dev \
    libncurses-dev \
    libpcre3-dev \
    librocksdb-dev \
    libsnappy-dev \
    libsodium-dev \
    libssl-dev \
    libtool \
    libunwind-dev \
    libxxhash-dev \
    libzstd-dev \
    make \
    ninja-build \
    pkg-config \
    python3 \
    python3-pip \
    rsync \
    wget \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install GHC and Cabal via ghcup
ENV GHCUP_INSTALL_BASE_PREFIX=/opt
RUN curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | \
    BOOTSTRAP_HASKELL_NONINTERACTIVE=1 \
    BOOTSTRAP_HASKELL_GHC_VERSION=9.6.7 \
    BOOTSTRAP_HASKELL_CABAL_VERSION=3.10.3.0 \
    BOOTSTRAP_HASKELL_INSTALL_NO_STACK=1 \
    sh
ENV PATH="/opt/.ghcup/bin:${PATH}"

# Clone Glean source
WORKDIR /build
RUN git clone --depth 1 https://github.com/facebookincubator/Glean.git glean
WORKDIR /build/glean

# Install hsthrift/folly C++ dependencies via getdeps.py
# install_deps.sh clones hsthrift and builds folly + deps from source
#
# Workaround: folly's aarch64 assembly files (external/aor/) produce duplicate
# symbol definitions when building as shared libs (which hsthrift requires).
# We patch the linker flags to allow multiple definitions on aarch64.
# See: https://github.com/facebook/folly/issues/2246
RUN ./install_deps.sh --threads "$(nproc)" || true && \
    if [ "$(uname -m)" = "aarch64" ]; then \
        echo ">>> aarch64 detected: patching linker flags for folly duplicate symbols" && \
        cd hsthrift && \
        sed -i 's|"BUILD_SHARED_LIBS": "ON"|"BUILD_SHARED_LIBS": "ON", "CMAKE_SHARED_LINKER_FLAGS": "-Wl,--allow-multiple-definition"|' build.sh && \
        cd .. && \
        ./install_deps.sh --threads "$(nproc)"; \
    fi

# Set library paths for the hsthrift-built libs
ENV LD_LIBRARY_PATH="/root/.hsthrift/lib:${LD_LIBRARY_PATH}"
ENV PKG_CONFIG_PATH="/root/.hsthrift/lib/pkgconfig:${PKG_CONFIG_PATH}"
ENV PATH="/root/.hsthrift/bin:${PATH}"

# Build Glean: core tools + LSP server
#
# install_deps.sh builds folly as a system library (with pkg-config support
# under ~/.hsthrift/). We tell folly-clib to use that system folly instead
# of bundling its own copy. This avoids:
#   - OpenSSL 3.0 deprecation errors in bundled folly C++ sources
#   - Missing lz4/zstd/bz2 link deps (the pkg-config file has them all)
#
# We also need to suppress -Werror for folly-clib since the system folly
# headers still have some deprecation warnings.
RUN echo "" >> cabal.project && \
    echo "package folly-clib" >> cabal.project && \
    echo "  flags: -bundled-folly" >> cabal.project && \
    echo "  ghc-options: -Wno-error" >> cabal.project && \
    echo "" >> cabal.project && \
    echo "=== Patched cabal.project (tail) ===" && \
    tail -10 cabal.project
RUN cabal update && make
RUN cabal build glean-lsp

# Collect binaries into a known location
RUN mkdir -p /opt/glean/bin && \
    cp "$(cabal -v0 list-bin glean)" /opt/glean/bin/ && \
    cp "$(cabal -v0 list-bin glean-server)" /opt/glean/bin/ && \
    cp "$(cabal -v0 list-bin glean-lsp)" /opt/glean/bin/

# Collect shared libraries that the binaries need at runtime
RUN mkdir -p /opt/glean/lib && \
    cp -a /root/.hsthrift/lib/*.so* /opt/glean/lib/ 2>/dev/null || true

# Collect Glean schema data files (required at runtime for indexing/queries)
# Schema source files live in the Glean source tree, not in .cabal/share
RUN mkdir -p /opt/glean/schema && \
    cp -a /build/glean/glean/schema/source /opt/glean/schema/

# ---------------------------------------------------------------------------
# Stage 2: Runtime image with Glean core (no language toolchains)
# ---------------------------------------------------------------------------
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime deps (shared libs the Glean binaries link against)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    libaio1 \
    libatomic1 \
    libboost-context1.74.0 \
    libboost-filesystem1.74.0 \
    libboost-program-options1.74.0 \
    libboost-regex1.74.0 \
    libboost-thread1.74.0 \
    libdouble-conversion3 \
    libevent-2.1-7 \
    libfmt8 \
    libgflags2.2 \
    libgmp10 \
    libgoogle-glog0v5 \
    libjemalloc2 \
    liblz4-1 \
    librocksdb-dev \
    libsnappy1v5 \
    libsodium23 \
    libssl3 \
    libunwind8 \
    libxxhash0 \
    libzstd1 \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy Glean binaries, libraries, and schema data
COPY --from=builder /opt/glean/bin/ /usr/local/bin/
COPY --from=builder /opt/glean/lib/ /usr/local/lib/glean/
COPY --from=builder /opt/glean/schema/ /opt/glean/schema/
ENV LD_LIBRARY_PATH="/usr/local/lib/glean:${LD_LIBRARY_PATH}"
RUN ldconfig

# Create schema symlink so Glean can find schema files at the expected path
# Glean looks for schemas at ~/.cabal/share/<arch>-linux-ghc-<ver>/glean-<ver>/glean/schema/source
RUN ARCH=$(uname -m | sed 's/x86_64/x86_64/;s/aarch64/aarch64/') && \
    SCHEMA_DIR="/root/.cabal/share/${ARCH}-linux-ghc-9.6.7/glean-0.2.0.0/glean/schema" && \
    mkdir -p "$SCHEMA_DIR" && \
    ln -sf /opt/glean/schema/source "$SCHEMA_DIR/source"

# Create directories for Glean databases and source mounting
RUN mkdir -p /data/glean-db /src

WORKDIR /src

# Default entrypoint: glean CLI
ENTRYPOINT ["glean"]
CMD ["--help"]
