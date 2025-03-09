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
| 17.3    |    ❌    |   ❌   |   ❌    |

### Known Issues ⚠️

The **macOS** `14.3` and **iOS** `17.3` builds are currently failing due to an error when compiling:

<details>
  <summary><i>View Error Log</i></summary>

```cpp
[2024-02-27 09:47:16] [build-stdout] darwin-webkit-build/WebKit/Source/WTF/wtf/posix/ThreadingPOSIX.cpp:337:35: error: expected ';' after expression
[2024-02-27 09:47:16] [build-stdout]     UNUSED_PARAM(schedulingPolicy)
[2024-02-27 09:47:16] [build-stdout]                                   ^
[2024-02-27 09:47:16] [build-stdout]                                   ;
[2024-02-27 09:47:16] [build-stdout] 1 error generated.
[2024-02-27 09:47:16] [build-stdout] [7/1213] Building CXX object Tools/TestWebKitAPI/CMakeFiles/TestWTF.dir/Tests/WTF/BloomFilter.cpp.o
[2024-02-27 09:47:16] [build-stdout] [8/1213] Building CXX object Tools/TestWebKitAPI/CMakeFiles/TestWTF.dir/Tests/WTF/CompactUniquePtrTuple.cpp.o
[2024-02-27 09:47:16] [build-stdout] [9/1213] Building CXX object Tools/TestWebKitAPI/CMakeFiles/TestWTF.dir/Tests/WTF/CompactRefPtrTuple.cpp.o
[2024-02-27 09:47:16] [build-stdout] [10/1213] Building CXX object Tools/TestWebKitAPI/CMakeFiles/TestWTF.dir/Tests/WTF/CheckedArithmeticOperations.cpp.o
[2024-02-27 09:47:17] [build-stdout] [11/1213] Building CXX object Tools/TestWebKitAPI/CMakeFiles/TestWTF.dir/Tests/WTF/CompactRefPtr.cpp.o
[2024-02-27 09:47:17] [build-stdout] [12/1213] Building CXX object Tools/TestWebKitAPI/CMakeFiles/TestWTF.dir/Tests/WTF/CompactPtr.cpp.o
[2024-02-27 09:47:17] [build-stdout] [13/1213] Building CXX object Tools/TestWebKitAPI/CMakeFiles/TestWTF.dir/Tests/WTF/CompletionHandlerTests.cpp.o
[2024-02-27 09:47:23] [build-stdout] [14/1213] Building CXX object Tools/TestWebKitAPI/CMakeFiles/TestWTF.dir/Tests/WTF/DataMutex.cpp.o
[2024-02-27 09:47:23] [build-stdout] [15/1213] Building CXX object Tools/TestWebKitAPI/CMakeFiles/TestWTF.dir/Tests/WTF/CrossThreadTask.cpp.o
[2024-02-27 09:47:23] [build-stdout] [16/1213] Building CXX object Tools/TestWebKitAPI/CMakeFiles/TestWTF.dir/Tests/WTF/Condition.cpp.o
[2024-02-27 09:47:24] [build-stdout] [17/1213] Building CXX object Tools/TestWebKitAPI/CMakeFiles/TestWTF.dir/Tests/WTF/CrossThreadCopierTests.cpp.o
[2024-02-27 09:47:24] [build-stdout] ninja: build stopped: subcommand failed.
[2024-02-27 09:47:24] [ERROR] Spawned process exited abnormally (code 1; tried to run: [/opt/homebrew/Caskroom/codeql/2.16.3/codeql/tools/osx64/preload_tracer, ./Tools/Scripts/build-webkit, --jsc-only, --debug])
A fatal error occurred: Exit status 1 from command: [./Tools/Scripts/build-webkit, --jsc-only, --debug]
```

</details>

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
make codeql-db
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
❯ tree artifacts/

artifacts/
└── Build
    └── binary
        └── xnu-codeql.zip

3 directories, 1 file
```

## License

MIT Copyright (c) 2024-2025 blacktop
