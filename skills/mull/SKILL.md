---
name: mull
description: Use when running mutation testing with Mull on C/C++ projects, integrating Mull into CMake builds, setting up Mull CMakePresets, or debugging low mutation scores.
---

# Mull - Mutation Testing for C/C++

LLVM-based mutation testing. Injects faults into compiled code and checks if tests catch them. Each survived mutant reveals a test gap.

## Detection

```bash
which mull-runner-18 && mull-runner-18 --version   # runner
ls /usr/lib/mull-ir-frontend-18                     # compiler plugin
dpkg -l 2>/dev/null | grep mull                     # installed packages
```

`mull-runner-N` matches LLVM/Clang version N. Use same N everywhere.

## Installation

```bash
# Add Cloudsmith repo
curl -1sLf 'https://dl.cloudsmith.io/public/mull-project/mull-stable/setup.deb.sh' | sudo -E bash

# If Kitware GPG error:
curl -fsSL https://apt.kitware.com/keys/kitware-archive-latest.asc | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg > /dev/null
sudo apt-get update

# Install
sudo apt-get install mull-18
```

RHEL: replace `.deb.sh` with `.rpm.sh`, use `yum install mull-19`.

macOS: `brew install mull-project/mull/mull@19`

## Usage

### 1. Compile with Mull plugin

```bash
clang++-18 \
  -fexperimental-new-pass-manager \
  -fpass-plugin=/usr/lib/mull-ir-frontend-18 \
  -g -grecord-command-line -O0 \
  source.cpp -o test_binary
```

### 2. Optional: mull.yml config

```yaml
mutators:
  - cxx_add_to_sub
  - cxx_ge_to_lt
excludePaths:
  - .*third_party.*
```

### 3. Run

```bash
mull-runner-18 ./test_binary                           # basic
mull-runner-18 --workers 8 ./test_binary                # parallel
mull-runner-18 --reporters SQLite --report-dir ./out ./test_binary
mull-runner-18 --dry-run ./test_binary                  # discover only
mull-runner-18 --allow-surviving --mutation-score-threshold 80 ./test_binary
```

## CMakePresets Integration

```json
{
  "version": 6,
  "configurePresets": [
    {
      "name": "tests-linux-mull",
      "inherits": "tests-linux-debug",
      "cacheVariables": {
        "CMAKE_C_COMPILER": "clang-18",
        "CMAKE_CXX_COMPILER": "clang++-18",
        "CMAKE_C_FLAGS": "-O0 -fexperimental-new-pass-manager -fpass-plugin=/usr/lib/mull-ir-frontend-18 -g -grecord-command-line",
        "CMAKE_CXX_FLAGS": "-O0 -fexperimental-new-pass-manager -fpass-plugin=/usr/lib/mull-ir-frontend-18 -g -grecord-command-line"
      }
    }
  ]
}
```

```bash
cmake --preset tests-linux-mull && cmake --build --preset tests-linux-mull
mull-runner-18 ./build/tests-linux-mull/tests/rvc_tests
```

Always use a **separate preset** — Mull adds build-time overhead and binaries include instrumentation.

## Key Options

| Option | Effect |
|--------|--------|
| `--workers N` | Parallel mutant threads |
| `--timeout MS` | Per-test timeout ms |
| `--minimum-timeout MS` | Min timeout = max(baseline×10, this) |
| `--include-not-covered` | Mutate uncovered lines too |
| `--dry-run` | Discover mutants, skip execution |
| `--reporters IDE\|SQLite\|Sarif\|...` | Output format(s) |
| `--report-dir DIR` | Report output directory |
| `--allow-surviving` | Don't fail on survived mutants |
| `--mutation-score-threshold N` | Min score 0-100 |
| `--coverage-info PATH` | LLVM profdata for coverage filter |

## Common Mutators (mull.yml)

`cxx_add_to_sub`, `cxx_sub_to_add`, `cxx_mul_to_div`, `cxx_div_to_mul`, `cxx_ge_to_lt`, `cxx_ge_to_gt`, `cxx_gt_to_le`, `cxx_eq_to_ne`, `cxx_ne_to_eq`, `cxx_and_to_or`, `cxx_or_to_and`, `cxx_assign_const`, `cxx_remove_void_call`, `negate_mutator`, `remove_negation`.

## Common Mistakes

| Symptom | Fix |
|---------|-----|
| `No mutants found` | Ensure code has comparable/arithmetic ops; use `-O0` |
| Config warning | Create `mull.yml` beside test binary |
| Plugin not called | Add `-fexperimental-new-pass-manager`, use `-O0` for Clang ≤11 |
| Wrong LLVM version | Match `mull-runner-N` / `mull-ir-frontend-N` / `clang-N` |
| `grecord-command-line` fails | Compile files separately (not `clang a.c b.c` at once) |
| Kitware GPG on install | See install section fix above |

## Docs

https://mull.readthedocs.io — https://github.com/mull-project/mull — Discord: https://discord.gg/Hphp7dW
