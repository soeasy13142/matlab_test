function imgPlatform()
%IMGPLATFORM 图像处理实验平台的图形界面
%
%   开出一个窗口：左栏按 8 个类别列出 16 个算法（未实现的置灰不可点），
%   顶部是图像管理按钮，右侧并排显示原图与结果，下方是参数调节区与结果信息。
%   打开图像后选中算法、调参数、点「执行」即可看到结果。
%
%   算法的全部知识来自 imgRegistry()，本函数只负责搭控件与派发。
%   「实现了没有」是登记表用 which 现场探测的，所以以后补上 +img/ 里的实现，
%   对应按钮会自动从灰变亮，本文件一行都不用改。
%
%   输入
%       无
%   输出
%       无（界面窗口本身即是输出）
%
%   调用示例
%       在编辑器里打开本文件点运行，或在命令窗口输入 imgPlatform

% ---------- 常量 ----------
STUDENT_SIGNATURE = "顾皓天0242010213";

FIG_NAME       = "图像处理实验平台  Plot by " + STUDENT_SIGNATURE;
FIG_POSITION   = [100 80 1100 720];
LEFT_WIDTH     = 190;    % 左栏算法列表宽度
BUTTON_WIDTH   = 158;    % 算法按钮宽度，留出左栏边框与滚动条的余量
ROW_HEIGHT     = 24;     % 算法按钮高度
ROW_GAP        = 3;      % 算法按钮之间的间隔
LABEL_HEIGHT   = 18;     % 类别标签高度
PANEL_PAD      = 6;      % 列表四周留白
DISABLED_COLOR = [0.55 0.55 0.55];   % 未实现算法的灰字
NORMAL_COLOR   = [0 0 0];
AXES_LABEL_ORIGINAL = "原图";
AXES_LABEL_RESULT   = "结果";

% 打开/保存对话框的文件类型过滤器。第 2 条要求「图像管理」，这里把第 3 条
% 要求的五种格式一并列上，底层直接用 imread / imwrite，不做额外封装。
IMAGE_FILTER = { ...
    "*.bmp;*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.gif", "所有支持的图像"; ...
    "*.bmp",        "BMP 图像"; ...
    "*.jpg;*.jpeg", "JPEG 图像"; ...
    "*.png",        "PNG 图像"; ...
    "*.tif;*.tiff", "TIFF 图像"; ...
    "*.gif",        "GIF 图像"; ...
    "*.*",          "所有文件"};

% ---------- 状态 ----------
% 这些变量被下面的嵌套函数共享，必须在父函数作用域里声明
registry     = imgRegistry();
currentImage = [];      % 已载入的灰度图，未载入时为 []
currentName  = "";      % 文件名，显示在状态栏
resultImage  = [];      % 上一次「执行」的结果，未执行时为 []
resultOutput = "";      % 产出 resultImage 的那个算法的 Output 类型。
                        % 不能现查 registry(selectedIdx) —— 用户可以在算完之后
                        % 改选别的算法，那时 selectedIdx 已经指向别的算法了。
isColorInput = false;   % 原图是否为彩色，用于状态栏标注
selectedIdx  = 0;       % 当前选中的算法下标，0 表示未选

algorithmButtons = gobjects(0);   % 左栏按钮，下标与 registry 一一对应
executeButton    = gobjects(0);   % 每次重建参数区时重新赋值
paramGetters     = {};            % cell of function handle，按登记表顺序取值

% ---------- 界面框架 ----------
fig = uifigure("Name", FIG_NAME, "Position", FIG_POSITION);

mainGrid = uigridlayout(fig, [2 2], ...
    "ColumnWidth", {LEFT_WIDTH, "1x"}, ...
    "RowHeight",   {"fit", "1x"}, ...
    "Padding",     [6 6 6 6], ...
    "RowSpacing",  6);

% --- 顶栏：图像管理 ---
topBar = uigridlayout(mainGrid, [1 3], ...
    "ColumnWidth", {100, 100, "1x"}, ...
    "Padding",     [0 0 0 0], ...
    "ColumnSpacing", 6);
