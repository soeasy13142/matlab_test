# 图像处理实验平台（A 算法库 + B 正确性验证）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 `hw04-imageGeometry/platform/` 下实现 8 类共 16 个手写图像处理算法，并写一个自动验证脚本，逐个与 MATLAB 图像处理工具箱对照，不达标的项全部跑完后统一汇总并以非零退出码结束。

**Architecture:** 算法放包目录 `+img/`，调用写成 `img.geomRotate(...)`，不写 `addpath`（实测包目录在 cwd 或 path 含其父目录时可解析）。`verifyAlgorithms.m` 是唯一的验证入口，用局部函数 `reportRow` 统一打印与判定：它不抛错，失败只打印明细并返回 `isPass`，由各验证函数累加条数，脚本跑完全部算法后在末尾统一报错。阈值常量声明在各 `verifyXxx` 局部函数开头——脚本的局部函数有独立工作区，读不到脚本体变量，所以做不到「顶部集中定义」。

**Tech Stack:** MATLAB R2025b，Image Processing Toolbox 25.2、Computer Vision Toolbox 25.2（均本机已装）。

## Global Constraints

- **不写 `addpath`，不写 `savepath`**。包目录 `+img/` 直接放在 `platform/` 下，靠 cwd 解析。
- **不写 `arguments` 块**（本项目 2026-09-11 起已废除），入参校验用 `narginchk` + 手动 `error`。
- **索引从 1 开始**；循环变量用 `ii`、`jj`、`kk`，不用 `i`、`j`。
- **循环前预分配**：`zeros` / `ones` / `cell` / `struct`。
- **浮点比较用容差**：`abs(a - b) < tol`，容差在文件顶部定义成 `UPPER_SNAKE_CASE` 常量。
- **赋值和非输出语句以 `;` 结尾**；文本用双引号 `"..."`，不用单引号。
- **路径用 `fullfile` 拼**，不硬编码 `/`。
- **函数头写 H1 行 + 功能说明 + 输入输出 + 一个调用示例**。
- **报错写清「问题 + 怎么修」**：`error("matlab_test:badInput", "...")`。
- **函数内部禁止 `clear` / `clc` / `close all`**，这三个只在脚本里用。
- **脚本是普通 `.m`**，不写 `%[text]` 等 Live Code 标记，不用 `%%` 分节。
- **commit message 格式** `<类型>: <中文描述>`，类型用 `feat` / `fix` / `refactor` / `docs` / `wip` / `chore`。
- **提交前必须跑通**（MATLAB 退出码 0），跑不通用 `wip:` 前缀。

---

## File Structure

本轮创建的文件，每个文件的职责：

| 文件 | 职责 |
|---|---|
| `hw04-imageGeometry/platform/README.md` | 平台说明、运行方式、依赖的工具箱与版本 |
| `hw04-imageGeometry/platform/verifyAlgorithms.m` | 唯一验证入口：载入测试图、逐类调用算法、打印对照表、判定并汇总未通过项 |
| `hw04-imageGeometry/platform/+img/threshOtsu.m` | Otsu 全局阈值分割 |
| `hw04-imageGeometry/platform/+img/threshIterative.m` | 迭代法阈值分割 |
| `hw04-imageGeometry/platform/+img/grayLinearStretch.m` | 线性灰度拉伸 |
| `hw04-imageGeometry/platform/+img/grayGamma.m` | 幂律（伽马）灰度变换 |
| `hw04-imageGeometry/platform/+img/histEqualize.m` | 全局直方图均衡 |
| `hw04-imageGeometry/platform/+img/histClahe.m` | 分块自适应直方图均衡（CLAHE） |
| `hw04-imageGeometry/platform/+img/filterMean.m` | 均值滤波 |
| `hw04-imageGeometry/platform/+img/filterMedian.m` | 中值滤波 |
| `hw04-imageGeometry/platform/+img/geomRotate.m` | 逆映射旋转 |
| `hw04-imageGeometry/platform/+img/geomScale.m` | 双线性缩放 |
| `hw04-imageGeometry/platform/+img/freqIdealLP.m` | 理想低通频域滤波 |
| `hw04-imageGeometry/platform/+img/freqButterLP.m` | 巴特沃斯低通频域滤波 |
| `hw04-imageGeometry/platform/+img/edgeSobel.m` | Sobel 边缘检测 |
| `hw04-imageGeometry/platform/+img/edgePrewitt.m` | Prewitt 边缘检测 |
| `hw04-imageGeometry/platform/+img/featHOG.m` | HOG 特征提取 |
| `hw04-imageGeometry/platform/+img/featLBP.m` | LBP 特征提取 |

`+imgio/`（格式兼容）属子项目 C，本轮不建。

`verifyAlgorithms.m` 每完成一个任务追加一个类别的验证块，任务之间只增不改已有部分。

---

## Task 1: 平台骨架 + 验证框架 + 阈值分割类

建立整个模式：函数怎么写、验证怎么写、失败怎么汇总报错。后续 7 个任务都照这个模子复制。

**Files:**
- Create: `hw04-imageGeometry/platform/README.md`
- Create: `hw04-imageGeometry/platform/+img/threshOtsu.m`
- Create: `hw04-imageGeometry/platform/+img/threshIterative.m`
- Create: `hw04-imageGeometry/platform/verifyAlgorithms.m`

**Interfaces:**
- Consumes: 无（本任务是起点）
- Produces:
  - `[BW, level] = img.threshOtsu(I)` — `I` 灰度图矩阵，`BW` logical 二值图，`level` 归一化阈值 `[0,1]`
  - `[BW, level] = img.threshIterative(I, tol)` — `tol` 迭代收敛容差，默认 `1e-6`
  - 局部函数 `isPass = reportRow(category, algorithm, metricName, value, threshold, unit, direction)` — 打印一行并判定是否达标，**不抛错**。`direction` 取 `"max"`（越大越好，默认）或 `"min"`（越小越好）
  - 局部函数 `nFail = verifyThresholding(images)` — 返回本函数记录的失败条数，供脚本累加
  - 脚本体在末尾按 `failureCount` 统一 `error`，退出码非零

- [ ] **Step 1: 建目录与 README**

```bash
mkdir -p hw04-imageGeometry/platform/+img
```

写 `hw04-imageGeometry/platform/README.md`：

```markdown
# 图像处理实验平台

作业四「提高要求」的实体，8 类共 16 个手写算法实现，各配 MATLAB 图像处理工具箱
对照基准。

## 运行

验证算法正确性，在编辑器里打开 `verifyAlgorithms.m` 点运行：

    matlab -batch "run('hw04-imageGeometry/platform/verifyAlgorithms.m')"

退出码 0 表示全部算法通过验证。

## 依赖

- MATLAB R2025b
- Image Processing Toolbox 25.2
- Computer Vision Toolbox 25.2（特征提取部分需要）

## 目录

    verifyAlgorithms.m   验证入口，跑完打印对照表
    +img/                16 个算法实现，调用写成 img.函数名(...)
```

- [ ] **Step 2: 写 threshOtsu.m**

`hw04-imageGeometry/platform/+img/threshOtsu.m`：

```matlab
function [BW, level] = threshOtsu(I)
%THRESHOTSU 用 Otsu 法（最大类间方差）对灰度图做全局阈值分割
%
%   灰度的类间方差定义为
%       sigmaB(t) = (muT*omega(t) - mu(t))^2 / (omega(t)*(1-omega(t)))
%   其中 omega(t) 是灰度 <= t 的累积概率，mu(t) 是累积一阶矩，muT 是全图均值。
%   使 sigmaB 最大的 t 即 Otsu 阈值。
%
%   输入
%       I      灰度图矩阵，uint8 / uint16 / double
%   输出
%       BW     与 I 同尺寸的 logical 二值图，前景为 I 中大于阈值的像素
%       level  归一化到 [0,1] 的阈值标量
%
%   调用示例
%       [BW, level] = img.threshOtsu(imread("cameraman.tif"));

NUM_BINS = 256;
UPPER_SAFE_TOL = 1e-12;   % 防止 omega 取到 0 或 1 时除零

narginchk(1, 1);

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "threshOtsu 只接受二维灰度图，当前输入是 %d 维。请先用 rgb2gray 转换。", ndims(I));
end

counts = imhist(I, NUM_BINS);
p = double(counts) / numel(I);
binValue = (0:NUM_BINS-1)';           % 第 k 个 bin 对应灰度值 k-1

omega = cumsum(p);                     % 类 1（暗）的累积概率
mu = cumsum(p .* binValue);            % 类 1 的累积一阶矩
muTotal = mu(end);

sigmaB = (muTotal * omega - mu).^2 ./ (omega .* (1 - omega));
sigmaB(~isfinite(sigmaB)) = 0;         % omega 为 0 或 1 的端点无定义
sigmaB(omega < UPPER_SAFE_TOL | omega > 1 - UPPER_SAFE_TOL) = 0;

[~, idxMax] = max(sigmaB);
level = (idxMax - 1) / (NUM_BINS - 1); % 换算回 [0,1]

% 与 imbinarize 的判据保持一致：大于阈值判为前景。
% 浮点输入按 [0,1] 量纲处理（与 imhist 的口径一致），不能取 intmax("double")
if isinteger(I)
    intensityMax = double(intmax(class(I)));
else
    intensityMax = 1;
end

BW = I > level * intensityMax;
end
```

- [ ] **Step 3: 写 threshIterative.m**

`hw04-imageGeometry/platform/+img/threshIterative.m`：

