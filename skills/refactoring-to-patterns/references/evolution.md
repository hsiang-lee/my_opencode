# 重构与模式（Refactoring to Patterns）

回到索引: [../SKILL.md](../SKILL.md)

**目录**：1 心法 · 2 三种方向 · 3 坏味道→模式 · 4 27 项目录 · 5 演化链 · 6 误区 · 7 评审表 · 8 书的分工

> Kerievsky 的核心：**模式是目的地，重构是道路。** 不要在绿地上先画模式，让模式从坏味道里长出来。
> Fowler：模式是你想到达的地方，重构是从现在位置到那里的条条道路。

---

## 1. 心法（三条）

1. **先写最简单能跑的代码**，不要一上来就 Strategy / Factory / Observer
2. **坏味道出现两次以上**（Rule of Three）才考虑抽象
3. **每一步行为不变 + 测试绿**，不做大爆炸式重写

---

## 2. 三种重构方向（最容易漏掉后两种）

| 方向 | 含义 | 何时用 |
|------|------|--------|
| **TO a Pattern** | 完整落地一个模式 | 坏味道明确、收益清晰、变体 ≥2 |
| **TOWARDS a Pattern** | 只走到模式的一部分，够用就停 | 不确定要不要全套结构 |
| **AWAY from a Pattern** | 拆掉多余的模式、inline 掉 | 复杂度不抵收益 |

**AWAY 的典型动作**：没人扩展的 Singleton 内联回普通类；只有一个实现的 Strategy 合并回原方法；只有一层转发的 Decorator 删掉；空壳 Factory 直接 new。

判据：**抽象的真实使用者 ≤1 且无排期中的第二个 → 反向重构。**

---

## 3. 坏味道 → 目标模式（指针）

坏味道的名称、识别特征与首选手法统一见 `refactoring/references/smells-catalog.md`；模式结构见 `design/references/gof.md`。本文件不再维护「坏味道→模式」映射表，避免与唯一事实源重复。


---

## 4. 27 个模式导向重构（分类速查）

> 手册列高频条目；完整 27 条以原书目录为准，命名可能与 Fowler 手法重叠。

### 创建

- Replace Constructors with Creation Methods
- Move Creation Knowledge to Factory
- Encapsulate Classes with Factory
- Introduce Polymorphic Creation with Factory Method
- Chain Constructors
- Unify Interfaces（用 Adapter 统一接口）

### 简化

- Compose Method（长方法拆成同层步骤）
- Replace Conditional Logic with Strategy
- Move Embellishment to Decorator
- Replace State-Altering Conditionals with State
- Introduce Null Object
- Replace Type Code with Class
- Replace Implicit Language with Interpreter

### 泛化与保护

- Form Template Method
- Extract Composite
- Replace Implicit Tree with Composite
- Replace One/Many Distinctions with Composite
- Move Accumulation to Collecting Parameter
- Move Accumulation to Visitor
- Inline Singleton（反向重构）
- Limit Instantiation with Singleton

### 组合与接口

- Encapsulate Composite with Builder
- Replace Conditional Dispatcher with Command
- Adapt Observer / Replace Hard-Coded Notifications with Observer
- Extract Adapter
- Unify Interfaces with Adapter

---

## 5. 典型演化链（以「重复的类型 switch」为例）

```
1. 识别坏味道        switch(type){ case A:… case B:… } 在 ≥2 处重复
        ↓
2. 机械重构          Extract Method 抽每分支 → Move Method 归位
        ↓
3. 引入多态          Replace Conditional with Polymorphism：每分支一个实现类
        ↓
4. 模式浮现          抽出统一接口 —— 这就是 Strategy
        ↓
5. 按需停止          变体只有 2 个且不再扩 → 留简单多态
                     确认还会扩 → 补注册表 / Factory
```

**第 2 步不做完，不要跳到第 4 步。** 直接写 Strategy 接口 = 过度设计。

---

## 6. 常见误区

| 误区 | 正确做法 |
|------|----------|
| 新项目第一天画满 GoF 类图 | 先写简单代码，等坏味道出现 |
| 为「以后可能扩展」预留抽象 | YAGNI：第三次出现再抽象 |
| 模式越多越「高级」 | 能删掉模式才是本事（AWAY） |
| 重构与功能开发混在同一步 | 先重构（行为不变），再加功能 |
| 没测试就重构到模式 | 没安全网不做结构性重构 |
| 只记模式名字不练小步重构 | 模式是结果，不是起点 |
| 模式掩盖坏味道 | 分支搬进 `execute()` 里继续 if = 只是搬家 |

---

## 7. 评审检查表（模式视角）

- [ ] 这个模式是长出来的，还是预置的？
- [ ] 有对应的坏味道吗？（没有就别加模式）
- [ ] 抽象现在有几个真实使用者？（≤1 → 考虑 inline）
- [ ] 每步重构后测试都绿了吗？
- [ ] 能否先「趋向模式」而不一次到位？
- [ ] 有反向操作空间吗？（Singleton 能内联？Strategy 能合并？）
- [ ] 抽象按「变化轴」划分，还是拍脑袋分类？
- [ ] 接口数量是否超过真实变体数量？

---

## 8. 与其他书的分工

| 阶段 | 依据 |
|------|------|
| 原子手法（Extract / Move / Rename） | Fowler《重构》→ `refactoring/references/smells-catalog.md` / `refactoring/references/techniques.md` |
| 目标形态（Strategy / State / …） | GoF → `design/references/gof.md` |
| 从坏味道到模式的路径 | 本文件 |
| 老代码没有测试 | `legacy-code/references/seams.md` / `legacy-code/references/dependency-breaking.md` |
| 「该不该继续抽象」的校验尺 | SOLID → `design/references/solid-packages.md` |

一句话：**Fowler 教怎么挪代码，GoF 教好代码长什么样，Kerievsky 教怎么从前者走到后者。**
