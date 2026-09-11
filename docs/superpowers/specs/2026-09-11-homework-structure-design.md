# MATLAB 作业项目结构设计

日期：2026-09-11
状态：待用户确认

## 背景

4–5 道 MATLAB 基础作业，每道题含 **要求 / 思考 / 提高** 三部分。题目已转成 markdown
（尚未提供内容）。需要先定下一套文件结构，让后续每道题都能直接往里放，不返工。

两个已知约束：

- 交付形式 **两种都要**：普通 `.m` 脚本 + Live Script
- 「思考部分」是**文字论述**，不是代码题 → 需要非代码落点

## 核心决策：单文件双用（方案 A）

不维护两份文件，只写一份 `.m`，同时充当可执行脚本与 Live Script。

依据是下面的实测结论，不是推断。

### 实测验证记录

| 验证项 | 命令 | 结果 |
|---|---|---|
| `%[text]` 行是合法 MATLAB 注释 | `matlab -batch "run('/tmp/hw_live_probe.m')"` | 正常执行，无语法错误 |
| 同一文件可当 Live Script | Live Code 规范 `guidelines://plain-text-live-code` | `%[text]` / `%%` / `%[appendix]` 格式成立，R2025a+ 支持 |
| 未加 `;` 的表达式会输出 | 同上，`y = sin(x)` | 打印 `y = 0 1.0000 0.0000 -1.0000 -0.0000` |
| `-batch` 退出码可用于提交门禁 | 同上，`echo $?` | `exit_code=0` |
| `addpath` 指向不存在的目录 | MCP `evaluate_matlab_code` | **抛警告**（非异常）：`名称不存在或不是目录` |
| `.gitkeep` 是否被忽略 | 读 `.gitignore` | 未忽略，可用于占位空目录 |
| MATLAB 版本 | `version` | 25.2.0.2998904 (R2025b) |

`addpath` 那条决定了一件事：**`functions/` 必须真实存在**，否则每次跑脚本都会刷一条警告。

### 代价（已知并接受）

Live Code 规范要求：正文不用 `fprintf`/`disp` 输出文字，改用「不加分号的表达式」显示值；
`%[text]` 每段写成单行。这会牺牲一点纯脚本的书写习惯，换掉两份文件不同步的风险。

## 目录结构

```
matlab_test/
├── CLAUDE.md
├── docs/superpowers/specs/       # 设计文档（本文件）
├── problems/                     # 题目原文 md，一题一份，只读参考，不放代码
│   └── .gitkeep
├── scripts/                      # 可执行脚本（= 交付物）
│   └── .gitkeep
├── functions/                    # 跨题复用函数；脚本顶部 addpath('functions')
│   └── .gitkeep
└── notes/                        # 思考题的论述、推导、踩坑记录（非代码）
    └── .gitkeep
```

**不建这些**（YAGNI）：

- `livescripts/` —— 方案 A 下没有第二份文件
- `tests/` —— 基础作业靠 `-batch` 退出码 + 与手算/参考答案比对，不引测试框架
- `data/` —— 脚本自包含，除非某道题本身要求读外部数据

## 每道题的工作流

1. 题目 markdown 落到 `problems/hw<NN>-<关键词>.md`
2. 脚本写到 `scripts/`，按 Live Code 格式书写
3. 跑通验证：`"$MATLAB" -batch "run('scripts/xxx.m')"`，退出码 0 才算数
4. 思考部分写进 `notes/`，文件与题目同名
5. 跑通即提交（粒度见 `.claude/rules/git.md`）

## 切分粒度

**默认一题一脚本**，用 `%%` 分节对应 要求 / 思考 / 提高。

例外：某道题的某一部分确实庞大、或需要独立可跑时，才拆成多个脚本。
具体留到读题时判断。

## 脚本命名

**本次不拍板**，留到读到题目内容时再定。

届时的取舍依据：

- CLAUDE.md 现有约定是「按行为命名，不要 `test1.m`」
- 但 4–5 道题 × 3 部分会撞名，纯行为名不够用

倾向方案：`hw<NN>_<行为名>.m`（例：`hw01_matrixInverse.m`），并把这条补进 CLAUDE.md。
读题后如果发现某题只有单一动作，就直接用纯行为名。

## 待办（读完题目后）

- [ ] 确定最终命名规则，同步更新 CLAUDE.md 的「脚本约定」一节
- [ ] 确认 `notes/` 的文件命名是否要和 `scripts/` 一一对应
