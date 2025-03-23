#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

: ${BUILD_TYPE:='release'}

export ARCHS=arm64
export HOST_ARCH=arm64

# ./Tools/Scripts/build-webkit --${BUILD_TYPE} --no-unified-builds --export-compile-commands --use-ccache --architecture=arm64
./Tools/Scripts/build-webkit --${BUILD_TYPE} --cmakeargs="-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" --use-ccache