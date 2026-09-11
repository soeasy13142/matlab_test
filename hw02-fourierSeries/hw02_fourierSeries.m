% 作业二：周期信号的傅里叶级数展开与波形逼近
%
% 题目给出的周期信号是一个双极性矩形波（周期为 T）：
%       f(t) = +1,  0 <= t < T/2
%       f(t) = -1,  T/2 <= t < T
% 它是奇函数，又满足半波对称 f(t + T/2) = -f(t)，所以直流分量与全部余弦项都为
% 零，展开后只剩奇次正弦项，且 b_n = 4/(pi*n)（n 为奇数）：
%       f(t) = (4/pi) * [ sin(w0*t) + sin(3*w0*t)/3 + sin(5*w0*t)/5 + ... ],
%       w0 = 2*pi/T
%
% 本脚本做两件事：
%   1. 取最高 2N+1 次谐波（N = 3、10、50、100）得到截断近似式，用 subplot 排成
%      2 行 2 列，观察逼近效果随 N 的变化；
%   2. 取 N = 5，用三维瀑布图与二维叠加图各画一幅，展示基波、各次谐波、合成波
%      与周期矩形波之间的关系。
%
% 预期结果：
%   · 弹出 3 个图形窗口：一幅 2x2 子图、一幅三维瀑布图、一幅二维叠加图；
%   · 2x2 子图中 N 越大波形越贴近矩形波，但跳变点附近的过冲始终存在（吉布斯现象），
%     过冲峰值稳定在 1.179 附近而不随 N 减小；
%   · 命令窗口打印各 N 下的过冲峰值与逼近误差。

clear; clc; close all;

STUDENT_SIGNATURE = "顾皓天0242010213";
PERIOD     = 1;                   % 周期 T，单位 s
NUM_PERIOD = 3;                   % 绘图显示的周期数
NUM_SAMPLE = 30001;               % 采样点数，取 4 的倍数加 1，使跳变点恰好落在网格上。
                                  % 跳变沿附近的振铃宽度仅约 T/(2(2N+1))，网格太疏会
                                  % 低估 RMSE（N=100 时 6001 点偏低约 7%，30001 点约 1%）
N_LIST     = [3, 10, 50, 100];    % 第二问要求的 N 取值
N_3D       = 5;                   % 第三问要求的 N 取值
EDGE_GUARD = 0.02;                % 统计误差时剔除跳变点邻域的半宽，单位 s
Y_LIMIT    = 1.5;                 % 纵轴半幅，需覆盖吉布斯过冲峰值（约 1.179）
SYNTH_TOL  = 1e-9;                % 合成波与截断近似式的一致性判据容差

% 第三问的画图外观：六条谐波靠「线型 + 颜色」两两区分。MATLAB 只有 4 种线型，
% 故线型循环使用，再配以互不相同的颜色。
LINE_STYLE_POOL = {"-", "--", ":", "-."};

t = linspace(0, NUM_PERIOD * PERIOD, NUM_SAMPLE);

% 理想矩形波，作为各幅图的参照波形
ftIdeal = squareWave(t, PERIOD);

% 跳变点 t = k*T/2 的邻域。受吉布斯现象影响，该邻域内的误差不随 N 增大而消失，
% 故统计「最大误差」时把它剔除；均方根误差仍在全区间上统计。
jumpTime = (0 : 2 * NUM_PERIOD) * (PERIOD / 2);
jumpMask = any(abs(t(:) - jumpTime) < EDGE_GUARD, 2)';

% ---------- 第二问：N = 3、10、50、100 的 2x2 子图 ----------
figure("Name", "作业二：不同 N 下的傅里叶级数近似");

fprintf("第二问：最高 2N+1 次谐波截断近似的误差指标\n");
fprintf("%4s %10s %12s %14s %16s\n", ...
    "N", "保留项数", "过冲峰值", "全区间RMSE", "边沿外最大误差");

for ii = 1:numel(N_LIST)
    N = N_LIST(ii);
    harmonicOrder = 1:2:(2*N + 1);
    ftApprox = fourierSquarePartial(t, N, PERIOD);

    % 自检：纵轴范围必须覆盖近似波的极值，否则图上的过冲会被裁掉
    assert(max(abs(ftApprox)) < Y_LIMIT, "matlab_test:overshootBeyondLimit", ...
        "近似波极值超出 Y_LIMIT，请把 Y_LIMIT 调大或检查级数系数");

    subplot(2, 2, ii)
    plot(t, ftIdeal, "Color", [0.75, 0.75, 0.75], "LineWidth", 1)
    hold on
    plot(t, ftApprox, "b", "LineWidth", 1.2)
    hold off
    grid on
    xlabel("t")
    ylabel("f(t)")
    ylim([-Y_LIMIT, Y_LIMIT])
    legend("周期矩形波", "傅里叶级数近似", "Location", "northeast")
    title(cellstr(["Fourier series by " + STUDENT_SIGNATURE; ...
                   sprintf("N = %d，最高 %d 次谐波", N, 2*N + 1)]))

    rmseAll   = sqrt(mean((ftApprox - ftIdeal).^2));
    maxErrOut = max(abs(ftApprox(~jumpMask) - ftIdeal(~jumpMask)));
    fprintf("%4d %10d %12.4f %14.6f %16.6f\n", ...
        N, numel(harmonicOrder), max(ftApprox), rmseAll, maxErrOut);