```matlab
function [BW, level] = threshIterative(I, tol)
%THRESHITERATIVE 用迭代法（迭代选择阈值）对灰度图做全局阈值分割
%
%   先把全图均值当作初始阈值 T0，然后反复做两件事直到收敛：
%     1. 用当前 T 把像素分成暗组和亮组；
%     2. 取两组均值的算术平均作为新阈值。
%   与 Otsu 的区别是它不假设双峰分布的方差结构，对偏斜直方图更稳。
%
%   输入
%       I      灰度图矩阵
%       tol    收敛容差，可选，默认 1e-6
%   输出
%       BW     与 I 同尺寸的 logical 二值图
%       level  归一化到 [0,1] 的阈值标量
%
%   调用示例
%       [BW, level] = img.threshIterative(imread("rice.png"));

DEFAULT_TOL      = 1e-6;
MAX_ITERATION    = 1000;

narginchk(1, 2);
if nargin < 2
    tol = DEFAULT_TOL;
end

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "threshIterative 只接受二维灰度图，当前输入是 %d 维。请先用 rgb2gray 转换。", ndims(I));
end

data = double(I);
level = mean(data(:));

for iter = 1:MAX_ITERATION
    isForeground = data > level;
    % any/all 默认沿第一个非单例维归约，矩阵输入会返回行向量，|| 要求标量操作数，
    % 必须显式加 "all"（Requires R2018b+）
    if ~any(isForeground, "all") || all(isForeground, "all")
        break;                          % 退化成单一分组，无阈值可言
    end
    levelNew = (mean(data(~isForeground)) + mean(data(isForeground))) / 2;
    if abs(levelNew - level) < tol
        level = levelNew;
        break;
    end
    level = levelNew;
end

% 浮点输入按 [0,1] 量纲处理，不能取 intmax("double")（那是 1.8e308）
if isinteger(I)
    intensityMax = double(intmax(class(I)));
else
    intensityMax = 1;
end

level = level / intensityMax;   % 归一化到 [0,1] 供调用者比较

% BW 为真等价于 I > 绝对阈值，与上面归一化后的 level 口径一致
BW = I > level * intensityMax;
end
```

`level` 在循环里是绝对灰度值，最后才归一化，所以返回的是 `[0,1]` 标量。

注意 `BW` 这一行必须有。上面那段浮点量纲的 `if/else` 很容易让人以为「归一化完就结束
了」，漏掉 `BW` 的赋值。漏了的话函数仍能跑，但第二个返回值是空的，验证脚本会静默地
拿到一个未赋值的 `BW`。`check_matlab_code` 能查出这个。

- [ ] **Step 4: 写 verifyAlgorithms.m**

`hw04-imageGeometry/platform/verifyAlgorithms.m`：

```matlab
% 验证 +img/ 里手写算法与 MATLAB 图像处理工具箱输出的一致性
%
% 运行：在编辑器里点运行，或
%   matlab -batch "run('hw04-imageGeometry/platform/verifyAlgorithms.m')"
% 退出码 0 表示全部通过。
%
% 预期结果：命令窗口打印一张对照表，每行一个算法，列出实测指标与阈值。
%          不达标的行紧随一段缩进的失败说明，但脚本继续往下跑完，
%          最后汇总未通过项数并以非零退出码结束。全部达标时打印「全部通过」。
%
% 阈值的定法见 docs/superpowers/specs/2026-09-15-image-platform-design.md。

clear; clc; close all;

% ---------- 判定阈值 ----------
% 阈值常量不放在脚本体里：脚本的局部函数有独立工作区，读不到脚本变量。
% 所以每类算法自己的阈值常量声明在对应 verifyXxx 函数的开头，与 +img 里
% NUM_BINS、下面 reportRow 的 DEFAULT_DIRECTION 是同一种写法。

% ---------- 测试图像 ----------
% cameraman 是双峰直方图的典型；rice 偏亮、直方图偏斜，适合区分两种阈值算法
IMAGES = { ...
    "cameraman", imread("cameraman.tif"); ...
    "rice",      imread("rice.png")};

fprintf("%-10s %-18s %-10s %12s %12s  %-5s %s\n", ...
    "类别", "算法", "指标", "实测", "阈值", "通过", "单位");
fprintf("%s\n", repmat('-', 1, 78));

% 每个验证函数返回它记录的失败条数，在这里累加
failureCount = 0;

fprintf("\n【阈值分割】\n");
failureCount = failureCount + verifyThresholding(IMAGES);

% 后续类别在这里各加一行，形如
%   failureCount = failureCount + verifyIntensity(IMAGES);

if failureCount > 0
    error("matlab_test:verifyFailed", ...
        "共 %d 项验证未通过，逐条明细见上方标了 false 的行。", failureCount);
end

fprintf("\n全部通过\n");

% ==================== 局部函数 ====================

function nFail = verifyThresholding(images)
%VERIFYTHRESHOLDING 验证两种阈值分割算法，返回未通过的条数

OTSUTHRESH_TOL   = 1e-12;   % Otsu 是确定性算法，手写版与工具箱应逐位相等
JACCARD_MIN_BIN  = 0.90;    % 二值分割结果的重叠度

nFail = 0;

for kk = 1:size(images, 1)
    imgName = images{kk, 1};
    I = images{kk, 2};

    % --- Otsu：与 otsuthresh 求出的阈值应逐位相等 ---
    % 「阈值差」越小越好，所以方向传 "min"
    levelRef = otsuthresh(imhist(I, 256));
    [BW, level] = img.threshOtsu(I);
    nFail = nFail + ~reportRow("阈值分割", "Otsu/" + imgName, "阈值差", ...
        abs(level - levelRef), OTSUTHRESH_TOL, "", "min");
    nFail = nFail + ~reportRow("阈值分割", "Otsu/" + imgName, "Jaccard", ...
        jaccard(BW, imbinarize(I, levelRef)), JACCARD_MIN_BIN, "", "max");

    % --- 迭代法：无对应工具箱函数，与 Otsu 的结果比重叠度 ---
    BWIter = img.threshIterative(I);
    nFail = nFail + ~reportRow("阈值分割", "迭代法/" + imgName, "Jaccard", ...
        jaccard(BWIter, BW), JACCARD_MIN_BIN, "", "max");
end
end

function isPass = reportRow(category, algorithm, metricName, value, threshold, unit, direction)
%REPORTROW 打印一行对照结果并判定是否达标，失败时追加一行缩进说明
%
%   不抛错。失败只记录并打印，由调用者累加条数，让整个脚本跑完所有算法后
%   再统一报错——否则第一个算法挂了，后面算法的实测值就看不到了。
%
%   输入
%       category    类别名，如 "阈值分割"
%       algorithm   算法名，如 "Otsu/cameraman"
%       metricName  指标名，如 "Jaccard"
%       value       实测值
%       threshold   阈值
%       unit        单位后缀，如 "dB"，无单位传 ""
%       direction   可选，"max" 表示越大越好（默认），"min" 表示越小越好
%   输出
%       isPass      logical，是否达标

DEFAULT_DIRECTION = "max";

narginchk(6, 7);
if nargin < 7 || strlength(direction) == 0
    direction = DEFAULT_DIRECTION;
end

switch direction
    case "max"
        isPass = value >= threshold;
        relation = "不低于";
    case "min"
        isPass = value <= threshold;
        relation = "不超过";
    otherwise
        error("matlab_test:badDirection", ...
            "direction 只支持 max 或 min，当前为 %s。", direction);
end

fprintf("%-10s %-18s %-10s %12.4f %12.4f  %-5s %s\n", ...
    category, algorithm, metricName, value, threshold, ...
    string(isPass), unit);

if ~isPass
    fprintf("    ^ 未通过: %s 应%s %.4f%s，实测 %.4f%s\n", ...
        metricName, relation, threshold, unit, value, unit);
end
end
```

- [ ] **Step 5: 跑验证，确认能通过**

Run:
```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "run('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform/verifyAlgorithms.m')"
```

Expected: 打印「【阈值分割】」段共 6 行，每行末列为 `true`，最后一行是「全部通过」，退出码 0。

如果 Otsu 的阈值差不为 0，先查 `imhist` 的 bin 数是否一致（本实现固定 256 档），再查阈值换算公式；不要直接放宽 `OTSUTHRESH_TOL`。

**后续任务往这个脚本里加新类别时，照这个模式加两处**：

1. 在 `if failureCount > 0` 之前加一行 `failureCount = failureCount + verifyXxx(IMAGES);`（前面配一个 `fprintf` 打类别名）；
2. 在局部函数区末尾加 `function nFail = verifyXxx(images)`，把该类自己的阈值常量声明在函数开头，内部每条断言写成 `nFail = nFail + ~reportRow(...);`。

`~isPass` 把 logical 转成 0/1 直接累加，避免再写一个 if 分支。

**阈值常量必须声明在使用它的局部函数内部，不能放在脚本体里。** 已实测：MATLAB
脚本的局部函数有独立工作区，读不到脚本变量（脚本里定义常量后，局部函数内
`exist("常量名", "var")` 返回 `0`）。所以「顶部集中定义阈值」这个想法在 MATLAB 里
做不到，每类算法的阈值与它的断言放在一起。这与 `+img/` 里 `NUM_BINS`、
`reportRow` 里 `DEFAULT_DIRECTION` 是同一种写法。

- [ ] **Step 6: 提交**

```bash
git add hw04-imageGeometry/platform
git commit -m "feat: 图像处理平台骨架与验证框架，含 Otsu 与迭代法阈值分割"
```

---

## Task 2: 灰度变换类

**Files:**
- Create: `hw04-imageGeometry/platform/+img/grayLinearStretch.m`
- Create: `hw04-imageGeometry/platform/+img/grayGamma.m`
- Modify: `hw04-imageGeometry/platform/verifyAlgorithms.m`（追加阈值常量、调用行、局部函数）

**Interfaces:**
- Consumes: Task 1 的 `reportRow` 局部函数
- Produces:
  - `out = img.grayLinearStretch(I, lowIn, highIn)` — 把 `[lowIn, highIn]` 拉伸到整个动态范围，超出部分截断
  - `out = img.grayGamma(I, gamma)` — 幂律变换 `s = r^gamma`

- [ ] **Step 1: 追加调用行，并在验证函数开头声明阈值常量**

这两个阈值常量声明在下面 `verifyIntensity` 函数的开头（脚本的局部函数读不到脚本体变量）：

```matlab
PSNR_MIN_POINTWISE = 45;    % 逐像素映射类，手写与工具箱应几乎完全一致
SSIM_MIN_POINTWISE = 0.999;
```

在 `if failureCount > 0` 之前追加：

```matlab
fprintf("\n【灰度变换】\n");
failureCount = failureCount + verifyIntensity(IMAGES);
```

- [ ] **Step 2: 写 grayLinearStretch.m**

`hw04-imageGeometry/platform/+img/grayLinearStretch.m`：

