#!/usr/bin/env bash
set -euo pipefail

crate="superposition_libaccounts"
version="$(python3 - <<'PY'
import tomllib

with open("superposition_libaccounts/Cargo.toml", "rb") as f:
    print(tomllib.load(f)["package"]["version"])
PY
)"

status="$(curl \
    --silent \
    --show-error \
    --location \
    --retry 3 \
    --user-agent "accounts.superposition.so-release (https://github.com/fluidity-money/accounts.superposition.so)" \
    --output /dev/null \
    --write-out '%{http_code}' \
    "https://crates.io/api/v1/crates/${crate}/${version}")"

case "$status" in
    200)
        echo "${crate} ${version} is already published; skipping"
        exit 0
        ;;
    404) ;;
    *)
        echo "Unexpected crates.io response for ${crate} ${version}: HTTP ${status}" >&2
        exit 1
        ;;
esac

cargo publish --locked --package "$crate"
