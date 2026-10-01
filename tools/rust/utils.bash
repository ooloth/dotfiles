#!/usr/bin/env bash

export TOOL_CARGO_DEPENDENCIES=(
  cargo-audit   # advisory check: https://github.com/rustsec/rustsec/tree/main/cargo-audit
  cargo-deny    # dependency policy check: https://github.com/EmbarkStudios/cargo-deny
  cargo-nextest # test runner: https://nexte.st
)
