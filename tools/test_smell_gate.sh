#!/bin/bash
# smell_gate.sh 自测：fixture 驱动，验证各检测项与 baseline 对比逻辑
# 注：不用 set -e —— 断言模式「gate 退出码 vs 期望值」需要捕获故意的非零退出码
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
GATE="${SCRIPT_DIR}/smell_gate.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
PASS=0; FAIL=0
check() { # check <名称> <期望退出码> <实际退出码>
  if [ "$2" -eq "$3" ]; then PASS=$((PASS+1)); echo "  ok: $1"; else FAIL=$((FAIL+1)); echo "  FAIL: $1 (期望 $2 实际 $3)"; fi
}

# ---- fixture: A6 伪多态（同文件相邻 cast 链）----
mkdir -p "$TMP/repo/src"
cat > "$TMP/repo/src/foo.cpp" <<'CPP'
void f(std::shared_ptr<ModifierBase> m) {
  if (std::dynamic_pointer_cast<const KeepPositionModifier>(m)) { a(); }
  else if (std::dynamic_pointer_cast<const KeepLaneModifier>(m)) { b(); }
}
CPP

# 测试1: 无 baseline 时新增命中 → 退出码 2（阻塞）
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/repo/src" >/dev/null 2>&1; check "A6 新增命中阻塞" 2 $?

# 测试2: 全部登记为债后 → 退出码 0（存量豁免；登记用文档格式 file:line）
cat > "$TMP/debt.md" <<'DEBT'
- 2026-10-15 | src/foo.cpp:2 | A6 | 处置方向
DEBT
GATE_BASELINE="$TMP/debt.md" bash "$GATE" --path "$TMP/repo/src" >/dev/null 2>&1; check "登记为债后放行" 0 $?

# 测试3: 干净代码 → 退出码 0
mkdir -p "$TMP/clean/src"
echo 'int main() { return 0; }' > "$TMP/clean/src/main.cpp"
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/clean/src" >/dev/null 2>&1; check "干净代码放行" 0 $?

# 测试4: smell-ok 豁免注释生效
mkdir -p "$TMP/exempt/src"
cat > "$TMP/exempt/src/bar.cpp" <<'CPP'
void g(TracePoint& s, TracePoint& e) {  // smell-ok(A7): 协调语义
  s.road_s = e.road_s;
}
CPP
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/exempt/src" >/dev/null 2>&1; check "smell-ok 豁免" 0 $?

# 测试5: A7 out-param 束（≥2 非 const 引用参数，无豁免）→ 2
mkdir -p "$TMP/a7/src"
cat > "$TMP/a7/src/baz.cpp" <<'CPP'
void h(TracePoint& s, TracePoint& e, double d) { s.road_s = d; }
CPP
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/a7/src" >/dev/null 2>&1; check "A7 新增命中阻塞" 2 $?

# ---- 测试6: 按文档格式（file:line）登记 → 放行，且命中出现在"存量"节
cat > "$TMP/debt_fmt.md" <<'DEBT'
- 2026-10-15 | src/foo.cpp:7 | A6 | 处置方向
DEBT
out6="$(GATE_BASELINE="$TMP/debt_fmt.md" bash "$GATE" --path "$TMP/repo/src" 2>&1)"; check "文档格式(file:line)登记放行" 0 $?
if printf '%s\n' "$out6" | grep -q '存量命中' && printf '%s\n' "$out6" | sed -n '/存量命中/,$p' | grep -q 'src/foo.cpp'; then
  PASS=$((PASS+1)); echo "  ok: 命中出现在存量节"
else
  FAIL=$((FAIL+1)); echo "  FAIL: 命中应出现在存量节"
fi

# ---- 测试7: 跨行负例——x.cpp 登记 A5、other.cpp 登记 A6，x.cpp 新 A6 命中 → 判新增 (exit 2)
mkdir -p "$TMP/xline/src"
cat > "$TMP/xline/src/x.cpp" <<'CPP'
void h(std::shared_ptr<BaseX> m) {
  if (std::dynamic_pointer_cast<const D1>(m)) { a(); }
  else if (std::dynamic_pointer_cast<const D2>(m)) { b(); }
}
CPP
echo 'int other() { return 0; }' > "$TMP/xline/src/other.cpp"
cat > "$TMP/debt_xline.md" <<'DEBT'
- 2026-10-15 | src/x.cpp | A5 | 处置方向
- 2026-10-15 | src/other.cpp | A6 | 处置方向
DEBT
GATE_BASELINE="$TMP/debt_xline.md" bash "$GATE" --path "$TMP/xline/src" >/dev/null 2>&1; check "跨行登记不误放行新 A6 (exit 2)" 2 $?

