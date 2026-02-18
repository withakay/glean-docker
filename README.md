# glean-docker

Pre-built [Glean](https://glean.software/) Docker images for code indexing and navigation.

Glean is Meta's code indexing system. It provides cross-reference navigation (go-to-definition, find-references, hover docs) via an LSP server backed by a persistent database of indexed facts.

## Architecture

```
ghcr.io/withakay/glean-docker/base     <- Glean core (glean, glean-server, glean-lsp, schemas)
  |
  +-- ghcr.io/withakay/glean-docker/rust      <- + Rust toolchain + rust-analyzer
  +-- ghcr.io/withakay/glean-docker/dotnet    <- + .NET SDK + scip-dotnet (planned)
  +-- ghcr.io/withakay/glean-docker/python    <- + Python + scip-python (planned)
  +-- ghcr.io/withakay/glean-docker/typescript <- + Node.js + scip-typescript (planned)
  +-- ghcr.io/withakay/glean-docker/go        <- + Go + scip-go (planned)
  +-- ghcr.io/withakay/glean-docker/cpp       <- + Clang + glean-clang (planned)
```

The **base image** contains the expensive Glean build (~30 min from source) and is language-agnostic. **Language images** extend the base with a toolchain and indexer, adding only a thin layer.

Both `linux/amd64` and `linux/arm64` are supported.

## Quick Start (Rust)

```bash
# Pull the pre-built Rust image
docker pull ghcr.io/withakay/glean-docker/rust:latest

# Index your project
docker run --rm \
  -v /path/to/your/project:/src:ro \
  -v glean-db:/data/glean-db \
  ghcr.io/withakay/glean-docker/rust:latest index

# Start the LSP server (stdio)
docker run --rm -i \
  -v glean-db:/data/glean-db \
  ghcr.io/withakay/glean-docker/rust:latest lsp

# Interactive Angle query shell
docker run --rm -it \
  -v glean-db:/data/glean-db \
  ghcr.io/withakay/glean-docker/rust:latest shell
```

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `GLEAN_DB_ROOT` | `/data/glean-db` | Path to the Glean database directory |
| `GLEAN_DB_NAME` | `project` | Database name |
| `GLEAN_DB_INSTANCE` | `1` | Database instance number |
| `GLEAN_SRC_ROOT` | `/src` | Path to the mounted source code |
| `GLEAN_INDEX_MODE` | `lsif` | Indexing mode: `lsif` or `scip` |

## Editor Setup

### VS Code

1. Install the [Generic LSP Client](https://marketplace.visualstudio.com/items?itemName=AGeiger.vscode-glspc) extension
2. Add to `.vscode/settings.json`:

```json
{
  "glean-lsp.repo": "project",
  "glspc.server.command": "docker",
  "glspc.server.commandArguments": [
    "run", "--rm", "-i",
    "-v", "glean-db:/data/glean-db",
    "ghcr.io/withakay/glean-docker/rust:latest",
    "lsp"
  ],
  "glspc.server.languageId": ["rust"]
}
```

### Neovim

```lua
vim.lsp.start({
  name = "glean-lsp",
  cmd = {
    "docker", "run", "--rm", "-i",
    "-v", "glean-db:/data/glean-db",
    "ghcr.io/withakay/glean-docker/rust:latest",
    "lsp"
  },
  filetypes = { "rust" },
})
```

## Building Locally

```bash
# Build the base image (~30 min first time)
docker build -t glean-base base/

# Build a language image
docker build -t glean-rust \
  --build-arg BASE_IMAGE=glean-base \
  lang/rust/
```

## Project Structure

```
glean-docker/
  base/
    Dockerfile          # Glean core: glean, glean-server, glean-lsp, schemas
  lang/
    rust/
      Dockerfile        # FROM base + Rust toolchain + rust-analyzer
      scripts/          # Entrypoint, index, LSP helper scripts
    dotnet/
      Dockerfile        # FROM base + .NET SDK (planned)
    python/
      Dockerfile        # FROM base + Python (planned)
    typescript/
      Dockerfile        # FROM base + Node.js (planned)
    go/
      Dockerfile        # FROM base + Go (planned)
    cpp/
      Dockerfile        # FROM base + Clang (planned)
  .github/
    workflows/
      build.yml         # CI: build + push to ghcr.io
```

## Build Workarounds

The Glean build from source requires several workarounds documented in `base/Dockerfile`:

- **aarch64 duplicate symbols**: folly's assembly files produce duplicate symbols when building shared libs on ARM64. Patched with `--allow-multiple-definition` linker flag.
- **OpenSSL 3.0 deprecation**: Ubuntu 22.04's OpenSSL 3.0 deprecates APIs used by folly. Solved by using system folly (`-bundled-folly` flag) instead of bundled sources.
- **System folly linking**: `folly-clib` uses system folly via pkg-config, which includes all transitive link dependencies (lz4, zstd, bz2, etc.).

## License

The Dockerfiles in this repository are MIT licensed. Glean itself is licensed under the BSD 3-Clause License.
