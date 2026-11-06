#!/usr/bin/env bash
# 校验渐进披露索引：链接有效、无孤立 reference、>100 行文件带目录。
set -u
root="$(cd "$(dirname "$0")/.." && pwd)/skills"
fail=0
for sk in "$root"/*/SKILL.md; do
  dir="$(dirname "$sk")"
  name="$(basename "$dir")"
  # 1) SKILL.md 引用的 references 必须存在
  while read -r ref; do
    [ -z "$ref" ] && continue
    if [ ! -f "$dir/$ref" ]; then
      echo "MISSING  $name  $ref"; fail=1
    fi
  done < <(grep -o 'references/[A-Za-z0-9._-]*\.md' "$sk" | sort -u)
  # 2) references 下不允许孤立文件
  if [ -d "$dir/references" ]; then
    for f in "$dir/references"/*.md; do
      [ -e "$f" ] || continue
      base="references/$(basename "$f")"
      grep -q "$base" "$sk" || { echo "ORPHAN   $name  $base"; fail=1; }
      # 3) 超过 100 行需要目录
      if [ "$(wc -l < "$f")" -gt 100 ] && ! grep -q '目录' "$f"; then
        echo "NO-TOC   $name  $base"; fail=1
      fi
      # 4) 反向链接
      grep -q 'SKILL.md' "$f" || { echo "NO-BACK  $name  $base"; fail=1; }
    done
  fi
  case "$name" in
    brainstorm|design|functional|refactoring|testing-techniques)
      if [ "$(wc -l < "$sk")" -gt 100 ] && ! grep -q '目录' "$sk"; then
        echo "NO-TOC   $name  SKILL.md"; fail=1
      fi ;;
  esac
done
# 5) agent 正文引用的 references 必须存在于某个 skill 下
agents_dir="$(dirname "$root")/agents"
if [ -d "$agents_dir" ]; then
  for a in "$agents_dir"/*.md; do
    while read -r ref; do
      [ -z "$ref" ] && continue
      if [ ! -f "$root/$ref" ]; then
        echo "MISSING  agents/$(basename "$a")  $ref"; fail=1
      fi
    done < <(grep -o '[a-z-]*/references/[A-Za-z0-9._-]*\.md' "$a" | sort -u)
  done
fi

[ "$fail" -eq 0 ] && echo "lint-skills: OK"
exit "$fail"
