# 作业四提高部分 · 图像处理实验平台设计

日期：2026-09-15
状态：**设计已确认** —— 本轮只做子项目 A（算法库）与 B（正确性验证）
上游文档：[2026-09-11-homework-structure-design.md](2026-09-11-homework-structure-design.md)

## 背景

作业四（`4_工程软件应用能力在数字图像处理中的应用.md`）的「提高要求」是一道加分选做
题，共 5 条：

1. 梳理图像处理核心知识点，定出平台展示的算法；8 类算法每类至少 2 种实现方法，并验证
   算法正确性；
2. 用 MATLAB 编程设计功能完善的图像处理实验平台，界面可选 App Designer 或 GUI；
3. 至少支持 BMP、JPG/JPEG、PNG、TIFF、GIF 五种格式的导入导出；
4. 平台各算法输出结果与 MATLAB 图像处理工具箱函数输出「视觉无明显差异」；
5. 自动化实验步骤记录、处理结果对比、实验报告自动生成。

基础要求部分已完成并提交，见 `hw04-imageGeometry/`。

## 范围

本轮实现 **A（算法库）+ B（正确性验证）**。理由是这两块是其余一切的地基，也是第 1 条与
第 4 条的实体，先做能在早期就看出方向对不对。C（格式兼容）、D（GUI 平台）、E（报告生成）
留到下一轮，本文档末尾记下它们的接口约定，避免 A、B 的签名返工。

## 架构决策

### 1. 界面用程序化 uifigure，不用 App Designer 的 .mlapp

实测 `.mlapp` 是 Zip 包，内部结构为：

```
[Content_Types].xml
appdesigner/appModel.mat          <- 二进制
matlab/document.xml               <- 代码藏在这里
metadata/appScreenshot.png
```

它入库后是一个二进制块，改一个控件位置就整个文件重写，git 无法 diff、冲突无法合并。
本项目一贯的约定是可读的普通 `.m`，两者冲突。作业原文写「可视化交互界面可选用 MATLAB
App Designer 或 GUI 设计」，程序化 GUI 属于后者，合规。

### 2. 用包目录分层，不写 addpath

CLAUDE.md 的铁律是「函数与脚本同目录，不要写 addpath」。16 个算法平铺会让 `platform/`
膨胀到 20 个以上文件。实测能否用包目录分层（`-batch` 从 `/tmp` 发起，脚本内打印 cwd）：

| 目录形式 | 调用 | 结果 |
|---|---|---|
| `+img/hello.m` | `img.hello()` | 解析成功 |
| `plain/helloPlain.m` | `helloPlain()` | `MATLAB:UndefinedFunction` |

同时测出 `run()` 会把 cwd 改到脚本所在目录并留在那里：从 `/tmp` 发起 `run()`，脚本内
`pwd` 是脚本所在目录。所以「编辑器点运行」与「`-batch` 里 `run()`」两种方式下，包目录
都能解析。

结论：算法放 `+img/`，格式兼容放 `+imgio/`，调用写成 `img.geomRotate(...)`。**不写
`addpath`，也不写 `savepath`。**

### 3. 算法全部手写

第 4 条要求「平台算法输出与工具箱函数输出视觉无明显差异」，这句话只有在自己实现了算法
的前提下才有意义（直接调工具箱则恒等成立）。所以 8 类算法每类的 2 种实现都由本平台自己
写，工具箱函数只用作对照基准。

## 算法清单

每类的两个实现在类别内互为交叉验证，同时各有一个工具箱对照基准。

| 类别 | 实现 1 | 实现 2 | 工具箱对照 |
|---|---|---|---|
| 几何变换 | `geomRotate` 逆映射旋转 | `geomScale` 双线性缩放 | `imrotate` / `imresize` |
| 灰度变换 | `grayLinearStretch` 线性拉伸 | `grayGamma` 幂律变换 | `imadjust` |
| 直方图均衡 | `histEqualize` 全局 CDF | `histClahe` 分块自适应 | `histeq` / `adapthisteq` |
| 空域滤波 | `filterMean` 均值 | `filterMedian` 中值 | `imfilter` / `medfilt2` |
| 频域滤波 | `freqIdealLP` 理想低通 | `freqButterLP` 巴特沃斯低通 | `fft2` 配合高斯低通 |
| 边缘检测 | `edgeSobel` | `edgePrewitt` | `edge` |
| 阈值分割 | `threshOtsu` | `threshIterative` 迭代法 | `otsuthresh` |
| 特征提取 | `featHOG` | `featLBP` | `extractHOGFeatures` / `extractLBPFeatures` |

