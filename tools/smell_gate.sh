#!/usr/bin/env bash
# smell_gate.sh — 架构坏味道 grep 门 (A5 贫血模型 / A6 伪多态 / A7 out-param 束)
# 依赖: bash + ripgrep(rg): apt install ripgrep / brew install ripgrep
# 用法: GATE_BASELINE=docs/debt-ledger.md bash tools/smell_gate.sh --path src/
#   --path <dir>    扫描目录 (默认 src/)，生成物 **/autogen/**、**/build/** 自动排除
#   GATE_BASELINE   债台账 (默认 docs/debt-ledger.md)：已登记命中 = 存量不阻塞；未登记 = 新增命中 → 退出码 2
# 豁免: 行内 // smell-ok(A5|A6|A7): 理由 (优先于台账登记，适用于永不需要处理的误报)
# 退出码: 0 = 无新增命中; 2 = 有新增命中。检测为启发式(两步 grep)，人工判断兜底。
set -u

baseline="${GATE_BASELINE:-docs/debt-ledger.md}"
scan_dir="src"
while [ $# -gt 0 ]; do
  if [ "$1" = "--path" ]; then
    scan_dir="$2"
  fi
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
is_registered() { # <file key> <ID> → 0 = 台账已登记（同一行同时含 | file | 与 | ID |）
  [ -f "$baseline" ] || return 1
  rg -qF "| $1 |" "$baseline" && rg -qF "| $2 |" "$baseline"
}
add_hit() { # <file> <line> <ID> → 追加命中
  hits="${hits}$(key_of "$1"):${2}|${3}"$'\n'
}

# ---- A5 贫血模型: 纯数据块(struct 仅字段无嵌套花括号) + 本文件无 X:: 成员定义 + 他文件有 X& 引用 (保守误报, 人工兜底)
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
    if [ -n "$(rg -l "$a5_name\\s*&" "${rgx[@]}" "$scan_dir" | grep -vF "$a5_file" || true)" ]; then
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

# ---- A7 out-param 束: 函数签名含 ≥2 个非 const T& (启发式正则, const 误报人工兜底)
while IFS= read -r a7_hit; do
  [ -n "$a7_hit" ] || continue
  a7_file="${a7_hit%%:*}"; a7_line="${a7_hit#*:}"; a7_line="${a7_line%%:*}"
  case "$(sed -n "${a7_line}p" "$a7_file")" in *"smell-ok(A7)"*) continue ;; esac
  add_hit "$a7_file" "$a7_line" A7
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
