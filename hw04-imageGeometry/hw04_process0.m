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

% ---------- 第 2、3 问：两次旋转 ----------
tRotate = tic;
B = imrotate(A, ANGLE_CCW, INTERP_METHOD);
C = imrotate(A, ANGLE_CW,  INTERP_METHOD);
rotateSeconds = toc(tRotate);

% ---------- 第 4 问：缩放为固定大小 ----------
tResize = tic;
D = imresize(A, TARGET_SIZE);
resizeSeconds = toc(tResize);

% ---------- 第 5 问：2x2 子图显示，并保存为 process0.jpg ----------
figure("Name", "作业四：图像的几何运算");

subplot(2, 2, 1);
imshow(A);
title("原灰度图 A");

subplot(2, 2, 2);
imshow(B);
title(sprintf("逆时针旋转 %d°  B", ANGLE_CCW));

subplot(2, 2, 3);
imshow(C);
title(sprintf("顺时针旋转 %d°  C", -ANGLE_CW));

subplot(2, 2, 4);
imshow(D);
title(sprintf("缩放为 %d×%d  D", TARGET_SIZE(1), TARGET_SIZE(2)));

sgtitle("Plot by " + STUDENT_SIGNATURE);

% 导出当前图形窗口。jpg 无透明通道，用 exportgraphics 比 saveas 画质更稳
exportgraphics(gcf, outJpgPath, "Resolution", 150);

% ---------- 结果汇总 ----------
fprintf("源照片  : %s\n", photoPath);
fprintf("彩色原图: %d x %d x %d  %s\n", size(rgbImage), class(rgbImage));
fprintf("A 灰度图         %5d x %5d\n", size(A));
fprintf("B 逆时针 %+3d°    %5d x %5d   黑边占比 %4.1f%%\n", ...
    ANGLE_CCW, size(B), 100 * mean(B(:) == 0));
fprintf("C 顺时针 %+3d°    %5d x %5d   黑边占比 %4.1f%%\n", ...
    ANGLE_CW, size(C), 100 * mean(C(:) == 0));
fprintf("D 缩放 %d x %d  %5d x %5d\n", TARGET_SIZE, size(D));
fprintf("耗时: 旋转 %.2f s，缩放 %.3f s\n", rotateSeconds, resizeSeconds);
fprintf("已保存图形: %s\n", outJpgPath);
