# 图像处理实验平台可视化界面 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `hw04-imageGeometry/platform/` 下实现作业四提高要求第 2 条要求的可视化交互界面：8 类 16 个算法按登记表列出（已实现的可点、未实现的置灰），能打开图像、调参数、执行算法、并排显示原图与结果。

**Architecture:** 三层。`imgRegistry.m` 是纯数据的算法登记表，界面与自检脚本都只通过它了解算法；「某个算法实现了没有」用它内部 `which(Fcn)` 现场探测，不写死字段，所以补上 `+img/` 里的实现后界面自动点亮。`imgPlatform.m` 用程序化 `uifigure` 搭界面，算法知识全部来自登记表，自身只剩控件搭建与派发。`verifyPlatform.m` 只验登记表自洽，不开界面。

**Tech Stack:** MATLAB R2025b，Image Processing Toolbox 25.2。

## Global Constraints

- **不写 `addpath`，不写 `savepath`**。`+img/` 直接放在 `platform/` 下，靠 cwd 解析。
- **不写 `arguments` 块**（本项目 2026-09-11 起已废除），入参校验用 `narginchk` + 手动 `error`。
- **索引从 1 开始**；循环变量用 `ii`、`jj`、`kk`，不用 `i`、`j`。
- **循环前预分配**：`zeros` / `ones` / `cell` / `struct` / `gobjects`。
- **浮点比较用容差**：`abs(a - b) < tol`，容差在文件顶部定义成 `UPPER_SNAKE_CASE` 常量。
- **赋值和非输出语句以 `;` 结尾**；文本用双引号 `"..."`，不用单引号。
- **路径用 `fullfile` 拼**，不硬编码 `/`。
- **函数头写 H1 行 + 功能说明 + 输入输出 + 一个调用示例**。
- **报错写清「问题 + 怎么修」**：`error("matlab_test:badInput", "...")`。
- **函数内部禁止 `clear` / `clc` / `close all`**，这三个只在脚本里用。
- **不用 `global` / `eval` / `evalin` / `assignin`**。
- **脚本是普通 `.m`**，不写 `%[text]` 等 Live Code 标记，不用 `%%` 分节。
- **界面用程序化 `uifigure`**，不建 App Designer 的 `.mlapp`（二进制包，git 无法 diff）。
- **commit message 格式** `<类型>: <中文描述>`，类型用 `feat` / `fix` / `refactor` / `docs` / `wip` / `chore`。
- **提交前必须跑通**（MATLAB 退出码 0），跑不通用 `wip:` 前缀。
- **署名常量** `"顾皓天0242010213"`，与 `hw04_process0.m` 的 `STUDENT_SIGNATURE` 一致。

## 设计依据

完整设计见 [2026-09-15-image-platform-gui-design.md](../specs/2026-09-15-image-platform-gui-design.md)。
以下实测结论是本计划的硬约束，**不要凭直觉改回去**：

| 实测 | 结果 | 约束 |
|---|---|---|
| `exist("img.grayGamma")` | **返回 0**（该函数存在） | 探测实现必须用 `which`，不能用 `exist` |
| `exist("img.grayGamma","file")` | 同样返回 0 | 同上 |
| `which("img.grayGamma")` | 返回路径；不存在的返回 `""` | 判据是 `~isempty(which(...))` |
| `str2func("img.featHOG")` | **成功**（函数不存在） | `str2func` 不能用作探测，但可用于派发 |
| `uitreenode` 属性 | **无 `Enable`** | 树控件无法逐节点灰显，左栏改用按钮 |
| 滚动面板里放 `uigridlayout` | 内层 grid **不按内容撑高**（停在 100×100） | 左栏子控件用绝对定位 |
| 滚动面板里绝对定位子控件 | 内容高于面板时滚动生效 | 采用此方案 |
| 程序化赋 `uislider.Value` | **不触发** `ValueChangedFcn` | 滑块与数值框双向同步不会死循环 |
| 工厂函数造 getter / 回调 | 各捕获各的句柄 | 循环里必须用工厂函数，不能直接闭包循环变量 |
| 真实照片 4284×5712 四个算法 | 合计 0.514 s | 不需要缩略图，直接跑全图 |
| `-batch` 下 `uifigure` | **能正常创建** | 冒烟测试可以在 `-batch` 里跑，不依赖桌面 |
| `findall(fig,"Type","uibutton")` | 能找到可滚动面板里的按钮 | 冒烟测试用它清点控件 |
| `findall` 的遍历深度 | 到第 4 层为止，**第 5 层找不到** | 只能断言按钮层；参数行标签（`panel → paramGrid → rowGrid → label`，第 5 层）够不着 |

---

## File Structure

| 文件 | 职责 | 状态 |
|---|---|---|
| `hw04-imageGeometry/platform/imgRegistry.m` | 算法登记表：8 类 16 个算法的元数据 + `which` 探测 | 新建 |
| `hw04-imageGeometry/platform/verifyPlatform.m` | 登记表自洽性检查，非零退出码表示不通过 | 新建 |
| `hw04-imageGeometry/platform/imgPlatform.m` | 可视化界面：算法列表、图像管理、参数调节、结果展示 | 新建 |
| `hw04-imageGeometry/platform/verifyPlatformGui.m` | 界面冒烟测试：构造界面、断言控件结构、关闭 | 新建 |
| `hw04-imageGeometry/platform/README.md` | 平台说明、算法清单、运行方式 | 修改 |
| `hw04-imageGeometry/notes.md` | 追加「平台界面」一节，含运行时操作清单 | 修改 |

`+img/` 本轮不动。`+imgio/`（格式兼容）仍属 C 阶段，不建。

---

## Task 1: 算法登记表与自检脚本

登记表是界面与算法之间的唯一接口，也是唯一能自动验证的部分。先做它，
后面界面的正确性就退化成「界面有没有正确读表」。

**Files:**
- Create: `hw04-imageGeometry/platform/imgRegistry.m`
- Create: `hw04-imageGeometry/platform/verifyPlatform.m`

**Interfaces:**
- Consumes: 无（本任务是起点）
- Produces:
  - `registry = imgRegistry()` — 返回 16×1 的 struct 数组，字段
    `Category`（string）、`Name`（string）、`Fcn`（string，形如 `"img.grayGamma"`）、
    `Params`（cell 数组，元素是参数 struct，无参数时为 `{}`）、
    `Output`（string，取值 `"image"` / `"binary"` / `"vector"`）、
    `ExtraLabel`（string，第二个返回值的显示名，无则为 `""`；
    只有两个阈值分割算法是 `"阈值"`，Task 2 的界面据此决定要不要取两个输出）。
    参数 struct 的字段：`Name`（string）、`Default`、`Kind`（string，
    取值 `"slider"` / `"edit"` / `"choice"` / `"size"`），
    可选字段 `Min` / `Max`（数值，`slider` 与 `size` 用）、
    `Options`（string 数组，`choice` 用）。
  - `verifyPlatform.m` 脚本，退出码 0 表示登记表自洽。

- [ ] **Step 1: 写 imgRegistry.m**

创建 `hw04-imageGeometry/platform/imgRegistry.m`：

