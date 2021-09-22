#!/bin/bash

set -e

CRUNTIME=${CRUNTIME:-"env DOCKER_BUILDKIT=1 docker"}
PREFIX=${PREFIX:-"/usr/local"}

function do_build() {
    ${CRUNTIME} build \
        --build-arg PREFIX=${PREFIX} \
        --target build \
        --tag lockc-build \
	.
    ${CRUNTIME} run \
        --rm -i \
        -e USER_ID=$(id -u) \
        -e GROUP_ID=$(id -g) \
        -v $(pwd):/usr/local/src/lockc \
        lockc-build
}

function do_install() {
    install -D -m 0644 build/lockcd.service /etc/systemd/system/lockcd.service
    install -D -m 0755 build/src/lockcd /usr/local/bin/lockcd
}

function do_fmt() {
    ${CRUNTIME} build \
        --build-arg USER_ID=$(id -u) \
        --build-arg GROUP_ID=$(id -g) \
        --target clippy \
        --tag lockc-clippy \
        .
    ${CRUNTIME} run \
        --rm -i \
        --user "$(id -u):$(id -g)" \
        -v $(pwd):/usr/local/src/lockc \
        lockc-clippy
}

function do_lint() {
    ${CRUNTIME} build \
        --build-arg USER_ID=$(id -u) \
        --build-arg GROUP_ID=$(id -g) \
        --target clippy \
        --tag lockc-clippy \
        .
    ${CRUNTIME} run \
        --rm -i \
        --user "$(id -u):$(id -g)" \
        -v $(pwd):/usr/local/src/lockc \
        lockc-clippy
}

function do_test() {
    ${CRUNTIME} build \
        --build-arg USER_ID=$(id -u) \
        --build-arg GROUP_ID=$(id -g) \
        --target test \
        --tag lockc-test \
        .
    ${CRUNTIME} run \
        --rm -i \
        --user "$(id -u):$(id -g)" \
        -v $(pwd):/usr/local/src/lockc \
        lockc-test
}

function do_help() {
    echo "Usage: $(basename $0) <subcommand>"
    echo
    echo "Subcommands:"
    echo "    gen        Compile BPF programs and generate BPF CO-RE skeleton"
    echo "    build      Build lockc"
    echo "    install    Install lockc"
    echo "    fmt        Autoformat code"
    echo "    lint       Code analysis"
    echo "    test       Execute unit tests"
    echo "    help       Show help information"
}

case "$1" in
    "gen")
        do_gen
        ;;
    "build")
        do_build
        ;;
    "install")
        do_install
        ;;
    "fmt")
        do_fmt
        ;;
    "lint")
        do_lint
        ;;
    "test")
        do_test
        ;;
    "")
        do_build
        ;;
    "help" | "-h" | "--help")
        do_help
        ;;
    *)
        do_help
        exit 1
        ;;
esac
