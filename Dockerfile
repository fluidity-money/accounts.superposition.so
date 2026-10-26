
FROM rust:1.98-bookworm AS rust-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
		wabt \
		binaryen \
		zip \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /build

COPY Cargo.toml Cargo.lock* ./
COPY contract/Cargo.toml contract/Cargo.toml
COPY superposition_libaccounts/Cargo.toml superposition_libaccounts/Cargo.toml
COPY contract-clearinghouse/Cargo.toml contract-clearinghouse/Cargo.toml
COPY accounts-cli/Cargo.toml accounts-cli/Cargo.toml
COPY .cargo .cargo

RUN mkdir -p contract/src superposition_libaccounts/src accounts-cli/src contract-clearinghouse/src && \
	echo "fn main() {}" > contract/src/main.rs && \
	echo "" > superposition_libaccounts/src/lib.rs && \
	echo "fn main() {}" > accounts-cli/src/main.rs && \
	echo "fn main() {}" > contract-clearinghouse/src/main.rs

RUN cargo fetch || true

COPY contract contract
COPY superposition_libaccounts superposition_libaccounts
COPY accounts-cli accounts-cli

RUN cargo build --release --bin accounts-cli && \
	mv target/release/accounts-cli accounts-cli.out

COPY ed25519-dalek-ph ed25519-dalek-ph
RUN cd ed25519-dalek-ph && \
	cargo build --release --bin ed25519-dalek-ph && \
	mv target/release/ed25519-dalek-ph ../ed25519-dalek-ph.out

FROM golang:1.27-bookworm AS go-builder
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

COPY --from=rust-builder /build/accounts-cli.out .
COPY --from=rust-builder /build/ed25519-dalek-ph.out /usr/local/bin/ed25519-dalek-ph

COPY graph/schema.graphqls graph/
USER app

ENV SPN_LISTEN_BACKEND=http
ENV SPN_LISTEN_ADDR=:80
EXPOSE 80
ENTRYPOINT ["./accounts-server"]
