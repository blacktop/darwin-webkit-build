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

function running() {
    echo -e "$COL_MAGENTA ⇒ $COL_RESET""$1"
}

function info() {
    echo -e "$COL_BLUE[info] $COL_RESET""$1"
}

# Config
: ${OS_TYPE:=''}
: ${IOS_VERSION:=''}
: ${MACOS_VERSION:=''}
: ${WEBKIT_VERSION:=''}

WORK_DIR="$PWD"

# Help
if [[ "${1-}" =~ ^-*h(elp)?$ ]]; then
    echo 'Usage: codeql.sh

This script creates the WebKit CodeQL database

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
            echo "  ✅ Exact tag: $tag"
            WEBKIT_VERSION=$tag
            return
        # Check if the tag is less than the given version
        elif [[ "$(printf '%s\n' "$tag" "${version}" | sort -V | head -n1)" != "${version}" ]]; then
            echo "  ⚠️ Closest tag: $tag"
            WEBKIT_VERSION=$tag
            return
        fi
    done < <(git ls-remote --tags https://github.com/WebKit/WebKit.git WebKit-7617\* | grep -Eo 'WebKit-[0-9.]+$' | sort -Vr)
}

function clone_webkit() {
    if [ -z "$WEBKIT_VERSION" ]; then
        if [ -z "$OS_TYPE" ]; then
            gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Choose $(gum style --foreground 212 'OS') type:"
            OS_TYPE=$(gum choose "macOS" "iOS")
        fi
        case ${OS_TYPE} in
        'macOS')
            if [ -z "$MACOS_VERSION" ]; then
                gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Choose $(gum style --foreground 212 'macOS') version to build:"
                MACOS_VERSION=$(gum choose "14.3")
                case ${MACOS_VERSION} in
                '14.3')
                    RELEASE_URL='https://raw.githubusercontent.com/apple-oss-distributions/distribution-macOS/macos-143/release.json'
                    ;;
                *)
                    error "Invalid macOS version"
                    exit 1
                    ;;
                esac
            fi
            ;;
        'iOS')
            if [ -z "$IOS_VERSION" ]; then
                gum style --border normal --margin "1" --padding "1 2" --border-foreground 212 "Choose $(gum style --foreground 212 'iOS') version to build:"
                IOS_VERSION=$(gum choose "17.3")
                case ${IOS_VERSION} in
                '17.3')
                    RELEASE_URL='https://raw.githubusercontent.com/apple-oss-distributions/distribution-iOS/ios-173/release.json'
                    ;;
                *)
                    error "Invalid iOS version"
                    exit 1
                    ;;
                esac
            fi
            ;;
        *)
            error "Invalid OS type"
            exit 1
            ;;
        esac
        # Parse the latest WebKit version from the release.json and lookup in the WebKit tags
        local version
        version=$(curl -s "$RELEASE_URL" | jq -r '.projects[] | select(.project=="WebKit") | .tag')
        info "Using version: $version"
        get_version "$version"
    fi
    if [ ! -d "${WORK_DIR}/WebKit" ]; then
        running "⬇️  Cloning WebKit"
        git clone --depth 1 --branch "${WEBKIT_VERSION}" https://github.com/WebKit/WebKit.git "${WORK_DIR}/WebKit"
    fi
}

function create_db() {
    WORK_DIR="$PWD"
    WEBKIT_SRC_DIR="${WORK_DIR}/WebKit"
    DATABASE_DIR="${WORK_DIR}/webkit-codeql"
    rm -rf "${DATABASE_DIR}"
    running "📦 Creating the CodeQL database..."
    CODEQL_CMD="./Tools/Scripts/build-webkit --jsc-only --debug"
    codeql database create "${DATABASE_DIR}" -v --threads=0 --language=cpp --source-root="${WEBKIT_SRC_DIR}" --command="${CODEQL_CMD}"
    info "Deleting log files..."
    rm -rf "${DATABASE_DIR}"/log
    info "Zipping the CodeQL database..."
    zip -r -X webkit-codeql.zip "${DATABASE_DIR}"/*
}

main() {
    install_deps
    clone_webkit
    create_db
    echo "  🎉 CodeQL Database Create Done!"
}

main "$@"
