% 冒烟测试 imgPlatform.m 的界面结构
%
% 运行：在编辑器里点运行，或
%   matlab -batch "run('<仓库根>/hw04-imageGeometry/platform/verifyPlatformGui.m')"
% 退出码 0 表示界面结构符合预期。
%
% 预期结果：程序化构造界面，按控件文字与 Enable 状态断言结构，然后关闭窗口。
%          命令窗口逐行打印检查项、期望值与实测值，全部通过时打印「全部通过」。
%
% 覆盖不到的部分：界面长得好不好看、图像显示效果、拖动滑块的手感、
% 报错弹窗的内容 —— 这些要人眼看，见 notes.md 的运行时操作清单。
%
% 为什么不并进 verifyPlatform.m：那个只验登记表、不开界面。两者的失败模式
% 不同（界面搭错了 vs 表填错了），分开更好定位。

clear; clc; close all;

FIG_NAME_KEYWORD = "图像处理实验平台";
% 顶栏与参数区的三个非算法按钮，其余 uibutton 都应当是算法按钮
CONTROL_BUTTONS  = ["打开图像", "保存结果", "执行"];

registry      = imgRegistry();
expectedNames = string({registry.Name});

failureCount = 0;

% ---------- 构造界面 ----------
imgPlatform();
drawnow;

% 按窗口标题找我们开的那个窗口。用 findall(groot) 而不是 gcf：
% -batch 下若有残留窗口，gcf 拿到的不一定是这一个
allFigures = findall(groot, "Type", "figure");
isOurs     = contains(string({allFigures.Name}), FIG_NAME_KEYWORD);
failureCount = failureCount + checkEq("标题含关键字的窗口数", nnz(isOurs), 1);

if nnz(isOurs) ~= 1
    error("matlab_test:guiSmokeFailed", ...
        "imgPlatform() 应当开出恰好 1 个标题含「%s」的窗口，实测 %d 个。" + ...
        "请检查 imgPlatform.m 里的 uifigure 调用。", FIG_NAME_KEYWORD, nnz(isOurs));
end
fig = allFigures(find(isOurs, 1));

% ---------- 控件清点 ----------
% findall 能穿进可滚动面板，深度到第 4 层为止。下面的断言都取第 3~4 层的按钮。
% 参数行里的标签在第 5 层，findall 够不着，所以不在这里断言 —— 见文件头说明。
buttons    = findall(fig, "Type", "uibutton");
buttonText = string({buttons.Text});

algorithmNames = setdiff(buttonText, CONTROL_BUTTONS);
failureCount = failureCount + checkEq("算法按钮数", numel(algorithmNames), numel(registry));
failureCount = failureCount + checkEq("算法按钮名与登记表一致", ...
    isempty(setxor(algorithmNames, expectedNames)), true);

% 「执行」按钮由 buildParamControls 创建。总数对不上说明它没跑或跑挂了
failureCount = failureCount + checkEq("按钮总数（含执行按钮）", ...
    numel(buttons), numel(registry) + numel(CONTROL_BUTTONS));

% ---------- 初始灰显状态 ----------
% 还没载入图像，所以 16 个算法按钮全灰，「执行」「保存结果」也灰，
% 「打开图像」可点。这是 refreshEnableState 的核心行为。
algorithmButtons  = buttons(ismember(buttonText, expectedNames));
nAlgorithmEnabled = nnz(string({algorithmButtons.Enable}) == "on");
failureCount = failureCount + checkEq("未载图时算法按钮可点数", nAlgorithmEnabled, 0);

isEnabled = @(label) string(buttons(buttonText == label).Enable) == "on";
failureCount = failureCount + checkEq("未载图时「打开图像」可点", isEnabled("打开图像"), true);
failureCount = failureCount + checkEq("未载图时「执行」灰",       isEnabled("执行"),     false);
failureCount = failureCount + checkEq("未载图时「保存结果」灰",   isEnabled("保存结果"), false);

close(fig);

% ---------- 汇总 ----------
if failureCount > 0
    error("matlab_test:guiSmokeFailed", ...
        "共 %d 项检查未通过，逐条明细见上方标了 false 的行。", failureCount);
end

fprintf("\n全部通过\n");

% ==================== 局部函数 ====================

function nFail = checkEq(label, actual, expected)
%CHECKEQ 打印一项检查并判定是否与期望相等，返回未通过条数（0 或 1）
%
%   与 verifyPlatform.m 里的同名函数职责相同，各自独立 —— MATLAB 的
%   局部函数不跨文件共享。两处各十余行，暂不提升为公共函数。
%
%   输入
%       label       检查项名称
%       actual      实测值
%       expected    期望值
%   输出
%       nFail       未通过条数，0 或 1
%
%   调用示例
%       failureCount = failureCount + checkEq("算法按钮数", numel(algorithmNames), 16);

isPass = isequal(actual, expected);

fprintf("%-28s 期望 %-10s 实测 %-10s %s\n", ...
    label, string(expected), string(actual), string(isPass));

if ~isPass
    fprintf("    ^ 未通过: %s 应为 %s，实测 %s\n", ...
        label, string(expected), string(actual));
end

nFail = ~isPass;
end
