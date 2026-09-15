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
