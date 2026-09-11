function ft = fourierSquarePartial(t, N, T)
%FOURIERSQUAREPARTIAL 周期矩形波傅里叶级数展开截断到第 N 次谐波的近似式。
%
%   ft = fourierSquarePartial(t, N, T) 返回周期矩形波（前半周期 +1、后半周期 -1，
%   周期为 T）的傅里叶级数截断近似值。该波形的展开式只有奇次正弦项，
%       f(t) = (4/pi) * sum_{n 为奇数} sin(n*w0*t) / n,    w0 = 2*pi/T
%   截断到第 N 次谐波，即保留 1、3、5、… 中所有不超过 N 的奇次项，共
%   ceil(N/2) 个非零项。偶次项系数本就为零，不占项数。
%   输入
%       t - 时刻数组，单位与 T 一致
%       N - 正整数，截断的最高谐波次数
%       T - 周期，正标量，单位与 t 一致
%   输出
%       ft - 与 t 同尺寸的数组，为截断近似值
%
%   示例
%       t = linspace(0, 3, 601);
%       plot(t, fourierSquarePartial(t, 3, 1))   % 保留 1、3 次谐波

omega0 = 2 * pi / T;
harmonicOrder = 1:2:N;              % 保留下来的奇次谐波次数：不超过 N 的奇数

% 相位矩阵为 (numel(t) x numel(harmonicOrder))，一次算完全部谐波后按 1/n 加权
% 求和，避免对各次谐波写循环。t(:) 是列、harmonicOrder 是行，借助隐式扩展生成
% 相位矩阵；sum(..., 2) 沿谐波维度求和，得到与 t 同尺寸的近似值。
phase = t(:) * (harmonicOrder * omega0);
ft = (4 / pi) * sum(sin(phase) ./ harmonicOrder, 2);
ft = reshape(ft, size(t));
end