### 函数签名约定

统一为「第一个参数是图像，其后是参数，返回值是处理结果」，便于将来 GUI 用统一的
`feval` 派发：

```matlab
out = img.geomRotate(I, angle, method)
out = img.geomScale(I, targetSize, method)
out = img.grayLinearStretch(I, lowIn, highIn)
out = img.grayGamma(I, gamma)
out = img.histEqualize(I, numLevels)
out = img.histClahe(I, numTiles, clipLimit)
out = img.filterMean(I, kernelSize)
out = img.filterMedian(I, kernelSize)
out = img.freqIdealLP(I, cutoff)
out = img.freqButterLP(I, cutoff, order)
out = img.edgeSobel(I, threshold)
out = img.edgePrewitt(I, threshold)
out = img.threshOtsu(I)
out = img.threshIterative(I, tol)
feat = img.featHOG(I, cellSize, numBins)
feat = img.featLBP(I, numNeighbors)
```

**返回值分三类**，共 16 个：

| 返回类型 | 函数 | 个数 | GUI 怎么展示 |
|---|---|---|---|
| 灰度/RGB 图像矩阵 | `geomRotate` … `freqButterLP` | 10 | `imshow` |
| 二值图（logical） | `edgeSobel`、`edgePrewitt`、`threshOtsu`、`threshIterative` | 4 | `imshow` |
| 特征向量 | `featHOG`、`featLBP` | 2 | `plot` |

前 14 个都能直接 `imshow`，只有后 2 个要换成 `plot`。GUI 需要按此分类决定展示方式，
约定写进每个函数的 H1 行注释里。

## 验证方案（子项目 B）

### 测试图像

用 MATLAB 内置图像，不依赖外部文件：`cameraman.tif`（灰度，512×512）、`peppers.png`
（彩色，转灰度后用）、`rice.png`（有噪声，适合滤波与分割）。另外用 `hw04-imageGeometry/photo.jpg`
跑一遍，确认在真实照片上也成立。

### 指标按算法类型分开

不同算法的「正确」含义不同，硬套一个指标会得到误导性的结论：

| 算法类型 | 涉及算法 | 指标 | 理由 |
|---|---|---|---|
| 数学上等价的 | `threshOtsu` | 逐位相等 | 同一算法的确定性实现，应完全一致 |
| 图像重建类 | 几何、灰度、直方图、空域、频域 | `psnr` + `ssim` | 关心逐像素差异与结构相似度 |
| 二值输出类 | `edgeSobel`、`edgePrewitt`、`threshIterative` | `jaccard` + `dice` | 二值图看重叠度，PSNR 无意义 |
| 特征描述类 | `featHOG`、`featLBP` | 向量相关系数 | 输出不是图像 |

### 阈值与断言

**实施修正（2026-09-15）**：本文档初稿写的是「顶部集中定义阈值常量」，实测发现做不到
——MATLAB 脚本的局部函数有独立工作区，读不到脚本体里的变量（脚本里定义常量后，局部
函数内 `exist("常量名", "var")` 返回 `0`）。改为每个类别的阈值常量声明在使用它的
`verifyXxx` 局部函数开头。另外失败不再立即 `error`，而是记录后继续跑完所有算法，末尾
按 `failureCount` 统一报错，这样一次运行能看到全部未通过项。

阈值常量用 `UPPER_SNAKE_CASE` 命名，未达标时打印实测值与阈值的差：

```matlab
PSNR_MIN_GEOMETRY  = 30;    % 几何变换，插值实现细节不同，放宽
SSIM_MIN_GEOMETRY  = 0.95;
PSNR_MIN_POINTWISE = 60;    % 灰度变换与全局直方图均衡，逐像素 LUT 映射，理论上应与
                            % 工具箱逐位一致。实测正确实现 PSNR = Inf / 72.03 dB；
                            % 把 round 换成 floor 的 bug 是 51.21 dB，取 60 能拦下
SSIM_MIN_POINTWISE = 0.999;
...
JACCARD_MIN_EDGE   = 0.85;  % 边缘检测，边界处理与细化策略不同
CORR_MIN_FEATURE   = 0.99;  % 特征描述子
```

