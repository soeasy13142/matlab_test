function ft = squareWave(t, T)
%SQUAREWAVE 周期矩形波：一个周期的前半段取 +1，后半段取 -1。
%
%   ft = squareWave(t, T) 返回周期矩形波在 t 各时刻的取值。一个周期定义为
%       f(t) = +1,  0 <= mod(t, T) < T/2
%       f(t) = -1,  T/2 <= mod(t, T) < T
%   周期为 T。跳变点落在 t = k*T/2（k 为整数）处，跳变点上取右极限值，
%   即 t = k*T 处为 +1、t = (k + 1/2)*T 处为 -1。
%
%   输入
%       t - 时刻数组，单位与 T 一致
%       T - 周期，正标量，单位与 t 一致
%   输出
%       ft - 与 t 同尺寸的数组，元素取值为 +1 或 -1
%
%   示例
%       t = linspace(0, 3, 601);
%       plot(t, squareWave(t, 1))
%
%   Requires R2019b+（使用了 arguments 块）

arguments
    t {mustBeNumeric, mustBeReal}
    T (1,1) {mustBeNumeric, mustBeReal, mustBePositive}
end

phase = mod(t, T);      % 把各时刻折合到一个周期 [0, T) 内
ft = ones(size(t));     % 先整段取前半周期的 +1
ft(phase >= T/2) = -1;  % 后半周期翻成 -1
end