```matlab
function out = grayLinearStretch(I, lowIn, highIn)
%GRAYLINEARSTRETCH 把输入灰度区间线性拉伸到整个动态范围
%
%   映射关系为
%       s = (r - lowIn) / (highIn - lowIn) * maxValue
%   小于 lowIn 的压到 0，大于 highIn 的压到 maxValue。
%
%   输入
%       I       灰度图矩阵
%       lowIn   输入区间的下界（与 I 同类型同量纲）
%       highIn  输入区间的上界
%   输出
%       out     与 I 同类型同尺寸的拉伸结果
%
%   调用示例
%       out = img.grayLinearStretch(imread("cameraman.tif"), 30, 220);

narginchk(3, 3);

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "grayLinearStretch 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end
if highIn <= lowIn
    error("matlab_test:badRange", ...
        "highIn(%g) 必须大于 lowIn(%g)，否则拉伸区间为空。", highIn, lowIn);
end

% 浮点输入按 [0,1] 量纲处理（与 imadjust 的口径一致），不能取 intmax("double")
if isinteger(I)
    maxValue = double(intmax(class(I)));
else
    maxValue = 1;
end

cls = class(I);
data = double(I);

stretched = (data - double(lowIn)) / double(highIn - lowIn) * maxValue;
stretched = min(max(stretched, 0), maxValue);   % 截断到有效动态范围

out = cast(stretched, cls);
end
```

- [ ] **Step 3: 写 grayGamma.m**

`hw04-imageGeometry/platform/+img/grayGamma.m`：

```matlab
function out = grayGamma(I, gamma)
%GRAYGAMMA 幂律（伽马）灰度变换
%
%   先把输入归一化到 [0,1]，做 s = r^gamma，再换算回原类型。
%   gamma < 1 提亮暗部，gamma > 1 压暗。计算前对 r 取下界保护，
%   避免 0^gamma 之外的负数（归一化后不会出现负数，这里只防浮点残差）。
%
%   输入
%       I       灰度图矩阵
%       gamma   幂指数，正数
%   输出
%       out     与 I 同类型同尺寸的变换结果
%
%   调用示例
%       out = img.grayGamma(imread("cameraman.tif"), 0.5);

MIN_GAMMA = 1e-6;

narginchk(2, 2);

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "grayGamma 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end
if gamma < MIN_GAMMA
    error("matlab_test:badGamma", ...
        "gamma 必须是正数，当前为 %g。", gamma);
end

% 浮点输入按 [0,1] 量纲处理（与 imadjust 的口径一致），不能取 intmax("double")
if isinteger(I)
    maxValue = double(intmax(class(I)));
else
    maxValue = 1;
end

cls = class(I);
normalized = double(I) / maxValue;

out = cast(normalized.^gamma * maxValue, cls);
end
```

- [ ] **Step 4: 追加 verifyIntensity 局部函数**

在 `verifyAlgorithms.m` 的局部函数区追加：

```matlab
function nFail = verifyIntensity(images)
%VERIFYINTENSITY 验证两种灰度变换算法，返回未通过的条数

nFail = 0;

for kk = 1:size(images, 1)
    imgName = images{kk, 1};
    I = images{kk, 2};

    % --- 线性拉伸：与 imadjust 对照，区间取直方图 1% 与 99% 分位 ---
    limits = stretchlim(I, [0.01, 0.99]) * double(intmax(class(I)));
    outOurs = img.grayLinearStretch(I, limits(1), limits(2));
    outRef  = imadjust(I, stretchlim(I, [0.01, 0.99]), []);
    nFail = nFail + ~reportRow("灰度变换", "线性拉伸/" + imgName, "PSNR", ...
        psnr(outOurs, outRef), PSNR_MIN_POINTWISE, "dB", "max");
    nFail = nFail + ~reportRow("灰度变换", "线性拉伸/" + imgName, "SSIM", ...
        ssim(outOurs, outRef), SSIM_MIN_POINTWISE, "", "max");

    % --- 伽马变换：与 imadjust 的 gamma 参数对照 ---
    GAMMA_TEST = 0.5;
    outOursG = img.grayGamma(I, GAMMA_TEST);
    refG = imadjust(I, [], [], GAMMA_TEST);
    nFail = nFail + ~reportRow("灰度变换", "伽马/" + imgName, "PSNR", ...
        psnr(outOursG, refG), PSNR_MIN_POINTWISE, "dB", "max");
    nFail = nFail + ~reportRow("灰度变换", "伽马/" + imgName, "SSIM", ...
        ssim(outOursG, refG), SSIM_MIN_POINTWISE, "", "max");
end
end
```

- [ ] **Step 5: 跑验证**

Run:
```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "run('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform/verifyAlgorithms.m')"
```

Expected: 「【灰度变换】」段 8 行全部 `true`，退出码 0。

伽马变换与 `imadjust` 的映射定义可能有半个灰阶的取整差，若 PSNR 卡在 40 出头而 SSIM 已过 0.999，说明只是取整口径不同，在 `grayGamma.m` 注释里记下差异来源。

- [ ] **Step 6: 提交**

```bash
git add hw04-imageGeometry/platform
git commit -m "feat: 灰度变换类算法（线性拉伸、伽马变换）并通过验证"
```

---

## Task 3: 直方图均衡类

**Files:**
- Create: `hw04-imageGeometry/platform/+img/histEqualize.m`
- Create: `hw04-imageGeometry/platform/+img/histClahe.m`
- Modify: `hw04-imageGeometry/platform/verifyAlgorithms.m`

**Interfaces:**
- Consumes: `reportRow`
- Produces:
  - `out = img.histEqualize(I, numLevels)` — 全局 CDF 均衡
  - `out = img.histClahe(I, numTiles, clipLimit)` — 分块自适应均衡，块间双线性插值

- [ ] **Step 1: 追加调用行，并在验证函数开头声明阈值常量**

```matlab
PSNR_MIN_HISTEQ  = 40;      % 直方图均衡，取整口径可能略有不同
SSIM_MIN_HISTEQ  = 0.99;
PSNR_MIN_CLAHE   = 18;      % CLAHE 三个参数耦合，与工具箱只能是近似
SSIM_MIN_CLAHE   = 0.70;
```

调用行：

```matlab
fprintf("\n【直方图均衡】\n");
failureCount = failureCount + verifyHistogram(IMAGES);
```

- [ ] **Step 2: 写 histEqualize.m**

```matlab
function out = histEqualize(I, numLevels)
%HISTEQUALIZE 全局直方图均衡
%
%   用累积分布函数做灰度映射。设第 k 档灰度的累积概率为 cdf(k)，
%   则映射后的灰度为
%       s(k) = round( cdf(k) * (numLevels - 1) )
%
%   输入
%       I           灰度图矩阵
%       numLevels   直方图档数，可选，默认 256
%   输出
%       out         与 I 同类型同尺寸的均衡结果
%
%   调用示例
%       out = img.histEqualize(imread("cameraman.tif"), 256);

DEFAULT_NUM_LEVELS = 256;

narginchk(1, 2);
if nargin < 2
    numLevels = DEFAULT_NUM_LEVELS;
end

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "histEqualize 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end

% 浮点输入按 [0,1] 量纲处理（与 imhist 的口径一致），不能取 intmax("double")
if isinteger(I)
    maxValue = double(intmax(class(I)));
else
    maxValue = 1;
end

cls = class(I);

counts = imhist(I, numLevels);

% 只有一个灰阶有像素时均衡无意义，提前拦掉（否则 lut 恒为常数，结果是张全黑图）
if nnz(counts) <= 1
    error("matlab_test:degenerateInput", ...
        "输入图像只有一个灰阶有像素，均衡无意义。请换一张有灰度分布的图。");
end

cdf = cumsum(double(counts)) / numel(I);
lut = round(cdf * (numLevels - 1));         % lut 的下标 1 对应灰阶 0

% 输入灰阶换算成直方图档位下标，再查表
idx = round(double(I) / maxValue * (numLevels - 1)) + 1;
idx = min(max(idx, 1), numLevels);          % 防浮点残差越界
out = cast(lut(idx) / (numLevels - 1) * maxValue, cls);
end
```

- [ ] **Step 3: 写 histClahe.m**

```matlab
function out = histClahe(I, numTiles, clipLimit)
%HISTCLAHE 对比度受限的分块自适应直方图均衡（CLAHE）
%
%   步骤：
%     1. 把图像切成 numTiles(1) × numTiles(2) 块；
%     2. 每块内做直方图均衡，但先把超过 clipLimit 的直方图峰值削平，
%        削下来的计数均匀补回各档（限制对比度放大倍数）；
%     3. 每个像素由相邻四块的中心按距离做双线性插值，消除块间边界。
%
%   输入
%       I           灰度图矩阵
%       numTiles    分块数 [行块数, 列块数]，可选，默认 [8, 8]
%       clipLimit   对比度限幅，可选，默认 0.01（与 adapthisteq 同口径）
%   输出
%       out         与 I 同类型同尺寸的结果
%
%   调用示例
%       out = img.histClahe(imread("cameraman.tif"), [8, 8], 0.01);

DEFAULT_NUM_TILES = [8, 8];
DEFAULT_CLIP_LIMIT = 0.01;
NUM_BINS = 256;

narginchk(1, 3);
if nargin < 2 || isempty(numTiles)
    numTiles = DEFAULT_NUM_TILES;
end
if nargin < 3 || isempty(clipLimit)
    clipLimit = DEFAULT_CLIP_LIMIT;
end

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "histClahe 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end

% 浮点输入按 [0,1] 量纲处理（与 imhist 的口径一致），不能取 intmax("double")
if isinteger(I)
    maxValue = double(intmax(class(I)));
else
    maxValue = 1;
end

cls = class(I);
data = double(I) / maxValue;                 % 归一化到 [0,1]
[imageH, imageW] = size(data);

tileH = ceil(imageH / numTiles(1));
tileW = ceil(imageW / numTiles(2));

% 每块的 CDF 查找表，尺寸 [NUM_BINS, numTiles(1), numTiles(2)]
% 下标 (bin, r, c) 表示第 (r,c) 块第 bin 档的映射输出
tileLut = zeros(NUM_BINS, numTiles(1), numTiles(2));

for rowIdx = 1:numTiles(1)
    for colIdx = 1:numTiles(2)
        r1 = (rowIdx - 1) * tileH + 1;
        r2 = min(rowIdx * tileH, imageH);
        c1 = (colIdx - 1) * tileW + 1;
        c2 = min(colIdx * tileW, imageW);

        block = data(r1:r2, c1:c2);
        counts = imhist(block, NUM_BINS);

        % 对比度限幅：削平峰值，把削下来的计数均匀补回
        limit = clipLimit * numel(block);
        excess = sum(max(counts - limit, 0));
        counts = min(counts, limit) + excess / NUM_BINS;

        cdf = cumsum(counts) / sum(counts);
        tileLut(:, rowIdx, colIdx) = cdf;
    end
end

% 逐像素双线性插值。为向量化，先算每个像素在块网格上的浮点坐标
rowCoord = ((1:imageH)' - 0.5) / tileH + 0.5;    % 1 对应第一块中心
colCoord = ((1:imageW)  - 0.5) / tileW + 0.5;
rowCoord = min(max(rowCoord, 1), numTiles(1));
colCoord = min(max(colCoord, 1), numTiles(2));

rowLow  = floor(rowCoord);  rowHigh = min(rowLow + 1, numTiles(1));
colLow  = floor(colCoord);  colHigh = min(colLow + 1, numTiles(2));
rowFrac = rowCoord - rowLow;
colFrac = colCoord - colLow;

% 输入灰阶对应的直方图档位
binIdx = round(data * (NUM_BINS - 1)) + 1;
binIdx = min(max(binIdx, 1), NUM_BINS);

% 查四角的映射值。rowLow 是 imageH×1、colLow 是 1×imageW，必须先都铺成
% imageH×imageW 的网格，sub2ind 才能一次查完所有像素
rowLowGrid  = repmat(rowLow,  1, imageW);
rowHighGrid = repmat(rowHigh, 1, imageW);
colLowGrid  = repmat(colLow,  imageH, 1);
colHighGrid = repmat(colHigh, imageH, 1);

lutSize = size(tileLut);
at = @(r, c) tileLut(sub2ind(lutSize, binIdx, r, c));
lut00 = at(rowLowGrid,  colLowGrid);
lut01 = at(rowLowGrid,  colHighGrid);
lut10 = at(rowHighGrid, colLowGrid);
lut11 = at(rowHighGrid, colHighGrid);

% 行方向先插值（列向量按行广播），再列方向插值
rowFracW = repmat(rowFrac, 1, imageW);
colFracW = repmat(colFrac', imageH, 1);
top    = lut00 .* (1 - colFracW) + lut01 .* colFracW;
bottom = lut10 .* (1 - colFracW) + lut11 .* colFracW;
mapped = top .* (1 - rowFracW) + bottom .* rowFracW;

out = cast(mapped * maxValue, cls);
end
```

