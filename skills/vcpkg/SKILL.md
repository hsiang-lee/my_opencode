---
name: vcpkg
description: Use when managing C++ dependencies with vcpkg, creating custom ports, or setting up a private vcpkg registry.
---

# vcpkg C++ 包管理工具

vcpkg 是微软开发的 C++ 包管理器,主要用于管理 Windows/Linux/macOS 上的 C++ 依赖。

## 常用命令

| 命令 | 说明 |
|------|------|
| `vcpkg search` | 搜索可用包 |
| `vcpkg install <pkg>` | 安装包 |
| `vcpkg list` | 列出已安装包 |
| `vcpkg remove <pkg>` | 移除包 |
| `vcpkg upgrade` | 升级所有过时包 |
| `vcpkg integrate install` | 全局集成(项目外使用) |
| `vcpkg integrate project` | 项目级集成 |

```bash
# 安装并集成到 CMake 项目
vcpkg install jsoncpp
vcpkg integrate install

# 搜索包
vcpkg search json
```

## 项目 vcpkg.json

项目根目录放置 `vcpkg.json` 声明依赖,项目级集成:

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "dependencies": [
    "nlohmann-json",
    "spdlog",
    "fmt"
  ]
}
```

安装依赖:
```bash
vcpkg install
```

## CMake 集成

### 方式一: vcpkg 作为子模块

```bash
git clone https://github.com/Microsoft/vcpkg.git
./vcpkg/bootstrap-vcpkg.sh
```

CMakeLists.txt:
```cmake
cmake_minimum_required(VERSION 3.14)
project(myproject)

find_package(nlohmann-json CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)

add_executable(app main.cpp)
target_link_libraries(app PRIVATE nlohmann_json::nlohmann_json spdlog::spdlog)
```

```bash
cmake -B build -S . -DCMAKE_TOOLCHAIN_FILE=[path to vcpkg]/scripts/buildsystems/vcpkg.cmake
cmake --build build
```

### 方式二: 通过 vcpkg install 安装

```bash
# 全局集成
vcpkg integrate install

# CMake 自动发现已安装的包
find_package(nlohmann-json CONFIG REQUIRED)
```

## CMakePresets 集成

推荐使用 CMakePresets.json 统一管理 vcpkg 构建配置，避免手动指定工具链。

```json
{
  "version": 3,
  "configurePresets": [
    {
      "name": "linux-x86-release",
      "generator": "Ninja",
      "binaryDir": "${sourceDir}/build",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_TOOLCHAIN_FILE": "$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake",
        "VCPKG_TARGET_TRIPLET": "x64-linux",
        "VCPKG_OVERLAY_PORTS": "${sourceDir}/overlay-ports"
      },
      "environment": {
        "VCPKG_ROOT": "/path/to/vcpkg",
        "VCPKG_FEATURE_FLAGS": "manifest"
      }
    },
    {
      "name": "linux-x86-debug",
      "inherits": "linux-x86-release",
      "binaryDir": "${sourceDir}/build-debug",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "linux-x86-release",
      "configurePreset": "linux-x86-release"
    }
  ]
}
```

```bash
# 使用 preset 构建
cmake --preset linux-x86-release
cmake --build build
```

### 跨平台 Triplet 配置

| Triplet | 用途 |
|---------|------|
| `x64-linux` | Linux x86_64 |
| `x64-windows` | Windows x64 |
| `arm64-linux` | ARM64 Linux |
| `arm64-qnx` | QNX ARM64 |
| `wasm32-emscripten` | WebAssembly |

QNX 交叉编译示例：

```json
"cacheVariables": {
  "CMAKE_TOOLCHAIN_FILE": "$env{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake",
  "VCPKG_TARGET_TRIPLET": "arm64-qnx",
  "VCPKG_OVERLAY_TRIPLETS": "$env{AVM_VCPKG_REGISTRY}/triplets/",
  "VCPKG_CHAINLOAD_TOOLCHAIN_FILE": "${sourceDir}/toolchain.cmake"
}
```

## CMake 正确用法与严禁事项

### ✅ 正确做法：find_package + target_link_libraries（导出目标）

```cmake
# 先 find_package
find_package(fmt CONFIG REQUIRED)
find_package(pugixml CONFIG REQUIRED)
find_package(yaml-cpp CONFIG REQUIRED)
find_package(OpenSSL REQUIRED)

# 再 target_link_libraries（使用导出的 CMake 目标）
add_executable(myapp main.cpp)
target_link_libraries(myapp PRIVATE
    fmt::fmt
    pugixml::pugixml
    yaml-cpp::yaml-cpp
    OpenSSL::SSL
)
```

vcpkg 安装的库在 `build/vcpkg_installed/x64-linux/share/` 下有 `<package>Config.cmake` 文件，`find_package` 自动查找。

### ❌ 严禁做法：手动指定路径

以下做法**极其错误，禁止使用**：

```cmake
# ❌ 手动指定 include 路径
target_include_directories(myapp PRIVATE /path/to/vcpkg/installed/x64-linux/include)

