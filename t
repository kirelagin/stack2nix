#!/usr/bin/env bash

set -e

RED="\033[1;31m"
YELLOW="\033[1;33m"
GREEN="\033[1;32m"
NC="\033[0m"

build_self() {
    local bin="$(mktemp -d)/bin"

    echo -e "${YELLOW}Building stack2nix...${NC}"
    cabal update
    cabal sandbox init
    cabal configure
    cabal build

    echo -e "${YELLOW}Installing stack2nix to $bin${NC}"
    mkdir -p "$bin"
    cabal install --bindir="$bin"
    export PATH="$bin:$PATH"
    echo "stack2nix path: $(which stack2nix)"
}

build_repo() {
    local description=$1
    local repo=$2
    local build_target=$3
    local rev=
    local work_dir="$(mktemp -d)"

    if [ ! -z ${4} ]; then
        rev="--revision $4"
    fi

    echo -e "${YELLOW}Running stack2nix on $repo${NC}"
    pushd "$work_dir"
    stack2nix $rev $repo || (echo -e "${RED}FAIL: stack2nix: $description${NC}"; popd; exit 1)

    echo -e "${YELLOW}Running nix-build on $build_target${NC}"
    nix-build -A $build_target --show-trace || (echo -e "${RED}FAIL: nix-build: $description${NC}"; popd; exit 1)

    echo -e "${GREEN}PASS: $description${NC}"
    echo ""

    popd
}

run_tests() {
    echo -e "${YELLOW}Running tests...${NC}"

    build_repo "Remote simple" https://github.com/jmitchell/haskell-multi-package-demo1 haskell-multi-proj-demo1

    # build_repo "Remote cardano-sl" https://github.com/input-output-hk/cardano-sl.git cardano-sl be7cb65f71e7bd5b34778652009469c4513ecb79
}

build_self && run_tests
