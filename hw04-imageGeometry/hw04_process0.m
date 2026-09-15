% 作业四：图像的几何运算
%
% 题目要求（见同目录 problem.md 的「基础要求」）：
%   1. 读入自己的照片，转换成灰度图，存入矩阵 A；
%   2. A 逆时针旋转 50 度，存入 B；
%   3. A 顺时针旋转 20 度，存入 C（旋转方法自定）；
%   4. A 改变为固定大小 120*200，存入 D；
%   5. 图形窗口划分为两行两列，依次显示 A、B、C、D，保存为 process0.jpg。
%
% 预期结果：
%   · 命令窗口打印各矩阵尺寸；
%   · 同目录生成 process0.jpg。

clear; clc; close all;

STUDENT_SIGNATURE = "顾皓天0242010213";
PHOTO_NAME        = "photo.jpg";      % 源照片，与本脚本同目录
OUT_JPG_NAME      = "process0.jpg";   % 第 5 问要求保存的图形文件
ANGLE_CCW         = 50;               % 逆时针旋转角度，imrotate 用正角表示逆时针
ANGLE_CW          = -20;              % 顺时针旋转角度，用负角表示
TARGET_SIZE       = [120, 200];       % 第 4 问要求的固定大小，格式为 [行数, 列数]
INTERP_METHOD     = "bicubic";        % 旋转插值方法，取双立方插值

% 用 mfilename 定位脚本所在目录，让「编辑器点运行」与「从别处 run()」两种方式
% 都能找到同目录的照片和输出位置
scriptDir  = fileparts(mfilename("fullpath"));
photoPath  = fullfile(scriptDir, PHOTO_NAME);
outJpgPath = fullfile(scriptDir, OUT_JPG_NAME);

if ~isfile(photoPath)
    error("matlab_test:photoNotFound", ...
        "找不到照片 %s。请把源照片放到脚本同目录，并命名为 %s", photoPath, PHOTO_NAME);
end

% ---------- 第 1 问：读入照片并转换为灰度图 ----------
rgbImage = imread(photoPath);
A = rgb2gray(rgbImage);

fprintf("源照片 : %s\n", photoPath);
fprintf("彩色原图: %d x %d x %d  %s\n", size(rgbImage), class(rgbImage));
fprintf("A 灰度图: %d x %d  %s\n", size(A), class(A));