- [ ] **Step 4: 追加 verifyHistogram 局部函数**

```matlab
function nFail = verifyHistogram(images)
%VERIFYHISTOGRAM 验证两种直方图均衡算法，返回未通过的条数

nFail = 0;

for kk = 1:size(images, 1)
    imgName = images{kk, 1};
    I = images{kk, 2};

    % --- 全局均衡：与 histeq 对照 ---
    outOurs = img.histEqualize(I, 256);
    outRef  = histeq(I, 256);
    nFail = nFail + ~reportRow("直方图均衡", "全局/" + imgName, "PSNR", ...
        psnr(outOurs, outRef), PSNR_MIN_HISTEQ, "dB", "max");
    nFail = nFail + ~reportRow("直方图均衡", "全局/" + imgName, "SSIM", ...
        ssim(outOurs, outRef), SSIM_MIN_HISTEQ, "", "max");

    % --- CLAHE：与 adapthisteq 对照，参数取两者的共同默认值 ---
    outClahe = img.histClahe(I, [8, 8], 0.01);
    refClahe = adapthisteq(I, "NumTiles", [8, 8], "ClipLimit", 0.01);
    nFail = nFail + ~reportRow("直方图均衡", "CLAHE/" + imgName, "PSNR", ...
        psnr(outClahe, refClahe), PSNR_MIN_CLAHE, "dB", "max");
    nFail = nFail + ~reportRow("直方图均衡", "CLAHE/" + imgName, "SSIM", ...
        ssim(outClahe, refClahe), SSIM_MIN_CLAHE, "", "max");
end
end
```

- [ ] **Step 5: 跑验证**

Run:
```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "run('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform/verifyAlgorithms.m')"
```

Expected: 「【直方图均衡】」段 8 行全部 `true`。

CLAHE 的阈值是本计划里最松的一处（PSNR 18 dB）。若连这个都过不了，优先查 `adapthisteq` 的 `Range` 参数默认值 "full" 是否与手写版的归一化一致，再查限幅公式里 `excess / NUM_BINS` 的补回方式。差异来源必须写进 `histClahe.m` 的注释。

- [ ] **Step 6: 提交**

```bash
git add hw04-imageGeometry/platform
git commit -m "feat: 直方图均衡类算法（全局 CDF、CLAHE）并通过验证"
```

---

## Task 4: 空域滤波类

**Files:**
- Create: `hw04-imageGeometry/platform/+img/filterMean.m`
- Create: `hw04-imageGeometry/platform/+img/filterMedian.m`
- Modify: `hw04-imageGeometry/platform/verifyAlgorithms.m`

**Interfaces:**
- Consumes: `reportRow`
- Produces:
  - `out = img.filterMean(I, kernelSize)` — `kernelSize` 为奇数标量，如 3、5
  - `out = img.filterMedian(I, kernelSize)` — 边界补零，与 `medfilt2` 默认一致

- [ ] **Step 1: 追加调用行，并在验证函数开头声明阈值常量**

```matlab
PSNR_MIN_SPATIAL = 45;      % 均值滤波与 imfilter 应完全一致
SSIM_MIN_SPATIAL = 0.999;
PSNR_MIN_MEDIAN  = 40;      % 中值滤波，边界填充口径可能不同
SSIM_MIN_MEDIAN  = 0.99;
```

调用行：

```matlab
fprintf("\n【空域滤波】\n");
failureCount = failureCount + verifySpatial(IMAGES);
```

- [ ] **Step 2: 写 filterMean.m**

```matlab
function out = filterMean(I, kernelSize)
%FILTERMEAN 均值滤波
%
%   用 kernelSize × kernelSize 的归一化均值模板做卷积，边界补零。
%   补零会让图像边缘被拉暗，这与 imfilter 的默认行为一致。
%
%   输入
%       I           灰度图矩阵
%       kernelSize  模板边长，正奇数
%   输出
%       out         与 I 同类型同尺寸的滤波结果
%
%   调用示例
%       out = img.filterMean(imread("rice.png"), 3);

narginchk(2, 2);

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "filterMean 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end
if mod(kernelSize, 2) ~= 1 || kernelSize < 1
    error("matlab_test:badKernelSize", ...
        "kernelSize 必须是正的奇数，当前为 %g。", kernelSize);
end

kernel = ones(kernelSize) / kernelSize^2;
filtered = conv2(double(I), kernel, "same");

out = cast(filtered, class(I));
end
```

- [ ] **Step 3: 写 filterMedian.m**

```matlab
function out = filterMedian(I, kernelSize)
%FILTERMEDIAN 中值滤波
%
%   kernelSize × kernelSize 邻域内取中位数。边界补零，与 medfilt2 的默认
%   padopt="zeros" 一致。
%
%   实现上把 kernelSize^2 个平移切片叠成三维数组，再沿第三维取中位数，
%   避免逐像素循环。
%
%   输入
%       I           灰度图矩阵
%       kernelSize  邻域边长，正奇数
%   输出
%       out         与 I 同类型同尺寸的滤波结果
%
%   调用示例
%       out = img.filterMedian(imread("rice.png"), 3);

narginchk(2, 2);

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "filterMedian 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end
if mod(kernelSize, 2) ~= 1 || kernelSize < 1
    error("matlab_test:badKernelSize", ...
        "kernelSize 必须是正的奇数，当前为 %g。", kernelSize);
end

halfWidth = (kernelSize - 1) / 2;
[imageH, imageW] = size(I);
padded = padarray(double(I), [halfWidth, halfWidth], 0, "both");

% 把 kernelSize^2 个平移切片叠起来，尺寸 [imageH, imageW, kernelSize^2]
stack = zeros(imageH, imageW, kernelSize^2);
sliceIdx = 0;
for offsetRow = 0:kernelSize-1
    for offsetCol = 0:kernelSize-1
        sliceIdx = sliceIdx + 1;
        stack(:, :, sliceIdx) = padded( ...
            1+offsetRow : imageH+offsetRow, ...
            1+offsetCol : imageW+offsetCol);
    end
end

out = cast(median(stack, 3), class(I));
end
```

- [ ] **Step 4: 追加 verifySpatial 局部函数**

```matlab
function nFail = verifySpatial(images)
%VERIFYSPATIAL 验证两种空域滤波算法，返回未通过的条数

KERNEL_SIZE = 3;
nFail = 0;

for kk = 1:size(images, 1)
    imgName = images{kk, 1};
    I = images{kk, 2};

    % --- 均值滤波：与 imfilter + fspecial 对照 ---
    outMean = img.filterMean(I, KERNEL_SIZE);
    refMean = imfilter(I, fspecial("average", [KERNEL_SIZE, KERNEL_SIZE]));
    nFail = nFail + ~reportRow("空域滤波", "均值/" + imgName, "PSNR", ...
        psnr(outMean, refMean), PSNR_MIN_SPATIAL, "dB", "max");
    nFail = nFail + ~reportRow("空域滤波", "均值/" + imgName, "SSIM", ...
        ssim(outMean, refMean), SSIM_MIN_SPATIAL, "", "max");

    % --- 中值滤波：与 medfilt2 对照 ---
    outMed = img.filterMedian(I, KERNEL_SIZE);
    refMed = medfilt2(I, [KERNEL_SIZE, KERNEL_SIZE]);
    nFail = nFail + ~reportRow("空域滤波", "中值/" + imgName, "PSNR", ...
        psnr(outMed, refMed), PSNR_MIN_MEDIAN, "dB", "max");
    nFail = nFail + ~reportRow("空域滤波", "中值/" + imgName, "SSIM", ...
        ssim(outMed, refMed), SSIM_MIN_MEDIAN, "", "max");
end
end
```

- [ ] **Step 5: 跑验证**

Run:
```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "run('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform/verifyAlgorithms.m')"
```

Expected: 「【空域滤波】」段 8 行全部 `true`。

均值滤波理论上应与 `imfilter` 逐位一致（同一卷积、同样补零）。若 PSNR 不是无穷大，查 `conv2` 的 `"same"` 取窗位置与 `imfilter` 的锚点是否对齐。

