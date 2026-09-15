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

% 用 close all force 而不是 close all —— 实测 close all 关不掉 uifigure
% （前后都是 2 个窗口，加 force 才清空）。若用户正开着界面时跑本脚本，
% 残留窗口会让下面的窗口计数断言误判，掩盖真实错误。
clear; clc; close all force;

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
    close(allFigures(isOurs));   % 先清掉现场，别把窗口留在桌面上
    error("matlab_test:guiSmokeFailed", ...
        "imgPlatform() 应当开出恰好 1 个标题含「%s」的窗口，实测 %d 个。" + ...
        "请检查 imgPlatform.m 里的 uifigure 调用。", FIG_NAME_KEYWORD, nnz(isOurs));
end
fig = allFigures(find(isOurs, 1));

% ---------- 控件清点 ----------
% 下面的断言只覆盖按钮层。参数区那些控件不是 findall 够不着（它没有深度限制，
% 实测 8 层嵌套仍全部返回），只是本脚本没写那部分的断言 —— 参数区的样子靠
% notes.md 的人工清单核。
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

% ---------- 字色只反映「实现了没有」，与有没有载图无关 ----------
% 刚打开界面时一张图都没有，已实现的那几个算法仍应是黑字，否则用户看不出
% 哪几个能用。最初把 FontColor 和 Enable 绑在同一个条件上，就是这个毛病，
% 而只断言 Enable 的检查抓不到它 —— 所以这条要单独测。
isImplemented = false(numel(registry), 1);
for kk = 1:numel(registry)
    isImplemented(kk) = ~isempty(which(registry(kk).Fcn));
end

nBlackText = nnz(arrayfun(@(btn) isequal(btn.FontColor, [0 0 0]), algorithmButtons));
failureCount = failureCount + checkEq("未载图时黑字按钮数（应等于已实现数）", ...
    nBlackText, nnz(isImplemented));

% ---------- 左栏从上到下的顺序 ----------
% 可滚动面板的坐标原点在左下角、y 轴向上，所以 y 大的在屏幕上方。
% 这条断言是为一个真实出过的 bug 加的：最初从下往上摆，整个列表上下颠倒
% （登记表第一条落到了最底部），而只清点按钮数量的断言完全看不出来 ——
% 那个 bug 一路穿过三次审查，最后靠人工看截图才发现。
positions = arrayfun(@(btn) btn.Position(2), algorithmButtons);
[~, screenOrder] = sort(positions, "descend");     % 自上而下
orderedTexts = string({algorithmButtons(screenOrder).Text});
failureCount = failureCount + checkEq("左栏自上而下的算法名与登记表一致", ...
    isequal(orderedTexts(:), expectedNames(:)), true);

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