# ---- 测试8: stdout 分类——测试6 场景：stdout 含"存量"，且"新增（阻塞）"节不含该命中
out8="$(GATE_BASELINE="$TMP/debt_fmt.md" bash "$GATE" --path "$TMP/repo/src" 2>&1)"; check "分类验证: exit 0" 0 $?
new_sec="$(printf '%s\n' "$out8" | sed -n '/^新增命中（阻塞）/,/^存量命中/p')"
if printf '%s\n' "$out8" | grep -q '存量' && ! printf '%s\n' "$new_sec" | grep -q 'src/foo.cpp'; then
  PASS=$((PASS+1)); echo "  ok: 存量进存量节且未入新增节"
else
  FAIL=$((FAIL+1)); echo "  FAIL: 分类错误（新增节内容: $new_sec）"
fi

# ---- 测试9: 行号通配——登记 :3，实际命中在 :9（同文件不同行）→ 放行（file+ID 对即可）
mkdir -p "$TMP/drift/src"
cat > "$TMP/drift/src/foo.cpp" <<'CPP'
void pad1() {}
void pad2() {}
void pad3() {}
void pad4() {}
void pad5() {}
void pad6() {}
void pad7() {}
void f(std::shared_ptr<ModifierBase> m) {
  if (std::dynamic_pointer_cast<const KeepPositionModifier>(m)) { a(); }
  else if (std::dynamic_pointer_cast<const KeepLaneModifier>(m)) { b(); }
}
CPP
cat > "$TMP/debt_drift.md" <<'DEBT'
- 2026-10-15 | src/foo.cpp:3 | A6 | 处置方向
DEBT
GATE_BASELINE="$TMP/debt_drift.md" bash "$GATE" --path "$TMP/drift/src" >/dev/null 2>&1; check "行号漂移(登记:3 命中:9)放行" 0 $?

# ---- 测试10: A7——const 引用不计入 out-param，仅 1 个非 const 引用 → 不命中 (exit 0)
mkdir -p "$TMP/a7c/src"
cat > "$TMP/a7c/src/cfg.cpp" <<'CPP'
struct Alpha { int x; };
struct Beta { int x; };
void f(const Alpha& in, Beta& out) { out.x = in.x; }
CPP
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/a7c/src" >/dev/null 2>&1; check "A7 const 引用不计入(仅1个非const引用)放行" 0 $?

# ---- 测试11: A7——2 个非 const 引用 → 仍命中（回归保护）
mkdir -p "$TMP/a7r/src"
cat > "$TMP/a7r/src/ro.cpp" <<'CPP'
void g(Alpha& a, Beta& b) { a.x = b.x; }
CPP
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/a7r/src" >/dev/null 2>&1; check "A7 2个非const引用仍命中 (exit 2)" 2 $?

# ---- 测试12: A5——struct 仅被他文件以 const 入参引用（无 out-param 证据）→ 不命中
mkdir -p "$TMP/a5/src"
cat > "$TMP/a5/src/config.h" <<'CPP'
struct ServerConfig { int port; int timeout; };
CPP
cat > "$TMP/a5/src/server.cpp" <<'CPP'
#include "config.h"
void start(const ServerConfig& cfg) { (void)cfg; }
CPP
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/a5/src" >/dev/null 2>&1; check "A5 const 入参不计(无out-param证据)放行" 0 $?

# ---- 测试13: 参数健壮性——--path 缺值 / 未知参数 → 输出 usage 并 exit 1（不崩溃）
out13a="$(bash "$GATE" --path 2>&1)"; rc13a=$?
if [ "$rc13a" -eq 1 ] && printf '%s' "$out13a" | grep -qi 'usage'; then
  PASS=$((PASS+1)); echo "  ok: --path 缺值 → usage+exit 1"
else
  FAIL=$((FAIL+1)); echo "  FAIL: --path 缺值 (rc=$rc13a out=$out13a)"
fi
out13b="$(bash "$GATE" --bogus 2>&1)"; rc13b=$?
if [ "$rc13b" -eq 1 ] && printf '%s' "$out13b" | grep -qi 'usage'; then
  PASS=$((PASS+1)); echo "  ok: 未知参数 → usage+exit 1"
else
  FAIL=$((FAIL+1)); echo "  FAIL: 未知参数 (rc=$rc13b out=$out13b)"
fi