topBar.Layout.Row    = 1;
topBar.Layout.Column = [1 2];

openButton  = uibutton(topBar, "Text", "打开图像", "ButtonPushedFcn", @onOpenImage);
saveButton  = uibutton(topBar, "Text", "保存结果", "ButtonPushedFcn", @onSaveResult);
statusLabel = uilabel(topBar, "Text", "未载入图像");

% --- 左栏：算法列表 ---
leftPanel = uipanel(mainGrid, "Title", "算法", "Scrollable", "on");
leftPanel.Layout.Row    = 2;
leftPanel.Layout.Column = 1;

% --- 右侧：原图 / 结果 / 参数 / 信息 ---
rightGrid = uigridlayout(mainGrid, [3 1], ...
    "RowHeight",  {"1x", "fit", "fit"}, ...
    "Padding",    [0 0 0 0], ...
    "RowSpacing", 6);
rightGrid.Layout.Row    = 2;
rightGrid.Layout.Column = 2;

axesGrid   = uigridlayout(rightGrid, [1 2], ...
    "Padding", [0 0 0 0], "ColumnSpacing", 6);
axOriginal = uiaxes(axesGrid);
axResult   = uiaxes(axesGrid);
title(axOriginal, AXES_LABEL_ORIGINAL);
title(axResult,   AXES_LABEL_RESULT);
axOriginal.XTick = [];  axOriginal.YTick = [];
axResult.XTick   = [];  axResult.YTick   = [];

paramPanel = uipanel(rightGrid, "Title", "参数");
infoLabel  = uilabel(rightGrid, "Text", "尚未执行");

% ---------- 初始内容 ----------
algorithmButtons = buildAlgorithmList(leftPanel);
buildParamControls();
refreshEnableState();

