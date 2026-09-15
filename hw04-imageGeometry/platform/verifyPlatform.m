% 检查 imgRegistry.m 的登记表是否自洽
%
% 运行：在编辑器里点运行，或
%   matlab -batch "run('hw04-imageGeometry/platform/verifyPlatform.m')"
% 退出码 0 表示全部通过。
%
% 预期结果：命令窗口逐行打印检查项、期望值与实测值，最后列出已实现的算法。
%          全部通过时打印「全部通过」；不通过时每项下面跟一行缩进说明，
%          末尾汇总未通过项数并以非零退出码结束。
%
% 本脚本只验登记表，不开界面 —— 界面回调没法自动点，人工清单见 notes.md。

clear; clc; close all;

EXPECTED_CATEGORIES = 8;
EXPECTED_PER_CAT    = 2;
VALID_OUTPUTS       = ["image", "binary", "vector"];
VALID_KINDS         = ["slider", "edit", "choice", "size"];

registry = imgRegistry();
failureCount = 0;

% ---------- 类别与数量 ----------
categories       = string({registry.Category});
uniqueCategories = unique(categories, "stable");

failureCount = failureCount + checkEq("类别数", numel(uniqueCategories), EXPECTED_CATEGORIES);
failureCount = failureCount + checkEq("算法总数", numel(registry), ...
    EXPECTED_CATEGORIES * EXPECTED_PER_CAT);

perCategory = zeros(numel(uniqueCategories), 1);
for kk = 1:numel(uniqueCategories)
    perCategory(kk) = nnz(categories == uniqueCategories(kk));
end
failureCount = failureCount + checkEq("每类算法数（最小值）", ...
    min(perCategory), EXPECTED_PER_CAT);

% ---------- 函数名与输出类型 ----------
fcnNames  = string({registry.Fcn});
badPrefix = nnz(~startsWith(fcnNames, "img."));
failureCount = failureCount + checkEq("Fcn 前缀不合规条数", badPrefix, 0);

% 重名会让「已实现」计数重复，界面上还会多出一个同名按钮
duplicateFcn = numel(fcnNames) - numel(unique(fcnNames));
failureCount = failureCount + checkEq("Fcn 重名条数", duplicateFcn, 0);

badOutput = nnz(~ismember(string({registry.Output}), VALID_OUTPUTS));
failureCount = failureCount + checkEq("Output 取值不合规条数", badOutput, 0);

% ---------- 参数定义 ----------
badKind          = 0;
badRange         = 0;
missingOptions   = 0;
badChoiceDefault = 0;

for kk = 1:numel(registry)
    params = registry(kk).Params;
    for pp = 1:numel(params)
        p = params{pp};

        if ~ismember(string(p.Kind), VALID_KINDS)
            badKind = badKind + 1;
        end
        % Min / Max 是标量，Default 可能是二元素（size 类），逐元素比
        if isfield(p, "Min") && any(p.Default < p.Min | p.Default > p.Max)
            badRange = badRange + 1;
        end
        if string(p.Kind) == "choice"
            if ~isfield(p, "Options")
                missingOptions = missingOptions + 1;
            elseif ~ismember(string(p.Default), string(p.Options))
                % 默认值打错字的话，界面上表现为下拉框选不中或静默退回第一项
                badChoiceDefault = badChoiceDefault + 1;
            end
        end
    end
end

failureCount = failureCount + checkEq("Kind 取值不合规条数", badKind, 0);
failureCount = failureCount + checkEq("choice 缺 Options 条数", missingOptions, 0);
failureCount = failureCount + checkEq("choice 默认值不在选项里条数", badChoiceDefault, 0);
failureCount = failureCount + checkEq("默认值越界条数", badRange, 0);

% ---------- 实现情况（仅供参考，不算通过与否）----------
implementedNames = strings(numel(registry), 1);
implementedCount = 0;
for kk = 1:numel(registry)
    if ~isempty(which(registry(kk).Fcn))
        implementedCount = implementedCount + 1;
        implementedNames(implementedCount) = registry(kk).Fcn;
    end
end
fprintf("\n已实现 %d/%d 个：%s\n", implementedCount, numel(registry), ...
    strjoin(implementedNames(1:implementedCount), ", "));

if failureCount > 0
    error("matlab_test:verifyPlatformFailed", ...
        "共 %d 项检查未通过，逐条明细见上方标了 false 的行。", failureCount);
end

fprintf("\n全部通过\n");

% ==================== 局部函数 ====================

function nFail = checkEq(label, actual, expected)
%CHECKEQ 打印一项检查并判定是否与期望相等，返回未通过条数（0 或 1）
%
%   不抛错。失败只打印明细，由脚本体累加后在末尾统一报错，
%   这样一次运行能看到全部未通过项。
%
%   输入
%       label       检查项名称
%       actual      实测值
%       expected    期望值
%   输出
%       nFail       未通过条数，0 或 1
%
%   调用示例
%       failureCount = failureCount + checkEq("算法总数", numel(registry), 16);

isPass = isequal(actual, expected);

fprintf("%-24s 期望 %-10s 实测 %-10s %s\n", ...
    label, string(expected), string(actual), string(isPass));

if ~isPass
    fprintf("    ^ 未通过: %s 应为 %s，实测 %s\n", ...
        label, string(expected), string(actual));
end

nFail = ~isPass;
end
