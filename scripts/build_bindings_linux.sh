#!/bin/bash

set -euxo pipefail

BINDDIR=src/bindings

mkdir -p ${BINDDIR}/build
pushd ${BINDDIR}/build
    gcc ../bindings.c
popd

${BINDDIR}/build/a.out