- [ ] **Step 6: 提交**

```bash
git add hw04-imageGeometry/platform
git commit -m "feat: 空域滤波类算法（均值、中值）并通过验证"
```

---

## Task 5: 几何变换类

**Files:**
- Create: `hw04-imageGeometry/platform/+img/geomRotate.m`
- Create: `hw04-imageGeometry/platform/+img/geomScale.m`
- Modify: `hw04-imageGeometry/platform/verifyAlgorithms.m`

**Interfaces:**
- Consumes: `reportRow`
- Produces:
  - `out = img.geomRotate(I, angle, method)` — 逆时针为正，`method` 取 `"nearest"` / `"bilinear"` / `"bicubic"`
  - `out = img.geomScale(I, targetSize, method)` — `targetSize` 为 `[行数, 列数]`

- [ ] **Step 1: 追加调用行，并在验证函数开头声明阈值常量**

```matlab
PSNR_MIN_GEOMETRY  = 30;    % 几何变换，插值实现细节不同，放宽
SSIM_MIN_GEOMETRY  = 0.95;
ROT90_TOL          = 1e-9;  % 90 度整数倍旋转与 rot90 应逐位相等
```

调用行：

```matlab
fprintf("\n【几何变换】\n");
failureCount = failureCount + verifyGeometry(IMAGES);
```

- [ ] **Step 2: 写 geomRotate.m**

```matlab
function out = geomRotate(I, angle, method)
%GEOMROTATE 绕图像中心逆时针旋转，边界补零
%
%   旋转后输出尺寸取原图的外接矩形
%       W' = w*|cos(th)| + h*|sin(th)|
%       H' = h*|cos(th)| + w*|sin(th)|
%   对每个输出像素用逆变换求出它在输入图中的坐标，再用 interp2 采样。
%   落在输入图之外的采样点补 0，即显示为黑色背景。
%
%   输入
%       I       灰度图矩阵
%       angle   逆时针旋转角度，度。负值表示顺时针
%       method  插值方法，可选 "nearest" / "bilinear" / "bicubic"，默认 "bicubic"
%   输出
%       out     与 I 同类型的旋转结果，尺寸为旋转后的外接矩形
%
%   调用示例
%       out = img.geomRotate(imread("cameraman.tif"), 50, "bicubic");

DEFAULT_METHOD = "bicubic";
VALID_METHODS  = ["nearest", "bilinear", "bicubic"];
TOL_CEIL       = 1e-10;   % 抵消 cos(90 度)=6.1e-17 这类残差，否则 ceil 会多算一行一列
TOL_SNAP       = 1e-9;    % 把差一点点落在边界上的采样点吸附回边界

narginchk(2, 3);
if nargin < 3 || strlength(method) == 0
    method = DEFAULT_METHOD;
end

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "geomRotate 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end
if ~any(strcmpi(method, VALID_METHODS))
    error("matlab_test:badMethod", ...
        "method 只支持 nearest / bilinear / bicubic，当前为 %s。", method);
end

[imageH, imageW] = size(I);
theta = deg2rad(angle);

outW = ceil(abs(imageW * cos(theta)) + abs(imageH * sin(theta)) - TOL_CEIL);
outH = ceil(abs(imageH * cos(theta)) + abs(imageW * sin(theta)) - TOL_CEIL);

centerInX  = (imageW + 1) / 2;
centerInY  = (imageH + 1) / 2;
centerOutX = (outW + 1) / 2;
centerOutY = (outH + 1) / 2;

[gridX, gridY] = meshgrid(1:outW, 1:outH);

% 逆变换：把输出像素中心映回输入图坐标
relX = gridX - centerOutX;
relY = gridY - centerOutY;
queryX = centerInX + relX * cos(theta) - relY * sin(theta);
queryY = centerInY + relX * sin(theta) + relY * cos(theta);

% 吸附贴边的采样点，避免有效像素被 interp2 判成越界而补 0
queryX(abs(queryX - 1) < TOL_SNAP) = 1;
queryX(abs(queryX - imageW) < TOL_SNAP) = imageW;
queryY(abs(queryY - 1) < TOL_SNAP) = 1;
queryY(abs(queryY - imageH) < TOL_SNAP) = imageH;

sampled = interp2(double(I), queryX, queryY, lower(method), 0);

out = cast(sampled, class(I));
end
```

- [ ] **Step 3: 写 geomScale.m**

```matlab
function out = geomScale(I, targetSize, method)
%GEOMSCALE 用 interp2 把图像缩放到指定尺寸
%
%   为保持与 imresize 一致，缩放后的采样网格按
%       xSrc = (xOut - 0.5) / scale + 0.5
%   计算，其中 scale = targetW / imageW。这个半像素偏移是 imresize 的口径，
%   不做的话整幅图会平移半个像素。
%
%   输入
%       I           灰度图矩阵
%       targetSize  [行数, 列数]
%       method      插值方法，可选 "nearest" / "bilinear" / "bicubic"，默认 "bilinear"
%   输出
%       out         尺寸为 targetSize 的结果
%
%   调用示例
%       out = img.geomScale(imread("cameraman.tif"), [120, 200], "bilinear");

DEFAULT_METHOD = "bilinear";
VALID_METHODS  = ["nearest", "bilinear", "bicubic"];

narginchk(2, 3);
if nargin < 3 || strlength(method) == 0
    method = DEFAULT_METHOD;
end

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "geomScale 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end
if numel(targetSize) ~= 2 || any(targetSize < 1)
    error("matlab_test:badTargetSize", ...
        "targetSize 必须是 [行数, 列数] 两个正数，当前为 %s。", mat2str(targetSize));
end
if ~any(strcmpi(method, VALID_METHODS))
    error("matlab_test:badMethod", ...
        "method 只支持 nearest / bilinear / bicubic，当前为 %s。", method);
end

[imageH, imageW] = size(I);
outH = round(targetSize(1));
outW = round(targetSize(2));

[gridX, gridY] = meshgrid(1:outW, 1:outH);
scaleX = outW / imageW;
scaleY = outH / imageH;

queryX = (gridX - 0.5) / scaleX + 0.5;
queryY = (gridY - 0.5) / scaleY + 0.5;

sampled = interp2(double(I), queryX, queryY, lower(method), 0);

out = cast(sampled, class(I));
end
```

- [ ] **Step 4: 追加 verifyGeometry 局部函数**

```matlab
function nFail = verifyGeometry(images)
%VERIFYGEOMETRY 验证两种几何变换算法，返回未通过的条数

ROT_ANGLE    = 50;
SCALE_ORDER  = [120, 200];
nFail = 0;

for kk = 1:size(images, 1)
    imgName = images{kk, 1};
    I = images{kk, 2};

    % --- 先验证旋转方向：90 度整数倍必须与 rot90 逐位相等 ---
    % 这是最强的一条基准，rot90 是基础 MATLAB 函数，不依赖图像处理工具箱。
    % 「差」越小越好，方向传 "min"
    diff90 = max(abs(double(img.geomRotate(I,  90, "nearest")) - double(rot90(I, 1))), [], "all");
    nFail = nFail + ~reportRow("几何变换", "旋转方向/" + imgName, "90度差", ...
        diff90, ROT90_TOL, "", "min");
    diff180 = max(abs(double(img.geomRotate(I, 180, "nearest")) - double(rot90(I, 2))), [], "all");
    nFail = nFail + ~reportRow("几何变换", "旋转方向/" + imgName, "180度差", ...
        diff180, ROT90_TOL, "", "min");

    % --- 旋转：与 imrotate 对照 ---
    outRot = img.geomRotate(I, ROT_ANGLE, "bicubic");
    refRot = imrotate(I, ROT_ANGLE, "bicubic");
    if ~isequal(size(outRot), size(refRot))
        error("matlab_test:sizeMismatch", ...
            "geomRotate 输出 %s，imrotate 输出 %s，尺寸不一致。", ...
            mat2str(size(outRot)), mat2str(size(refRot)));
    end
    nFail = nFail + ~reportRow("几何变换", "旋转" + ROT_ANGLE + "度/" + imgName, "PSNR", ...
        psnr(outRot, refRot), PSNR_MIN_GEOMETRY, "dB", "max");
    nFail = nFail + ~reportRow("几何变换", "旋转" + ROT_ANGLE + "度/" + imgName, "SSIM", ...
        ssim(outRot, refRot), SSIM_MIN_GEOMETRY, "", "max");

    % --- 缩放：与 imresize 对照 ---
    outScale = img.geomScale(I, SCALE_ORDER, "bilinear");
    refScale = imresize(I, SCALE_ORDER, "bilinear");
    nFail = nFail + ~reportRow("几何变换", "缩放/" + imgName, "PSNR", ...
        psnr(outScale, refScale), PSNR_MIN_GEOMETRY, "dB", "max");
    nFail = nFail + ~reportRow("几何变换", "缩放/" + imgName, "SSIM", ...
        ssim(outScale, refScale), SSIM_MIN_GEOMETRY, "", "max");
end
end

- [ ] **Step 5: 跑验证**

Run:
```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "run('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform/verifyAlgorithms.m')"
```

Expected: 「【几何变换】」段全部 `true`。`90度差` 和 `180度差` 必须是 `0.0000`，这两条不过说明旋转方向或中心约定错了，必须先修这个再看 PSNR。

- [ ] **Step 6: 提交**

```bash
git add hw04-imageGeometry/platform
git commit -m "feat: 几何变换类算法（逆映射旋转、双线性缩放）并通过验证"
```

---

## Task 6: 频域滤波类

频域滤波没有直接对应的工具箱函数，验证方式与前几类不同，用三条性质代替。

**Files:**
- Create: `hw04-imageGeometry/platform/+img/freqIdealLP.m`
- Create: `hw04-imageGeometry/platform/+img/freqButterLP.m`
- Modify: `hw04-imageGeometry/platform/verifyAlgorithms.m`

**Interfaces:**
- Consumes: `reportRow`
- Produces:
  - `out = img.freqIdealLP(I, cutoff)` — `cutoff` 为归一化截止频率 `(0, 0.5]`
  - `out = img.freqButterLP(I, cutoff, order)` — `order` 为巴特沃斯阶数

- [ ] **Step 1: 追加调用行，并在验证函数开头声明阈值常量**

```matlab
RECON_TOL        = 1e-9;    % 全通掩膜下 ifft2(fft2(I)) 应无损重建
RINGING_MAX_BUTTER = 0.02;  % 巴特沃斯低通的过冲应小于理想低通
```

调用行：

```matlab
fprintf("\n【频域滤波】\n");
failureCount = failureCount + verifyFrequency(IMAGES);
```

- [ ] **Step 2: 写 freqIdealLP.m**

```matlab
function out = freqIdealLP(I, cutoff)
%FREQIDEALLP 理想低通频域滤波
%
%   把图像做二维傅里叶变换并中心化，然后把到中心的归一化距离超过 cutoff
%   的频率分量置零，再反变换回空域。理想低通在截止频率处是硬截断，
%   反变换后会有明显的振铃（吉布斯现象）。
%
%   输入
%       I       灰度图矩阵
%       cutoff  归一化截止频率，取值 (0, 0.5]
%   输出
%       out     与 I 同类型同尺寸的低通结果
%
%   调用示例
%       out = img.freqIdealLP(imread("cameraman.tif"), 0.1);