```matlab
function registry = imgRegistry()
%IMGREGISTRY 图像处理实验平台的算法登记表
%
%   返回 8 类共 16 个算法的元数据。界面与自检脚本都只通过本表了解算法。
%
%   「某个算法实现了没有」不写死在表里，由 which(Fcn) 现场探测 —— 实测
%   exist("img.grayGamma") 对一个存在的包函数返回 0，exist(...,"file") 也是 0，
%   只有 which 可靠。所以补上 +img/ 里的实现后，界面会自动点亮，
%   本表与界面代码都不用改。
%
%   顺序按类别排列，已实现的「灰度变换」「阈值分割」放在最前，
%   界面左栏从上到下就按这个顺序显示。
%
%   输入
%       无
%   输出
%       registry    16×1 的 struct 数组，字段：
%                     Category    类别名
%                     Name        算法显示名
%                     Fcn         包函数名，形如 "img.grayGamma"
%                     Params      参数定义 cell 数组，无参数时为 {}
%                     Output      输出类型，"image" / "binary" / "vector"
%                     ExtraLabel  第二个返回值的显示名，无则为 ""
%
%   调用示例
%       registry = imgRegistry();
%       isDone = ~isempty(which(registry(1).Fcn));

registry = [ ...
    entry("灰度变换", "线性拉伸", "img.grayLinearStretch", { ...
        pSlider("lowIn",  30,   0, 255), ...
        pSlider("highIn", 220,  0, 255)}, ...
        "image"); ...
    entry("灰度变换", "伽马变换", "img.grayGamma", { ...
        pSlider("gamma", 0.5, 0.05, 3)}, ...
        "image"); ...
    entry("阈值分割", "Otsu", "img.threshOtsu", {}, ...
        "binary", "阈值"); ...
    entry("阈值分割", "迭代法", "img.threshIterative", { ...
        pEdit("tol", 1e-6, 1e-9, 1e-2)}, ...
        "binary", "阈值"); ...
    entry("几何变换", "旋转", "img.geomRotate", { ...
        pSlider("angle", 50, -180, 180), ...
        pChoice("method", "bicubic", ["nearest", "bilinear", "bicubic"])}, ...
        "image"); ...
    entry("几何变换", "缩放", "img.geomScale", { ...
        pSize("targetSize", [120, 200], 1, 4096), ...
        pChoice("method", "bilinear", ["nearest", "bilinear", "bicubic"])}, ...
        "image"); ...
    entry("直方图均衡", "全局均衡", "img.histEqualize", { ...
        pSlider("numLevels", 256, 2, 256)}, ...
        "image"); ...
    entry("直方图均衡", "CLAHE", "img.histClahe", { ...
        pSize("numTiles", [8, 8], 1, 64), ...
        pSlider("clipLimit", 0.01, 0.001, 0.2)}, ...
        "image"); ...
    entry("空域滤波", "均值滤波", "img.filterMean", { ...
        pSlider("kernelSize", 3, 3, 15)}, ...
        "image"); ...
    entry("空域滤波", "中值滤波", "img.filterMedian", { ...
        pSlider("kernelSize", 3, 3, 15)}, ...
        "image"); ...
    entry("频域滤波", "理想低通", "img.freqIdealLP", { ...
        pSlider("cutoff", 0.1, 0.01, 0.5)}, ...
        "image"); ...
    entry("频域滤波", "巴特沃斯低通", "img.freqButterLP", { ...
        pSlider("cutoff", 0.1, 0.01, 0.5), ...
        pSlider("order", 2, 1, 10)}, ...
        "image"); ...
    entry("边缘检测", "Sobel", "img.edgeSobel", { ...
        pSlider("threshold", 0.1, 0, 1)}, ...
        "binary"); ...
    entry("边缘检测", "Prewitt", "img.edgePrewitt", { ...
        pSlider("threshold", 0.1, 0, 1)}, ...
        "binary"); ...
    entry("特征提取", "HOG", "img.featHOG", { ...
        pSlider("cellSize", 8, 4, 32), ...
        pSlider("numBins", 9, 4, 16)}, ...
        "vector"); ...
    entry("特征提取", "LBP", "img.featLBP", { ...
        pSlider("numNeighbors", 8, 1, 16)}, ...
        "vector")];

end

% ==================== 局部函数 ====================

function e = entry(category, name, fcn, params, output, extraLabel)
%ENTRY 组装一条算法登记项
%
%   Params 字段用 {params} 再包一层 cell，否则 struct 会把 params 的每个元素
%   当成数组元素展开，16 条登记项就拼不成 struct 数组了。
%
%   extraLabel 可选，第二个返回值的显示名。只有 threshOtsu 与 threshIterative
%   返回 [BW, level] 两个值，那个 level 是阈值分割这道题的核心数字，界面上要
%   显示出来，所以需要在这里登记它叫什么。其余算法只返回一个值，省略即可。
%
%   输入
%       category    类别名
%       name        算法显示名
%       fcn         包函数名
%       params      参数定义 cell 数组
%       output      输出类型
%       extraLabel  可选，第二个返回值的显示名，默认 ""
%   输出
%       e           一条登记项 struct
%
%   调用示例
%       e = entry("阈值分割", "Otsu", "img.threshOtsu", {}, "binary", "阈值");

narginchk(5, 6);
if nargin < 6
    extraLabel = "";
end

e = struct("Category", category, "Name", name, "Fcn", fcn, ...
    "Params", {params}, "Output", output, "ExtraLabel", extraLabel);
end

function p = pSlider(name, defaultValue, minValue, maxValue)
%PSLIDER 范围明确的数值参数，界面上给滑块 + 数值框，两者双向同步
%
%   输入
%       name            参数名，与 +img/ 里的形参名一致
%       defaultValue    默认值，必须落在 [minValue, maxValue] 内
%       minValue        下界
%       maxValue        上界
%   输出
%       p               参数定义 struct，Kind 为 "slider"
%
%   调用示例
%       p = pSlider("gamma", 0.5, 0.05, 3);

p = struct("Name", name, "Default", defaultValue, "Kind", "slider", ...
    "Min", minValue, "Max", maxValue);
end

function p = pEdit(name, defaultValue, minValue, maxValue)
%PEDIT 跨数量级的数值参数，界面上只给数值框
%
%   滑块在 1e-6 这种量级上没法拖，所以不给滑块。范围仍然记下来，
%   供 verifyPlatform.m 检查默认值是否越界。
%
%   输入
%       name            参数名
%       defaultValue    默认值，必须落在 [minValue, maxValue] 内
%       minValue        下界
%       maxValue        上界
%   输出
%       p               参数定义 struct，Kind 为 "edit"
%
%   调用示例
%       p = pEdit("tol", 1e-6, 1e-9, 1e-2);

p = struct("Name", name, "Default", defaultValue, "Kind", "edit", ...
    "Min", minValue, "Max", maxValue);
end

function p = pChoice(name, defaultValue, options)
%PCHOICE 枚举字符串参数，界面上给下拉框
%
%   输入
%       name            参数名
%       defaultValue    默认选项，必须是 options 里的一个
%       options         候选值，字符串数组
%   输出
%       p               参数定义 struct，Kind 为 "choice"
%
%   调用示例
%       p = pChoice("method", "bicubic", ["nearest", "bilinear", "bicubic"]);

p = struct("Name", name, "Default", defaultValue, "Kind", "choice", ...
    "Options", options);
end

function p = pSize(name, defaultValue, minValue, maxValue)
%PSIZE 二元素尺寸参数，界面上给两个数值框
%
%   Min / Max 是标量，对两个分量都适用。
%
%   defaultValue 的分量顺序随算法而定，界面按原样透传给算法，不做解释：
%     targetSize  [行数, 列数] —— 与 imresize 的口径一致
%     numTiles    [行块数, 列块数] —— CLAHE 的分块数
%   上游 spec 与 +img/ 里对应函数的形参定义都以「先行后列」为准。
%
%   输入
%       name            参数名
%       defaultValue    [第一分量, 第二分量]，都必须落在 [minValue, maxValue] 内
%       minValue        下界，对两个分量都适用
%       maxValue        上界，对两个分量都适用
%   输出
%       p               参数定义 struct，Kind 为 "size"
%
%   调用示例
%       p = pSize("targetSize", [120, 200], 1, 4096);

p = struct("Name", name, "Default", defaultValue, "Kind", "size", ...
    "Min", minValue, "Max", maxValue);
end
```

**为什么参数定义用 cell 而不是 struct 数组**：`pChoice` 有 `Options` 字段、
`pSlider` 有 `Min`/`Max` 字段，字段集不同，拼不成 struct 数组。cell 可以装
异构的 struct，所以 `Params` 是 cell。

- [ ] **Step 2: 在命令窗口验证登记表能读出来**

用 MATLAB MCP 工具跑：

```matlab
cd('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform');
registry = imgRegistry();
fprintf('登记项数 = %d\n', numel(registry));
fprintf('首项: %s / %s / %s\n', registry(1).Category, registry(1).Name, registry(1).Fcn);
fprintf('参数个数 = %d, 第一个参数 = %s\n', ...
    numel(registry(1).Params), registry(1).Params{1}.Name);
fprintf('choice 参数 Options = %s\n', ...
    strjoin(registry(5).Params{2}.Options, '|'));
```

Expected:
```
登记项数 = 16
首项: 灰度变换 / 线性拉伸 / img.grayLinearStretch
参数个数 = 2, 第一个参数 = lowIn
choice 参数 Options = nearest|bilinear|bicubic
```

若报「无法从 struct 创建数组」之类的错，多半是 `entry` 里 `"Params", {params}`
的那层 cell 忘了加。

- [ ] **Step 3: 写 verifyPlatform.m**

创建 `hw04-imageGeometry/platform/verifyPlatform.m`：