end

% ---------- 第三问：N = 5 的基波、谐波、合成波与矩形波 ----------
omega0        = 2 * pi / PERIOD;
harmonicOrder = 1:2:(2*N_3D + 1);      % 1, 3, ..., 11，共 6 次谐波
numHarmonic   = numel(harmonicOrder);

% 每一行是一条谐波分量，第 k 行对应 harmonicOrder(k) 次谐波，幅值为 4/(pi*n)。
% 行向量与列向量借助隐式扩展一次性算出全部谐波，无需逐条写循环。
harmonicWave = (4 / pi) * sin(harmonicOrder(:) * omega0 * t) ./ harmonicOrder(:);
ftSynth      = sum(harmonicWave, 1);   % 合成波即各谐波分量之和

% 自检：合成波必须与 fourierSquarePartial 在同一 N 下的结果一致，否则说明两条
% 代码路径的谐波次数或加权系数脱节
assert(max(abs(ftSynth - fourierSquarePartial(t, N_3D, PERIOD))) < SYNTH_TOL, ...
    "matlab_test:inconsistentSum", "合成波与截断近似式不一致，请检查谐波次数与加权系数");

COLOR_POOL  = lines(numHarmonic);
LEVEL_SYNTH = max(harmonicOrder) + 2;  % 合成波在谐波次数轴上的摆放位置
LEVEL_IDEAL = max(harmonicOrder) + 4;  % 矩形波在谐波次数轴上的摆放位置

% 三维瀑布图：每次谐波沿「谐波次数」轴分层排开，最上方放合成波与矩形波。
% 两幅图用同一组线型与颜色，可对照着看。
figure("Name", "作业二：N = 5 时基波、谐波与合成波的三维展开");
hold on
for kk = 1:numHarmonic
    plot3(t, harmonicOrder(kk) * ones(size(t)), harmonicWave(kk, :), ...
        LINE_STYLE_POOL{mod(kk - 1, numel(LINE_STYLE_POOL)) + 1}, ...
        "Color", COLOR_POOL(kk, :), "LineWidth", 1.2)
end
plot3(t, LEVEL_SYNTH * ones(size(t)), ftSynth, ...
    "-", "Color", [0, 0, 0], "LineWidth", 2)
plot3(t, LEVEL_IDEAL * ones(size(t)), ftIdeal, ...
    "--", "Color", [0.85, 0.1, 0.1], "LineWidth", 2)
hold off
grid on
xlabel("t")
ylabel("谐波次数 n")
zlabel("f(t)")
yticks([harmonicOrder, LEVEL_SYNTH, LEVEL_IDEAL])
yticklabels([compose("%d 次谐波", harmonicOrder), "合成波", "周期矩形波"])
title(cellstr(["Fourier series by " + STUDENT_SIGNATURE; ...
               sprintf("N = %d，最高 %d 次谐波的三维展开", N_3D, 2*N_3D + 1)]))
legend([compose("%d 次谐波", harmonicOrder), "合成波", "周期矩形波"], ...
    "Location", "northeast")
view(-40, 25)

% 二维叠加图：全部波形画在同一坐标系内，靠线型区分
figure("Name", "作业二：N = 5 时基波、谐波、合成波与矩形波的二维叠加");
hold on
for kk = 1:numHarmonic
    plot(t, harmonicWave(kk, :), ...
        LINE_STYLE_POOL{mod(kk - 1, numel(LINE_STYLE_POOL)) + 1}, ...
        "Color", COLOR_POOL(kk, :), "LineWidth", 1.1)
end
plot(t, ftSynth, "-", "Color", [0, 0, 0], "LineWidth", 2)
plot(t, ftIdeal, "--", "Color", [0.85, 0.1, 0.1], "LineWidth", 2)
hold off
grid on
xlabel("t")
ylabel("f(t)")
ylim([-Y_LIMIT, Y_LIMIT])
title(cellstr(["Fourier series by " + STUDENT_SIGNATURE; ...
               sprintf("N = %d 时基波、谐波、合成波与矩形波的二维叠加", N_3D)]))
legend([compose("%d 次谐波", harmonicOrder), "合成波", "周期矩形波"], ...
    "Location", "northeast")

fprintf("\n第三问：N = %d 时保留的奇次谐波次数为 ", N_3D);
fprintf("%d ", harmonicOrder);
fprintf("，共 %d 项\n", numHarmonic);
