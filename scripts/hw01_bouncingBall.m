%[text] # 作业一：自由落体皮球的反弹
%[text] 皮球从 100 m 处自由落下，每次落地后弹起上一次高度的 50%，共弹起 5 次。本脚本调用 `bounceBall` 计算末次弹起高度与总路程，并绘制每次落地的累计路程与弹起高度。

%%
%[text] ## 参数设置

clear; clc; close all;

% 让脚本无论从哪个工作目录运行都能找到 functions/（直接写 addpath("functions")
% 只在当前目录恰为仓库根目录时才有效）
scriptFolder = fileparts(mfilename("fullpath"));
addpath(fullfile(scriptFolder, "..", "functions"));

% ===== 交作业前替换下面这一行 =====
STUDENT_SIGNATURE = "姓名学号";   % 改成「姓名汉字+学号」，如 "小明2121021145"

INITIAL_HEIGHT = 100;      % 初始下落高度，单位 m
NUM_BOUNCE     = 5;        % 弹起次数
DISTANCE_TOL   = 1e-9;     % 浮点相等判定的容差，单位 m

%%
%[text] ## 调用函数
%[text] `bounceBall` 返回末次弹起高度与总路程。总路程算到第 5 次弹起后再次落地的瞬间，因此与右图第 6 个落地点对应。

[lastBounceHeight, totalDistance] = bounceBall(INITIAL_HEIGHT, NUM_BOUNCE)   % 刻意不加分号：本行用于展示结果

%%
%[text] ## 构造绘图数据
%[text] 第 k 次落地时的累计路程，等于初始下落高度加上此前每次「弹起再落下」的两倍弹起高度。弹起 5 次对应落地 6 次。

bounceHeight       = INITIAL_HEIGHT * 0.5 .^ (1:NUM_BOUNCE);            % 第 k 次弹起达到的高度
landingIndex       = 1:(NUM_BOUNCE + 1);                                % 落地次数 1..6
cumulativeDistance = INITIAL_HEIGHT + [0, 2 * cumsum(bounceHeight)];    % 每次落地时的累计路程
riseAfterLanding   = [bounceHeight, 0];                                 % 每次落地后弹起的高度，第 6 次为 0

% 自检：图上最后一个落地点必须等于函数返回的总路程，否则函数与图形口径不一致
assert(abs(cumulativeDistance(end) - totalDistance) < DISTANCE_TOL, ...
    "matlab_test:inconsistentDistance", "累计路程末值与函数返回的总路程不一致");

%%
%[text] ## 绘图
%[text] 左图以落地次数为 x 轴、累计路程为 y 轴，线型 `-s`；右图以落地次数为 x 轴、落地后弹起高度为 y 轴，曲线加标记 `x`。

subplot(1, 2, 1)
plot(landingIndex, cumulativeDistance, "-s")
grid on
xlabel("落地次数")
ylabel("累计经历路程 (m)")
legend("累计路程", "Location", "northwest")
title("累计路程随落地次数变化")

subplot(1, 2, 2)
plot(landingIndex, riseAfterLanding, "-x")
grid on
xlabel("落地次数")
ylabel("落地后弹起高度 (m)")
legend("弹起高度", "Location", "northeast")
title("弹起高度随落地次数变化")

sgtitle("Plot by " + STUDENT_SIGNATURE)

%%
%[text] ## 导出绘图结果
%[text] 以 `.m` 脚本形式交作业时需要单独附上图片，这里一并导出到 `outputs/`，重跑本脚本即可刷新。

outputFolder = fullfile(scriptFolder, "..", "outputs");
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
exportgraphics(gcf, fullfile(outputFolder, "hw01.png"), "Resolution", 150);

%%
%[text] ---
%[text] 作业一 · 基础要求 2

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