# ❌ 手动指定库文件路径
target_link_directories(myapp PRIVATE /path/to/vcpkg/installed/x64-linux/lib)
target_link_libraries(myapp /path/to/vcpkg/installed/x64-linux/lib/libfmt.a)

# ❌ 手动设置变量绕过 vcpkg
set(OpenCV_DIR /custom/path/to/opencv)
```

**原因：** vcpkg 通过 `-DCMAKE_TOOLCHAIN_FILE` 自动注入所有搜索路径，`find_package` 会到 `vcpkg_installed/` 下查找。手动指定路径破坏可移植性和可重现性，换一个 triplet 或升级 vcpkg 就崩溃。

### 检查 vcpkg 安装的库

```bash
# 查看安装的包
ls build/vcpkg_installed/x64-linux/share/

# 查看包的 CMake 配置
cat build/vcpkg_installed/x64-linux/share/fmt/fmt-config.cmake

# 查看导出的目标
grep -r "add_library\|ALIAS" build/vcpkg_installed/x64-linux/share/
```

从 esmini 项目实际案例：

```cmake
find_package(fmt CONFIG REQUIRED)           # → fmt::fmt
find_package(pugixml CONFIG REQUIRED)        # → pugixml::pugixml
find_package(osc2_parser CONFIG REQUIRED)    # → osc2::osc2_parser
find_package(GTest CONFIG REQUIRED)          # → GTest::gtest
```

### 与 vcpkg 集成的 vcpkg.json 示例

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "dependencies": [
    "fmt",
    "pugixml",
    "yaml-cpp"
  ],
  "configuration": {
    "default-registry": {
      "kind": "builtin",
      "baseline": "c941d5e450738629213a60ab8911fd26efca7c6e"
    },
    "registries": [
      {
        "kind": "git",
        "repository": "ssh://git@github.com/myorg/vcpkg-registry.git",
        "baseline": "<commit-hash>",
        "packages": ["my-custom-lib"]
      }
    ]
  }
}
```

## 实际项目案例

来自 avm_camera_render 和 esmini 项目的真实用法：

| vcpkg.json 依赖 | CMakeLists.txt | CMake 目标 |
|----------------|---------------|-----------|
| `"fmt"` | `find_package(fmt CONFIG REQUIRED)` | `fmt::fmt` |
| `"pugixml"` | `find_package(pugixml CONFIG REQUIRED)` | `pugixml::pugixml` |
| `"yaml-cpp"` | `find_package(yaml-cpp CONFIG REQUIRED)` | `yaml-cpp::yaml-cpp` |
| `"gtest"` | `find_package(GTest CONFIG REQUIRED)` | `GTest::gtest` |
| `"osc2-parser"` | `find_package(osc2_parser CONFIG REQUIRED)` | `osc2::osc2_parser` |
| `"osg"` | `find_package(osg CONFIG REQUIRED)` | 包定义 |

## 自定义端口

端口结构:
```
ports/<port-name>/
├── vcpkg.json        # 端口清单
├── portfile.cmake    # 构建脚本
└── CMakeLists.txt    # 源代码构建文件(可选)
```

### 端口清单 (vcpkg.json)

```json
{
  "name": "my-lib",
  "version": "1.0.0",
  "description": "My custom library",
  "dependencies": [
    "vcpkg-cmake",
    "vcpkg-cmake-config"
  ]
}
```

### 构建脚本 (portfile.cmake)

使用 Git 源码的典型模式:

```cmake
vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL "https://github.com/owner/repo.git"
    REF "<commit-hash>"
    HEAD_REF main
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS -DBUILD_TESTS=OFF
)

vcpkg_cmake_build()
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME my-lib)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
```

常用 vcpkg 函数:

| 函数 | 用途 |
|------|------|
| `vcpkg_from_git` | 从 Git 获取源码 |
| `vcpkg_from_github` | 从 GitHub 获取源码 |
| `vcpkg_download_distfile` | 下载压缩包 |
| `vcpkg_cmake_configure` | 配置 CMake |
| `vcpkg_cmake_build` | 执行构建 |
| `vcpkg_cmake_install` | 执行安装 |
| `vcpkg_cmake_config_fixup` | 修复安装配置 |

## 自定义 Registry

Registry 结构:
```
vcpkg-registry/
├── ports/
│   └── <port-name>/
│       ├── vcpkg.json
│       └── portfile.cmake
├── versions/
│   ├── baseline.json
│   └── <letter>-/
│       └── <port-name>.json
```

### baseline.json

声明每个 port 的默认版本:

```json
{
  "default": {
    "my-lib": {
      "baseline": "1.0.0",
      "port-version": 0
    },
    "another-lib": {
      "baseline": "2.1.0",
      "port-version": 1
    }
  }
}
```

### versions/<letter>-/<port>.json

记录每个版本的 git tree SHA:

```json
{
  "versions": [
    {
      "git-tree": "abc123...",
      "version": "1.0.0",
      "port-version": 0
    }
  ]
}
```

### 项目中使用 Custom Registry

在项目 `vcpkg.json` 中添加:

```json
{
  "name": "my-project",
  "version": "1.0.0",
  "dependencies": ["nlohmann-json", "my-lib"],
  "registries": [
    {
      "kind": "git",
      "repository": "https://gitlab.example.com/vcpkg-registry.git",
      "baseline": "<commit-hash>",
      "packages": ["my-lib", "another-lib"]
    }
  ]
}
```

## 实际端口示例

来自 osc2-parser 端口:

**vcpkg.json:**
```json
{
  "name": "osc2-parser",
  "version": "1.0.1",
  "description": "OpenSCENARIO 2 parser library",
  "dependencies": [
    "antlr4",
    "vcpkg-cmake",
    "vcpkg-cmake-config",
    "behaviortree_cpp"
  ]
}
```

**portfile.cmake:**
```cmake
vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL "git@github.com:osc2studio/osc2_parser.git"
    REF "53d3d283859382c4472bb48f80f7a050de85d23d"
    HEAD_REF main
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS -DBUILD_EMSCRIPTEN=OFF
)

vcpkg_cmake_build()
vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME osc2-parser)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug")
```

## Baseline 版本锁定

使用 `builtin-baseline` 将项目所有依赖锁定到 vcpkg 某个 commit：

```json
{
  "name": "myapp",
  "version": "1.0.0",
  "builtin-baseline": "e79c0d2b5d72eb3063cf32a1f7de1a3e8f6b5d3a",
  "dependencies": ["zlib", "fmt"]
}
```

```bash
# 获取当前 baseline
git -C /path/to/vcpkg rev-parse HEAD
# 更新 baseline
vcpkg x-update-baseline
```

## Feature 标志

按需启用包的特定功能：

```json
{
  "dependencies": [
    {
      "name": "boost",
      "features": ["filesystem", "regex"]
    },
    {
      "name": "openssl",
      "default-features": false,
      "features": ["ssl"]
    }
  ]
}
```

## 自定义 Triplet

`triplets/x64-linux-release.cmake`：

```cmake
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE static)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_BUILD_TYPE release)
```

```bash
cmake -B build -S . \
  -DCMAKE_TOOLCHAIN_FILE=[vcpkg]/scripts/buildsystems/vcpkg.cmake \
  -DVCPKG_TARGET_TRIPLET=x64-linux-release \
  -DVCPKG_OVERLAY_TRIPLETS=triplets/
```

## Overlay Ports（项目内自定义端口）

```
my-project/
├── vcpkg.json
└── ports/
    └── mylib/
        ├── vcpkg.json
        └── portfile.cmake
```

```bash
cmake -B build -S . \
  -DCMAKE_TOOLCHAIN_FILE=[vcpkg]/scripts/buildsystems/vcpkg.cmake \
  -DVCPKG_OVERLAY_PORTS=ports/
```

## CI 集成

```yaml
- name: Setup vcpkg
  uses: lukka/run-vcpkg@v11
  with:
    vcpkgGitCommitId: 'e79c0d2...'

- name: Configure
  run: |
    cmake -B build -S . \
      -DCMAKE_TOOLCHAIN_FILE=$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake
```

## 常用库名称

| 库 | vcpkg 名称 | CMake 目标 |
|---|-----------|-----------|
| zlib | `zlib` | `ZLIB::ZLIB` |
| OpenSSL | `openssl` | `OpenSSL::SSL` `OpenSSL::Crypto` |
| curl | `curl` | `CURL::libcurl` |
| fmt | `fmt` | `fmt::fmt` |
| spdlog | `spdlog` | `spdlog::spdlog` |
| nlohmann-json | `nlohmann-json` | `nlohmann_json::nlohmann_json` |
| gtest | `gtest` | `GTest::gtest` `GTest::gtest_main` |
| protobuf | `protobuf` | `protobuf::libprotobuf` |
| sqlite3 | `sqlite3` | `SQLite::SQLite3` |

## 快速参考

| 场景 | 命令 |
|------|------|
| 安装包 | `vcpkg install <pkg>` |
| 搜索包 | `vcpkg search <keyword>` |
| 查看已安装 | `vcpkg list` |
| CMake 构建 | `cmake --preset <preset>` |
| CMake 工具链 | `-DCMAKE_TOOLCHAIN_FILE=[vcpkg]/scripts/buildsystems/vcpkg.cmake` |
| 查看安装目录 | `ls build/vcpkg_installed/<triplet>/share/` |
| 添加自定义端口 | 创建 `ports/<name>/vcpkg.json` + `portfile.cmake` |
| 自定义 Registry | 在 vcpkg.json 中配置 registries 字段 |

### 严禁清单

- ❌ `target_include_directories(... /vcpkg/.../include)` — 使用 find_package 代替
- ❌ `target_link_directories(... /vcpkg/.../lib)` — 使用 find_package 代替
- ❌ `target_link_libraries(... /path/to/libxxx.a)` — 使用 vcpkg 导出的 CMake 目标
- ❌ `set(XXX_DIR /custom/path)` 绕过 vcpkg — 会破坏可移植性
- ❌ 在 CMakeLists.txt 中硬编码 `-DVCPKG_ROOT` 绝对路径 — 使用 CMakePresets 中的 `$env{VCPKG_ROOT}`