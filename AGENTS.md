# AGENTS.md -- Guidance for AI Assistants

## Project Overview

This repo provides pre-built Docker images for [Glean](https://glean.software/), Meta's code indexing system. Glean indexes source code into a queryable database and provides cross-reference navigation (go-to-definition, find-references, hover docs) via an LSP server and an Angle query language.

The repo also includes `gleanctl`, a CLI for managing a persistent local Glean server that supports multiple codebases.

## Architecture

```
base/Dockerfile          -- Glean core built from source (~30 min)
                            Contains: glean, glean-server, glean-lsp, Angle schemas
                            Ubuntu 22.04, GHC 9.6.7, hsthrift, folly

lang/<language>/         -- Language layers (thin, FROM base)
  rust/                  -- Rust stable + rust-analyzer (LSIF/SCIP indexing)
  dotnet/                -- .NET SDK + scip-dotnet (stub)
  python/                -- Python + scip-python (stub)
  typescript/            -- Node.js + scip-typescript (stub)
  go/                    -- Go + scip-go (stub)
  cpp/                   -- Clang + glean-clang (stub)

gleanctl                 -- CLI for managing the persistent server + indexing
```

Images are published to `ghcr.io/withakay/glean-docker/{base,rust,...}`.

### Image Layers

- **Base image** is the expensive part (~30 min build). It compiles Glean and all C++ dependencies (folly, hsthrift, rocksdb) from source. This rarely needs rebuilding.
- **Language images** are thin layers (~2 min build) that add a toolchain and indexer. These are cheap to rebuild when a toolchain updates.

### Multi-Arch Support

Both `linux/amd64` and `linux/arm64` are supported. The Dockerfile has arch-specific workarounds gated behind `uname -m` checks:

- **aarch64**: folly assembly files produce duplicate symbols. Patched with `--allow-multiple-definition`.
- **x86_64**: No workarounds needed.

CI builds both platforms via `docker/build-push-action` with QEMU.

## Key Build Workarounds

Building Glean from source on Ubuntu 22.04 required several hard-won fixes. **Do not remove these without testing** -- they took many iterations to get right:

1. **System folly (`-bundled-folly`)**: The `folly-clib` Hackage package bundles folly sources that are missing lz4/zstd/bz2/z link deps. We set `flags: -bundled-folly` in `cabal.project` to use the system folly built by `install_deps.sh` via pkg-config, which includes all transitive deps.

2. **aarch64 linker fix**: folly's `external/aor/` assembly files for memcpy/memset produce duplicate symbols (`_aarch64_memcpy`, `_aarch64_memset`) when building shared libs on ARM64. We patch `hsthrift/build.sh` to add `-Wl,--allow-multiple-definition`. Only triggered on aarch64.

3. **OpenSSL 3.0 compatibility**: Solved by #1 (system folly was compiled against OpenSSL 3.0 correctly).

4. **Missing system packages**: `libaio-dev`, `libbz2-dev`, `rsync` are not in the hsthrift CI base image but are required.

5. **Schema files location**: Glean expects schema files at `~/.cabal/share/<arch>-linux-ghc-<ver>/glean-<ver>/glean/schema/`. The builder copies them from `/build/glean/glean/schema/` and creates a symlink.

## gleanctl

`gleanctl` is a shell script (`/bin/bash`) that manages a persistent Docker container running `glean-server` on a configurable port (default 12345).

### Commands

| Command | Description |
|---|---|
| `start` | Create and start the server container |
| `stop` / `restart` | Stop or restart the server |
| `destroy` | Remove container (preserves DB volume) |
| `status` | Show server status and list indexed databases |
| `index [PATH] [--db NAME] [--lang LANG] [--mode lsif\|scip]` | Index a codebase |
| `query DB 'ANGLE_QUERY' [--limit N]` | Run an Angle query against a database |
| `shell [DB]` | Interactive Angle query REPL |
| `lsp DB` | Start LSP server for editor integration (stdio) |
| `db list` | List all databases |
| `db delete DB` | Delete a database |
| `logs [-f]` | View server logs |
| `install` | Self-install to `~/.local/bin` |

### How Indexing Works

1. `gleanctl index` runs a **separate ephemeral container** (not `docker exec`) because it needs to mount the source directory.
2. The ephemeral container shares the server's network namespace (`--network container:glean-server`) so it can connect to the server on `localhost:12345`.
3. The `glean index` command generates LSIF/SCIP via the language toolchain (e.g., `rust-analyzer lsif .`) and writes facts through the server's Thrift API (`--service localhost:12345`).
4. Because indexing goes through the server API, databases are immediately visible without restart.

### Configuration

All configurable via environment variables:

| Variable | Default | Description |
|---|---|---|
| `GLEANCTL_CONTAINER` | `glean-server` | Docker container name |
| `GLEANCTL_IMAGE` | `ghcr.io/withakay/glean-docker/rust:latest` | Docker image to use |
| `GLEANCTL_PORT` | `12345` | Server Thrift port |
| `GLEANCTL_VOLUME` | `glean-data` | Docker volume for database persistence |

### Language Auto-Detection

`gleanctl index` detects language from project files:

| File | Language | Indexer |
|---|---|---|
| `Cargo.toml` | rust | `rust-lsif` (default) or `rust-scip` |
| `go.mod` | go | `go-lsif` (planned) |
| `package.json` | typescript | (planned) |
| `setup.py` / `pyproject.toml` | python | `python-scip` (planned) |
| `*.csproj` / `*.sln` | dotnet | `scip-dotnet` (planned) |
| `CMakeLists.txt` | cpp | `cpp-cmake` (planned) |

## Adding a New Language

1. Create `lang/<language>/Dockerfile`:
   ```dockerfile
   ARG BASE_IMAGE=ghcr.io/withakay/glean-docker/base:latest
   FROM ${BASE_IMAGE}
   # Install toolchain + indexer
   # Copy scripts
   COPY scripts/ /usr/local/share/glean/scripts/
   RUN chmod +x /usr/local/share/glean/scripts/*.sh
   ENTRYPOINT ["/usr/local/share/glean/scripts/entrypoint.sh"]
   CMD ["lsp"]
   ```

2. Create `lang/<language>/scripts/`:
   - `entrypoint.sh` -- dispatch on `$1` (server, index, lsp, shell, query)
   - `index.sh` -- run the language-specific indexer, then `glean index <lang>-{lsif,scip}`
   - `lsp.sh` -- start `glean-lsp` with `--repo`

3. Uncomment the language in `.github/workflows/build.yml` matrix.

4. Add language detection to `gleanctl`'s `detect_language()` function.

5. Update `gleanctl`'s `GLEANCTL_IMAGE` default if needed, or document that users should set it per-project.

### Indexer Formats

Glean supports two index formats for non-native languages:

- **LSIF** (Language Server Index Format): Older, broader support. Schema: `lsif.angle`. Rust uses `rust-analyzer lsif .`.
- **SCIP** (SCIP Code Intelligence Protocol): Newer, richer. Schema: `scip.angle`. Rust uses `rust-analyzer scip .` but has a known bug ("file emitted multiple times") in some versions.

**Prefer LSIF for Rust** until the `rust-analyzer scip` bug is fixed. For Python and .NET, use SCIP (Glean has `python-scip` and `scip-dotnet` indexers).

## Angle Query Language

Glean uses [Angle](https://glean.software/docs/angle/guide/) for querying. Key patterns for LSIF-indexed code:

```
# List all indexed files
src.File _

# Files matching a prefix
src.File "ito"..

# All definitions
lsif.Definition _

# Find definition by moniker
lsif.MonikerDefinition { ident = "some::module::symbol" }

# Count facts
:count lsif.Reference _

# Database statistics
:stat
```

The schema predicates depend on the indexer format. LSIF uses `lsif.*` predicates, SCIP uses `scip.*` predicates.

## CI/CD

GitHub Actions workflow (`.github/workflows/build.yml`):

- Triggers: push to `main`, tags `v*`, PRs, manual dispatch
- Builds base image first (~30 min with cache), then language images in parallel
- Multi-arch: `linux/amd64` + `linux/arm64` via QEMU
- Pushes to `ghcr.io/withakay/glean-docker/{base,rust,...}`
- Uses GitHub Actions cache (`type=gha`) for Docker layer caching
- Base image timeout: 120 min. Language images: 30 min.

## Known Issues

1. **SCIP mode for Rust**: `rust-analyzer scip .` panics with "file emitted multiple times" on some workspace configurations. Use LSIF mode (`--mode lsif`) until fixed.

2. **`NameDefinition` predicate empty**: The LSIF indexer does not populate `lsif.NameDefinition` (a stored/derived predicate). Use `lsif.MonikerDefinition` or `lsif.Definition` instead for finding symbols.

3. **Schema symlink is arch-specific**: The runtime image creates a symlink using `$(uname -m)` for the GHC platform directory. This is resolved at build time, so multi-arch images work correctly.

4. **Image currently monolithic**: The published `rust:latest` image was built from the monolithic Dockerfile (before the base/lang split). It works correctly but is larger than necessary. A proper rebuild from the split Dockerfiles will produce smaller images.

## Development Workflow

```bash
# Build base locally (~30 min)
docker build -t glean-base base/

# Build Rust image locally (~2 min)
docker build -t glean-rust --build-arg BASE_IMAGE=glean-base lang/rust/

# Test locally
gleanctl destroy
GLEANCTL_IMAGE=glean-rust gleanctl start
GLEANCTL_IMAGE=glean-rust gleanctl index /path/to/project
gleanctl query myproject 'src.File _' --limit 5

# Push (requires ghcr.io auth)
docker tag glean-base ghcr.io/withakay/glean-docker/base:latest
docker push ghcr.io/withakay/glean-docker/base:latest
docker tag glean-rust ghcr.io/withakay/glean-docker/rust:latest
docker push ghcr.io/withakay/glean-docker/rust:latest
```

## File Inventory

| File | Purpose |
|---|---|
| `base/Dockerfile` | Glean core build (Ubuntu 22.04, GHC 9.6.7, folly, hsthrift) |
| `lang/rust/Dockerfile` | Rust layer (FROM base + rustup + rust-analyzer) |
| `lang/rust/scripts/entrypoint.sh` | Command dispatch (server, index, lsp, shell, query) |
| `lang/rust/scripts/index.sh` | Indexing logic (LSIF/SCIP, server/local mode) |
| `lang/rust/scripts/lsp.sh` | LSP server startup |
| `lang/{dotnet,python,typescript,go,cpp}/Dockerfile` | Stub Dockerfiles for planned languages |
| `gleanctl` | CLI for managing the persistent Glean server |
| `.github/workflows/build.yml` | CI: multi-arch build + push to ghcr.io |
| `README.md` | User-facing documentation |