% ==================== 嵌套函数 ====================
% 嵌在 imgPlatform 里，所以能直接读写上面的状态变量

    % ---------------- 图像管理 ----------------

    function onOpenImage(~, ~)
        [fileName, folder] = uigetfile(IMAGE_FILTER, "选择图像");
        if isequal(fileName, 0)
            return;                          % 用户取消
        end

        fullPath = fullfile(folder, fileName);

        % 读图、转灰度、显示三段都包在同一个 try 里。只包 imread 是不够的：
        % 4 通道图（RGBA / CMYK 的 TIFF）会在 rgb2gray 处抛错，而打开对话框的
        % 过滤器里就有 *.gif 和 *.tif。抛在 try 外面的话，回调会中途死掉，
        % 留下「图像已换、状态栏没更新、按钮没刷新」的半截状态。
        try
            raw = imread(fullPath);

            % +img/ 里的算法开头都有 ~ismatrix(I) 检查，彩色图会直接报错。
            % 这里统一转灰度，并在状态栏说明，免得用户以为显示的就是原色。
            isColor = (ndims(raw) == 3);
            if isColor
                loadedImage = rgb2gray(raw);
            else
                loadedImage = raw;
            end

            % rgb2gray 之后还不是二维的（多帧图之类），说明这个文件超出
            % 支持范围，与其让后面的算法报「只接受二维灰度图」，不如在这里说清
            if ~ismatrix(loadedImage)
                error("matlab_test:unsupportedImage", ...
                    "读到的图是 %d 维，只支持单帧灰度图或三通道彩色图。" + ...
                    "请换一张图。", ndims(loadedImage));
            end

            showImage(axOriginal, loadedImage, AXES_LABEL_ORIGINAL);
        catch err
            uialert(fig, "读取失败：" + err.message, "打开图像失败");
            return;
        end

        % 走到这里说明读图和显示都成功了，这时才改状态 ——
        % 上面任何一步失败都不会留下半更新的界面
        currentImage = loadedImage;
        currentName  = string(fileName);
        isColorInput = isColor;

        resultImage    = [];                 % 换了图，上一次的结果作废
        resultOutput   = "";
        infoLabel.Text = "尚未执行";

        cla(axResult);
        title(axResult, AXES_LABEL_RESULT);

        colorNote = "";
        if isColorInput
            colorNote = "   已自动转灰度";
        end
        statusLabel.Text = string(sprintf("%s   %d×%d   %s%s", ...
            currentName, size(currentImage, 1), size(currentImage, 2), ...
            class(currentImage), colorNote));

        refreshEnableState();
    end

    function onSaveResult(~, ~)
        if isempty(resultImage)
            return;
        end

        [fileName, folder] = uiputfile(IMAGE_FILTER, "保存结果");
        if isequal(fileName, 0)
            return;                          % 用户取消
        end

        fullPath = fullfile(folder, fileName);
        try
            imwrite(resultImage, fullPath);
        catch err
            uialert(fig, "保存失败：" + err.message, "保存结果失败");
            return;
        end

        statusLabel.Text = "已保存 " + string(fullPath);
    end

    % ---------------- 算法选择与执行 ----------------

    function onSelectAlgorithm(idx)
        selectedIdx = idx;
        buildParamControls();
        refreshEnableState();
    end

    function fh = makeAlgorithmCallback(idx)
        % 工厂函数：把当次的 idx 绑进回调。
        % 不能直接写 @(~,~) onSelectAlgorithm(kk) —— kk 是循环变量，
        % 所有回调会共享它最终的值，点哪个按钮都选到最后一个算法。
        % 实测过：工厂函数传参进去，每个句柄才各捕获各的。
        fh = @(~, ~) onSelectAlgorithm(idx);
    end

    function onExecute(~, ~)
        if isempty(currentImage) || selectedIdx == 0
            return;
        end

        entryNow = registry(selectedIdx);

        % 按当前控件取值，顺序与登记表里的参数定义一致
        args = cell(numel(paramGetters), 1);
        for kk = 1:numel(paramGetters)
            args{kk} = paramGetters{kk}();
        end

        fcn    = str2func(entryNow.Fcn);
        tStart = tic;
        try
            % 登记表里标了 ExtraLabel 的算法返回 [结果, 标量]，第二个返回值是
            % 收敛阈值，要在信息行里显示出来 —— 它是阈值分割这道题的核心数字。
            % 不能一律写成 [result, extra] = fcn(...)：只定义一个返回值的算法
            % 被要两个输出会直接报「输出参数太多」。
            if strlength(entryNow.ExtraLabel) > 0
                [result, extraValue] = fcn(currentImage, args{:});
            else
                result     = fcn(currentImage, args{:});
                extraValue = [];
            end
        catch err
            uialert(fig, err.message, "算法执行失败");
            return;
        end
        elapsed = toc(tStart);

        resultImage  = result;
        resultOutput = entryNow.Output;

        extraText = "";
        if ~isempty(extraValue)
            extraText = sprintf("   %s %.4f", entryNow.ExtraLabel, extraValue);
        end

        if entryNow.Output == "vector"
            % 特征描述子不是图像，用 plot 画
            plot(axResult, result);
            title(axResult, "结果（特征向量）");
            infoLabel.Text = string(sprintf("维度 %d   耗时 %.3f s%s", ...
                numel(result), elapsed, extraText));
        else
            showImage(axResult, result, AXES_LABEL_RESULT);
            infoLabel.Text = string(sprintf("尺寸 %d×%d   类型 %s   耗时 %.3f s%s", ...
                size(result, 1), size(result, 2), class(result), elapsed, extraText));
        end

        refreshEnableState();
    end

    function refreshEnableState()
        hasImage = ~isempty(currentImage);

        for kk = 1:numel(algorithmButtons)
            isImplemented = ~isempty(which(registry(kk).Fcn));

            % Enable 和 FontColor 表示两件不同的事，不能绑在同一个条件上：
            %   Enable     —— 现在能不能点（要有图，且算法实现了）
            %   FontColor  —— 这个算法实现了没有（灰 = 未实现）
            % 混在一起的话，没载图时 16 个按钮全是灰的，用户看不出哪几个能用，
            % 而那正是刚打开界面、还没载图时的状态。
            algorithmButtons(kk).Enable = onOff(hasImage && isImplemented);
            if isImplemented
                algorithmButtons(kk).FontColor = NORMAL_COLOR;
            else
                algorithmButtons(kk).FontColor = DISABLED_COLOR;
            end
        end

        % 特征向量不是图像，imwrite 会把它当 1×N 的图写出垃圾，所以不给保存。
        % 判据用「产出这个结果的算法」的 Output，不是当前选中的那个 ——
        % 用户可以在算完之后改选别的算法。
        isSavable = ~isempty(resultImage) && resultOutput ~= "vector";

        saveButton.Enable    = onOff(hasImage && isSavable);
        executeButton.Enable = onOff(hasImage && selectedIdx > 0);
    end

    % ---------------- 左栏列表 ----------------

    function buttons = buildAlgorithmList(parentPanel)
        % 左栏是滚动面板，子控件用绝对定位 —— 实测滚动面板里的 uigridlayout
        % 高度恒等于面板内高、不随内容增长，超出的部分被裁掉且滚不到。
        buttons          = gobjects(numel(registry), 1);
        categories       = string({registry.Category});
        uniqueCategories = unique(categories, "stable");

        yCursor = PANEL_PAD;
        for cc = 1:numel(uniqueCategories)
            uilabel(parentPanel, "Text", uniqueCategories(cc), ...
                "FontWeight", "bold", ...
                "Position", [PANEL_PAD, yCursor, BUTTON_WIDTH, LABEL_HEIGHT]);
            yCursor = yCursor + LABEL_HEIGHT + 2;

            for kk = 1:numel(registry)
                if categories(kk) ~= uniqueCategories(cc)
                    continue;
                end
                buttons(kk) = uibutton(parentPanel, ...
                    "Text", registry(kk).Name, ...
                    "Position", [PANEL_PAD, yCursor, BUTTON_WIDTH, ROW_HEIGHT], ...
                    "ButtonPushedFcn", makeAlgorithmCallback(kk));
                yCursor = yCursor + ROW_HEIGHT + ROW_GAP;
            end
        end
    end

    % ---------------- 参数区 ----------------

    function buildParamControls()
        % 切换算法时销毁旧控件、按新算法的参数定义重建。
        % 「执行」按钮每次也重建，refreshEnableState 里重新读它的句柄。
        delete(paramPanel.Children);

        if selectedIdx == 0
            params      = {};
            placeholder = "请在左侧选择一个算法";
        else
            params      = registry(selectedIdx).Params;
            placeholder = "该算法无可调参数";
        end

        % 无参数时要放「占位标签 + 执行按钮」两个控件，所以至少 2 行
        numParams = numel(params);
        numRows   = max(numParams, 1) + 1;

        paramGrid = uigridlayout(paramPanel, [numRows 1], ...
            "RowHeight",  repmat({"fit"}, 1, numRows), ...
            "Padding",    PANEL_PAD * ones(1, 4), ...
            "RowSpacing", 4);

        paramGetters = cell(numParams, 1);
        for kk = 1:numParams
            paramGetters{kk} = buildParamRow(paramGrid, kk, params{kk});
        end
        if numParams == 0
            uilabel(paramGrid, "Text", placeholder);
        end

        executeButton = uibutton(paramGrid, "Text", "执行", ...
            "ButtonPushedFcn", @onExecute);
    end

    function getter = buildParamRow(parentGrid, rowIdx, p)
        % 一行参数，三列：名称 | 控件 | （滑块的）数值框
        rowGrid = uigridlayout(parentGrid, [1 3], ...
            "ColumnWidth", {90, "1x", 80}, ...
            "Padding",     [0 0 0 0]);
        rowGrid.Layout.Row = rowIdx;

        uilabel(rowGrid, "Text", p.Name);

        switch p.Kind
            case "slider"
                sld = uislider(rowGrid, "Limits", [p.Min, p.Max], ...
                    "Value", p.Default);
                edt = uieditfield(rowGrid, "numeric", ...
                    "Limits", [p.Min, p.Max], "Value", p.Default);
                % 实测程序化赋值不会再触发 ValueChangedFcn，双向同步不会死循环
                sld.ValueChangedFcn = makeCopyTo(sld, edt);
                edt.ValueChangedFcn = makeCopyTo(edt, sld);
                getter = makeGetter(sld);

            case "edit"
                edt = uieditfield(rowGrid, "numeric", ...
                    "Limits", [p.Min, p.Max], "Value", p.Default);
                edt.Layout.Column = [2 3];
                getter = makeGetter(edt);

            case "choice"
                ddn = uidropdown(rowGrid, "Items", p.Options, "Value", p.Default);
                ddn.Layout.Column = [2 3];
                getter = makeGetter(ddn);

            case "size"
                edtRow = uieditfield(rowGrid, "numeric", ...
                    "Limits", [p.Min, p.Max], "Value", p.Default(1));
                edtCol = uieditfield(rowGrid, "numeric", ...
                    "Limits", [p.Min, p.Max], "Value", p.Default(2));
                getter = makeSizeGetter(edtRow, edtCol);

            otherwise
                error("matlab_test:badParamKind", ...
                    "参数 %s 的 Kind 是 %s，只支持 slider / edit / choice / size。" + ...
                    "请改 imgRegistry.m 里该参数的定义。", p.Name, p.Kind);
        end
    end
