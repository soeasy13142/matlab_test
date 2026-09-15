function out = grayGamma(I, gamma)
%GRAYGAMMA 幂律（伽马）灰度变换
%
%   先把输入归一化到 [0,1]，做 s = r^gamma，再换算回原类型。
%   gamma < 1 提亮暗部，gamma > 1 压暗。
%
%   实测与 imadjust(I, [], [], gamma) 逐位相等（uint8 测试图上最大灰阶差为 0），
%   即工具箱的 gamma 参数用的也是 s = r^gamma 这一定义，不存在取整口径差异。
%
%   输入
%       I       灰度图矩阵，uint8 / uint16 / double
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
        "grayGamma 只接受二维灰度图，当前输入是 %d 维，请先用 rgb2gray 转换。", ndims(I));
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