```matlab
% 检查 imgRegistry.m 的登记表是否自洽
%
% 运行：在编辑器里点运行，或
%   matlab -batch "run('hw04-imageGeometry/platform/verifyPlatform.m')"
% 退出码 0 表示全部通过。
%
% 预期结果：命令窗口逐行打印检查项、期望值与实测值，最后列出已实现的算法。
%          全部通过时打印「全部通过」；不通过时每项下面跟一行缩进说明，
%          末尾汇总未通过项数并以非零退出码结束。
%
% 本脚本只验登记表，不开界面 —— 界面回调没法自动点，人工清单见 notes.md。

clear; clc; close all;

EXPECTED_CATEGORIES = 8;
EXPECTED_PER_CAT    = 2;
VALID_OUTPUTS       = ["image", "binary", "vector"];
VALID_KINDS         = ["slider", "edit", "choice", "size"];

registry = imgRegistry();
failureCount = 0;

% ---------- 类别与数量 ----------
categories       = string({registry.Category});
uniqueCategories = unique(categories, "stable");

failureCount = failureCount + checkEq("类别数", numel(uniqueCategories), EXPECTED_CATEGORIES);
failureCount = failureCount + checkEq("算法总数", numel(registry), ...
    EXPECTED_CATEGORIES * EXPECTED_PER_CAT);

perCategory = zeros(numel(uniqueCategories), 1);
for kk = 1:numel(uniqueCategories)
    perCategory(kk) = nnz(categories == uniqueCategories(kk));
end
failureCount = failureCount + checkEq("每类算法数（最小值）", ...
    min(perCategory), EXPECTED_PER_CAT);

% ---------- 函数名与输出类型 ----------
fcnNames  = string({registry.Fcn});
badPrefix = nnz(~startsWith(fcnNames, "img."));
failureCount = failureCount + checkEq("Fcn 前缀不合规条数", badPrefix, 0);

% 重名会让「已实现」计数重复，界面上还会多出一个同名按钮
duplicateFcn = numel(fcnNames) - numel(unique(fcnNames));
failureCount = failureCount + checkEq("Fcn 重名条数", duplicateFcn, 0);

badOutput = nnz(~ismember(string({registry.Output}), VALID_OUTPUTS));
failureCount = failureCount + checkEq("Output 取值不合规条数", badOutput, 0);

% ---------- 参数定义 ----------
badKind          = 0;
badRange         = 0;
missingOptions   = 0;
badChoiceDefault = 0;

for kk = 1:numel(registry)
    params = registry(kk).Params;
    for pp = 1:numel(params)
        p = params{pp};

        if ~ismember(string(p.Kind), VALID_KINDS)
            badKind = badKind + 1;
        end
        % Min / Max 是标量，Default 可能是二元素（size 类），逐元素比
        if isfield(p, "Min") && any(p.Default < p.Min | p.Default > p.Max)
            badRange = badRange + 1;
        end
        if string(p.Kind) == "choice"
            if ~isfield(p, "Options")
                missingOptions = missingOptions + 1;
            elseif ~ismember(string(p.Default), string(p.Options))
                % 默认值打错字的话，界面上表现为下拉框选不中或静默退回第一项
                badChoiceDefault = badChoiceDefault + 1;
            end
        end
    end
end

failureCount = failureCount + checkEq("Kind 取值不合规条数", badKind, 0);
failureCount = failureCount + checkEq("choice 缺 Options 条数", missingOptions, 0);
failureCount = failureCount + checkEq("choice 默认值不在选项里条数", badChoiceDefault, 0);
failureCount = failureCount + checkEq("默认值越界条数", badRange, 0);

% ---------- 实现情况（仅供参考，不算通过与否）----------
implementedNames = strings(numel(registry), 1);
implementedCount = 0;
for kk = 1:numel(registry)
    if ~isempty(which(registry(kk).Fcn))
        implementedCount = implementedCount + 1;
        implementedNames(implementedCount) = registry(kk).Fcn;
    end
end
fprintf("\n已实现 %d/%d 个：%s\n", implementedCount, numel(registry), ...
    strjoin(implementedNames(1:implementedCount), ", "));

if failureCount > 0
    error("matlab_test:verifyPlatformFailed", ...
        "共 %d 项检查未通过，逐条明细见上方标了 false 的行。", failureCount);
end

fprintf("\n全部通过\n");

% ==================== 局部函数 ====================

function nFail = checkEq(label, actual, expected)
%CHECKEQ 打印一项检查并判定是否与期望相等，返回未通过条数（0 或 1）
%
%   不抛错。失败只打印明细，由脚本体累加后在末尾统一报错，
%   这样一次运行能看到全部未通过项。
%
%   输入
%       label       检查项名称
%       actual      实测值
%       expected    期望值
%   输出
%       nFail       未通过条数，0 或 1
%
%   调用示例
%       failureCount = failureCount + checkEq("算法总数", numel(registry), 16);

isPass = isequal(actual, expected);

fprintf("%-24s 期望 %-10s 实测 %-10s %s\n", ...
    label, string(expected), string(actual), string(isPass));

if ~isPass
    fprintf("    ^ 未通过: %s 应为 %s，实测 %s\n", ...
        label, string(expected), string(actual));
end

nFail = ~isPass;
end
```

- [ ] **Step 4: 跑自检，确认通过**

用 MATLAB MCP 的 `run_matlab_file` 跑 `hw04-imageGeometry/platform/verifyPlatform.m`，
或命令行：

```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "run('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform/verifyPlatform.m')"
```

Expected:
```
类别数                        期望 8          实测 8          true
算法总数                      期望 16         实测 16         true
每类算法数（最小值）          期望 2          实测 2          true
Fcn 前缀不合规条数            期望 0          实测 0          true
Fcn 重名条数                  期望 0          实测 0          true
Output 取值不合规条数         期望 0          实测 0          true
Kind 取值不合规条数           期望 0          实测 0          true
choice 缺 Options 条数        期望 0          实测 0          true
choice 默认值不在选项里条数   期望 0          实测 0          true
默认值越界条数                期望 0          实测 0          true

已实现 4/16 个：img.grayLinearStretch, img.grayGamma, img.threshOtsu, img.threshIterative

全部通过
```

退出码 0。**「已实现 4/16」这个数字必须是 4** —— 若是 0，说明 `which` 探测写错了
（比如误用了 `exist`）；若是 16，说明探测恒真。

- [ ] **Step 5: 负向探针 —— 证明每个计数器都真的会失败**

**这一步不能省。** 全 `true` 的输出只能说明「当前没发现问题」，不能说明检查有效：
一个写坏了的计数器（比如恒为 0）打印出来的也是 `0 / true / 全部通过`。
所以要在临时副本上逐个注入错误，确认对应计数器真的会变非零。

做法的关键限制：`verifyPlatform.m` 是脚本，它**自己内部**调 `imgRegistry()`，
没法从外面喂一张坏表进去。所以只能**复制一份脚本**、在
`registry = imgRegistry();` 那行后面插一句把表改坏。

副本要放在 `platform/` 目录里 —— `run()` 会把 cwd 切到脚本所在目录，
放 `/tmp` 的话 `imgRegistry()` 解析不到。跑完**把临时文件删掉，不要提交**。

十种注入，以及各自应当变非零的计数器：

| 注入 | 插在 `registry = imgRegistry();` 之后的那一句 | 应当变非零的计数器 |
|---|---|---|
| 类别数 | `registry(1).Category = "新类别";` | 类别数、每类算法数（最小值）|
| 算法总数 | `registry(16) = [];` | 算法总数、每类算法数（最小值） |
| 每类算法数 | `registry(2) = [];` | 算法总数、每类算法数（最小值） |
| Fcn 前缀 | `registry(1).Fcn = "grayGamma";` | Fcn 前缀不合规条数（**不含** Fcn 重名条数） |
| Fcn 重名 | `registry(2).Fcn = registry(1).Fcn;` | Fcn 重名条数 |
| Output 取值 | `registry(1).Output = "pic";` | Output 取值不合规条数 |
| Kind 取值 | `registry(1).Params{1}.Kind = "dial";` | Kind 取值不合规条数 |
| choice 缺 Options | `registry(5).Params{2} = rmfield(registry(5).Params{2}, "Options");` | choice 缺 Options 条数 |
| choice 默认值 | `registry(5).Params{2}.Default = "nope";` | choice 默认值不在选项里条数 |
| 默认值越界 | `registry(1).Params{1}.Default = 999;` | 默认值越界条数 |

用 `registry(5)` 是因为**第 5 条才是第一个带 `choice` 参数的登记项**
（几何变换/旋转，参数是 `angle` 的 slider 与 `method` 的 choice）。
`registry(1)` 是灰度变换/线性拉伸，两个参数都是 slider，没有 `Options` 字段，
拿它做 choice 注入会直接报「无法识别的字段名」，测不到计数器。

每种注入都把脚本**完整跑一遍**，把实际输出原样贴进报告 —— 这是「自检脚本本身
有效」的证据。**若某个计数器怎么注入都不变非零**，说明那条检查写错了，
要修 `verifyPlatform.m` 再重跑。

- [ ] **Step 6: 提交**

```bash
git add hw04-imageGeometry/platform/imgRegistry.m hw04-imageGeometry/platform/verifyPlatform.m
git commit -m "feat: 算法登记表与自检脚本，16 个算法按 which 现场探测实现情况"
```

---

## Task 2: 可视化界面

界面的算法知识全部来自 Task 1 的登记表，本任务只做控件搭建与派发。

**Files:**
- Create: `hw04-imageGeometry/platform/imgPlatform.m`

**Interfaces:**
- Consumes: `imgRegistry()`（Task 1）
- Produces:
  - `imgPlatform()` — 无入参无返回，调用即开界面。约定：窗口标题含
    `"图像处理实验平台"`；左栏每个算法的按钮 `Text` 等于 `registry.Name`；
    顶栏与参数区另有三个按钮，文字为 `"打开图像"` / `"保存结果"` / `"执行"`。
    这三条约定是 Task 2 Step 2 的冒烟测试赖以定位控件的东西，改动要同步。
  - `verifyPlatformGui.m` 脚本，退出码 0 表示界面结构符合预期。

- [ ] **Step 1: 写 imgPlatform.m**

创建 `hw04-imageGeometry/platform/imgPlatform.m`。**完整内容如下**，注意最后那个
`end` 之前是嵌套函数、之后是局部函数，顺序不能调换（MATLAB 要求局部函数在文件末尾）。

