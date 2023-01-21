#!/bin/bash

set -euo pipefail

LUAJIT_TMP=/tmp/luajitbuild
rm -rf $LUAJIT_TMP

pushd lib/LuaJit-2.1
    # build
    export MACOSX_DEPLOYMENT_TARGET=11.6
    make

    # copy all the stuff to the place
    make install PREFIX=$LUAJIT_TMP
popd

function install() {
    pushd $LUAJIT_TMP/lib
        for filename in $1; do mv "$filename" "mac_x86_${filename}"; done;
    popd
    cp $LUAJIT_TMP/lib/$1 lib/lib
}

# install in lib folder
install *.a
install *.dylib || true
