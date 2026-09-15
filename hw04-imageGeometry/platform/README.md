# 图像处理实验平台

作业四「提高要求」的实体，分两部分：

- **可视化界面** `imgPlatform.m` —— 打开图像、选算法、调参数、并排看结果。
- **算法库** `+img/` —— 手写图像处理算法，各配 MATLAB 图像处理工具箱对照基准。

## 运行

**打开实验平台界面**：在编辑器里打开 `imgPlatform.m` 点运行。

**三支验证脚本**，都在仓库根目录（`matlab_test/`）下执行，退出码 0 表示通过。
`matlab` 没在 PATH 上，先指定二进制路径（与项目 CLAUDE.md 的 Quick Start 同一写法）：

    export MATLAB=/Applications/MATLAB_R2025b.app/bin/matlab

    "$MATLAB" -batch "run('hw04-imageGeometry/platform/verifyAlgorithms.m')"
    "$MATLAB" -batch "run('hw04-imageGeometry/platform/verifyPlatform.m')"
    "$MATLAB" -batch "run('hw04-imageGeometry/platform/verifyPlatformGui.m')"

`run(...)` 里写的是相对路径，所以**要在仓库根目录执行**。换到别处跑就把
路径换成脚本的绝对路径。三者各管一段：

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
- Computer Vision Toolbox 25.2（仅「待实现」的特征提取部分需要，当前 4 个算法只用 IPT）

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
实现后界面会自动点亮 —— 「实现了没有」是**界面与验证脚本**用 `which`
现场探测的（`imgRegistry.m` 只存元数据，不做探测），不写死在表里，
登记表与界面代码都不用改。

## 界面操作

见上级目录的 `notes.md` 的「三、平台界面」一节（本文件在 `platform/` 下，
`notes.md` 在 `hw04-imageGeometry/` 下）。
