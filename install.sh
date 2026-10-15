#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENTS_DIR="${HOME}/.config/opencode/agents"
SKILLS_DIR="${HOME}/.config/opencode/skills"
TOOLS_DIR="${HOME}/.config/opencode/tools"

# 1. 依赖检查（最先，先于任何删除操作）
echo "[1/6] 依赖检查: ripgrep (smell_gate.sh 需要)"
if ! command -v rg >/dev/null 2>&1; then
  echo "❌ 缺少依赖: ripgrep (smell_gate.sh 需要)"; echo "   安装: apt install ripgrep / brew install ripgrep"; exit 1
fi
echo "      ✅ rg 可用"

echo "=== OpenCode Agent & Skill 安装 ==="
echo ""

# 2. 删除旧 agents
echo "[2/6] 删除旧 agents: ${AGENTS_DIR}"
rm -rf "${AGENTS_DIR}"
echo "      ✅ 完成"

# 3. 删除旧 skills
echo "[3/6] 删除旧 skills: ${SKILLS_DIR}"
rm -rf "${SKILLS_DIR}"
echo "      ✅ 完成"

# 4. 安装 agents
echo "[4/6] 安装 agents: ${SCRIPT_DIR}/agents/ → ${AGENTS_DIR}"
mkdir -p "${AGENTS_DIR}"
cp "${SCRIPT_DIR}"/agents/*.md "${AGENTS_DIR}/"
echo "      ✅ 完成"

# 5. 安装 skills
echo "[5/6] 安装 skills: ${SCRIPT_DIR}/skills/ → ${SKILLS_DIR}"
mkdir -p "${SKILLS_DIR}"
cp -r "${SCRIPT_DIR}"/skills/* "${SKILLS_DIR}/"
echo "      ✅ 完成"

# 6. 安装 tools（先删后装，与 agents/skills 对称）
echo "[6/6] 安装 tools: ${SCRIPT_DIR}/tools/ → ${TOOLS_DIR}"
rm -rf "${TOOLS_DIR}"
mkdir -p "${TOOLS_DIR}"
cp "${SCRIPT_DIR}"/tools/*.sh "${TOOLS_DIR}/"
echo "      ✅ 完成"

echo ""
echo "=== 安装完成 ==="
echo ""
echo "Agent 数量: $(ls -1 ${AGENTS_DIR}/*.md 2>/dev/null | wc -l)"
echo "Skill 数量: $(find ${SKILLS_DIR} -name 'SKILL.md' 2>/dev/null | wc -l)"
