#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
shopt -s nullglob
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

# Config defaults
: ${BUILD_TYPE="release"}
: ${BUILD_TARGET="webkit"}
: ${BUILD_FUZZILLI=""}
: ${CODEQL_THREADS="--threads=0"}
: ${CODEQL_RAM=""}
: ${OS_TYPE=""}
: ${OS_VERSION=""}
: ${WEBKIT_VERSION=""}

WORK_DIR="$PWD"

# Helper functions
function running() {
    echo -e "$COL_MAGENTA ⇒ $COL_RESET""$1"
}

function info() {
    echo -e "$COL_BLUE[info] $COL_RESET""$1"
}

function error() {
    echo -e "$COL_RED[error] $COL_RESET""$1"
}

# Help
function show_help() {
    echo 'Usage: codeql.sh [options]

This script creates the WebKit CodeQL database

Options:
  --debug    Build in debug mode (default is release mode)
  --jsc      Build JavaScriptCore instead of WebKit
  --fuzz     Build with Fuzzilli support
'
    exit 0
}

# Parse command line arguments
if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    show_help
fi

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
    --fuzz)
        BUILD_FUZZILLI=1
        shift
        ;;
    *)
        shift
        ;;
    esac
done

# Functions
function install_deps() {
    local required_tools=("jq" "cmake" "ninja")
    local missing_tools=()
    local os_type=$(uname -s)

    # Add platform-specific tools
    if [[ "$os_type" == "Darwin" ]]; then
        required_tools+=("codeql" "gum")
    fi

    for tool in "${required_tools[@]}"; do
        if [ ! -x "$(command -v $tool)" ]; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -eq 0 ]; then
        return 0
    fi

    running "Installing dependencies: ${missing_tools[*]}"

    # Handle package installation based on OS
    if [[ "$os_type" == "Darwin" ]]; then
        # macOS installation with Homebrew
        if [ ! -x "$(command -v brew)" ]; then
            error "Please install homebrew - https://brew.sh (or install required tools manually)"
            read -p "Install homebrew now? [y/N] " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                running "Installing homebrew"
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            else
                exit 1
            fi
        fi

        brew install ${missing_tools[@]}
    else
        error "Unsupported operating system: $os_type"
        exit 1
    fi
}

function select_os_and_version() {
    if [ -z "$OS_TYPE" ]; then
        gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Choose $(gum style --foreground 212 'OS') type:"
        OS_TYPE=$(gum choose "macOS" "iOS")
    fi
    case ${OS_TYPE} in
    "macOS")
        if [ -z "$OS_VERSION" ]; then
            gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Choose $(gum style --foreground 212 'macOS') version to build:"
            OS_VERSION=$(gum choose $(jq -r '.macOS[].version' version.json | tr '\n' ' '))
        fi
        ;;
    "iOS")
        if [ -z "$OS_VERSION" ]; then
            gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Choose $(gum style --foreground 212 'iOS') version to build:"
            OS_VERSION=$(gum choose $(jq -r '.iOS[].version' version.json | tr '\n' ' '))
        fi
        ;;
    *)
        error "Invalid OS type: $OS_TYPE"
        exit 1
        ;;
    esac

    version=$(jq -r ".${OS_TYPE}[] | select(.version==\"${OS_VERSION}\") | .tag" version.json)

    if [ -n "$version" ]; then
        info "Using version: $version"
        get_version "$version"
    else
        error "Version not found for ${OS_TYPE} ${OS_VERSION}"
        exit 1
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
        select_os_and_version
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

function create_codeql_database() {
    local target=$1
    local build_script=$2
    local database_dir="${WORK_DIR}/${target}-codeql"
    local build_dir=$(echo "${BUILD_TYPE}" | awk '{ print toupper(substr($0, 1, 1)) tolower(substr($0, 2)) }')
    local os_version_suffix="${OS_VERSION}-${BUILD_TYPE}"

    # Add OS_TYPE prefix for webkit
    if [[ "${target}" == "webkit" ]]; then
        os_version_suffix="${OS_TYPE}-${os_version_suffix}"
    fi

    # Clean previous database
    rm -rf "${database_dir}"

    info "Building CodeQL DB for '${target}'..."
    codeql database create "${database_dir}" -v ${CODEQL_THREADS} ${CODEQL_RAM} --language=cpp --command=${build_script}

    info "Generating compile_commands..."
    ${WEBKIT_SRC_DIR}/Tools/Scripts/generate-compile-commands "${WEBKIT_SRC_DIR}/WebKitBuild/${build_dir}"

    info "Zipping the compile_commands..."
    zip -j "${WORK_DIR}/${target}-compile_commands-${os_version_suffix}.zip" "${WEBKIT_SRC_DIR}/compile_commands.json"

    info "Deleting log files..."
    rm -rf "${database_dir}"/log

    info "Zipping the CodeQL database..."
    zip -r -X "${WORK_DIR}/${target}-codeql-${os_version_suffix}.zip" "${database_dir}"
}

function create_db() {
    WEBKIT_SRC_DIR="${WORK_DIR}/WebKit"
    cd "${WEBKIT_SRC_DIR}"

    running "📦 Creating the CodeQL database..."

    # Set the build command based on target
    if [[ "${BUILD_TARGET}" == "jsc" ]]; then
        local build_script="${WORK_DIR}/scripts/build-jsc.sh"
        if [[ -n "${BUILD_FUZZILLI}" ]]; then
            exec "${WORK_DIR}/scripts/build-fuzzilli.sh"
        fi
        create_codeql_database "jsc" "${build_script}"
    else
        create_codeql_database "webkit" "${WORK_DIR}/scripts/build-webkit.sh"
    fi
}

main() {
    install_deps
    clone_webkit
    create_db
    echo "  🎉 CodeQL Database Create Done!"
}

main "$@"
