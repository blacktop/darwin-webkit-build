#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

: ${BUILD_TYPE:='release'}

# export ARCHS=arm64
# export HOST_ARCH=arm64

# ./Tools/Scripts/build-jsc --${BUILD_TYPE} --cmakeargs="-DENABLE_STATIC_JSC=ON -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DENABLE_UNIFIED_BUILDS=OFF" --export-compile-commands --use-ccache --architecture=arm64
# ./Tools/Scripts/build-jsc --${BUILD_TYPE} --cmakeargs="-DCMAKE_EXE_LINKER_FLAGS='-not_for_dyld_shared_cache' -DENABLE_STATIC_JSC=ON -DCMAKE_EXPORT_COMPILE_COMMANDS=ON" --use-ccache
./Tools/Scripts/build-jsc --debug --cmakeargs="-DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DENABLE_DEVELOPER_MODE=ON -DCLANGD_AUTO_SETUP=ON" --export-compile-commands --use-ccache