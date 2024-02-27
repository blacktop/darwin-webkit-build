# 🚧 darwin-webkit-build

[![WebKit CodeQL](https://github.com/blacktop/darwin-webkit-build/actions/workflows/c-cpp.yml/badge.svg)](https://github.com/blacktop/darwin-webkit-build/actions/workflows/c-cpp.yml) ![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/blacktop/darwin-webkit-build/total)
 [![LICENSE](https://img.shields.io/:license-mit-blue.svg)](https://doge.mit-license.org)

> WebKit CodeQL Databases


## Supported OS Versions

| Version  | Compiles | CodeQL | Binary |
| -------- | :------: | :----: | :----: |
| iOS 17.3 |    ❌    |   ❌    |   ❌   |

## Getting Started

### Dependencies

- [homebrew](https://brew.sh)
  - [jq](https://stedolan.github.io/jq/)
  - [gum](https://github.com/charmbracelet/gum)
  - [ipsw](https://github.com/blacktop/ipsw)
  - [cmake](https://cmake.org)
  - [ninja](https://ninja-build.org)
- XCode
- python3
- [codeql CLI](https://codeql.github.com/docs/codeql-cli/)

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

## License

MIT Copyright (c) 2024 blacktop
