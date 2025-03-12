# darwin-webkit-build

[![WebKit (JSC) CodeQL](https://github.com/blacktop/darwin-webkit-build/actions/workflows/jsc.yml/badge.svg)](https://github.com/blacktop/darwin-webkit-build/actions/workflows/jsc.yml) ![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/blacktop/darwin-webkit-build/total)
 [![LICENSE](https://img.shields.io/:license-mit-blue.svg)](https://doge.mit-license.org)

> WebKit CodeQL Databases


## Supported OS Versions

### nightly

| Version | Compiles | CodeQL | Binary |
| ------- | :------: | :----: | :----: |
| `main`  |    ✅     |   [DB](https://github.com/blacktop/darwin-webkit-build/releases/download/nightly/webkit-codeql.zip)    |   ❌    |

### macOS

| Version | Compiles | CodeQL | Binary |
| ------- | :------: | :----: | :----: |
| 14.3    |    ❌     |   ❌    |   ❌    |

### iOS

| Version | Compiles | CodeQL | Binary |
| ------- | :------: | :----: | :----: |
| 18.3.1  |    ❌    |   ❌   |   ❌    |

## Getting Started

### Dependencies

- [homebrew](https://brew.sh)
  - [codeql CLI](https://codeql.github.com/docs/codeql-cli/)
  - [jq](https://stedolan.github.io/jq/)
  - [gum](https://github.com/charmbracelet/gum)
  - [cmake](https://cmake.org)
  - [ninja](https://ninja-build.org)
- XCode
- python3

> [!NOTE]
> The `codeql.sh` script will install all these for you if you are connected to the internet.

### Generate a CodeQL database

```bash
./codeql.sh
```
```bash
<SNIP>
[2023-03-03 22:33:20] [build-stdout]   🎉 WebKit Build Done!
Finalizing database at darwin-webkit-build/webkit-codeql.
Running TRAP import for CodeQL database at darwin-webkit-build/webkit-codeql...
TRAP import complete (1m46s).
Successfully created database at darwin-webkit-build/webkit-codeql.
[info] Deleting log files...
[info] Zipping the CodeQL database...
  🎉 CodeQL Database Create Done!
```

Script builds and zips up the CodeQL database

```bash
❯ ll webkit-codeql.zip
-rw-r--r--@ 1 blacktop  staff   219M Mar  3 22:35 webkit-codeql.zip
```

### Generate a CodeQL database *(in a `local` **Tart** VM)*

Install deps: *[packer](https://developer.hashicorp.com/packer), [tart](https://tart.ru) and [cirrus](https://github.com/cirruslabs/cirrus-cli)*

```bash
make deps
```

Build VM image

```bash
make build-vm
```

Create CodeQL DB

```bash
OS_VERSION=18.3.1 make codeql-db-jsc
```

```bash
 > Building CodeQL Database
🕓 'Build' Task 08:22
   ✅ pull virtual machine 0.0s
✅ 'Build' Task 47:59
 🎉 Done! 🎉
🕒 'Build' Task 46:28
✅ 'Build' Task 48:15
```

```bash
tree artifacts/

artifacts/
└── Build
    └── binary
        ├── jsc-codeql-18.3.1-release.zip
        ├── jsc-codeql-18.3.1-release.zip.sha256
        └── jsc-compile_commands-18.3.1-release.zip

3 directories, 1 file
```

## License

MIT Copyright (c) 2024-2025 blacktop
