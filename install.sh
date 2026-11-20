#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCODE_DIR="${HOME}/.config/opencode"
AGENTS_DIR="${OPENCODE_DIR}/agents"
SKILLS_DIR="${OPENCODE_DIR}/skills"

echo "=== OpenCode Agent & Skill 安装 ==="
echo ""

# 1. 删除旧 agents
echo "[1/6] 删除旧 agents: ${AGENTS_DIR}"
rm -rf "${AGENTS_DIR}"
echo "      ✅ 完成"

# 2. 删除旧 skills
echo "[2/6] 删除旧 skills: ${SKILLS_DIR}"
rm -rf "${SKILLS_DIR}"
echo "      ✅ 完成"

# 3. 安装 agents
echo "[3/6] 安装 agents: ${SCRIPT_DIR}/agents/ → ${AGENTS_DIR}"
mkdir -p "${AGENTS_DIR}"
cp "${SCRIPT_DIR}"/agents/*.md "${AGENTS_DIR}/"
echo "      ✅ 完成"

# 4. 安装 skills
echo "[4/6] 安装 skills: ${SCRIPT_DIR}/skills/ → ${SKILLS_DIR}"
mkdir -p "${SKILLS_DIR}"
cp -r "${SCRIPT_DIR}"/skills/* "${SKILLS_DIR}/"
echo "      ✅ 完成"

# 5. 安装 AGENTS.md（全局规则文件，补此前遗漏的根因）
echo "[5/6] 安装 AGENTS.md: ${SCRIPT_DIR}/AGENTS.md → ${OPENCODE_DIR}/AGENTS.md"
mkdir -p "${OPENCODE_DIR}"
cp "${SCRIPT_DIR}/AGENTS.md" "${OPENCODE_DIR}/AGENTS.md"
echo "      ✅ 完成"

# 6. 合并运行期配置：subagent_depth
# 默认值为 1，story-executor(depth 1) 派发 smell-scout/refactor(depth 2) 会被拒绝
CONFIG_FILE="${OPENCODE_DIR}/opencode.json"
echo "[6/6] 合并配置: ${CONFIG_FILE} → experimental.subagent_depth=2"
if command -v python3 >/dev/null 2>&1; then
  python3 - "${CONFIG_FILE}" <<'PY'
import json, os, sys

path = sys.argv[1]
if not os.path.exists(path):
    with open(path, "w") as f:
        json.dump({"$schema": "https://opencode.ai/config.json",
                   "experimental": {"subagent_depth": 2}}, f, indent=2)
        f.write("\n")
    print("      created")
    raise SystemExit

raw = open(path).read()
try:
    data = json.loads(raw)
except json.JSONDecodeError:
    print("      ⚠️  跳过：现有配置含注释（JSONC），请手动设置 experimental.subagent_depth=2")
    raise SystemExit

if data.get("experimental", {}).get("subagent_depth") == 2:
    print("      unchanged")
    raise SystemExit

data.setdefault("experimental", {})["subagent_depth"] = 2
with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write("\n")
print("      updated")
PY
  echo "      ✅ 完成"
else
  echo "      ⚠️  跳过：未找到 python3，请手动设置 experimental.subagent_depth=2"
fi

echo ""
echo "=== 安装完成 ==="
echo ""
echo "Agent 数量: $(ls -1 ${AGENTS_DIR}/*.md 2>/dev/null | wc -l)"
echo "Skill 数量: $(find ${SKILLS_DIR} -name 'SKILL.md' 2>/dev/null | wc -l)"
