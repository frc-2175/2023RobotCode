#!/bin/bash

set -euxo pipefail

BINDDIR=src/bindings

mkdir -p ${BINDDIR}/build
pushd ${BINDDIR}/build
    clang ../bindings.c
popd

${BINDDIR}/build/a.out
