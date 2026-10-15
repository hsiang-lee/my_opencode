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

# 测试2: 全部登记为债后 → 退出码 0（存量豁免）
cat > "$TMP/debt.md" <<'DEBT'
- 2026-10-15 | src/foo.cpp | A6 | 处置方向
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

echo ""
echo "通过 $PASS / $((PASS+FAIL))"
[ "$FAIL" -eq 0 ]
