% 验证 +img/ 里手写算法与 MATLAB 图像处理工具箱输出的一致性
%
% 运行：在编辑器里点运行，或
%   matlab -batch "run('hw04-imageGeometry/platform/verifyAlgorithms.m')"
% 退出码 0 表示全部通过。
%
% 预期结果：命令窗口打印一张对照表，每行一个算法，列出实测指标与阈值。
%          不达标的行紧随一段缩进的失败说明，但脚本继续往下跑完，
%          最后汇总未通过项数并以非零退出码结束。全部达标时打印「全部通过」。
%
% 阈值的定法见 docs/superpowers/specs/2026-09-15-image-platform-design.md。

clear; clc; close all;

% ---------- 判定阈值 ----------
% 阈值常量不放在脚本体里：脚本的局部函数有独立工作区，读不到脚本变量。
% 所以每类算法自己的阈值常量声明在对应 verifyXxx 函数的开头，与 +img 里
% NUM_BINS、下面 reportRow 的 DEFAULT_DIRECTION 是同一种写法。

% ---------- 测试图像 ----------
% cameraman 是双峰直方图的典型；rice 偏亮、直方图偏斜，适合区分两种阈值算法
IMAGES = { ...
    "cameraman", imread("cameraman.tif"); ...
    "rice",      imread("rice.png")};

fprintf("%-10s %-18s %-10s %12s %12s  %-5s %s\n", ...
    "类别", "算法", "指标", "实测", "阈值", "通过", "单位");
fprintf("%s\n", repmat('-', 1, 78));

% 每个验证函数返回它记录的失败条数，在这里累加
failureCount = 0;

fprintf("\n【阈值分割】\n");
failureCount = failureCount + verifyThresholding(IMAGES);

% 后续类别在这里各加一行，形如
%   failureCount = failureCount + verifyIntensity(IMAGES);

if failureCount > 0
    error("matlab_test:verifyFailed", ...
        "共 %d 项验证未通过，逐条明细见上方标了 false 的行。", failureCount);
end

fprintf("\n全部通过\n");

% ==================== 局部函数 ====================

function nFail = verifyThresholding(images)
%VERIFYTHRESHOLDING 验证两种阈值分割算法，返回未通过的条数

OTSUTHRESH_TOL   = 1e-12;   % Otsu 是确定性算法，手写版与工具箱应逐位相等
JACCARD_MIN_BIN  = 0.90;    % 二值分割结果的重叠度

nFail = 0;

for kk = 1:size(images, 1)
    imgName = images{kk, 1};
    I = images{kk, 2};

    % --- Otsu：与 otsuthresh 求出的阈值应逐位相等 ---
    % 「阈值差」越小越好，所以方向传 "min"
    levelRef = otsuthresh(imhist(I, 256));
    [BW, level] = img.threshOtsu(I);
    nFail = nFail + ~reportRow("阈值分割", "Otsu/" + imgName, "阈值差", ...
        abs(level - levelRef), OTSUTHRESH_TOL, "", "min");
    nFail = nFail + ~reportRow("阈值分割", "Otsu/" + imgName, "Jaccard", ...
        jaccard(BW, imbinarize(I, levelRef)), JACCARD_MIN_BIN, "", "max");

    % --- 迭代法：无对应工具箱函数，与 Otsu 的结果比重叠度 ---
    BWIter = img.threshIterative(I);
    nFail = nFail + ~reportRow("阈值分割", "迭代法/" + imgName, "Jaccard", ...
        jaccard(BWIter, BW), JACCARD_MIN_BIN, "", "max");
end
end

function isPass = reportRow(category, algorithm, metricName, value, threshold, unit, direction)
%REPORTROW 打印一行对照结果并判定是否达标，失败时追加一行缩进说明
%
%   不抛错。失败只记录并打印，由调用者累加条数，让整个脚本跑完所有算法后
%   再统一报错——否则第一个算法挂了，后面算法的实测值就看不到了。
%
%   输入
%       category    类别名，如 "阈值分割"
%       algorithm   算法名，如 "Otsu/cameraman"
%       metricName  指标名，如 "Jaccard"
%       value       实测值
%       threshold   阈值
%       unit        单位后缀，如 "dB"，无单位传 ""
%       direction   可选，"max" 表示越大越好（默认），"min" 表示越小越好
%   输出
%       isPass      logical，是否达标

DEFAULT_DIRECTION = "max";

narginchk(6, 7);
if nargin < 7 || strlength(direction) == 0
    direction = DEFAULT_DIRECTION;
end

switch direction
    case "max"
        isPass = value >= threshold;
        relation = "不低于";
    case "min"
        isPass = value <= threshold;
        relation = "不超过";
    otherwise
        error("matlab_test:badDirection", ...
            "direction 只支持 max 或 min，当前为 %s。", direction);
end

fprintf("%-10s %-18s %-10s %12.4f %12.4f  %-5s %s\n", ...
    category, algorithm, metricName, value, threshold, ...
    string(isPass), unit);

if ~isPass
    fprintf("    ^ 未通过: %s 应%s %.4f%s，实测 %.4f%s\n", ...
        metricName, relation, threshold, unit, value, unit);
end
end
