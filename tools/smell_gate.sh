#!/usr/bin/env bash
# smell_gate.sh — 架构坏味道 grep 门 (A5 贫血模型 / A6 伪多态 / A7 out-param 束: 仅引用, 指针不检测)
# 依赖: bash + ripgrep(rg): apt install ripgrep / brew install ripgrep
# 用法: GATE_BASELINE=docs/debt-ledger.md bash tools/smell_gate.sh --path src/
#   --path <dir>    扫描目录 (默认 src/)，生成物 **/autogen/**、**/build/** 自动排除
#   GATE_BASELINE   债台账 (默认 docs/debt-ledger.md)：已登记命中 = 存量不阻塞；未登记 = 新增命中 → 退出码 2
# 豁免: 行内 // smell-ok(A5|A6|A7): 理由 (优先于台账登记，适用于永不需要处理的误报)
# 退出码: 0 = 无新增命中; 2 = 有新增命中。检测为启发式(两步 grep)，人工判断兜底。
set -u

baseline="${GATE_BASELINE:-docs/debt-ledger.md}"
scan_dir="src"
usage() {
  echo "usage: GATE_BASELINE=docs/debt-ledger.md bash tools/smell_gate.sh --path <dir>" >&2
  echo "  --path <dir>   扫描目录 (默认 src/); baseline 由 GATE_BASELINE 指定 (默认 docs/debt-ledger.md)" >&2
}
while [ $# -gt 0 ]; do
  case "$1" in
    --path)
      if [ $# -lt 2 ]; then
        echo "error: --path 缺值" >&2
        usage
        exit 1
      fi
      scan_dir="$2"
      shift
      ;;
    *)
      echo "error: 未知参数: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done
scan_dir="${scan_dir%/}"
parent_dir="$(dirname "$scan_dir")"
rgx=(-g '!**/autogen/**' -g '!**/build/**' --type cpp --no-messages)
today="$(date +%F)"
hits=""

key_of() { # 文件路径 → 台账 key（相对 scan_dir 的父目录，与默认 --path src 的输出形态一致）
  case "$1" in
    "$parent_dir"/*) printf '%s' "${1#"$parent_dir"/}" ;;
    *) printf '%s' "$1" ;;
  esac
}
is_registered() { # <file key> <ID> → 0 = 台账已登记（单行匹配: file 列（容忍 :line 后缀）与 ID 列同行，禁止跨行误放行）
  [ -f "$baseline" ] || return 1
  rg -q --no-messages -e "\\|[[:space:]]*$1(:[0-9]+)?[[:space:]]*\\|[[:space:]]*$2[[:space:]]*\\|" "$baseline"
}
add_hit() { # <file> <line> <ID> → 追加命中
  hits="${hits}$(key_of "$1"):${2}|${3}"$'\n'
}

# ---- A5 贫血模型: 纯数据块(struct 仅字段无嵌套花括号) + 本文件无 X:: 成员定义 + 他文件有非 const X& 引用证据 (const 入参排除, 保守误报人工兜底)
while IFS= read -r a5_file; do
  [ -n "$a5_file" ] || continue
  for a5_pair in $(awk '
    in_struct { if ($0 ~ /\};/) { print start "|" name; in_struct = 0; next } if ($0 ~ /\}/) in_struct = 0 }
    /^[[:space:]]*struct[[:space:]]+[A-Za-z_][A-Za-z0-9_]*[[:space:]]*[{]/ && !in_struct {
      tmp = $0; sub(/^[[:space:]]*struct[[:space:]]+/, "", tmp); sub(/[[:space:]]*[{].*/, "", tmp)
      if (tmp ~ /^[A-Za-z_][A-Za-z0-9_]*$/) { if ($0 ~ /\};/) print NR "|" tmp; else { name = tmp; start = NR; in_struct = 1 } }
    }' "$a5_file"); do
    a5_line="${a5_pair%%|*}"; a5_name="${a5_pair#*|}"
    rg -qF "$a5_name::" "$a5_file" && continue
    case "$(sed -n "${a5_line}p" "$a5_file")" in *"smell-ok(A5)"*) continue ;; esac
    # 两步法: 抓他文件 Name& 引用行, 再排除其中 const Name& 行（const 入参不是 out-param 证据）
    a5_refs="$(rg -n "$a5_name\\s*&" "${rgx[@]}" "$scan_dir" | grep -vF "$a5_file" | rg -v "const[[:space:]]+${a5_name}[[:space:]]*&" || true)"
    if [ -n "$a5_refs" ]; then
      add_hit "$a5_file" "$a5_line" A5
    fi
  done