narginchk(2, 2);

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "freqIdealLP 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end
if cutoff <= 0 || cutoff > 0.5
    error("matlab_test:badCutoff", ...
        "cutoff 必须落在 (0, 0.5] 内，当前为 %g。", cutoff);
end

[imageH, imageW] = size(I);
spectrum = fftshift(fft2(double(I)));

% 归一化距离网格：到中心的距离除以图像对角线的一半，落在 [0,1]
[gridX, gridY] = meshgrid( ...
    (1:imageW) - (imageW + 1) / 2, ...
    (1:imageH) - (imageH + 1) / 2);
radius = sqrt(gridX.^2 + gridY.^2) / sqrt((imageW/2)^2 + (imageH/2)^2);

mask = radius <= cutoff * 2;   % cutoff 以 Nyquist 的倍率计，1.0 对应 Nyquist

filtered = ifft2(ifftshift(spectrum .* mask));
out = cast(real(filtered), class(I));
end
```

- [ ] **Step 3: 写 freqButterLP.m**

```matlab
function out = freqButterLP(I, cutoff, order)
%FREQBUTTERLP 巴特沃斯低通频域滤波
%
%   巴特沃斯低通的传递函数为
%       H(u,v) = 1 / (1 + (D(u,v)/D0)^(2n))
%   其中 D 是到频域中心的距离，D0 是截止频率，n 是阶数。与理想低通的
%   硬截断不同，它从通带到阻带是平滑过渡的，振铃明显更小。
%
%   输入
%       I       灰度图矩阵
%       cutoff  归一化截止频率，取值 (0, 0.5]
%       order   阶数，正整数，越大越接近理想低通
%   输出
%       out     与 I 同类型同尺寸的低通结果
%
%   调用示例
%       out = img.freqButterLP(imread("cameraman.tif"), 0.1, 2);

narginchk(3, 3);

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "freqButterLP 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end
if cutoff <= 0 || cutoff > 0.5
    error("matlab_test:badCutoff", ...
        "cutoff 必须落在 (0, 0.5] 内，当前为 %g。", cutoff);
end
if order < 1 || mod(order, 1) ~= 0
    error("matlab_test:badOrder", ...
        "order 必须是正整数，当前为 %g。", order);
end

[imageH, imageW] = size(I);
spectrum = fftshift(fft2(double(I)));

[gridX, gridY] = meshgrid( ...
    (1:imageW) - (imageW + 1) / 2, ...
    (1:imageH) - (imageH + 1) / 2);
radius = sqrt(gridX.^2 + gridY.^2) / sqrt((imageW/2)^2 + (imageH/2)^2);

cutoffRadius = cutoff * 2;                  % 与 freqIdealLP 同一口径
mask = 1 ./ (1 + (radius / cutoffRadius).^(2 * order));

filtered = ifft2(ifftshift(spectrum .* mask));
out = cast(real(filtered), class(I));
end
```

- [ ] **Step 4: 追加 verifyFrequency 局部函数**

```matlab
function nFail = verifyFrequency(images)
%VERIFYFREQUENCY 验证两种频域滤波算法，返回未通过的条数
%
%   频域滤波没有一一对应的工具箱函数，用三条性质代替直接对照：
%     1. 全通掩膜下必须无损重建（验证 fft2 / ifft2 / fftshift 配对正确）；
%     2. 截止频率越大保留的能量越多（验证单调性）；
%     3. 巴特沃斯低通的过冲小于理想低通（验证平滑过渡确实抑制了振铃）。

CUTOFF = 0.1;
ORDER  = 2;
CUTOFF_SWEEP = [0.05, 0.1, 0.2, 0.4];
nFail = 0;

for kk = 1:size(images, 1)
    imgName = images{kk, 1};
    I = images{kk, 2};
    data = double(I);

    % --- 性质 1：全通掩膜下无损重建。「误差」越小越好 ---
    recon = real(ifft2(ifftshift(fftshift(fft2(data)) .* 1)));
    reconErr = max(abs(recon - data), [], "all");
    nFail = nFail + ~reportRow("频域滤波", "重构/" + imgName, "误差", ...
        reconErr, RECON_TOL, "", "min");

    % --- 性质 2：截止频率越大，保留的能量越多 ---
    energies = zeros(size(CUTOFF_SWEEP));
    for cc = 1:numel(CUTOFF_SWEEP)
        filtered = double(img.freqIdealLP(data, CUTOFF_SWEEP(cc)));
        energies(cc) = sum(filtered(:).^2);
    end
    isMonotone = all(diff(energies) > 0);
    nFail = nFail + ~reportRow("频域滤波", "单调性/" + imgName, "通过", ...
        double(isMonotone), 1, "", "max");

    % --- 性质 3：巴特沃斯的过冲小于理想低通 ---
    % 过冲用一个亮边缘邻域的振铃幅度衡量：取中心行，算相邻像素的最大跳变，
    % 再减去原图同一位置的最大跳变
    idealOut  = double(img.freqIdealLP(data, CUTOFF));
    butterOut = double(img.freqButterLP(data, CUTOFF, ORDER));
    rowIdx = round(size(data, 1) / 2);
    baseJump = max(abs(diff(data(rowIdx, :))));
    idealRing  = max(abs(diff(idealOut(rowIdx, :))))  - baseJump;
    butterRing = max(abs(diff(butterOut(rowIdx, :)))) - baseJump;
    nFail = nFail + ~reportRow("频域滤波", "振铃抑制/" + imgName, "差值", ...
        idealRing - butterRing, RINGING_MAX_BUTTER, "", "max");
end
end
```

- [ ] **Step 5: 跑验证**

Run:
```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "run('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform/verifyAlgorithms.m')"
```

Expected: 「【频域滤波】」段全部 `true`。重构误差必须是 `0.0000`（`-reconErr` 与 `-RECON_TOL` 比），不过说明 `fftshift` / `ifftshift` 用反了。

- [ ] **Step 6: 提交**

```bash
git add hw04-imageGeometry/platform
git commit -m "feat: 频域滤波类算法（理想低通、巴特沃斯低通）并通过性质验证"
```

---

## Task 7: 边缘检测类

**Files:**
- Create: `hw04-imageGeometry/platform/+img/edgeSobel.m`
- Create: `hw04-imageGeometry/platform/+img/edgePrewitt.m`
- Modify: `hw04-imageGeometry/platform/verifyAlgorithms.m`

**Interfaces:**
- Consumes: `reportRow`
- Produces:
  - `BW = img.edgeSobel(I, threshold)` — `threshold` 为相对于最大梯度幅值的比例，`[0,1]`
  - `BW = img.edgePrewitt(I, threshold)` — 同上

- [ ] **Step 1: 追加调用行，并在验证函数开头声明阈值常量**

```matlab
JACCARD_MIN_EDGE   = 0.85;  % edge 会做细化，手写版不做，重叠度到不了 1
DICE_MIN_EDGE      = 0.90;
CORR_MIN_GRADIENT  = 0.95;  % 梯度幅值图与 imgradient 的相关系数
MIN_OPERATOR_DIFF  = 1e-6;  % Sobel 与 Prewitt 的幅值差下限，防止两个函数写成同一个
```

调用行：

```matlab
fprintf("\n【边缘检测】\n");
failureCount = failureCount + verifyEdge(IMAGES);
```

- [ ] **Step 2: 写 edgeSobel.m**

```matlab
function [BW, magnitude] = edgeSobel(I, threshold)
%EDGESOBEL 用 Sobel 算子做边缘检测
%
%   Sobel 的两个卷积核为
%       Gx = [-1 0 1; -2 0 2; -1 0 1]      Gy = [-1 -2 -1; 0 0 0; 1 2 1]
%   梯度幅值取 sqrt(Gx^2 + Gy^2)。阈值按相对量给：大于
%   threshold * max(幅值) 的像素判为边缘。
%
%   本函数不做非极大值抑制与细化，因此与 edge() 的结果在边缘宽度上有差异，
%   这是有意的：细化属于另一个处理环节。
%
%   输入
%       I           灰度图矩阵
%       threshold   相对阈值，[0,1]。可选，默认 0.1
%   输出
%       BW          与 I 同尺寸的 logical 边缘图
%       magnitude   与 I 同尺寸的梯度幅值图
%
%   调用示例
%       [BW, mag] = img.edgeSobel(imread("cameraman.tif"), 0.1);

DEFAULT_THRESHOLD = 0.1;
KERNEL_X = [-1, 0, 1; -2, 0, 2; -1, 0, 1];
KERNEL_Y = [-1, -2, -1; 0, 0, 0; 1, 2, 1];

narginchk(1, 2);
if nargin < 2 || isempty(threshold)
    threshold = DEFAULT_THRESHOLD;
end

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "edgeSobel 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end
if threshold < 0 || threshold > 1
    error("matlab_test:badThreshold", ...
        "threshold 必须落在 [0,1] 内，当前为 %g。", threshold);
end

data = double(I);
gradX = conv2(data, KERNEL_X, "same");
gradY = conv2(data, KERNEL_Y, "same");
magnitude = sqrt(gradX.^2 + gradY.^2);

peak = max(magnitude(:));
if peak <= 0
    BW = false(size(I));
    return;
end

