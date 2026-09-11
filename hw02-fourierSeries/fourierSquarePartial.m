function ft = fourierSquarePartial(t, N, T)
%FOURIERSQUAREPARTIAL 周期矩形波傅里叶级数展开在最高 2N+1 次谐波处截断的近似式。
%
%   ft = fourierSquarePartial(t, N, T) 返回周期矩形波（前半周期 +1、后半周期 -1，
%   周期为 T）的傅里叶级数截断近似值。该波形的展开式只有奇次正弦项，
%       f(t) = (4/pi) * sum_{n 为奇数} sin(n*w0*t) / n,    w0 = 2*pi/T
%   取最高 2N+1 次谐波即保留 n = 1, 3, 5, ..., 2N+1 共 N+1 个非零项。
%   输入
%       t - 时刻数组，单位与 T 一致
%       N - 非负整数，最高谐波次数为 2N+1
%       T - 周期，正标量，单位与 t 一致
%   输出
%       ft - 与 t 同尺寸的数组，为截断近似值
%
%   示例
%       t = linspace(0, 3, 601);
%       plot(t, fourierSquarePartial(t, 3, 1))   % 最高 7 次谐波

omega0 = 2 * pi / T;
harmonicOrder = 1:2:(2*N + 1);      % 保留下来的奇次谐波次数 1, 3, ..., 2N+1

% 相位矩阵为 (numel(t) x numel(harmonicOrder))，一次算完全部谐波后按 1/n 加权
% 求和，避免对各次谐波写循环。t(:) 是列、harmonicOrder 是行，借助隐式扩展生成
% 相位矩阵；sum(..., 2) 沿谐波维度求和，得到与 t 同尺寸的近似值。
phase = t(:) * (harmonicOrder * omega0);
ft = (4 / pi) * sum(sin(phase) ./ harmonicOrder, 2);
ft = reshape(ft, size(t));
end
