---
name: gdb
description: GDB debugger skill for C/C++ projects. Guides when and how to use GDB for crash analysis, runtime variable inspection, memory debugging, and core dump analysis. Activates on segfaults, crashes, SIGABRT, memory errors, and unknown runtime state.
---

# GDB — C/C++ 调试器

指导在适当的时机使用 GDB 进行运行时调试。不要为了用而用，要在真正需要时才启动。

**核心原则：GDB 是运行时问题的分析工具，不是代码阅读工具。不需要时不要启动。**

---

## 何时必须使用 GDB

以下场景应优先考虑 GDB 而非静态分析：

| 场景 | 触发信号 | GDB 的作用 |
|------|----------|-----------|
| **程序崩溃** | SIGSEGV, SIGABRT, SIGBUS, SIGFPE, SIGILL | 获取调用栈、崩溃位置、寄存器状态 |
| **Core Dump** | 有 core 文件生成 | 事后分析崩溃时的完整状态 |
| **段错误（Segfault）** | 空指针解引用、越界访问 | 定位具体哪一行、哪个指针出错 |
| **断言失败** | assert() 触发、abort() | 查看调用链、变量值、程序状态 |
| **内存破坏** | 数据被意外修改 | 设 watchpoint 监控变量何时被改 |
| **不确定行为** | 每次运行结果不同 | 设断点、单步观察变量变化 |
| **运行到特定点时状态不明** | 需要知道某个变量的值 | 设条件断点，打印运行时状态 |
| **死循环/卡死** | 程序无响应 | attach 到进程，查看卡在哪个函数 |
| **多线程问题** | 死锁、数据竞争 | 查看所有线程状态、调用栈 |
| **信号处理异常** | 信号被吞、处理不当 | 在信号处理函数设断点 |
| **动态库加载失败** | dlopen/dlsym 错误 | 查看符号解析、加载路径 |
| **栈溢出** | 递归太深、大局部变量 | 查看调用栈深度、局部变量大小 |

---

## 何时不需要 GDB

以下场景 GDB 不是最佳工具：

| 场景 | 应该用什么 |
|------|-----------|
| 代码逻辑错误（能稳定复现） | 先加日志/assert，再考虑 GDB |
| 编译错误 | 编译器输出已经够了 |
| 类型错误 | 静态分析工具 |
| 内存泄漏（退出时报告） | valgrind / AddressSanitizer |
| 性能瓶颈 | perf / gprof / valgrind --tool=callgrind |
| 能用 printf 快速定位的问题 | printf > GDB（更快） |
| 单元测试失败 | 先看测试输出，再决定是否需要 GDB |

---

## 基本工作流

### 启动 GDB

```bash
# 直接启动
gdb ./program

# 带参数启动
gdb --args ./program arg1 arg2

# 分析 core dump
gdb ./program core

# attach 到运行中的进程
gdb -p <pid>

# 安静模式（不显示欢迎信息）
gdb -q ./program
```

### 崩溃分析流程

```
1. 复现崩溃，获取 core dump
   ulimit -c unlimited          # 允许生成 core 文件
   ./program                    # 运行 → 崩溃 → 生成 core

2. 分析 core
   gdb ./program core
   (gdb) bt                     # 调用栈
   (gdb) bt full                # 调用栈 + 局部变量
   (gdb) frame N                # 切换到第 N 帧
   (gdb) info locals            # 查看局部变量
   (gdb) info args              # 查看函数参数
   (gdb) print var              # 打印变量值
   (gdb) print *ptr             # 解引用指针
   (gdb) info registers         # 查看寄存器
   (gdb) x/10x $rsp             # 查看栈内存
```

### 断点调试流程