**阈值的定法**：先按算法性质给出理论预期值，实现完成后实测，若实测与预期差距大，先查是
实现错了还是阈值定得不合理，把结论写进注释。不允许为了让断言通过而调阈值，除非能说清
差异的来源（例如 `medfilt2` 在边界上的填充策略与手写实现不同）。这条要落到
`notes.md` 里。

**这套阈值的已知盲区（2026-09-15 实测）**：PSNR 与 SSIM 两条都拦不住「只影响少量像素」
的细微实现错误。以 5% 的像素差 1 个灰阶为例，PSNR 约 61 dB、SSIM 约 0.9997，两条都会放
过。它们能拦住的是影响面较大的错误（实测：`floor` 替 `round` 影响 49% 的像素，PSNR
51.21 dB、SSIM 0.9974，两条都拦下）。若要堵住这个盲区，需要对「正确实现应当逐位相等」
的类别再加一条 `max|差|` 硬断言，本轮未加。

## 目录结构（本轮）

```
hw04-imageGeometry/platform/
├── README.md                  平台说明、运行方式、依赖的工具箱
├── verifyAlgorithms.m         验证脚本，跑完打印对照表
├── +img/                      16 个算法实现
│   ├── geomRotate.m           geomScale.m
│   ├── grayLinearStretch.m    grayGamma.m
│   ├── histEqualize.m         histClahe.m
│   ├── filterMean.m           filterMedian.m
│   ├── freqIdealLP.m          freqButterLP.m
│   ├── edgeSobel.m            edgePrewitt.m
│   ├── threshOtsu.m           threshIterative.m
│   └── featHOG.m              featLBP.m
└── +imgio/                    格式兼容（本轮只建接口，C 阶段实现）
    ├── imLoad.m
    ├── imSave.m
    └── supportedFormats.m
```

`imgPlatform.m`（GUI 入口）、`buildReport.m`（报告生成）、`report/` 目录留到 D、E 阶段
再建，不提前建。

## 验收标准（本轮）

1. 16 个算法实现全部可调用，`verifyAlgorithms.m` 退出码 0；
2. 验证脚本输出的对照表里每个算法的实测指标都在阈值之上；
3. 在 `cameraman.tif`、`rice.png`、`photo.jpg` 三种输入上都成立；
4. 每个函数有 H1 行 + 功能说明 + 输入输出 + 一个调用示例；
5. 跑不通的状态用 `wip:` 前缀提交，跑通即按 `git.md` 的粒度提交。

## 风险

**边界填充策略不一致。** 手写滤波与 `imfilter`、手写旋转与 `imrotate` 在图像边界上的
处理很容易不同，这是 PSNR 不达标最常见的原因，且不一定是实现错了。对策是把填充策略
做成显式参数并写进注释，对比时先对齐填充方式再比数值。

**`histClahe` 的实现复杂度。** `adapthisteq` 的分块数、剪裁限幅、块间双线性插值三个
参数耦合，手写版本很难与工具箱完全一致。这个算法的阈值要放宽，并在注释里说明差异来源。

**`featHOG` 的归一化口径。** HOG 的分块归一化方案有多种，工具箱的具体口径需要查文档
确认，不能凭记忆写。

## 后续阶段（C、D、E）的接口约定

先记下，避免 A、B 的签名返工。

- **C 格式兼容**：`+imgio/imLoad.m` 返回 `[I, map, alpha, info]`，`imSave.m` 签名
  `imSave(I, path, quality)`。第 3 条要求「小于 4096×4096 导入成功率 100%」，验证时用
  5 种格式各生成一张测试图，往返读写后比对像素是否无损。
- **D GUI**：`imgPlatform.m` 用 `uifigure` + `uigridlayout` 搭界面，参数控件按算法动态
  生成与销毁。算法调用统一走 `feval("img." + fcnName, I, params{:})`。
- **E 报告**：`buildReport.m` 生成 Markdown，图片以相对路径引用，不内嵌 base64（内嵌会
  让文件膨胀且 git 每次都整文件重写，与 2026-09-11 废弃 Live Script 的理由相同）。