BW = magnitude > threshold * peak;
end
```

- [ ] **Step 3: 写 edgePrewitt.m**

```matlab
function [BW, magnitude] = edgePrewitt(I, threshold)
%EDGEPREWITT 用 Prewitt 算子做边缘检测
%
%   Prewitt 与 Sobel 的区别只在核的权重：Prewitt 不做中心行/列的加权，
%   因此对噪声更敏感，但在梯度均匀的区域响应更真实。
%       Gx = [-1 0 1; -1 0 1; -1 0 1]      Gy = [-1 -1 -1; 0 0 0; 1 1 1]
%
%   输入
%       I           灰度图矩阵
%       threshold   相对阈值，[0,1]。可选，默认 0.1
%   输出
%       BW          与 I 同尺寸的 logical 边缘图
%       magnitude   与 I 同尺寸的梯度幅值图
%
%   调用示例
%       [BW, mag] = img.edgePrewitt(imread("cameraman.tif"), 0.1);

DEFAULT_THRESHOLD = 0.1;
KERNEL_X = [-1, 0, 1; -1, 0, 1; -1, 0, 1];
KERNEL_Y = [-1, -1, -1; 0, 0, 0; 1, 1, 1];

narginchk(1, 2);
if nargin < 2 || isempty(threshold)
    threshold = DEFAULT_THRESHOLD;
end

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "edgePrewitt 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end
if threshold < 0 || threshold > 1
    error("matlab_test:badThreshold", ...
        "threshold 必须落在 [0,1] 内，当前为 %g。", threshold);
end

data = double(I);
gradX = conv2(data, KERNEL_X, "same");
gradY = conv2(data, KERNEL_Y, "same");
magnitude = sqrt(gradX.^2 + gradY.^2);

peak = max(magnitude(:));
if peak <= 0
    BW = false(size(I));
    return;
end

BW = magnitude > threshold * peak;
end
```

- [ ] **Step 4: 追加 verifyEdge 局部函数**

```matlab
function nFail = verifyEdge(images)
%VERIFYEDGE 验证两种边缘检测算法，返回未通过的条数

EDGE_THRESHOLD = 0.1;
nFail = 0;

for kk = 1:size(images, 1)
    imgName = images{kk, 1};
    I = images{kk, 2};

    % --- Sobel：梯度幅值与 imgradient 对照 ---
    [BWSobel, magSobel] = img.edgeSobel(I, EDGE_THRESHOLD);
    refMag = imgradient(I, "sobel");
    nFail = nFail + ~reportRow("边缘检测", "Sobel幅值/" + imgName, "相关系数", ...
        corr(magSobel(:), double(refMag(:))), CORR_MIN_GRADIENT, "", "max");

    % 二值图与 edge 对照。edge 的 threshold 是相对最大梯度的比例，口径一致
    refBW = edge(I, "sobel", EDGE_THRESHOLD);
    nFail = nFail + ~reportRow("边缘检测", "Sobel二值/" + imgName, "Jaccard", ...
        jaccard(BWSobel, refBW), JACCARD_MIN_EDGE, "", "max");
    nFail = nFail + ~reportRow("边缘检测", "Sobel二值/" + imgName, "Dice", ...
        dice(BWSobel, refBW), DICE_MIN_EDGE, "", "max");

    % --- Prewitt ---
    [BWPrewitt, magPrewitt] = img.edgePrewitt(I, EDGE_THRESHOLD);
    refMagP = imgradient(I, "prewitt");
    nFail = nFail + ~reportRow("边缘检测", "Prewitt幅值/" + imgName, "相关系数", ...
        corr(magPrewitt(:), double(refMagP(:))), CORR_MIN_GRADIENT, "", "max");

    refBWP = edge(I, "prewitt", EDGE_THRESHOLD);
    nFail = nFail + ~reportRow("边缘检测", "Prewitt二值/" + imgName, "Jaccard", ...
        jaccard(BWPrewitt, refBWP), JACCARD_MIN_EDGE, "", "max");
    nFail = nFail + ~reportRow("边缘检测", "Prewitt二值/" + imgName, "Dice", ...
        dice(BWPrewitt, refBWP), DICE_MIN_EDGE, "", "max");

    % --- 两种算子的权重不同，梯度幅值应当有可见差异，防止两个函数写成同一个 ---
    magDiff = mean(abs(magSobel(:) - magPrewitt(:)));
    nFail = nFail + ~reportRow("边缘检测", "算子区分度/" + imgName, "幅值差", ...
        magDiff, MIN_OPERATOR_DIFF, "", "max");
end
end
```

- [ ] **Step 5: 跑验证**

Run:
```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "run('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform/verifyAlgorithms.m')"
```

Expected: 「【边缘检测】」段全部 `true`。

若 Jaccard 低于 0.85，先确认 `edge` 的 threshold 口径：它对 Sobel 是相对最大梯度幅值的比例，与手写版一致；差异主要来自 `edge` 的细化步骤（把梯度脊线压成一个像素宽）。可以在 `verifyEdge` 里给 `edge(..., "nothinning")` 再比一次，作为诊断信息打印，但判定仍用细化版。

- [ ] **Step 6: 提交**

```bash
git add hw04-imageGeometry/platform
git commit -m "feat: 边缘检测类算法（Sobel、Prewitt）并通过验证"
```

---

## Task 8: 特征提取类

**Files:**
- Create: `hw04-imageGeometry/platform/+img/featHOG.m`
- Create: `hw04-imageGeometry/platform/+img/featLBP.m`
- Modify: `hw04-imageGeometry/platform/verifyAlgorithms.m`

**Interfaces:**
- Consumes: `reportRow`
- Produces:
  - `feat = img.featHOG(I, cellSize, numBins)` — 返回 HOG 特征行向量
  - `feat = img.featLBP(I, numNeighbors)` — 返回 LBP 直方图行向量

- [ ] **Step 1: 追加调用行，并在验证函数开头声明阈值常量**

```matlab
CORR_MIN_FEATURE = 0.99;   % 特征描述子的相关系数
```

调用行：

```matlab
fprintf("\n【特征提取】\n");
failureCount = failureCount + verifyFeature(IMAGES);
```

- [ ] **Step 2: 查 extractHOGFeatures 的归一化口径**

**不允许凭记忆写。** 先跑官方文档确认分块归一化方案，把结论写进 `featHOG.m` 的注释：

```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "doc extractHOGFeatures"
```

若 `doc` 在 `-batch` 下打不开，改用：

```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "help extractHOGFeatures"
```

已知的默认参数（已确认）：`CellSize` 为 `[8 8]`，`BlockSize` 为 `[2 2]`，
`BlockOverlap` 为 `ceil(BlockSize/2)`，`NumBins` 为 `9`，`UseSignedOrientation` 为 `false`。

- [ ] **Step 3: 写 featHOG.m**

```matlab
function feat = featHOG(I, cellSize, numBins)
%FEATHOG 提取方向梯度直方图（HOG）特征
%
%   流程：
%     1. 用中心差分求每个像素的水平、垂直梯度；
%     2. 按 cellSize 划格，每格内按梯度方向投票到 numBins 个方向区间，
%        票权用梯度幅值。无符号方向（0 到 180 度）时方向区间跨 180/numBins 度；
%     3. 每 2×2 个 cell 组成一个 block，block 之间重叠一半；
%     4. 每个 block 内的四个 cell 直方图拼起来做 L2 归一化，再拼成最终特征。
%
%   输入
%       I           灰度图矩阵
%       cellSize    cell 边长，可选，默认 8
%       numBins     方向区间数，可选，默认 9
%   输出
%       feat        1×N 的行向量
%
%   调用示例
%       feat = img.featHOG(imread("cameraman.tif"), 8, 9);

DEFAULT_CELL_SIZE = 8;
DEFAULT_NUM_BINS  = 9;
BLOCK_CELLS       = 2;
NORMALIZE_EPS     = 1e-6;

narginchk(1, 3);
if nargin < 2 || isempty(cellSize)
    cellSize = DEFAULT_CELL_SIZE;
end
if nargin < 3 || isempty(numBins)
    numBins = DEFAULT_NUM_BINS;
end

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "featHOG 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end

data = double(I);

% 中心差分梯度
gradX = zeros(size(data));
gradY = zeros(size(data));
gradX(:, 2:end-1) = (data(:, 3:end) - data(:, 1:end-2)) / 2;
gradY(2:end-1, :) = (data(3:end, :) - data(1:end-2, :)) / 2;

magnitude = sqrt(gradX.^2 + gradY.^2);
% 无符号方向：落在 [0, 180) 度
orientation = mod(atan2d(gradY, gradX), 180);

[imageH, imageW] = size(data);
numCellsY = floor(imageH / cellSize);
numCellsX = floor(imageW / cellSize);

% 每格的直方图，尺寸 [numBins, numCellsY, numCellsX]
cellHist = zeros(numBins, numCellsY, numCellsX);
binWidth = 180 / numBins;

for cellY = 1:numCellsY
    for cellX = 1:numCellsX
        rows = (cellY - 1) * cellSize + (1:cellSize);
        cols = (cellX - 1) * cellSize + (1:cellSize);
        cellMag = magnitude(rows, cols);
        cellOri = orientation(rows, cols);

        binIdx = floor(cellOri / binWidth) + 1;
        binIdx = min(max(binIdx, 1), numBins);

        % 用累加数组替代内层循环：把每个像素的票权加到对应 bin
        flatIdx = binIdx(:) + numBins * 0;
        cellHist(:, cellY, cellX) = accumarray(flatIdx, cellMag(:), [numBins, 1]);
    end
end

% 逐 block 做 L2 归一化后拼接
numBlockY = numCellsY - BLOCK_CELLS + 1;
numBlockX = numCellsX - BLOCK_CELLS + 1;
if numBlockY < 1 || numBlockX < 1
    error("matlab_test:imageTooSmall", ...
        "图像 %d×%d 太小，按 cellSize=%d 切不出一个 %d×%d 的 block。请换大图或调小 cellSize。", ...
        imageH, imageW, cellSize, BLOCK_CELLS, BLOCK_CELLS);
end

blockFeat = zeros(numBlockY * numBlockX, numBins * BLOCK_CELLS^2);
blockIdx = 0;
for blockY = 1:numBlockY
    for blockX = 1:numBlockX
        blockIdx = blockIdx + 1;
        rows = blockY : blockY + BLOCK_CELLS - 1;
        cols = blockX : blockX + BLOCK_CELLS - 1;
        block = reshape(cellHist(:, rows, cols), [], 1);

        % L2 归一化
        blockFeat(blockIdx, :) = block' / sqrt(sum(block.^2) + NORMALIZE_EPS^2);
    end
