# 架构债台账 (debt-ledger)

smell_gate.sh 的 baseline。命中此处的坏味道 = 已登记存量，门禁放行；**新命中会阻塞**。
登记格式（与脚本输出对齐，可直接粘贴）：
`- YYYY-MM-DD | file:line | ID(A5/A6/A7) | 处置方向一句话`

豁免注释：代码行内 `// smell-ok(ID): 理由`（优先于登记，适用于永不需要处理的误报）。

## 台账
（暂无 — 首轮 baseline 待对目标代码库扫描后登记）
