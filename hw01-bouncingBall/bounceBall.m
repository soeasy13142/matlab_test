function [lastBounceHeight, totalDistance] = bounceBall(initialHeight, numBounce)
%BOUNCEBALL 皮球自由落下反复弹起后的最后弹起高度与经过的总路程
%
%   皮球从 initialHeight 米处自由落下，每次落地后反弹回上一次落地前高度的
%   BOUNCE_RATIO 倍，然后再次下落，如此重复 numBounce 次。
%
%   输入：
%     initialHeight - 初始下落高度，正标量，单位米
%     numBounce     - 弹起次数，非负整数标量
%
%   输出：
%     lastBounceHeight - 第 numBounce 次弹起达到的高度，单位米；
%                        numBounce 为 0 时返回 0（球从未弹起）
%     totalDistance    - 从开始下落起，到第 numBounce 次弹起后再次落地的
%                        瞬间为止，球经过的总路程，单位米
%
%   示例：
%     [hei, dist] = bounceBall(100, 5)
%     % hei  = 3.1250
%     % dist = 293.7500

% Requires R2019b+（arguments 输入校验块）

%% 输入校验
% 注意：arguments 块必须是函数体内的第一条语句，任何赋值放在它前面都会
% 使其失去作用（MATLAB 会把 arguments 当成普通函数调用而报语法错），
% 因此这里排在常量定义之前。
arguments
    initialHeight (1,1) double {mustBePositive}
    numBounce     (1,1) double {mustBeNonnegative, mustBeInteger}
end

%% 常量
BOUNCE_RATIO = 0.5;   % 每次弹起高度相对上一次的比例，题目给定 50%

%% 计算
% 第 k 次弹起达到的高度为 initialHeight * BOUNCE_RATIO^k。
% 用幂运算一次算出全部弹起高度，避免逐次循环累乘。
bounceHeight = initialHeight * BOUNCE_RATIO .^ (1:numBounce);

if isempty(bounceHeight)
    % numBounce 为 0：球只下落一次，从未弹起
    lastBounceHeight = 0;
else
    lastBounceHeight = bounceHeight(end);
end

% 总路程 = 第一次下落的高度 + 每次弹起后「上升+下落」的两倍弹起高度。
% sum 对空数组返回 0，因此 numBounce 为 0 时结果为 initialHeight，即只落一次。
totalDistance = initialHeight + 2 * sum(bounceHeight);

end