```
1. 设断点
   (gdb) break function_name    # 函数断点
   (gdb) break file.cpp:123     # 行断点
   (gdb) break file.cpp:123 if x > 100  # 条件断点
   (gdb) tbreak function_name   # 临时断点（触发一次后删除）

2. 运行
   (gdb) run                    # 开始执行
   (gdb) continue               # 继续到下一个断点
   (gdb) next                   # 单步执行（不进入函数）
   (gdb) step                   # 单步执行（进入函数）
   (gdb) finish                 # 执行到当前函数返回
   (gdb) until 456              # 执行到第 456 行

3. 检查
   (gdb) print expression       # 打印表达式
   (gdb) print/x var            # 十六进制打印
   (gdb) print/t var            # 二进制打印
   (gdb) display var            # 每次停下自动打印
   (gdb) info locals            # 所有局部变量
   (gdb) ptype var              # 打印变量类型
   (gdb) whatis var             # 打印变量类型（简短）
```

---

## 常用场景及命令组合

### 场景 1：段错误定位

```bash
# 如果崩溃可稳定复现
gdb --args ./program
(gdb) run
# 崩溃后:
(gdb) bt                        # 谁调用了出错代码
(gdb) bt full                   # 带局部变量
(gdb) frame 0                   # 到崩溃帧
(gdb) info locals               # 哪个变量是 NULL
(gdb) print ptr                 # 查看可疑指针
(gdb) print *ptr                # 如果 ptr 是 NULL，这里会崩溃（确认是 NULL）
```

### 场景 2：查看某个变量的中间状态

```bash
gdb ./program
(gdb) break important_function
(gdb) run
# 停在断点:
(gdb) print result              # 看看此时的值
(gdb) print/x flags             # 十六进制看标志位
(gdb) print expression->field   # 看结构体成员
(gdb) print *buffer@100         # 打印数组前 100 个元素
(gdb) continue                  # 继续运行
```

### 场景 3：监控变量何时被修改

```bash
gdb ./program
(gdb) watch global_counter      # 写时停下
(gdb) rwatch global_counter     # 读时停下
(gdb) awatch global_counter     # 读或写时停下
(gdb) run
# 变量被修改时自动停下，显示旧值和新值
```

### 场景 4：多线程死锁

```bash
gdb -p <pid>                    # attach 到卡住的进程
(gdb) info threads              # 列出所有线程
(gdb) thread apply all bt       # 所有线程的调用栈
# 找到互相等待的线程:
(gdb) thread 2                  # 切换到线程 2
(gdb) bt
(gdb) frame 0                   # 看卡在哪个锁上
(gdb) print mutex.__owner       # 查看锁拥有者
```

### 场景 5：Core Dump 事后分析

```bash
# 确保有 core dump
ulimit -c unlimited
echo "/tmp/core.%e.%p" | sudo tee /proc/sys/kernel/core_pattern

# 程序崩溃后
ls /tmp/core.*                  # 找到 core 文件
gdb ./program /tmp/core.program.12345
(gdb) bt
(gdb) bt full
(gdb) info registers
(gdb) info frame                # 栈帧详情
(gdb) thread apply all bt       # 多线程全部栈
```

### 场景 6：信号处理

```bash
gdb ./program
(gdb) handle SIGSEGV stop       # 收到 SIGSEGV 时停下
(gdb) handle SIGUSR1 nostop print  # 打印但不停止
(gdb) signal SIGINT             # 向程序发送信号
(gdb) run
# 收到信号时停下，查看完整状态
```

---

## 实用技巧

### 打印技巧

```bash
# 结构体
(gdb) print *struct_ptr        # 展开所有字段
(gdb) print/x *struct_ptr      # 十六进制
(gdb) ptype struct_name        # 查看结构体定义

# 数组
(gdb) print array[0]@100       # 打印前 100 个元素
(gdb) print *array@len         # 用变量指定长度

# 字符串
(gdb) print char_ptr           # 打印指针值
(gdb) x/s char_ptr             # 打印为字符串

# 容器（需要 pretty printer）
(gdb) print vec._M_impl._M_start[0]@vec.size()  # std::vector

# 调用函数
(gdb) call strlen(str)         # 调用库函数
(gdb) call dump_debug_info()   # 调用自己的调试函数
```

