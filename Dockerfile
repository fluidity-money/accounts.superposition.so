
FROM rust:1.87-bookworm AS rust-builder

RUN rustup target add wasm32-unknown-unknown wasm32-wasip1

RUN apt-get update && apt-get install -y --no-install-recommends \
		wabt \
		binaryen \
		zip \
	&& rm -rf /var/lib/apt/lists/*

RUN cargo install wasm-bindgen-cli@0.2.105
WORKDIR /build

COPY Cargo.toml Cargo.lock* ./
COPY contract/Cargo.toml contract/Cargo.toml
COPY superposition_libaccounts/Cargo.toml superposition_libaccounts/Cargo.toml
COPY accounts-cli/Cargo.toml accounts-cli/Cargo.toml
COPY .cargo .cargo

RUN mkdir -p contract/src superposition_libaccounts/src accounts-cli/src && \
	echo "fn main() {}" > contract/src/main.rs && \
	echo "" > superposition_libaccounts/src/lib.rs && \
	echo "fn main() {}" > accounts-cli/src/main.rs

RUN cargo fetch || true

COPY contract contract
COPY superposition_libaccounts superposition_libaccounts
COPY accounts-cli accounts-cli
COPY wasm-post.sh check-codesize.sh ./
RUN chmod +x wasm-post.sh check-codesize.sh

RUN cargo build --release --target wasm32-unknown-unknown --bin contract && \
	./wasm-post.sh \
		target/wasm32-unknown-unknown/release/contract.wasm \
		accounts.superposition.so.wasm && \
	./check-codesize.sh accounts.superposition.so.wasm

RUN cargo build --release --bin accounts-cli && \
	mv target/release/accounts-cli accounts-cli.out

COPY ed25519-dalek-ph ed25519-dalek-ph
RUN cd ed25519-dalek-ph && \
	cargo build --release --bin ed25519-dalek-ph && \
	mv target/release/ed25519-dalek-ph ../ed25519-dalek-ph.out

COPY frontend frontend
RUN cd frontend && \
	cargo build --release --target wasm32-wasip1 && \
	wasm-bindgen target/wasm32-wasip1/release/frontend.wasm --out-dir ../out

FROM golang:1.25-bookworm AS go-builder
WORKDIR /build

COPY go.mod go.sum* ./
RUN go mod download || true

COPY main.go ./
COPY graph graph
COPY lib lib
COPY tools tools

RUN CGO_ENABLED=0 go build -o accounts-server .

FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
	&& rm -rf /var/lib/apt/lists/*
RUN useradd --create-home --shell /bin/bash app
WORKDIR /app

COPY --from=go-builder /build/accounts-server .

COPY --from=rust-builder /build/accounts.superposition.so.wasm .
COPY --from=rust-builder /build/accounts-cli.out .
COPY --from=rust-builder /build/ed25519-dalek-ph.out .
COPY --from=rust-builder /build/out out/

COPY graph/schema.graphqls graph/
USER app

ENV SPN_LISTEN_BACKEND=http
ENV SPN_LISTEN_ADDR=:80
EXPOSE 80
ENTRYPOINT ["./accounts-server"]
