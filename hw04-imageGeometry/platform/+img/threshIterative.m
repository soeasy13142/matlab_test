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
