function registry = imgRegistry()
%IMGREGISTRY 图像处理实验平台的算法登记表
%
%   返回 8 类共 16 个算法的元数据。界面与自检脚本都只通过本表了解算法。
%
%   「某个算法实现了没有」不写死在表里，由 which(Fcn) 现场探测 —— 实测
%   exist("img.grayGamma") 对一个存在的包函数返回 0，exist(...,"file") 也是 0，
%   只有 which 可靠。所以补上 +img/ 里的实现后，界面会自动点亮，
%   本表与界面代码都不用改。
%
%   顺序按类别排列，已实现的「灰度变换」「阈值分割」放在最前，
%   界面左栏从上到下就按这个顺序显示。
%
%   输入
%       无
%   输出
%       registry    16×1 的 struct 数组，字段：
%                     Category    类别名
%                     Name        算法显示名
%                     Fcn         包函数名，形如 "img.grayGamma"
%                     Params      参数定义 cell 数组，无参数时为 {}
%                     Output      输出类型，"image" / "binary" / "vector"
%                     ExtraLabel  第二个返回值的显示名，无则为 ""
%
%   调用示例
%       registry = imgRegistry();
%       isDone = ~isempty(which(registry(1).Fcn));

registry = [ ...
    entry("灰度变换", "线性拉伸", "img.grayLinearStretch", { ...
        pSlider("lowIn",  30,   0, 255), ...
        pSlider("highIn", 220,  0, 255)}, ...
        "image"); ...
    entry("灰度变换", "伽马变换", "img.grayGamma", { ...
        pSlider("gamma", 0.5, 0.05, 3)}, ...
        "image"); ...
    entry("阈值分割", "Otsu", "img.threshOtsu", {}, ...
        "binary", "阈值"); ...
    entry("阈值分割", "迭代法", "img.threshIterative", { ...
        pEdit("tol", 1e-6, 1e-9, 1e-2)}, ...
        "binary", "阈值"); ...
    entry("几何变换", "旋转", "img.geomRotate", { ...
        pSlider("angle", 50, -180, 180), ...
        pChoice("method", "bicubic", ["nearest", "bilinear", "bicubic"])}, ...
        "image"); ...
    entry("几何变换", "缩放", "img.geomScale", { ...
        pSize("targetSize", [120, 200], 1, 4096), ...
        pChoice("method", "bilinear", ["nearest", "bilinear", "bicubic"])}, ...
        "image"); ...
    entry("直方图均衡", "全局均衡", "img.histEqualize", { ...
        pSlider("numLevels", 256, 2, 256)}, ...
        "image"); ...
    entry("直方图均衡", "CLAHE", "img.histClahe", { ...
        pSize("numTiles", [8, 8], 1, 64), ...
        pSlider("clipLimit", 0.01, 0.001, 0.2)}, ...
        "image"); ...
    entry("空域滤波", "均值滤波", "img.filterMean", { ...
        pSlider("kernelSize", 3, 3, 15)}, ...
        "image"); ...
    entry("空域滤波", "中值滤波", "img.filterMedian", { ...
        pSlider("kernelSize", 3, 3, 15)}, ...
        "image"); ...
    entry("频域滤波", "理想低通", "img.freqIdealLP", { ...
        pSlider("cutoff", 0.1, 0.01, 0.5)}, ...
        "image"); ...
    entry("频域滤波", "巴特沃斯低通", "img.freqButterLP", { ...
        pSlider("cutoff", 0.1, 0.01, 0.5), ...
        pSlider("order", 2, 1, 10)}, ...
        "image"); ...
    entry("边缘检测", "Sobel", "img.edgeSobel", { ...
        pSlider("threshold", 0.1, 0, 1)}, ...
        "binary"); ...
    entry("边缘检测", "Prewitt", "img.edgePrewitt", { ...
        pSlider("threshold", 0.1, 0, 1)}, ...
        "binary"); ...
    entry("特征提取", "HOG", "img.featHOG", { ...
        pSlider("cellSize", 8, 4, 32), ...
        pSlider("numBins", 9, 4, 16)}, ...
        "vector"); ...
    entry("特征提取", "LBP", "img.featLBP", { ...
        pSlider("numNeighbors", 8, 1, 16)}, ...
        "vector")];

end