done < <(rg -lU 'struct\s+\w+\s*\{[^}]*\};' "${rgx[@]}" "$scan_dir" || true)

# ---- A6 伪多态: 同文件 dynamic(_pointer_)cast ≥2 处行号差 ≤10 且含 if/else if 上下文
while IFS= read -r a6_hit; do
  [ -n "$a6_hit" ] || continue
  add_hit "${a6_hit%:*}" "${a6_hit##*:}" A6
done < <(rg -n 'dynamic_pointer_cast|dynamic_cast' "${rgx[@]}" "$scan_dir" | awk '
  { p1 = index($0, ":"); rest = substr($0, p1 + 1); p2 = index(rest, ":")
    f = substr($0, 1, p1 - 1); l = substr(rest, 1, p2 - 1) + 0; t = substr(rest, p2 + 1)
    if (t ~ /smell-ok\(A6\)/) next
    n = ++c[f]; L[f, n] = l; T[f, n] = t }
  END { for (f in c) { i = 1
    while (i <= c[f]) { j = i
      while (j < c[f] && L[f, j + 1] - L[f, j] <= 10) j++
      if (j - i + 1 >= 2) { for (k = i; k <= j && !ctx; k++) if (T[f, k] ~ /if[[:space:]]*\(/) ctx = 1
        if (ctx) print f ":" L[f, i]; ctx = 0 }
      i = j + 1 } } }')

# ---- A7 out-param 束: 函数签名含 ≥2 个非 const 左值引用（仅引用, 指针不检测; 右值引用 && 与 const 引用不计, 启发式人工兜底）
while IFS= read -r a7_hit; do
  [ -n "$a7_hit" ] || continue
  a7_file="${a7_hit%%:*}"; a7_rest="${a7_hit#*:}"; a7_line="${a7_rest%%:*}"; a7_content="${a7_rest#*:}"
  case "$a7_content" in *"smell-ok(A7)"*) continue ;; esac
  a7_norv="${a7_content//&&/}" # 先剔除右值引用, 剩余 & 均为左值引用
  a7_total="$(printf '%s\n' "$a7_norv" | rg -o '\w+\s*&' | wc -l)"
  a7_const="$(printf '%s\n' "$a7_norv" | rg -o 'const\s+\w+\s*&' | wc -l)"
  if [ $((a7_total - a7_const)) -ge 2 ]; then
    add_hit "$a7_file" "$a7_line" A7
  fi
done < <(rg -n '^\w[\w:<>,\s\*&]*\([^;]*\w+\s*&[^&][^;]*\w+\s*&' "${rgx[@]}" "$scan_dir" || true)

# ---- baseline 对比: 台账已登记 = 存量(不阻塞); 未登记 = 新增命中(阻塞, 行格式可直接粘贴登记)
new_hits=""
old_hits=""
while IFS= read -r hit; do
  [ -n "$hit" ] || continue
  hit_file="${hit%%:*}"; line_id="${hit##*:}"; hit_id="${line_id#*|}"; hit_line="${line_id%|*}"
  if is_registered "$hit_file" "$hit_id"; then
    old_hits="${old_hits}- ${today} | ${hit_file}:${hit_line} | ${hit_id} | TODO 处置方向"$'\n'
  else
    new_hits="${new_hits}- ${today} | ${hit_file}:${hit_line} | ${hit_id} | TODO 处置方向"$'\n'
  fi
done <<< "$hits"

printf '新增命中（阻塞）\n%s' "$new_hits"
printf '存量命中（已登记 debt-ledger，不阻塞）\n%s' "$old_hits"
if [ -n "$new_hits" ]; then
  exit 2
fi
exit 0