end

feat = reshape(blockFeat', 1, []);
end
```

- [ ] **Step 4: 写 featLBP.m**

```matlab
function feat = featLBP(I, numNeighbors)
%FEATLBP 提取局部二值模式（LBP）直方图特征
%
%   对每个像素，取以它为中心、半径 1 的圆环上 numNeighbors 个采样点
%   （用双线性插值取灰度），与中心像素比较，大于等于记 1，否则记 0，
%   按固定顺序拼成一个 numNeighbors 位的二进制数作为该像素的 LBP 码，
%   最后统计整幅图的 LBP 码直方图。
%
%   输入
%       I               灰度图矩阵
%       numNeighbors    圆环采样点数，可选，默认 8
%   输出
%       feat            1×(2^numNeighbors) 的直方图行向量，已归一化
%
%   调用示例
%       feat = img.featLBP(imread("cameraman.tif"), 8);

DEFAULT_NUM_NEIGHBORS = 8;
RADIUS = 1;

narginchk(1, 2);
if nargin < 2 || isempty(numNeighbors)
    numNeighbors = DEFAULT_NUM_NEIGHBORS;
end

if ~ismatrix(I)
    error("matlab_test:notGrayscale", ...
        "featLBP 只接受二维灰度图，当前输入是 %d 维。", ndims(I));
end
if numNeighbors < 1 || numNeighbors > 16 || mod(numNeighbors, 1) ~= 0
    error("matlab_test:badNeighbors", ...
        "numNeighbors 必须是 1 到 16 的整数，当前为 %g。", numNeighbors);
end

data = double(I);
[imageH, imageW] = size(data);
code = zeros(imageH - 2 * RADIUS, imageW - 2 * RADIUS);

% 预分配各采样点的偏移，按固定顺序排列
offsets = zeros(numNeighbors, 2);
for nn = 1:numNeighbors
    angle = 2 * pi * (nn - 1) / numNeighbors;
    offsets(nn, :) = [cos(angle), -sin(angle)] * RADIUS;
end

for rowIdx = 1:size(code, 1)
    for colIdx = 1:size(code, 2)
        centerRow = rowIdx + RADIUS;
        centerCol = colIdx + RADIUS;
        centerValue = data(centerRow, centerCol);

        % 圆环上的采样点用双线性插值取灰度
        sampleRow = centerRow + offsets(:, 2);
        sampleCol = centerCol + offsets(:, 1);
        sampled = interp2(data, sampleCol, sampleRow, "linear");

        bits = sampled(:)' >= centerValue;
        code(rowIdx, colIdx) = bits * (2.^(numNeighbors-1:-1:0)');
    end
end

counts = histcounts(code(:), -(0.5) : 1 : (2^numNeighbors - 0.5));
feat = counts / sum(counts);
end
```

- [ ] **Step 5: 追加 verifyFeature 局部函数**

```matlab
function nFail = verifyFeature(images)
%VERIFYFEATURE 验证两种特征提取算法，返回未通过的条数

CELL_SIZE     = 8;
NUM_BINS      = 9;
NUM_NEIGHBORS = 8;
nFail = 0;

for kk = 1:size(images, 1)
    imgName = images{kk, 1};
    I = images{kk, 2};

    % --- HOG：与 extractHOGFeatures 对照，参数显式对齐默认值 ---
    featOurs = img.featHOG(I, CELL_SIZE, NUM_BINS);
    featRef  = extractHOGFeatures(I, "CellSize", [CELL_SIZE, CELL_SIZE], ...
        "BlockSize", [2, 2], "NumBins", NUM_BINS, "UseSignedOrientation", false);

    if numel(featOurs) ~= numel(featRef)
        error("matlab_test:featureLengthMismatch", ...
            "featHOG 返回 %d 维，extractHOGFeatures 返回 %d 维。先对齐 cell/block 切分口径。", ...
            numel(featOurs), numel(featRef));
    end
    nFail = nFail + ~reportRow("特征提取", "HOG/" + imgName, "相关系数", ...
        corr(featOurs(:), double(featRef(:))), CORR_MIN_FEATURE, "", "max");

    % --- LBP：与 extractLBPFeatures 对照 ---
    featLbpOurs = img.featLBP(I, NUM_NEIGHBORS);
    featLbpRef  = extractLBPFeatures(I, "NumNeighbors", NUM_NEIGHBORS, ...
        "Upright", true);
    nFail = nFail + ~reportRow("特征提取", "LBP/" + imgName, "相关系数", ...
        corr(featLbpOurs(:), double(featLbpRef(:))), CORR_MIN_FEATURE, "", "max");
end
end
```

- [ ] **Step 6: 跑验证**

Run:
```bash
cd /tmp && /Applications/MATLAB_R2025b.app/bin/matlab -batch "run('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform/verifyAlgorithms.m')"
```

Expected: 「【特征提取】」段 4 行全部 `true`。

HOG 的特征维数必须先对上。若维数不一致，查 `numCellsY`、`numBlockY` 的取整方向；`extractHOGFeatures` 会丢弃右侧、底部不足一个 cell 的余量，手写版按 `floor` 处理应一致。

`extractLBPFeatures` 返回的直方图长度可能与 `2^numNeighbors` 不同（它可能只统计均匀模式），若如此，改用 `img.featLBP` 与 `extractLBPFeatures` 都支持的公共口径，并在两者注释里写明差异。

- [ ] **Step 7: 提交**

```bash
git add hw04-imageGeometry/platform
git commit -m "feat: 特征提取类算法（HOG、LBP）并通过验证"
```

---

## Task 9: 真实照片复验与文档收尾

前 8 个任务都在 MATLAB 内置图上验证。这一步换题目自己的照片，确认在真实输入上也成立。

**Files:**
- Modify: `hw04-imageGeometry/platform/verifyAlgorithms.m`
- Modify: `hw04-imageGeometry/platform/README.md`
- Modify: `hw04-imageGeometry/notes.md`

**Interfaces:**
- Consumes: 全部 16 个算法
- Produces: 无新接口

- [ ] **Step 1: 把真实照片加入测试集**

照片是彩色的，验证前先转灰度。把 `verifyAlgorithms.m` 里原有的 `IMAGES` 定义整块替换成：

```matlab
% 真实照片（彩色转灰度）。路径用 mfilename 定位，与 hw04_process0.m 同一套做法
photoPath = fullfile(fileparts(mfilename("fullpath")), "..", "photo.jpg");

% 每个分支里一次把测试集构造完，不用 end+1 逐步扩数组
if isfile(photoPath)
    IMAGES = { ...
        "cameraman", imread("cameraman.tif"); ...
        "rice",      imread("rice.png"); ...
        "photo",     rgb2gray(imread(photoPath))};
else
    fprintf("提示: 未找到 %s，本次跳过真实照片复验\n", photoPath);
    IMAGES = { ...
        "cameraman", imread("cameraman.tif"); ...
        "rice",      imread("rice.png")};
end
```

注意照片是 5513×3971，`histClahe` 和 `filterMedian` 在这个尺寸上会明显变慢。若单次运行超过 5 分钟，在 `IMAGES` 构造时就把照片缩到千像素级：

```matlab
        "photo",     img.geomScale(rgb2gray(imread(photoPath)), [1024, 738], "bilinear")};
```

并把「为控制验证耗时，真实照片降到 1024×738 再验」写进该行注释。

- [ ] **Step 2: 跑全量验证**

Run:
```bash
cd /tmp && time /Applications/MATLAB_R2025b.app/bin/matlab -batch "run('/Users/charliepan/Downloads/matlab_test/hw04-imageGeometry/platform/verifyAlgorithms.m')"
```

Expected: 全部段落每行 `true`，最后打印「全部通过」，退出码 0。记录总耗时。

- [ ] **Step 3: 更新 README 的算法清单**

在 `README.md` 的目录一节后追加：

```markdown
## 算法清单

| 类别 | 实现 1 | 实现 2 | 工具箱对照 |
|---|---|---|---|
| 几何变换 | `geomRotate` 逆映射旋转 | `geomScale` 双线性缩放 | `imrotate` / `imresize` |
| 灰度变换 | `grayLinearStretch` 线性拉伸 | `grayGamma` 幂律变换 | `imadjust` |
| 直方图均衡 | `histEqualize` 全局 CDF | `histClahe` 分块自适应 | `histeq` / `adapthisteq` |
| 空域滤波 | `filterMean` 均值 | `filterMedian` 中值 | `imfilter` / `medfilt2` |
| 频域滤波 | `freqIdealLP` 理想低通 | `freqButterLP` 巴特沃斯低通 | 无直接对照，用性质验证 |
| 边缘检测 | `edgeSobel` | `edgePrewitt` | `edge` / `imgradient` |
| 阈值分割 | `threshOtsu` | `threshIterative` 迭代法 | `otsuthresh` |
| 特征提取 | `featHOG` | `featLBP` | `extractHOGFeatures` / `extractLBPFeatures` |
```

- [ ] **Step 4: 把验证结论写进 notes.md**

在 `hw04-imageGeometry/notes.md` 末尾追加一节，记下：

- 每个算法的实测指标（从验证脚本的输出直接抄）
- 哪些算法与工具箱完全一致，哪些只能近似，各自的差异来源
- 阈值的最终取值，以及有没有发生「实测与预期差距大」的情况；若发生了，是实现错了还是阈值不合理

这一节是本作业「验证算法的正确性」这条要求的文字交付物，不能省。

- [ ] **Step 5: 提交**

```bash
git add hw04-imageGeometry/platform hw04-imageGeometry/notes.md
git commit -m "docs: 真实照片复验通过，补齐平台 README 与验证结论"
```

---

## 计划的验收标准

对照 spec 的验收标准：

1. 16 个算法实现全部可调用，`verifyAlgorithms.m` 退出码 0 → Task 1~9 每步的 Expected 覆盖
2. 对照表里每个算法的实测指标都在阈值之上 → `reportRow` 的判定与末尾 `failureCount` 汇总覆盖
3. 在 `cameraman.tif`、`rice.png`、`photo.jpg` 三种输入上都成立 → Task 9 Step 1~2
4. 每个函数有 H1 行 + 功能说明 + 输入输出 + 一个调用示例 → Global Constraints 覆盖
5. 跑通即按 `git.md` 的粒度提交 → 每个 Task 的最后一步
