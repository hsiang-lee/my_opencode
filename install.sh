#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_DIR="${HOME}/.config/opencode/agents"
SKILLS_DIR="${HOME}/.config/opencode/skills"

echo "=== OpenCode Agent & Skill 安装 ==="
echo ""

# 1. Delete old agents
echo "[1/4] 删除旧 agents: ${AGENTS_DIR}"
rm -rf "${AGENTS_DIR}"
echo "      ✅ 完成"

# 2. Delete old skills
echo "[2/4] 删除旧 skills: ${SKILLS_DIR}"
rm -rf "${SKILLS_DIR}"
echo "      ✅ 完成"

# 3. Copy agents
echo "[3/4] 安装 agents: ${SCRIPT_DIR}/agents/ → ${AGENTS_DIR}"
mkdir -p "${AGENTS_DIR}"
cp "${SCRIPT_DIR}"/agents/*.md "${AGENTS_DIR}/"
echo "      ✅ 完成"

# 4. Copy skills
echo "[4/4] 安装 skills: ${SCRIPT_DIR}/skills/ → ${SKILLS_DIR}"
mkdir -p "${SKILLS_DIR}"
cp -r "${SCRIPT_DIR}"/skills/* "${SKILLS_DIR}/"
echo "      ✅ 完成"

echo ""
echo "=== 安装完成 ==="
echo ""
echo "Agent 数量: $(ls -1 ${AGENTS_DIR}/*.md 2>/dev/null | wc -l)"
echo "Skill 数量: $(find ${SKILLS_DIR} -name 'SKILL.md' 2>/dev/null | wc -l)"
