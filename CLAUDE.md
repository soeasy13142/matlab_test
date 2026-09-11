# matlab_test

用来完成**基础 MATLAB 作业**的项目：一个作业一个问题、一个脚本，跑出结果即可。
MATLAB 已安装调试完成，不需要再折腾环境。

- **环境**: MATLAB R2025b，`/Applications/MATLAB_R2025b.app`（不在 PATH 上）
- **无 build / lint / 测试框架**，每个 `.m` 文件都能直接执行

<!-- 已于 2026-09-11 用 version / matlabroot 核实：25.2.0.2998904 (R2025b) -->

## Quick Start

```bash
export MATLAB=/Applications/MATLAB_R2025b.app/bin/matlab

# 跑脚本（-batch 非交互，跑完自动退出，出错返回非零退出码）
"$MATLAB" -batch "run('scripts/homework1.m')"

# 行为跟版本相关时，把版本一起记进输出
"$MATLAB" -batch "version"
```

本会话已接入 MATLAB MCP Server，**优先用它而不是 `matlab -batch`** —— 能直接读到真实输出。

## 铁律

两条规则的共同点是**不要猜**，区别只在于答案该从哪里来。

**一、有任何不明白、不清楚、有疑问的地方，必须先停下来问我。**
用 `AskUserQuestion` 工具提问，不要自己揣测我的意图就往下做。宁可多问一句，也不要交出一个方向错了的结果。

需要问的典型情况：

- 作业要求本身有歧义，或存在不止一种合理解法
- **这次作业要交普通 `.m` 脚本还是 Live Script**（两种都可能，不要预设）
- 要改动我已有的代码或文件
- 我给的描述前后不一致，或漏了关键信息
- 你不确定我想要的输出形式（数值？图？脚本？）

**二、任何数值结果都必须来自真实执行，不能心算或推测。**
这类问题**不要问我，直接跑** —— MATLAB 是数值环境，矩阵运算没法靠推理得出。
不确定某个函数是否存在、参数签名如何，同理：先用 MCP 工具跑一遍验证或查官方文档，不要凭记忆编造 API。
用到非基础函数前，先确认它属于哪个 Toolbox；没装就给出基础 MATLAB 的替代写法。

## Key Conventions

| ❌ 不要 | ✅ 要 |
|---|---|
| `a[0]`、`a[1:3]`、列表推导等 Python 习惯 | 索引从 1 开始：`a(1)` 是第一个元素，切片用圆括号 `a(1:3)` |
| 循环里 `a(end+1) = x` 动态扩数组 | 循环前预分配：`zeros` / `ones` / `cell` / `struct` |
| 用 `i` / `j` 当循环变量（它们是虚数单位） | 用 `ii`、`jj` 或语义名（`idxRow`、`kPoint`） |
| 逐元素的 `for` 循环 | 矩阵运算 / 逻辑索引；确实要循环时优先 `arrayfun` / `cellfun` |
| `a == b` 比较浮点数 | `abs(a - b) < tol`，容差在文件顶部定义成常量 |
| `global` / `eval` / `evalin` / `assignin` | 数据走函数参数 |
| 硬编码 `/` 或 `\` 拼路径 | `fullfile` |
| 赋值语句不写分号 | 所有赋值和非输出语句以 `;` 结尾 |
| 单引号 `'text'` 存文本 | 双引号 `"text"`（需要 char 兼容时才用单引号） |
| 硬编码的阈值 / 上限 | 文件顶部定义 `UPPER_SNAKE_CASE` 常量 |

另外：

- 文件名必须和它定义的主函数名完全一致（`functions/solveQuadratic.m` 里是 `function solveQuadratic`）。
- 用到较新特性时注明版本：`% Requires R2023a+`。
- 用 `arguments` 块校验输入（R2019b+），或 `narginchk` / `validateattributes`。
- 函数头写 H1 行 + 功能说明 + 输入输出 + 一个调用示例。
- 画图给全 `title` / `xlabel` / `ylabel`，多条曲线加 `legend`。
- 脚本顶部 `addpath('functions')`；`clear; clc; close all;` 只在脚本里用，函数内部禁止。
- 报错写清"问题 + 怎么修"：`error('matlab_test:badInput', '输入必须是正数')`。

## 脚本约定

- 一个作业一个脚本，按行为命名（`scripts/solveQuadratic.m`），不要 `test1.m`。
- 脚本自带注释说明**预期结果**，或它复现的**确切错误**。
- 单文件、自包含 —— 不要外部数据文件，除非作业本身需要。

## 版本管理

git 已初始化（仅本地，无 remote）。每个作业完成后提交一次，commit message 说清这个作业是干什么的。

## Reference

| 资源 | 用途 |
|------|------|
| `guidelines://coding`（MATLAB MCP resource） | MathWorks 官方编码规范，权威依据 |
| [MATLAB-Coding-Guidelines](https://github.com/mathworks/MATLAB-Coding-Guidelines) | 上面规范的源仓库 |

<!-- 刻意不写的内容，重新加回来前先读这段：
     - MCP 工具清单：MCP server 已自动注入自己的工具描述，重写一遍是纯重复。
     - 目录树 / 架构说明：`ls` 就能看到，且本项目没有构建系统。
     - camelCase / PascalCase / UPPER_SNAKE_CASE：~/.claude/rules/common/coding-style.md
       已有全局规则，每次会话都会加载，此处不重复（rules 应扩展，不应复述）。
     - 满屏加粗：官方 "emphasis works on one line at a time"，
       加粗只保留给「铁律」一节。 -->