end

% ==================== 局部函数 ====================
% 不碰界面状态，所以放在父函数外面

function showImage(ax, I, labelText)
%SHOWIMAGE 在指定坐标区显示图像并统一外观
%
%   输入
%       ax          目标 uiaxes
%       I           图像矩阵
%       labelText   标题文字
%   输出
%       无（就地改写 ax）
%
%   调用示例
%       showImage(axResult, result, "结果");

imshow(I, "Parent", ax);
title(ax, labelText);
ax.XTick = [];
ax.YTick = [];
end

function getter = makeGetter(control)
%MAKEGETTER 返回一个读该控件 Value 的函数句柄
%
%   必须写成工厂函数。直接在循环里写 @() sld.Value，所有句柄会共享循环变量
%   sld 最终的值，取哪个控件的值都变成最后一个。实测过：工厂函数传参进去，
%   每个句柄才各捕获各的。
%
%   输入
%       control     任意有 Value 属性的控件（uislider / uieditfield / uidropdown）
%   输出
%       getter      无参函数句柄，调用返回该控件当前的 Value
%
%   调用示例
%       getter = makeGetter(edt);
%       v = getter();

getter = @() control.Value;
end

function getter = makeSizeGetter(edtRow, edtCol)
%MAKESIZEGETTER 返回一个把两个数值框读成 [行, 列] 的函数句柄
%
%   输入
%       edtRow      行分量数值框
%       edtCol      列分量数值框
%   输出
%       getter      无参函数句柄，调用返回 [行, 列] 二元素数组
%
%   调用示例
%       getter = makeSizeGetter(edtRow, edtCol);
%       targetSize = getter();

