#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

# export ARCHS=arm64
# export HOST_ARCH=arm64

./Tools/gtk/install-dependencies
./Tools/Scripts/update-webkitgtk-libs
./Tools/Scripts/set-webkit-configuration --debug --fuzzilli --force-optimization-level=O3
./Tools/Scripts/build-jsc --cmakeargs="-DENABLE_STATIC_JSC=ON -DENABLE_DEVELOPER_MODE=ON"
# ./Tools/Scripts/build-jsc --cmakeargs="-DLD_SHARED_CACHE_ELIGIBLE=NO -DENABLE_STATIC_JSC=ON -DCMAKE_EXPORT_COMPILE_COMMANDS=ON" --export-compile-commands --use-ccache