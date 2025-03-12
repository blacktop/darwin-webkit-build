#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
fi

# Colors
export ESC_SEQ="\x1b["
export COL_RESET=$ESC_SEQ"39;49;00m"
export COL_RED=$ESC_SEQ"31;01m"
export COL_GREEN=$ESC_SEQ"32;01m"
export COL_YELLOW=$ESC_SEQ"33;01m"
export COL_BLUE=$ESC_SEQ"34;01m"
export COL_MAGENTA=$ESC_SEQ"35;01m"
export COL_CYAN=$ESC_SEQ"36;01m"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --debug)
            BUILD_TYPE="debug"
            shift
            ;;
        --jsc)
            BUILD_TARGET="jsc"
            shift
            ;;
        *)
            shift
            ;;
    esac
done

function running() {
    echo -e "$COL_MAGENTA ⇒ $COL_RESET""$1"
}

function info() {
    echo -e "$COL_BLUE[info] $COL_RESET""$1"
}

function error() {
    echo -e "$COL_RED[error] $COL_RESET""$1"
}

# Config
: ${OS_TYPE:=''}
: ${OS_VERSION:=''}
: ${WEBKIT_VERSION:=''}

: ${BUILD_TYPE:='release'}
: ${BUILD_TARGET:='webkit'}

: ${CODEQL_THREADS:=--threads=0}
: ${CODEQL_RAM:=}

WORK_DIR="$PWD"

# Help
if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    echo 'Usage: codeql.sh [options]

This script creates the WebKit CodeQL database

Options:
  --debug    Build in debug mode (default is release mode)
  --jsc      Build JavaScriptCore instead of WebKit
'
    exit
fi

# Functions
function install_deps() {
    if [ ! -x "$(command -v codeql)" ] || [ ! -x "$(command -v jq)" ] || [ ! -x "$(command -v gum)" ] || [ ! -x "$(command -v cmake)" ] || [ ! -x "$(command -v ninja)" ]; then
        running "Installing dependencies"
        if [ ! -x "$(command -v brew)" ]; then
            error "Please install homebrew - https://brew.sh (or install 'codeql', 'jq', 'gum', 'cmake' and 'ninja' manually)"
            read -p "Install homebrew now? " -n 1 -r
            echo # (optional) move to a new line
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                running "Installing homebrew"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            else
                exit 1
            fi
        fi
        brew install codeql jq gum bash cmake ninja
    fi
}

function get_version() {
    local version=$1
    while read -r tag; do
        if [[ "${tag}" == "${version}" ]]; then
            echo "   ✅ Exact tag: $tag"
            WEBKIT_VERSION=$tag
            return
        # Check if the tag is less than the given version
        elif [[ "$(printf '%s\n' "$tag" "${version}" | sort -V | head -n1)" != "${version}" ]]; then
            echo "   ⚠️ Closest tag: $tag"
            WEBKIT_VERSION=$tag
            return
        fi
    done < <(git ls-remote --tags https://github.com/WebKit/WebKit.git WebKit-76\* | grep -Eo 'WebKit-[0-9.]+$' | sort -Vr)
}

function clone_webkit() {
    if [ -z "$WEBKIT_VERSION" ]; then
        if [ -z "$OS_TYPE" ]; then
            gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Choose $(gum style --foreground 212 'OS') type:"
            OS_TYPE=$(gum choose "macOS" "iOS")
        fi
        local version
        case ${OS_TYPE} in
        'macOS')
            if [ -z "$OS_VERSION" ]; then
                gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Choose $(gum style --foreground 212 'macOS') version to build:"
                OS_VERSION=$(gum choose "15.2" "15.3")
            fi
            case ${OS_VERSION} in
            '15.2')
                RELEASE_URL='https://raw.githubusercontent.com/apple-oss-distributions/distribution-macOS/macos-152/release.json'
                # Parse the latest WebKit version from the release.json and lookup in the WebKit tags
                version=$(curl -s $RELEASE_URL | jq -r '.projects[] | select(.project=="WebKit") | .tag')
                ;;
            '15.3')
                RELEASE_URL='https://raw.githubusercontent.com/apple-oss-distributions/distribution-macOS/macos-153/release.json'
                # Parse the latest WebKit version from the release.json and lookup in the WebKit tags
                version=$(curl -s $RELEASE_URL | jq -r '.projects[] | select(.project=="WebKit") | .tag')
                ;;
            *)
                error "Invalid macOS version"
                exit 1
                ;;
            esac
            ;;
        'iOS')
            if [ -z "$OS_VERSION" ]; then
                gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Choose $(gum style --foreground 212 'iOS') version to build:"
                OS_VERSION=$(gum choose "18.2" "18.3" "18.3.1")
            fi
            case ${OS_VERSION} in
            '18.2')
                RELEASE_URL='https://raw.githubusercontent.com/apple-oss-distributions/distribution-iOS/ios-182/release.json'
                # Parse the latest WebKit version from the release.json and lookup in the WebKit tags
                version=$(curl -s $RELEASE_URL | jq -r '.projects[] | select(.project=="WebKit") | .tag')
                ;;
            '18.3')
                RELEASE_URL='https://raw.githubusercontent.com/apple-oss-distributions/distribution-iOS/ios-183/release.json'
                # Parse the latest WebKit version from the release.json and lookup in the WebKit tags
                version=$(curl -s $RELEASE_URL | jq -r '.projects[] | select(.project=="WebKit") | .tag')
                ;;
            '18.3.1')
                version="WebKit-7620.2.4.10.7"
                ;;
            '18.3.2')
                version="WebKit-7620.2.4.10.8"
                ;;
            *)
                error "Invalid iOS version"
                exit 1
                ;;
            esac
            ;;
        *)
            error "Invalid OS type"
            exit 1
            ;;
        esac
        info "Using version: $version"
        get_version "$version"
    fi
    if [ ! -d "${WORK_DIR}/WebKit" ]; then
        running "⬇️  Cloning WebKit"
        if [[ "${WEBKIT_VERSION}" == "latest" ]]; then
            git clone --depth 1 https://github.com/WebKit/WebKit.git "${WORK_DIR}/WebKit"
        else
            git clone --depth 1 --branch "${WEBKIT_VERSION}" https://github.com/WebKit/WebKit.git "${WORK_DIR}/WebKit"
        fi
    fi
}

