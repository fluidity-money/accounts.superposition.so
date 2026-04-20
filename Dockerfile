# ============================================================
# Multi-stage Dockerfile for accounts.superposition.so
#
# Build targets produced:
#   - accounts.superposition.so.wasm  (Stylus contract)
#   - accounts-cli.out                (CLI tool)
#   - ed25519-dalek-ph.out            (ed25519 helper binary)
#   - out/frontend_bg.wasm            (frontend WASM via wasm-bindgen)
#   - Go server binary                (GraphQL API, HTTP or Lambda)
#
# Runtime: the Go server binary in a minimal image.
# ============================================================

# ------------------------------------------------------------------
# Stage 1: Rust builds (contract WASM, CLI, ed25519 helper, frontend)
# ------------------------------------------------------------------
FROM rust:1.87-bookworm AS rust-builder

# Install wasm targets
RUN rustup target add wasm32-unknown-unknown wasm32-wasip1

# Install WABT (wasm2wat, wat2wasm) and Binaryen (wasm-opt)
RUN apt-get update && apt-get install -y --no-install-recommends \
        wabt \
        binaryen \
        zip \
    && rm -rf /var/lib/apt/lists/*

# Install wasm-bindgen-cli (must match the version in frontend/Cargo.toml)
RUN cargo install wasm-bindgen-cli@0.2.105

WORKDIR /build

# Copy workspace manifests first for layer caching
COPY Cargo.toml Cargo.lock* ./
COPY contract/Cargo.toml contract/Cargo.toml
COPY libaccounts/Cargo.toml libaccounts/Cargo.toml
COPY accounts-cli/Cargo.toml accounts-cli/Cargo.toml
COPY .cargo .cargo

# Create stub source files so cargo can resolve the workspace
RUN mkdir -p contract/src libaccounts/src accounts-cli/src && \
    echo "fn main() {}" > contract/src/main.rs && \
    echo "" > libaccounts/src/lib.rs && \
    echo "fn main() {}" > accounts-cli/src/main.rs

# Pre-fetch workspace dependencies
RUN cargo fetch || true

# Now copy all real source
COPY contract contract
COPY libaccounts libaccounts
COPY accounts-cli accounts-cli
COPY wasm-post.sh check-codesize.sh ./
RUN chmod +x wasm-post.sh check-codesize.sh

# Build the WASM contract
RUN cargo build --release --target wasm32-unknown-unknown --bin contract && \
    ./wasm-post.sh \
        target/wasm32-unknown-unknown/release/contract.wasm \
        accounts.superposition.so.wasm && \
    ./check-codesize.sh accounts.superposition.so.wasm

# Build accounts-cli
RUN cargo build --release --bin accounts-cli && \
    mv target/release/accounts-cli accounts-cli.out

# Build ed25519-dalek-ph (separate workspace)
COPY ed25519-dalek-ph ed25519-dalek-ph
RUN cd ed25519-dalek-ph && \
    cargo build --release --bin ed25519-dalek-ph && \
    mv target/release/ed25519-dalek-ph ../ed25519-dalek-ph.out

# Build frontend WASM
COPY frontend frontend
RUN cd frontend && \
    cargo build --release --target wasm32-wasip1 && \
    wasm-bindgen target/wasm32-wasip1/release/frontend.wasm --out-dir ../out

# ------------------------------------------------------------------
# Stage 2: Go build (GraphQL server / Lambda handler)
# ------------------------------------------------------------------
FROM golang:1.25-bookworm AS go-builder

WORKDIR /build

# Copy go module files first for layer caching
COPY go.mod go.sum* ./
RUN go mod download || true

# Copy Go source
COPY main.go ./
COPY graph graph
COPY lib lib
COPY tools tools

# Build the Go server binary (static for a minimal runtime image)
RUN CGO_ENABLED=0 go build -o accounts-server .

# ------------------------------------------------------------------
# Stage 3: Runtime image
# ------------------------------------------------------------------
FROM debian:bookworm-slim AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd --create-home --shell /bin/bash app
WORKDIR /app

# Copy Go server binary
COPY --from=go-builder /build/accounts-server .

# Copy Rust build artifacts
COPY --from=rust-builder /build/accounts.superposition.so.wasm .
COPY --from=rust-builder /build/accounts-cli.out .
COPY --from=rust-builder /build/ed25519-dalek-ph.out .
COPY --from=rust-builder /build/out out/

# Copy GraphQL schema (needed at runtime by gqlgen)
COPY graph/schema.graphqls graph/

USER app

# Environment variables the server expects (provide at runtime):
#   SPN_LISTEN_BACKEND  - "http" or "lambda"
#   SPN_LISTEN_ADDR     - e.g. ":8080" (for http mode)
#   SPN_GETH_URL        - Ethereum/Superposition RPC URL
#   SPN_TIMESCALE       - PostgreSQL connection string
#   SPN_CHAIN_ID        - Chain ID (e.g. "55244")
#   SPN_ACCOUNTS_ADDR   - Accounts factory contract address
#   SPN_ACCOUNTS_PRIVATE_KEY - Hex-encoded private key
#   SPN_ACCOUNTS_PUBLIC_KEY  - Hex-encoded public key
#   SPN_FUSDC_ADDR      - fUSDC token address
#   SPN_CLAIMANT_HELPER - ClaimantHelper contract address
#   SPN_ADMIN_SECRET    - Admin auth secret (optional)
#   SPN_ALARM_WEBHOOK   - Alarm webhook URL (optional)

ENV SPN_LISTEN_BACKEND=http
ENV SPN_LISTEN_ADDR=:8080

EXPOSE 8080

ENTRYPOINT ["./accounts-server"]