getter = @() [edtRow.Value, edtCol.Value];
end

function fh = makeCopyTo(source, target)
%MAKECOPYTO 返回一个把 source 的 Value 抄给 target 的回调
%
%   匿名函数里不能写赋值语句，所以抄值这一步要交给 assignValue。
%
%   输入
%       source      取值来源控件
%       target      被写入的控件
%   输出
%       fh          两参数回调句柄，可直接赋给 ValueChangedFcn
%
%   调用示例
%       sld.ValueChangedFcn = makeCopyTo(sld, edt);

fh = @(~, ~) assignValue(target, source.Value);
end

function assignValue(control, newValue)
%ASSIGNVALUE 把新值写进控件
%
%   单独拆出来是因为匿名函数里不能写赋值语句。
%
%   输入
%       control     目标控件
%       newValue    新值
%   输出
%       无（就地改写 control.Value）
%
%   调用示例
%       assignValue(edt, 0.5);

control.Value = newValue;
end

function value = onOff(isOn)
%ONOFF 把 logical 转成控件 Enable 属性要的 "on" / "off"
%
%   输入
%       isOn        logical 标量
%   输出
%       value       "on" 或 "off"
%
%   调用示例
%       button.Enable = onOff(hasImage && isImplemented);

if isOn
    value = "on";
else
    value = "off";
end
end