% ==================== 局部函数 ====================

function e = entry(category, name, fcn, params, output, extraLabel)
%ENTRY 组装一条算法登记项
%
%   Params 字段用 {params} 再包一层 cell，否则 struct 会把 params 的每个元素
%   当成数组元素展开，16 条登记项就拼不成 struct 数组了。
%
%   extraLabel 可选，第二个返回值的显示名。只有 threshOtsu 与 threshIterative
%   返回 [BW, level] 两个值，那个 level 是阈值分割这道题的核心数字，界面上要
%   显示出来，所以需要在这里登记它叫什么。其余算法只返回一个值，省略即可。
%
%   输入
%       category    类别名
%       name        算法显示名
%       fcn         包函数名
%       params      参数定义 cell 数组
%       output      输出类型
%       extraLabel  可选，第二个返回值的显示名，默认 ""
%   输出
%       e           一条登记项 struct
%
%   调用示例
%       e = entry("阈值分割", "Otsu", "img.threshOtsu", {}, "binary", "阈值");

narginchk(5, 6);
if nargin < 6
    extraLabel = "";
end

e = struct("Category", category, "Name", name, "Fcn", fcn, ...
    "Params", {params}, "Output", output, "ExtraLabel", extraLabel);
end

function p = pSlider(name, defaultValue, minValue, maxValue)
%PSLIDER 范围明确的数值参数，界面上给滑块 + 数值框，两者双向同步
%
%   输入
%       name            参数名，与 +img/ 里的形参名一致
%       defaultValue    默认值，必须落在 [minValue, maxValue] 内
%       minValue        下界
%       maxValue        上界
%   输出
%       p               参数定义 struct，Kind 为 "slider"
%
%   调用示例
%       p = pSlider("gamma", 0.5, 0.05, 3);

p = struct("Name", name, "Default", defaultValue, "Kind", "slider", ...
    "Min", minValue, "Max", maxValue);
end

function p = pEdit(name, defaultValue, minValue, maxValue)
%PEDIT 跨数量级的数值参数，界面上只给数值框
%
%   滑块在 1e-6 这种量级上没法拖，所以不给滑块。范围仍然记下来，
%   供 verifyPlatform.m 检查默认值是否越界。
%
%   输入
%       name            参数名
%       defaultValue    默认值，必须落在 [minValue, maxValue] 内
%       minValue        下界
%       maxValue        上界
%   输出
%       p               参数定义 struct，Kind 为 "edit"
%
%   调用示例
%       p = pEdit("tol", 1e-6, 1e-9, 1e-2);

p = struct("Name", name, "Default", defaultValue, "Kind", "edit", ...
    "Min", minValue, "Max", maxValue);
end

function p = pChoice(name, defaultValue, options)
%PCHOICE 枚举字符串参数，界面上给下拉框
%
%   输入
%       name            参数名
%       defaultValue    默认选项，必须是 options 里的一个
%       options         候选值，字符串数组
%   输出
%       p               参数定义 struct，Kind 为 "choice"
%
%   调用示例
%       p = pChoice("method", "bicubic", ["nearest", "bilinear", "bicubic"]);

p = struct("Name", name, "Default", defaultValue, "Kind", "choice", ...
    "Options", options);
end

function p = pSize(name, defaultValue, minValue, maxValue)
%PSIZE 二元素尺寸参数，界面上给两个数值框
%
%   Min / Max 是标量，对两个分量都适用。
%
%   defaultValue 的分量顺序随算法而定，界面按原样透传给算法，不做解释：
%     targetSize  [行数, 列数] —— 与 imresize 的口径一致
%     numTiles    [行块数, 列块数] —— CLAHE 的分块数
%   上游 spec 与 +img/ 里对应函数的形参定义都以「先行后列」为准。
%
%   输入
%       name            参数名
%       defaultValue    [第一分量, 第二分量]，都必须落在 [minValue, maxValue] 内
%       minValue        下界，对两个分量都适用
%       maxValue        上界，对两个分量都适用
%   输出
%       p               参数定义 struct，Kind 为 "size"
%
%   调用示例
%       p = pSize("targetSize", [120, 200], 1, 4096);

p = struct("Name", name, "Default", defaultValue, "Kind", "size", ...
    "Min", minValue, "Max", maxValue);
end