```matlab
function imgPlatform()
%IMGPLATFORM 图像处理实验平台的图形界面
%
%   开出一个窗口：左栏按 8 个类别列出 16 个算法（未实现的置灰不可点），
%   顶部是图像管理按钮，右侧并排显示原图与结果，下方是参数调节区与结果信息。
%   打开图像后选中算法、调参数、点「执行」即可看到结果。
%
%   算法的全部知识来自 imgRegistry()，本函数只负责搭控件与派发。
%   「实现了没有」是登记表用 which 现场探测的，所以以后补上 +img/ 里的实现，
%   对应按钮会自动从灰变亮，本文件一行都不用改。
%
%   输入
%       无
%   输出
%       无（界面窗口本身即是输出）
%
%   调用示例
%       在编辑器里打开本文件点运行，或在命令窗口输入 imgPlatform

% ---------- 常量 ----------
STUDENT_SIGNATURE = "顾皓天0242010213";

FIG_NAME       = "图像处理实验平台  Plot by " + STUDENT_SIGNATURE;
FIG_POSITION   = [100 80 1100 720];
LEFT_WIDTH     = 190;    % 左栏算法列表宽度
BUTTON_WIDTH   = 158;    % 算法按钮宽度，留出左栏边框与滚动条的余量
ROW_HEIGHT     = 24;     % 算法按钮高度
ROW_GAP        = 3;      % 算法按钮之间的间隔
LABEL_HEIGHT   = 18;     % 类别标签高度
PANEL_PAD      = 6;      % 列表四周留白
DISABLED_COLOR = [0.55 0.55 0.55];   % 未实现算法的灰字
NORMAL_COLOR   = [0 0 0];
AXES_LABEL_ORIGINAL = "原图";
AXES_LABEL_RESULT   = "结果";

% 打开/保存对话框的文件类型过滤器。第 2 条要求「图像管理」，这里把第 3 条
% 要求的五种格式一并列上，底层直接用 imread / imwrite，不做额外封装。
IMAGE_FILTER = { ...
    "*.bmp;*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.gif", "所有支持的图像"; ...
    "*.bmp",        "BMP 图像"; ...
    "*.jpg;*.jpeg", "JPEG 图像"; ...
    "*.png",        "PNG 图像"; ...
    "*.tif;*.tiff", "TIFF 图像"; ...
    "*.gif",        "GIF 图像"; ...
    "*.*",          "所有文件"};

% ---------- 状态 ----------
% 这些变量被下面的嵌套函数共享，必须在父函数作用域里声明
registry     = imgRegistry();
currentImage = [];      % 已载入的灰度图，未载入时为 []
currentName  = "";      % 文件名，显示在状态栏
resultImage  = [];      % 上一次「执行」的结果，未执行时为 []
resultOutput = "";      % 产出 resultImage 的那个算法的 Output 类型。
                        % 不能现查 registry(selectedIdx) —— 用户可以在算完之后
                        % 改选别的算法，那时 selectedIdx 已经指向别的算法了。
isColorInput = false;   % 原图是否为彩色，用于状态栏标注
selectedIdx  = 0;       % 当前选中的算法下标，0 表示未选

algorithmButtons = gobjects(0);   % 左栏按钮，下标与 registry 一一对应
executeButton    = gobjects(0);   % 每次重建参数区时重新赋值
paramGetters     = {};            % cell of function handle，按登记表顺序取值

% ---------- 界面框架 ----------
fig = uifigure("Name", FIG_NAME, "Position", FIG_POSITION);

mainGrid = uigridlayout(fig, [2 2], ...
    "ColumnWidth", {LEFT_WIDTH, "1x"}, ...
    "RowHeight",   {"fit", "1x"}, ...
    "Padding",     [6 6 6 6], ...
    "RowSpacing",  6);

% --- 顶栏：图像管理 ---
topBar = uigridlayout(mainGrid, [1 3], ...
    "ColumnWidth", {100, 100, "1x"}, ...
    "Padding",     [0 0 0 0], ...
    "ColumnSpacing", 6);
topBar.Layout.Row    = 1;
topBar.Layout.Column = [1 2];

openButton  = uibutton(topBar, "Text", "打开图像", "ButtonPushedFcn", @onOpenImage);
saveButton  = uibutton(topBar, "Text", "保存结果", "ButtonPushedFcn", @onSaveResult);
statusLabel = uilabel(topBar, "Text", "未载入图像");

% --- 左栏：算法列表 ---
leftPanel = uipanel(mainGrid, "Title", "算法", "Scrollable", "on");
leftPanel.Layout.Row    = 2;
leftPanel.Layout.Column = 1;

% --- 右侧：原图 / 结果 / 参数 / 信息 ---
rightGrid = uigridlayout(mainGrid, [3 1], ...
    "RowHeight",  {"1x", "fit", "fit"}, ...
    "Padding",    [0 0 0 0], ...
    "RowSpacing", 6);
rightGrid.Layout.Row    = 2;
rightGrid.Layout.Column = 2;

axesGrid   = uigridlayout(rightGrid, [1 2], ...
    "Padding", [0 0 0 0], "ColumnSpacing", 6);
axOriginal = uiaxes(axesGrid);
axResult   = uiaxes(axesGrid);
title(axOriginal, AXES_LABEL_ORIGINAL);
title(axResult,   AXES_LABEL_RESULT);
axOriginal.XTick = [];  axOriginal.YTick = [];
axResult.XTick   = [];  axResult.YTick   = [];

paramPanel = uipanel(rightGrid, "Title", "参数");
infoLabel  = uilabel(rightGrid, "Text", "尚未执行");

% ---------- 初始内容 ----------
algorithmButtons = buildAlgorithmList(leftPanel);
buildParamControls();
refreshEnableState();

% ==================== 嵌套函数 ====================
% 嵌在 imgPlatform 里，所以能直接读写上面的状态变量

    % ---------------- 图像管理 ----------------

    function onOpenImage(~, ~)
        [fileName, folder] = uigetfile(IMAGE_FILTER, "选择图像");
        if isequal(fileName, 0)
            return;                          % 用户取消
        end

        fullPath = fullfile(folder, fileName);

        % 读图、转灰度、显示三段都包在同一个 try 里。只包 imread 是不够的：
        % 4 通道图（RGBA / CMYK 的 TIFF）会在 rgb2gray 处抛错，而打开对话框的
        % 过滤器里就有 *.gif 和 *.tif。抛在 try 外面的话，回调会中途死掉，
        % 留下「图像已换、状态栏没更新、按钮没刷新」的半截状态。
        try
            raw = imread(fullPath);

            % +img/ 里的算法开头都有 ~ismatrix(I) 检查，彩色图会直接报错。
            % 这里统一转灰度，并在状态栏说明，免得用户以为显示的就是原色。
            isColor = (ndims(raw) == 3);
            if isColor
                loadedImage = rgb2gray(raw);
            else
                loadedImage = raw;
            end

            % rgb2gray 之后还不是二维的（多帧图之类），说明这个文件超出
            % 支持范围，与其让后面的算法报「只接受二维灰度图」，不如在这里说清
            if ~ismatrix(loadedImage)
                error("matlab_test:unsupportedImage", ...
                    "读到的图是 %d 维，只支持单帧灰度图或三通道彩色图。" + ...
                    "请换一张图。", ndims(loadedImage));
            end

            showImage(axOriginal, loadedImage, AXES_LABEL_ORIGINAL);
        catch err
            uialert(fig, "读取失败：" + err.message, "打开图像失败");
            return;
        end

        % 走到这里说明读图和显示都成功了，这时才改状态 ——
        % 上面任何一步失败都不会留下半更新的界面
        currentImage = loadedImage;
        currentName  = string(fileName);
        isColorInput = isColor;

        resultImage    = [];                 % 换了图，上一次的结果作废
        resultOutput   = "";
        infoLabel.Text = "尚未执行";

        cla(axResult);
        title(axResult, AXES_LABEL_RESULT);

        colorNote = "";
        if isColorInput
            colorNote = "   已自动转灰度";
        end
        statusLabel.Text = string(sprintf("%s   %d×%d   %s%s", ...
            currentName, size(currentImage, 1), size(currentImage, 2), ...
            class(currentImage), colorNote));

        refreshEnableState();
    end

    function onSaveResult(~, ~)
        if isempty(resultImage)
            return;
        end

        [fileName, folder] = uiputfile(IMAGE_FILTER, "保存结果");
        if isequal(fileName, 0)
            return;                          % 用户取消
        end

        fullPath = fullfile(folder, fileName);
        try
            imwrite(resultImage, fullPath);
        catch err
            uialert(fig, "保存失败：" + err.message, "保存结果失败");
            return;
        end

        statusLabel.Text = "已保存 " + string(fullPath);
    end

    % ---------------- 算法选择与执行 ----------------

    function onSelectAlgorithm(idx)
        selectedIdx = idx;
        buildParamControls();
        refreshEnableState();
    end

    function fh = makeAlgorithmCallback(idx)
        % 工厂函数：把当次的 idx 绑进回调。
        % 不能直接写 @(~,~) onSelectAlgorithm(kk) —— kk 是循环变量，
        % 所有回调会共享它最终的值，点哪个按钮都选到最后一个算法。
        % 实测过：工厂函数传参进去，每个句柄才各捕获各的。
        fh = @(~, ~) onSelectAlgorithm(idx);
    end

    function onExecute(~, ~)
        if isempty(currentImage) || selectedIdx == 0
            return;
        end

        entryNow = registry(selectedIdx);

        % 按当前控件取值，顺序与登记表里的参数定义一致
        args = cell(numel(paramGetters), 1);
        for kk = 1:numel(paramGetters)
            args{kk} = paramGetters{kk}();
        end

        fcn    = str2func(entryNow.Fcn);
        tStart = tic;
        try
            % 登记表里标了 ExtraLabel 的算法返回 [结果, 标量]，第二个返回值是
            % 收敛阈值，要在信息行里显示出来 —— 它是阈值分割这道题的核心数字。
            % 不能一律写成 [result, extra] = fcn(...)：只定义一个返回值的算法
            % 被要两个输出会直接报「输出参数太多」。
            if strlength(entryNow.ExtraLabel) > 0
                [result, extraValue] = fcn(currentImage, args{:});
            else
                result     = fcn(currentImage, args{:});
                extraValue = [];
            end
        catch err
            uialert(fig, err.message, "算法执行失败");
            return;
        end
        elapsed = toc(tStart);

        resultImage  = result;
        resultOutput = entryNow.Output;

        extraText = "";
        if ~isempty(extraValue)
            extraText = sprintf("   %s %.4f", entryNow.ExtraLabel, extraValue);
        end

        if entryNow.Output == "vector"
            % 特征描述子不是图像，用 plot 画
            plot(axResult, result);
            title(axResult, "结果（特征向量）");
            infoLabel.Text = string(sprintf("维度 %d   耗时 %.3f s%s", ...
                numel(result), elapsed, extraText));
        else
            showImage(axResult, result, AXES_LABEL_RESULT);
            infoLabel.Text = string(sprintf("尺寸 %d×%d   类型 %s   耗时 %.3f s%s", ...
                size(result, 1), size(result, 2), class(result), elapsed, extraText));
        end

        refreshEnableState();
    end

    function refreshEnableState()
        hasImage = ~isempty(currentImage);

        for kk = 1:numel(algorithmButtons)
            isImplemented = ~isempty(which(registry(kk).Fcn));

            % Enable 和 FontColor 表示两件不同的事，不能绑在同一个条件上：
            %   Enable     —— 现在能不能点（要有图，且算法实现了）
            %   FontColor  —— 这个算法实现了没有（灰 = 未实现）
            % 混在一起的话，没载图时 16 个按钮全是灰的，用户看不出哪几个能用，
            % 而那正是刚打开界面、还没载图时的状态。
            algorithmButtons(kk).Enable = onOff(hasImage && isImplemented);
            if isImplemented
                algorithmButtons(kk).FontColor = NORMAL_COLOR;
            else
                algorithmButtons(kk).FontColor = DISABLED_COLOR;
            end
        end

        % 特征向量不是图像，imwrite 会把它当 1×N 的图写出垃圾，所以不给保存。
        % 判据用「产出这个结果的算法」的 Output，不是当前选中的那个 ——
        % 用户可以在算完之后改选别的算法。
        isSavable = ~isempty(resultImage) && resultOutput ~= "vector";

        saveButton.Enable    = onOff(hasImage && isSavable);
        executeButton.Enable = onOff(hasImage && selectedIdx > 0);
    end

    % ---------------- 左栏列表 ----------------

    function buttons = buildAlgorithmList(parentPanel)
        % 左栏是滚动面板，子控件用绝对定位 —— 实测滚动面板里的 uigridlayout
        % 不会按内容撑高（停在默认 100×100），滚动不生效。
        buttons          = gobjects(numel(registry), 1);
        categories       = string({registry.Category});
        uniqueCategories = unique(categories, "stable");

        yCursor = PANEL_PAD;
        for cc = 1:numel(uniqueCategories)
            uilabel(parentPanel, "Text", uniqueCategories(cc), ...
                "FontWeight", "bold", ...
                "Position", [PANEL_PAD, yCursor, BUTTON_WIDTH, LABEL_HEIGHT]);
            yCursor = yCursor + LABEL_HEIGHT + 2;

            for kk = 1:numel(registry)
                if categories(kk) ~= uniqueCategories(cc)
                    continue;
                end
                buttons(kk) = uibutton(parentPanel, ...
                    "Text", registry(kk).Name, ...
                    "Position", [PANEL_PAD, yCursor, BUTTON_WIDTH, ROW_HEIGHT], ...
                    "ButtonPushedFcn", makeAlgorithmCallback(kk));
                yCursor = yCursor + ROW_HEIGHT + ROW_GAP;
            end
        end
    end

    % ---------------- 参数区 ----------------

    function buildParamControls()
        % 切换算法时销毁旧控件、按新算法的参数定义重建。
        % 「执行」按钮每次也重建，refreshEnableState 里重新读它的句柄。
        delete(paramPanel.Children);

        if selectedIdx == 0
            params      = {};
            placeholder = "请在左侧选择一个算法";
        else
            params      = registry(selectedIdx).Params;
            placeholder = "该算法无可调参数";
        end

        % 无参数时要放「占位标签 + 执行按钮」两个控件，所以至少 2 行
        numParams = numel(params);
        numRows   = max(numParams, 1) + 1;

        paramGrid = uigridlayout(paramPanel, [numRows 1], ...
            "RowHeight",  repmat({"fit"}, 1, numRows), ...
            "Padding",    PANEL_PAD * ones(1, 4), ...
            "RowSpacing", 4);

        paramGetters = cell(numParams, 1);
        for kk = 1:numParams
            paramGetters{kk} = buildParamRow(paramGrid, kk, params{kk});
        end
        if numParams == 0
            uilabel(paramGrid, "Text", placeholder);
        end

        executeButton = uibutton(paramGrid, "Text", "执行", ...
            "ButtonPushedFcn", @onExecute);
    end

    function getter = buildParamRow(parentGrid, rowIdx, p)
        % 一行参数，三列：名称 | 控件 | （滑块的）数值框
        rowGrid = uigridlayout(parentGrid, [1 3], ...
            "ColumnWidth", {90, "1x", 80}, ...
            "Padding",     [0 0 0 0]);
        rowGrid.Layout.Row = rowIdx;

        uilabel(rowGrid, "Text", p.Name);

        switch p.Kind
            case "slider"
                sld = uislider(rowGrid, "Limits", [p.Min, p.Max], ...
                    "Value", p.Default);
                edt = uieditfield(rowGrid, "numeric", ...
                    "Limits", [p.Min, p.Max], "Value", p.Default);
                % 实测程序化赋值不会再触发 ValueChangedFcn，双向同步不会死循环
                sld.ValueChangedFcn = makeCopyTo(sld, edt);
                edt.ValueChangedFcn = makeCopyTo(edt, sld);
                getter = makeGetter(sld);

            case "edit"
                edt = uieditfield(rowGrid, "numeric", ...
                    "Limits", [p.Min, p.Max], "Value", p.Default);
                edt.Layout.Column = [2 3];
                getter = makeGetter(edt);

            case "choice"
                ddn = uidropdown(rowGrid, "Items", p.Options, "Value", p.Default);
                ddn.Layout.Column = [2 3];
                getter = makeGetter(ddn);

            case "size"
                edtRow = uieditfield(rowGrid, "numeric", ...
                    "Limits", [p.Min, p.Max], "Value", p.Default(1));
                edtCol = uieditfield(rowGrid, "numeric", ...
                    "Limits", [p.Min, p.Max], "Value", p.Default(2));
                getter = makeSizeGetter(edtRow, edtCol);

            otherwise
                error("matlab_test:badParamKind", ...
                    "参数 %s 的 Kind 是 %s，只支持 slider / edit / choice / size。" + ...
                    "请改 imgRegistry.m 里该参数的定义。", p.Name, p.Kind);
        end
    end
end

% ==================== 局部函数 ====================
% 不碰界面状态，所以放在父函数外面

function showImage(ax, I, labelText)
%SHOWIMAGE 在指定坐标区显示图像并统一外观
%
%   输入
%       ax          目标 uiaxes
%       I           图像矩阵
%       labelText   标题文字
%   输出
%       无（就地改写 ax）
%
%   调用示例
%       showImage(axResult, result, "结果");

imshow(I, "Parent", ax);
title(ax, labelText);
ax.XTick = [];
ax.YTick = [];
end

function getter = makeGetter(control)
%MAKEGETTER 返回一个读该控件 Value 的函数句柄
%
%   必须写成工厂函数。直接在循环里写 @() sld.Value，所有句柄会共享循环变量
%   sld 最终的值，取哪个控件的值都变成最后一个。实测过：工厂函数传参进去，
%   每个句柄才各捕获各的。
%
%   输入
%       control     任意有 Value 属性的控件（uislider / uieditfield / uidropdown）
%   输出
%       getter      无参函数句柄，调用返回该控件当前的 Value
%
%   调用示例
%       getter = makeGetter(edt);
%       v = getter();

getter = @() control.Value;
end

function getter = makeSizeGetter(edtRow, edtCol)
%MAKESIZEGETTER 返回一个把两个数值框读成 [行, 列] 的函数句柄
%
%   输入
%       edtRow      行分量数值框
%       edtCol      列分量数值框
%   输出
%       getter      无参函数句柄，调用返回 [行, 列] 二元素数组
%
%   调用示例
%       getter = makeSizeGetter(edtRow, edtCol);
%       targetSize = getter();

getter = @() [edtRow.Value, edtCol.Value];
end

function fh = makeCopyTo(source, target)
%MAKECOPYTO 返回一个把 source 的 Value 抄给 target 的回调
%
%   匿名函数里不能写赋值语句，所以抄值这一步要交给 assignValue。
%
%   输入
%       source      取值来源控件
%       target      被写入的控件
%   输出
%       fh          两参数回调句柄，可直接赋给 ValueChangedFcn
%
%   调用示例
%       sld.ValueChangedFcn = makeCopyTo(sld, edt);

fh = @(~, ~) assignValue(target, source.Value);
end

function assignValue(control, newValue)
%ASSIGNVALUE 把新值写进控件
%
%   单独拆出来是因为匿名函数里不能写赋值语句。
%
%   输入
%       control     目标控件
%       newValue    新值
%   输出
%       无（就地改写 control.Value）
%
%   调用示例
%       assignValue(edt, 0.5);

control.Value = newValue;
end

function value = onOff(isOn)
%ONOFF 把 logical 转成控件 Enable 属性要的 "on" / "off"
%
%   输入
%       isOn        logical 标量
%   输出
%       value       "on" 或 "off"
%
%   调用示例
%       button.Enable = onOff(hasImage && isImplemented);

if isOn
    value = "on";
else
    value = "off";
end
end
```

