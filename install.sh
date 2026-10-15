#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCODE_DIR="${HOME}/.config/opencode"
AGENTS_DIR="${OPENCODE_DIR}/agents"
SKILLS_DIR="${OPENCODE_DIR}/skills"
TOOLS_DIR="${OPENCODE_DIR}/tools"

# 1. 依赖检查（最先，先于任何删除操作）
echo "[1/7] 依赖检查: ripgrep (smell_gate.sh 需要)"
if ! command -v rg >/dev/null 2>&1; then
  echo "❌ 缺少依赖: ripgrep (smell_gate.sh 需要)"; echo "   安装: apt install ripgrep / brew install ripgrep"; exit 1
fi
echo "      ✅ rg 可用"

echo "=== OpenCode Agent & Skill 安装 ==="
echo ""

# 2. 删除旧 agents
echo "[2/7] 删除旧 agents: ${AGENTS_DIR}"
rm -rf "${AGENTS_DIR}"
echo "      ✅ 完成"

# 3. 删除旧 skills
echo "[3/7] 删除旧 skills: ${SKILLS_DIR}"
rm -rf "${SKILLS_DIR}"
echo "      ✅ 完成"

# 4. 安装 agents
echo "[4/7] 安装 agents: ${SCRIPT_DIR}/agents/ → ${AGENTS_DIR}"
mkdir -p "${AGENTS_DIR}"
cp "${SCRIPT_DIR}"/agents/*.md "${AGENTS_DIR}/"
echo "      ✅ 完成"

# 5. 安装 skills
echo "[5/7] 安装 skills: ${SCRIPT_DIR}/skills/ → ${SKILLS_DIR}"
mkdir -p "${SKILLS_DIR}"
cp -r "${SCRIPT_DIR}"/skills/* "${SKILLS_DIR}/"
echo "      ✅ 完成"

# 6. 安装 tools（先删后装，与 agents/skills 对称）
echo "[6/7] 安装 tools: ${SCRIPT_DIR}/tools/ → ${TOOLS_DIR}"
rm -rf "${TOOLS_DIR}"
mkdir -p "${TOOLS_DIR}"
cp "${SCRIPT_DIR}"/tools/*.sh "${TOOLS_DIR}/"
echo "      ✅ 完成"

# 7. 安装 AGENTS.md（全局规则文件，补此前遗漏的根因）
echo "[7/7] 安装 AGENTS.md: ${SCRIPT_DIR}/AGENTS.md → ${OPENCODE_DIR}/AGENTS.md"
mkdir -p "${OPENCODE_DIR}"
cp "${SCRIPT_DIR}/AGENTS.md" "${OPENCODE_DIR}/AGENTS.md"
echo "      ✅ 完成"

echo ""
echo "=== 安装完成 ==="
echo ""
echo "Agent 数量: $(ls -1 ${AGENTS_DIR}/*.md 2>/dev/null | wc -l)"
echo "Skill 数量: $(find ${SKILLS_DIR} -name 'SKILL.md' 2>/dev/null | wc -l)"
