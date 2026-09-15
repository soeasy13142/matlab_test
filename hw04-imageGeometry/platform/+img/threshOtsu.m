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