- [ ] **Step 2: 写 verifyPlatformGui.m 界面冒烟测试**

界面回调没法自动点，但**界面结构可以**。这个脚本程序化构造界面、清点控件、
断言初始灰显状态，然后关掉窗口。它能替子代理把守「界面搭对了没有」这道门，
剩下真正需要人眼的（图像显示效果、滑块手感）才留给人工清单。

创建 `hw04-imageGeometry/platform/verifyPlatformGui.m`：

```matlab
% 冒烟测试 imgPlatform.m 的界面结构
%
% 运行：在编辑器里点运行，或
%   matlab -batch "run('<仓库根>/hw04-imageGeometry/platform/verifyPlatformGui.m')"
% 退出码 0 表示界面结构符合预期。
%
% 预期结果：程序化构造界面，按控件文字与 Enable 状态断言结构，然后关闭窗口。
%          命令窗口逐行打印检查项、期望值与实测值，全部通过时打印「全部通过」。
%
% 覆盖不到的部分：界面长得好不好看、图像显示效果、拖动滑块的手感、
% 报错弹窗的内容 —— 这些要人眼看，见 notes.md 的运行时操作清单。
%
% 为什么不并进 verifyPlatform.m：那个只验登记表、不开界面。两者的失败模式
% 不同（界面搭错了 vs 表填错了），分开更好定位。

clear; clc; close all;

FIG_NAME_KEYWORD = "图像处理实验平台";
% 顶栏与参数区的三个非算法按钮，其余 uibutton 都应当是算法按钮
CONTROL_BUTTONS  = ["打开图像", "保存结果", "执行"];

registry      = imgRegistry();
expectedNames = string({registry.Name});

failureCount = 0;

% ---------- 构造界面 ----------
imgPlatform();
drawnow;

% 按窗口标题找我们开的那个窗口。用 findall(groot) 而不是 gcf：
% -batch 下若有残留窗口，gcf 拿到的不一定是这一个
allFigures = findall(groot, "Type", "figure");
isOurs     = contains(string({allFigures.Name}), FIG_NAME_KEYWORD);
failureCount = failureCount + checkEq("标题含关键字的窗口数", nnz(isOurs), 1);

if nnz(isOurs) ~= 1
    error("matlab_test:guiSmokeFailed", ...
        "imgPlatform() 应当开出恰好 1 个标题含「%s」的窗口，实测 %d 个。" + ...
        "请检查 imgPlatform.m 里的 uifigure 调用。", FIG_NAME_KEYWORD, nnz(isOurs));
end
fig = allFigures(find(isOurs, 1));

% ---------- 控件清点 ----------
% findall 能穿进可滚动面板，深度到第 4 层为止。下面的断言都取第 3~4 层的按钮。
% 参数行里的标签在第 5 层，findall 够不着，所以不在这里断言 —— 见文件头说明。
buttons    = findall(fig, "Type", "uibutton");
buttonText = string({buttons.Text});

algorithmNames = setdiff(buttonText, CONTROL_BUTTONS);
failureCount = failureCount + checkEq("算法按钮数", numel(algorithmNames), numel(registry));
failureCount = failureCount + checkEq("算法按钮名与登记表一致", ...
    isempty(setxor(algorithmNames, expectedNames)), true);

% 「执行」按钮由 buildParamControls 创建。总数对不上说明它没跑或跑挂了
failureCount = failureCount + checkEq("按钮总数（含执行按钮）", ...
    numel(buttons), numel(registry) + numel(CONTROL_BUTTONS));

% ---------- 初始灰显状态 ----------
% 还没载入图像，所以 16 个算法按钮全灰，「执行」「保存结果」也灰，
% 「打开图像」可点。这是 refreshEnableState 的核心行为。
algorithmButtons  = buttons(ismember(buttonText, expectedNames));
nAlgorithmEnabled = nnz(string({algorithmButtons.Enable}) == "on");
failureCount = failureCount + checkEq("未载图时算法按钮可点数", nAlgorithmEnabled, 0);

isEnabled = @(label) string(buttons(buttonText == label).Enable) == "on";
failureCount = failureCount + checkEq("未载图时「打开图像」可点", isEnabled("打开图像"), true);
failureCount = failureCount + checkEq("未载图时「执行」灰",       isEnabled("执行"),     false);
failureCount = failureCount + checkEq("未载图时「保存结果」灰",   isEnabled("保存结果"), false);

% ---------- 字色只反映「实现了没有」，与有没有载图无关 ----------
% 刚打开界面时一张图都没有，已实现的那几个算法仍应是黑字，否则用户看不出
% 哪几个能用。最初把 FontColor 和 Enable 绑在同一个条件上，就是这个毛病，
% 而只断言 Enable 的检查抓不到它 —— 所以这条要单独测。
isImplemented = false(numel(registry), 1);
for kk = 1:numel(registry)
    isImplemented(kk) = ~isempty(which(registry(kk).Fcn));
end

nBlackText = nnz(arrayfun(@(btn) isequal(btn.FontColor, [0 0 0]), algorithmButtons));
failureCount = failureCount + checkEq("未载图时黑字按钮数（应等于已实现数）", ...
    nBlackText, nnz(isImplemented));

close(fig);

% ---------- 汇总 ----------
if failureCount > 0
    error("matlab_test:guiSmokeFailed", ...
        "共 %d 项检查未通过，逐条明细见上方标了 false 的行。", failureCount);
end

fprintf("\n全部通过\n");

% ==================== 局部函数 ====================

function nFail = checkEq(label, actual, expected)
%CHECKEQ 打印一项检查并判定是否与期望相等，返回未通过条数（0 或 1）
%
%   与 verifyPlatform.m 里的同名函数职责相同，各自独立 —— MATLAB 的
%   局部函数不跨文件共享。两处各十余行，暂不提升为公共函数。
%
%   输入
%       label       检查项名称
%       actual      实测值
%       expected    期望值
%   输出
%       nFail       未通过条数，0 或 1
%
%   调用示例
%       failureCount = failureCount + checkEq("算法按钮数", numel(algorithmNames), 16);

isPass = isequal(actual, expected);

fprintf("%-28s 期望 %-10s 实测 %-10s %s\n", ...
    label, string(expected), string(actual), string(isPass));

if ~isPass
    fprintf("    ^ 未通过: %s 应为 %s，实测 %s\n", ...
        label, string(expected), string(actual));
end

nFail = ~isPass;
end
```