# ---- 测试14: A5——混合签名行（const 入参 + 非 const 出参同行）→ 行级剔除不得整行吞掉出参，exit 2
mkdir -p "$TMP/a5m/src"
cat > "$TMP/a5m/src/mix.h" <<'CPP'
struct Mix { int v; };
CPP
cat > "$TMP/a5m/src/use.cpp" <<'CPP'
#include "mix.h"
void u(const Mix& in, Mix& out);
CPP
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/a5m/src" >/dev/null 2>&1; check "A5 混合签名行(const入参+非const出参)命中 (exit 2)" 2 $?

# ---- 测试15: file key 正则转义——台账登记 src/foo_cpp:1 (X 非点字符)，src/foo.cpp 新 A6 命中不得被 . 通配误放行，exit 2
mkdir -p "$TMP/fkey/src"
cat > "$TMP/fkey/src/foo.cpp" <<'CPP'
void f(std::shared_ptr<ModifierBase> m) {
  if (std::dynamic_pointer_cast<const KeepPositionModifier>(m)) { a(); }
  else if (std::dynamic_pointer_cast<const KeepLaneModifier>(m)) { b(); }
}
CPP
cat > "$TMP/debt_fkey.md" <<'DEBT'
- 2026-10-15 | src/foo_cpp:1 | A6 | 处置方向
DEBT
GATE_BASELINE="$TMP/debt_fkey.md" bash "$GATE" --path "$TMP/fkey/src" >/dev/null 2>&1; check "file key 转义(台账相似名文件不误放行新A6, exit 2)" 2 $?

# ---- 测试16: A7——const 引用剥 cv 需含命名空间限定 (const std::string& 不计入 out-param) → 放行
mkdir -p "$TMP/a7ns/src"
cat > "$TMP/a7ns/src/bt.cpp" <<'CPP'
struct Config { int v; };
void bt_node(const std::string& name, const Config& cfg, Config& out);
CPP
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/a7ns/src" >/dev/null 2>&1; check "A7 const 命名空间限定引用不计入(混合签名)" 0 $?

# ---- 测试17: A5——struct 含 inline 方法（体内含 }; 子串形态）+ 他文件非 const 引用 → 有方法不判贫血, 放行
mkdir -p "$TMP/a5im/src"
cat > "$TMP/a5im/src/tp.h" <<'CPP'
struct SpeedChannel { double min; double max; };
struct TracePoint {
    double x_ = 0.0;
    double y_ = 0.0;
    void SetX(double v) { x_ = {v}; }
    void SetAccel(double lo, double hi) {
        x_ = lo;
        y_ = hi;
    }
    double& GetRef() { return x_; }
};
CPP
cat > "$TMP/a5im/src/use.cpp" <<'CPP'
#include "tp.h"
void touch(TracePoint& s) { s.SetX(1.0); }
CPP
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/a5im/src" >/dev/null 2>&1; check "A5 有 inline 方法的 struct 不判贫血(方法体内 }; 子串不失明)" 0 $?

# ---- 测试18: A6——同文件不同函数各 1 个 cast (行号差 ≤10) 不得拼簇 → 放行; 对照: 同函数相邻双 cast 仍命中
mkdir -p "$TMP/a6xf/src" "$TMP/a6sf/src"
cat > "$TMP/a6xf/src/two_fn.cpp" <<'CPP'
void f(std::shared_ptr<Base> m) {
  if (std::dynamic_pointer_cast<const A>(m)) { a(); }
}
void g(std::shared_ptr<Base> m) {
  if (std::dynamic_pointer_cast<const B>(m)) { b(); }
}
CPP
cat > "$TMP/a6sf/src/one_fn.cpp" <<'CPP'
void f(std::shared_ptr<Base> m) {
  if (std::dynamic_pointer_cast<const A>(m)) { a(); }
  if (std::dynamic_pointer_cast<const B>(m)) { b(); }
}
CPP
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/a6xf/src" >/dev/null 2>&1; rc18a=$?
GATE_BASELINE="$TMP/none.md" bash "$GATE" --path "$TMP/a6sf/src" >/dev/null 2>&1; rc18b=$?
if [ "$rc18a" -eq 0 ] && [ "$rc18b" -eq 2 ]; then
  PASS=$((PASS+1)); echo "  ok: A6 跨函数不拼簇(0) 且 同函数相邻仍命中(2)"
else
  FAIL=$((FAIL+1)); echo "  FAIL: A6 跨函数 rc=$rc18a (期望 0) / 同函数 rc=$rc18b (期望 2)"
fi

echo ""
echo "通过 $PASS / $((PASS+FAIL))"
[ "$FAIL" -eq 0 ]
