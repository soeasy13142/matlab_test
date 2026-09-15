function out = grayLinearStretch(I, lowIn, highIn)
%GRAYLINEARSTRETCH 把输入灰度区间线性拉伸到整个动态范围
%
%   映射关系为
%       s = (r - lowIn) / (highIn - lowIn) * maxValue
%   小于 lowIn 的压到 0，大于 highIn 的压到 maxValue。
%
%   输入
%       I       灰度图矩阵，uint8 / uint16 / double
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
        "grayLinearStretch 只接受二维灰度图，当前输入是 %d 维，请先用 rgb2gray 转换。", ndims(I));
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