- [ ] **Step 3: 跑冒烟测试**

用 MATLAB MCP 的 `run_matlab_file` 跑 `verifyPlatformGui.m`，或命令行：

```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "run('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform/verifyPlatformGui.m')"
```

Expected:
```
标题含关键字的窗口数          期望 1          实测 1          true
算法按钮数                    期望 16         实测 16         true
算法按钮名与登记表一致        期望 true       实测 true       true
按钮总数（含执行按钮）        期望 19         实测 19         true
未载图时算法按钮可点数        期望 0          实测 0          true
未载图时「打开图像」可点      期望 true       实测 true       true
未载图时「执行」灰            期望 false      实测 false      true
未载图时「保存结果」灰        期望 false      实测 false      true
未载图时黑字按钮数（应等于已实现数） 期望 4    实测 4          true

全部通过
```

退出码 0。若「算法按钮数」不是 16，查 `buildAlgorithmList` 的双层循环有没有
漏掉类别；若「未载图时算法按钮可点数」不是 0，查 `refreshEnableState` 里
`hasImage && isImplemented` 的两个条件是不是写成了 `||`。

- [ ] **Step 4: 静态检查**

用 MATLAB MCP 的 `check_matlab_code` 检查
`hw04-imageGeometry/platform/imgPlatform.m`。

Expected: 没有报错级问题。若提示 `paramGetters`、`executeButton` 等变量
「似乎未使用」或「可能未定义」，那是嵌套函数共享变量的正常提示，可忽略；
但若提示 `end` 不匹配，说明嵌套函数与局部函数的分界写错了 ——
嵌套函数必须在 `imgPlatform` 的 `end` **之前**，局部函数在**之后**。

- [ ] **Step 5（人工）: 打开界面看视觉部分**

前面两步都是子代理能自动跑的。这一步开始要人眼。用 MATLAB MCP 的
`evaluate_matlab_code` 跑：

```matlab
cd('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform');
imgPlatform();
```

界面应在 MATLAB 桌面弹出。结构性问题冒烟测试已经管了，这里只看**冒烟测试
够不着的**：