function create_db() {
    WORK_DIR="$PWD"
    WEBKIT_SRC_DIR="${WORK_DIR}/WebKit"
    DATABASE_DIR="${WORK_DIR}/webkit-codeql"
    rm -rf "${DATABASE_DIR}"
    cd "${WEBKIT_SRC_DIR}"
    ARCHS="arm64"
    running "📦 Creating the CodeQL database..."

    # Set the build command based on target
    if [[ "${BUILD_TARGET}" == "jsc" ]]; then
        # BUILD_CMD="./Tools/Scripts/build-jsc --jsc-only --${BUILD_TYPE} --export-compile-commands"
        BUILD_CMD="./Tools/Scripts/build-jsc --cmakeargs="-DENABLE_UNIFIED_BUILDS=OFF" --export-compile-commands --architecture ARM64"
        BUILD_DIR=$(echo "${BUILD_TYPE}" | awk '{ print toupper(substr($0, 1, 1)) tolower(substr($0, 2)) }')
        
        info "Building CodeQL DB for 'jsc'..."
        codeql database create "${DATABASE_DIR}" -v "${CODEQL_THREADS}" "${CODEQL_RAM}" --language=cpp --command="${BUILD_CMD}"
        ./Tools/Scripts/generate-compile-commands "WebKitBuild/${BUILD_DIR}"

        info "Zipping the compile_commands..."
        zip -r -X "${WORK_DIR}/jsc-compile_commands-${OS_VERSION}-${BUILD_TYPE}.zip" "${WEBKIT_SRC_DIR}/WebKitBuild/${BUILD_DIR}/compile_commands"

        info "Deleting log files..."
        rm -rf "${DATABASE_DIR}"/log

        info "Zipping the CodeQL database..."
        zip -r -X "${WORK_DIR}/jsc-codeql-${OS_VERSION}-${BUILD_TYPE}.zip" "${DATABASE_DIR}"        
    else
        BUILD_CMD="./Tools/Scripts/build-webkit --${BUILD_TYPE} --ios-device --no-unified-builds --export-compile-commands"
        BUILD_DIR=$(echo "${BUILD_TYPE}" | awk '{ print toupper(substr($0, 1, 1)) tolower(substr($0, 2)) }')
        
        info "Building CodeQL DB for 'webkit'..."
        codeql database create "${DATABASE_DIR}" -v "${CODEQL_THREADS}" "${CODEQL_RAM}" --language=cpp --command="${BUILD_CMD}"
        ./Tools/Scripts/generate-compile-commands WebKitBuild/Release

        info "Zipping the compile_commands..."
        zip -r -X "${WORK_DIR}/webkit-compile_commands-${OS_TYPE}-${OS_VERSION}-${BUILD_TYPE}.zip" "${WEBKIT_SRC_DIR}/WebKitBuild/${BUILD_DIR}-iphoneos/compile_commands"

        info "Deleting log files..."
        rm -rf "${DATABASE_DIR}"/log

        info "Zipping the CodeQL database..."
        zip -r -X "${WORK_DIR}/webkit-codeql-${OS_TYPE}-${OS_VERSION}-${BUILD_TYPE}.zip" "${DATABASE_DIR}"        
    fi
}

main() {
    install_deps
    clone_webkit
    create_db
    echo "  🎉 CodeQL Database Create Done!"
}

main "$@"
