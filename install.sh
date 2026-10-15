#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCODE_DIR="${HOME}/.config/opencode"
AGENTS_DIR="${OPENCODE_DIR}/agents"
SKILLS_DIR="${OPENCODE_DIR}/skills"

echo "=== OpenCode Agent & Skill 安装 ==="
echo ""

# 1. 删除旧 agents
echo "[1/5] 删除旧 agents: ${AGENTS_DIR}"
rm -rf "${AGENTS_DIR}"
echo "      ✅ 完成"

# 2. 删除旧 skills
echo "[2/5] 删除旧 skills: ${SKILLS_DIR}"
rm -rf "${SKILLS_DIR}"
echo "      ✅ 完成"

# 3. 安装 agents
echo "[3/5] 安装 agents: ${SCRIPT_DIR}/agents/ → ${AGENTS_DIR}"
mkdir -p "${AGENTS_DIR}"
cp "${SCRIPT_DIR}"/agents/*.md "${AGENTS_DIR}/"
echo "      ✅ 完成"

# 4. 安装 skills
echo "[4/5] 安装 skills: ${SCRIPT_DIR}/skills/ → ${SKILLS_DIR}"
mkdir -p "${SKILLS_DIR}"
cp -r "${SCRIPT_DIR}"/skills/* "${SKILLS_DIR}/"
echo "      ✅ 完成"

# 5. 安装 AGENTS.md（全局规则文件，补此前遗漏的根因）
echo "[5/5] 安装 AGENTS.md: ${SCRIPT_DIR}/AGENTS.md → ${OPENCODE_DIR}/AGENTS.md"
mkdir -p "${OPENCODE_DIR}"
cp "${SCRIPT_DIR}/AGENTS.md" "${OPENCODE_DIR}/AGENTS.md"
echo "      ✅ 完成"

echo ""
echo "=== 安装完成 ==="
echo ""
echo "Agent 数量: $(ls -1 ${AGENTS_DIR}/*.md 2>/dev/null | wc -l)"
echo "Skill 数量: $(find ${SKILLS_DIR} -name 'SKILL.md' 2>/dev/null | wc -l)"