| # | 该看到什么 |
|---|---|
| 1 | 窗口标题含「图像处理实验平台  Plot by 顾皓天0242010213」 |
| 2 | 左栏 8 个类别从上到下依次是：灰度变换、阈值分割、几何变换、直方图均衡、空域滤波、频域滤波、边缘检测、特征提取 |
| 3 | 未实现的 12 个按钮是**灰字**，已实现的 4 个是**黑字**（但都还点不动 —— 因为还没载图） |
| 4 | 左栏放不下时能滚动 |
| 5 | 参数区显示「请在左侧选择一个算法」，下面有个灰的「执行」按钮 |

第 3 条容易搞错 ——「未实现」和「没有图像」是两回事，`refreshEnableState`
里两个条件都满足按钮才可点，此刻是「已实现但没图」，所以黑字但不可点。

- [ ] **Step 6（人工）: 核对打开图像的行为**

在界面上点「打开图像」，选 `hw04-imageGeometry/photo.jpg`（彩色 5712×4284）。

Expected:
- 左侧「原图」坐标区显示灰度照片，标题「原图」
- 顶栏状态栏显示 `photo.jpg   4284×5712   uint8   已自动转灰度`
- 4 个已实现算法的按钮**从灰变黑、可点**
- 其余 12 个仍然灰

再点一次「打开图像」，选上一级目录的 `hw04-imageGeometry/process0.jpg`
（那是个彩色 JPEG 图形文件）确认换图正常：原图区换成新图、结果区被清空、
信息行回到「尚未执行」。

- [ ] **Step 7（人工）: 核对参数调节与执行**

**点一下「伽马变换」**，核对：
- 参数区出现 `gamma` 一行，滑块在 0.05–3 之间、当前值 0.50，右侧数值框也是 0.50
- 拖动滑块，数值框跟着变；在数值框里输入 1.5 回车，滑块跟着跳到 1.5
- 点「执行」后，右侧「结果」区出现提亮后的图，信息行显示
  `尺寸 4284×5712   类型 uint8   耗时 0.xxx s`（实测约 0.10 s）

拖动滑块与输入数值框**两个方向都要试** —— 走的是不同的回调，只试一个会漏掉另一个。

再点「Otsu」（它没有入参），参数区应显示「该算法无可调参数」，执行后结果区
是二值图，信息行的类型是 `logical`，**并且末尾多出一段 `阈值 0.5255`**。

Otsu 与迭代法都返回 `[BW, level]` 两个值，登记表里用 `ExtraLabel` 标了第二个
返回值叫什么，界面按需取两个输出并显示。实测这张照片上 Otsu 的阈值是 0.5255、
迭代法是 0.5278 —— 两个算法在真实照片上给出的阈值很接近，这也是它们都合理的
一个旁证。再点「迭代法」确认它的信息行末尾是 `阈值 0.5278`。

- [ ] **Step 8（人工）: 核对算法报错会弹窗，而不是静默失败**

点「线性拉伸」，它的两个参数 `lowIn` / `highIn` 滑杆范围都是 0–255，
把 `lowIn` 拖到 200、`highIn` 拖到 100（即低界高于高界），点「执行」。

Expected: 弹出消息框，标题「算法执行失败」，正文含
`highIn(100) 必须大于 lowIn(200)，否则拉伸区间为空。`

这条走的是 `onExecute` 里的 `catch` 分支 —— 算法自己 `error` 抛出的信息要
被 `uialert` 原样显示出来，不能吞掉。结果区应保持上一次的内容不变。

把 `lowIn` 拖回 30 再执行一次，应正常出结果。

- [ ] **Step 9（人工）: 核对保存结果**

点「保存结果」，确认弹出的对话框里文件类型下拉有 BMP / JPEG / PNG / TIFF / GIF
五种格式，存成 PNG 后状态栏显示保存路径，且磁盘上确实多出了这个文件。
再存一次 JPG 确认换格式也正常。

- [ ] **Step 10: 提交**

提交前确认 Step 3 的冒烟测试退出码 0、Step 4 的静态检查无报错级问题。
人工核对（Step 5~9）若有不过的，先修再提交。

```bash
git add hw04-imageGeometry/platform/imgPlatform.m hw04-imageGeometry/platform/verifyPlatformGui.m
git commit -m "feat: 图像处理平台可视化界面，算法列表按登记表生成并灰显未实现项，附界面冒烟测试"
```

---

## Task 3: 文档收尾与运行时操作清单

**Files:**
- Modify: `hw04-imageGeometry/platform/README.md`（整文件替换）
- Modify: `hw04-imageGeometry/notes.md`（末尾追加一节）

**Interfaces:**
- Consumes: Task 1、Task 2 的全部产物
- Produces: 无新代码接口

- [ ] **Step 1: 重写 README.md**

**必须改**：现在的 README 写着「8 类共 16 个手写算法实现」，但实际只实现了 4 个。
这是设计文档的措辞被提前抄进了 README，交付前必须和实际对上。

把 `hw04-imageGeometry/platform/README.md` 整个替换为：

```markdown
# 图像处理实验平台

作业四「提高要求」的实体，分两部分：

- **可视化界面** `imgPlatform.m` —— 打开图像、选算法、调参数、并排看结果。
- **算法库** `+img/` —— 手写图像处理算法，各配 MATLAB 图像处理工具箱对照基准。

## 运行

**打开实验平台界面**：在编辑器里打开 `imgPlatform.m` 点运行。

**三支验证脚本**，都在仓库根目录（`matlab_test/`）下执行，退出码 0 表示通过：

    matlab -batch "run('hw04-imageGeometry/platform/verifyAlgorithms.m')"
    matlab -batch "run('hw04-imageGeometry/platform/verifyPlatform.m')"
    matlab -batch "run('hw04-imageGeometry/platform/verifyPlatformGui.m')"

写的是相对路径，所以**要在仓库根目录执行**。换到别处跑就把 `run(...)` 里
换成脚本的绝对路径。三者各管一段：

| 脚本 | 管什么 |
|---|---|
| `verifyAlgorithms.m` | 手写算法与图像处理工具箱的输出是否一致 |
| `verifyPlatform.m` | 算法登记表是否自洽（不开界面） |
| `verifyPlatformGui.m` | 界面结构是否正确（会开界面再关掉） |

界面上需要人眼判断的部分（图像显示效果、拖动滑块的手感、报错弹窗内容）
三支脚本都覆盖不到，见 `notes.md` 的运行时操作清单。

## 依赖

- MATLAB R2025b
- Image Processing Toolbox 25.2
- Computer Vision Toolbox 25.2（特征提取部分需要）

## 目录

    imgPlatform.m        可视化界面入口
    imgRegistry.m        算法登记表，8 类 16 个算法的元数据
    verifyAlgorithms.m   验证手写算法与工具箱的一致性
    verifyPlatform.m     检查登记表自洽
    verifyPlatformGui.m  界面结构冒烟测试
    +img/                手写算法实现，调用写成 img.函数名(...)

## 算法清单

| 类别 | 实现 1 | 实现 2 | 工具箱对照 | 状态 |
|---|---|---|---|---|
| 灰度变换 | `grayLinearStretch` 线性拉伸 | `grayGamma` 幂律变换 | `imadjust` | **已实现** |
| 阈值分割 | `threshOtsu` | `threshIterative` 迭代法 | `otsuthresh` | **已实现** |
| 几何变换 | `geomRotate` 逆映射旋转 | `geomScale` 双线性缩放 | `imrotate` / `imresize` | 待实现 |
| 直方图均衡 | `histEqualize` 全局 CDF | `histClahe` 分块自适应 | `histeq` / `adapthisteq` | 待实现 |
| 空域滤波 | `filterMean` 均值 | `filterMedian` 中值 | `imfilter` / `medfilt2` | 待实现 |
| 频域滤波 | `freqIdealLP` 理想低通 | `freqButterLP` 巴特沃斯低通 | 无直接对照，用性质验证 | 待实现 |
| 边缘检测 | `edgeSobel` | `edgePrewitt` | `edge` / `imgradient` | 待实现 |
| 特征提取 | `featHOG` | `featLBP` | `extractHOGFeatures` / `extractLBPFeatures` | 待实现 |

「待实现」的算法在界面上按登记表列出，但按钮置灰点不动。补上 `+img/` 里的
实现后界面会自动点亮 —— 「实现了没有」是 `imgRegistry.m` 用 `which`
现场探测的，不写死在表里，登记表与界面代码都不用改。

## 界面操作

见同目录 `notes.md` 的「三、平台界面」一节。
```

- [ ] **Step 2: 从仓库根目录跑一次三支脚本，确认 README 里的命令是对的**

README 里改成了「从仓库根目录执行相对路径」，这一步就**照 README 的原样**验证一遍：

```bash
cd /Users/charliepan/Downloads/matlab_test && \
/Applications/MATLAB_R2025b.app/bin/matlab -batch "run('hw04-imageGeometry/platform/verifyAlgorithms.m')" && \
/Applications/MATLAB_R2025b.app/bin/matlab -batch "run('hw04-imageGeometry/platform/verifyPlatform.m')" && \
/Applications/MATLAB_R2025b.app/bin/matlab -batch "run('hw04-imageGeometry/platform/verifyPlatformGui.m')" && \
echo "三支脚本退出码全为 0"
```

Expected: 三支都打印「全部通过」，最后 echo 出「三支脚本退出码全为 0」。

这一步是在还上一轮遗留的账：旧的 README 写的是同样的相对路径，但实际验证时
一直是从 `/tmp` 用绝对路径跑的，命令照着抄会失败。现在两者对齐了。