### 反汇编

```bash
(gdb) disassemble               # 当前函数的汇编
(gdb) disassemble /m            # 混合源码和汇编
(gdb) x/5i $pc                  # 当前指令附近的 5 条指令
(gdb) info registers rip        # 指令指针
```

### 保存和恢复

```bash
# 保存断点到文件
(gdb) save breakpoints bps.txt

# 恢复断点
(gdb) source bps.txt

# 保存日志
(gdb) set logging on
(gdb) bt full
(gdb) set logging off
```

---

## 与 AddressSanitizer 协同

GDB 和 ASan 可以互补：

```bash
# ASan 提供更详细的内存错误信息
gcc -fsanitize=address -g -O0 program.c
./program  # 崩溃时 ASan 报告精确的内存操作

# 再用 GDB 深入分析
ASAN_OPTIONS=abort_on_error=1 gdb ./program
(gdb) run
# ASan 检测到错误时会调用 abort()，GDB 可以捕获
```

| 工具 | 擅长 |
|------|------|
| **GDB** | 精确控制执行流、查看运行时状态、步进调试 |
| **ASan** | 自动检测越界、use-after-free、double-free |
| **Valgrind** | 全面的内存错误检测（更慢但更全） |
| **TSan** | 数据竞争检测 |

---

## 红线（Hard Constraints）

- **不要在生产环境 attach GDB**。除非用户明确要求。
- **不要修改代码后不重新编译就运行 GDB**。二进制和源码必须匹配。
- **不要忽略优化影响**。-O2 以上级别，变量可能被优化掉，行号可能不准。
- **不要在不确定时猜测 GDB 命令**。不确定时说"我需要查一下 GDB 手册"。
- **不要用 GDB 替代单元测试**。GDB 是调试工具，不是验证工具。

---

## 共享库符号加载（解决"Could not load shared library symbols"）

Core dump 分析时栈回溯显示 "??" 或 "corrupt stack"，通常是因为库符号未加载。

### 设置搜索路径

```gdb
# 设置 sysroot（目标系统的库路径）
set sysroot /path/to/qnx/sysroot/aarch64le

# 设置共享库搜索路径（多个路径用冒号分隔）
set solib-search-path /root/rvc_service/3rdparty/lib:/path/to/qnx/sysroot/lib:/path/to/qnx/sysroot/usr/lib
```

### 加载项目依赖库

第三方库（如 dpc_base、protobuf）也需要手动指定：

```gdb
set solib-search-path /root/rvc_service/3rdparty/dpc_base/lib:/root/rvc_service/build/vcpkg_installed/arm64-qnx/lib:/opt/toolchain/qnx700_8155/target/qnx7/aarch64le/lib
```

### 验证符号加载

```gdb
info sharedlibrary
```

查看 "Syms Read" 列是否为 "Yes"。如果为 "No"，符号未加载成功。

### QNX 常用命令

```bash
# 查找 QNX sysroot 库路径
find /opt/toolchain/qnx700_8155/target/qnx7/aarch64le -name "libc++.so*"

# 启动 QNX GDB
/opt/toolchain/qnx700_8155/host/linux/x86_64/usr/bin/ntoaarch64-gdb ./program core

# 检查二进制 Build ID（确保版本匹配）
readelf -n ./program | grep Build
```

---

## 红旗 — 停止

- "我直接 GDB 看看" — 但没有复现步骤 → 先复现
- "用 printf 就够了" — 但每次改 printf 都要重新编译，已经改了 5 次 → 用 GDB
- 程序生产环境崩溃，用户让你直接 attach → 先要 core dump
- 看不懂 GDB 输出 → 如实报告，不要编造解释
- "设个断点看看" — 但没有明确要看什么 → 先想清楚目的
- 栈回溯全是 "??" → 设置 solib-search-path 再试