- [ ] **Step 3: 在 notes.md 末尾追加「平台界面」一节**

在 `hw04-imageGeometry/notes.md` 末尾追加：

```markdown
## 三、平台界面

提高要求第 2 条要求「设计功能完善的图像处理实验平台，实现图像管理、算法操作、
参数调节、结果展示」。界面在 `platform/imgPlatform.m`，在编辑器里点运行即开。

### 1. 界面构成

单窗口，`uigridlayout` 分两栏。左栏是可滚动的算法列表，按 8 个类别列出 16 个
算法；右栏上方是原图与结果并排两个 `uiaxes`，中间是参数区，下方一行结果信息。
顶栏放「打开图像」「保存结果」与状态栏。窗口标题带学号署名。

**用程序化 `uifigure` 而不是 App Designer 的 `.mlapp`。** `.mlapp` 入库后是个
二进制 Zip 包，改一个控件位置整个文件重写，git 无法 diff、冲突无法合并。
作业原文写「可视化交互界面可选用 MATLAB App Designer 或 GUI 设计」，
程序化 GUI 属于后者，合规。

### 2. 登记表驱动

界面不硬编码任何算法知识，全部来自 `imgRegistry.m` 的 16 条登记项：
类别、显示名、包函数名、参数定义、输出类型。

**「某个算法实现了没有」不写死在表里，用 `which(Fcn)` 现场探测。** 这条是实测
逼出来的：`exist("img.grayGamma")` 对一个明明存在的包函数**返回 0**，
`exist(..., "file")` 也是 0，只有 `which` 返回路径、不存在时返回空串。
另外 `str2func("img.featHOG")` 对不存在的函数也**会成功**返回句柄，
所以它也不能用来探测（但可以放心用来派发）。

好处是以后补上 `+img/featHOG.m`，界面按钮自动从灰变黑，`imgRegistry.m` 与
`imgPlatform.m` 都不用改。

### 3. 两个被实测推翻的做法

**没用 `uitree`。** 树控件看起来最适合列算法，但实测 `uitreenode` 的属性表里
**根本没有 `Enable`**（只有 `Text` / `NodeData` / `Children` / `Icon` 等），
只有整棵树有 `Enable`。也就是说树做不到逐节点灰显，只能要么全亮要么全灰。
改用「类别标签 + 按钮」的绝对定位布局，每个按钮单独置灰。

**滚动面板里的子控件用绝对定位，不用 `uigridlayout`。** 实测在
`Scrollable="on"` 的 `uipanel` 里放一个 24 行的 `uigridlayout`，
内层 grid 不会按内容撑高，停在默认的 100×100，滚动因此不生效。
改用绝对定位后，内容总高 552 px 超过面板高度，滚动正常。

### 4. 双向同步与闭包

参数区里滑块与数值框双向同步。两个前提都实测确认过：

- 程序化赋 `uislider.Value` **不会**再触发 `ValueChangedFcn`，
  所以互相赋值不会死循环；
- 读控件值的 getter 与同步回调都用**工厂函数**造，把控件句柄作为参数传进去。
  直接在 `for` 循环里写 `@() sld.Value`，所有句柄会共享循环变量最终的值，
  取哪个参数的值都变成最后一个。实测工厂函数写法下三个 getter 分别返回
  10 / 20 / 30，直接闭包则全返回 30。

### 5. 运行时操作清单

在编辑器里打开 `platform/imgPlatform.m` 点运行，然后：

1. **看初始状态。** 左栏 8 个类别 16 个算法：灰度变换与阈值分割下的 4 个是黑字，
   其余 6 类 12 个是灰字且点不动。参数区显示「请在左侧选择一个算法」，
   「执行」与「保存结果」都是灰的。
2. **打开图像。** 点「打开图像」选 `hw04-imageGeometry/photo.jpg`。
   原图区显示灰度照片，状态栏出现 `photo.jpg   4284×5712   uint8   已自动转灰度`，
   4 个已实现算法的按钮从灰变黑。
   照片是彩色的，而 `+img/` 里的算法开头都有 `~ismatrix(I)` 检查、彩色图会直接
   报错，所以界面统一先 `rgb2gray` 并在状态栏标注。
3. **选算法。** 点「伽马变换」，参数区出现 `gamma` 一行：滑块范围 0.05–3，
   当前值 0.50，右边数值框同步显示 0.50。
4. **调参数。** 拖滑块，数值框跟着变；反过来在数值框输入 1.5 回车，滑块跟着跳。
5. **执行。** 点「执行」，结果区出现提亮后的图，信息行显示尺寸、类型与耗时
   （实测约 0.10 s）。
6. **换个算法。** 点「Otsu」，参数区变成「该算法无可调参数」（它没有入参），
   执行后得到二值图，信息行里类型是 `logical`，末尾还有一段 `阈值 0.5255`。
   换个「迭代法」再跑，末尾应是 `阈值 0.5278` —— 两个算法在这张照片上给出的
   阈值很接近，互相印证。
7. **看报错会不会被吞。** 点「线性拉伸」，把 `lowIn` 拖到 200、`highIn` 拖到 100
   （低界高于高界），点「执行」。应弹出消息框，正文含
   `highIn(100) 必须大于 lowIn(200)，否则拉伸区间为空。` ——
   这是算法自己 `error` 抛的，界面只负责原样显示，不能吞掉。
   把 `lowIn` 拖回 30 再执行一次即恢复正常。
8. **保存结果。** 点「保存结果」，对话框的文件类型下拉里有 BMP / JPEG / PNG /
   TIFF / GIF 五种格式，存成 PNG 后状态栏显示保存路径。

### 6. 三支验证脚本各管一段

| 脚本 | 管什么 | 怎么跑 |
|---|---|---|
| `verifyAlgorithms.m` | 手写算法与工具箱的输出是否一致 | 自动，退出码 0 |
| `verifyPlatform.m` | 登记表是否自洽：8 类 × 2 无缺漏、`Fcn` 前缀、参数默认值不越界、`Kind` 与 `Output` 取值合法 | 自动，退出码 0 |
| `verifyPlatformGui.m` | 界面结构：窗口数、16 个算法按钮与登记表名称一致、未载图时全部置灰 | 自动，退出码 0 |

`verifyPlatformGui.m` 是程序化构造界面再清点控件的冒烟测试，所以界面「搭得对不对」
也有自动门禁，不是全靠人看。它靠 `findall` 找控件 —— 实测 `findall` 能穿进可滚动
面板，但**只到第 4 层**，参数行里的标签在第 5 层够不着，所以断言只覆盖按钮层。

剩下真正要人眼的部分（图像显示效果、拖动滑块的手感、报错弹窗内容、
保存对话框的格式列表）靠上面第 5 节那份清单过一遍。
```

- [ ] **Step 4: 提交**

```bash
git add hw04-imageGeometry/platform/README.md hw04-imageGeometry/notes.md
git commit -m "docs: 平台 README 与界面运行清单，修正算法数量与实际不符的描述"
```

---

## 计划的验收标准

对照 spec 的验收标准：

1. 点运行 `imgPlatform.m` 能开出界面，不报错 → Task 2 Step 3（自动）、Step 5（人工）
2. 打开彩色照片自动转灰度并标注 → Task 2 Step 6（人工）
3. 4 个已实现算法都能选中、跑到结果、显示耗时与尺寸 → Task 2 Step 7（人工）
4. 6 类未实现算法的按钮为灰、点不动 → Task 2 Step 3（自动断言初始状态）、
   Step 5（人工看灰字）
5. 保存结果弹出含 5 种格式的对话框并成功写文件 → Task 2 Step 9（人工）、
   notes.md 运行时操作清单第 8 条
6. `verifyPlatform.m` 退出码 0 → Task 1 Step 4、Task 3 Step 2
7. 每个函数有 H1 行 + 功能说明 + 输入输出 + 一个调用示例 → 四个新文件的注释
8. 跑通即按 `git.md` 的粒度提交 → 每个 Task 的最后一步

## 已知限制

- **未实现算法的参数定义未经真实运行检验。** 6 类待实现算法的参数
  （`angle`、`targetSize`、`numTiles`、`kernelSize`、`numBins` 等）是从
  上游 spec 的函数签名抄的，界面渲染不到它们，所以没有跑过。将来点亮这些类别时，
  参数的范围与控件类型可能要微调 —— 比如 `kernelSize` 要求奇数、
  `numLevels` 要求整数，而滑块给的是连续值，用户拖到偶数会被算法自己的
  `error` 拦下并弹出提示，不会静默出错。这是有意为之：不为暂时够不着的路径
  提前加约束机制。
- **`imshow` 大图首次渲染的耗时未实测。** 算法本身只要 0.1 s，但把
  4284×5712 送进 `uiaxes` 的时间没有单独测过。若实际卡顿明显，
  退回「显示前先 `imresize` 到千像素级、算法仍跑全图」即可，
  只影响显示不影响结果。
- **`checkEq` / `reportRow` 这类判定函数在每个验证脚本里各写一份。**
  `verifyAlgorithms.m` 有 `reportRow`，`verifyPlatform.m` 与
  `verifyPlatformGui.m` 各有一个 `checkEq`，三处职责相近。
  MATLAB 的局部函数不跨文件共享，真要合并得提升为同目录的独立函数，
  并改动已跑通的 `verifyAlgorithms.m`。三处各约 15 行，
  暂不合并，避免动到已验证的代码。
