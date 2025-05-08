function gab = mygabor(pxlpdg,sizedeg,ang,contrast)
% mygabor :生成gabor刺激
%
% 输入参数:
%   pxlpdg (pixels per degree):
%   - 每视角度对应的像素数量
%   - 这是一个与显示设备和观察距离相关的校准参数
%   - 例如，如果30个像素对应1度视角，则pxlpdg=30
%   - 单位：像素/度
%   sizedeg (size in degrees):
%   - 刺激的视角大小
%   - 在原始描述中为10度视角
%   - 单位：度
%   ang (angle):
%   - Gabor光栅的方向(顺时针旋转)
%   - 表示正弦波纹理的走向，以度为单位
%   - 0度通常表示水平光栅，90度表示垂直光栅
%   - 单位：度
%
% 输出参数:
%   gab:Gabor图像(二维矩阵)

% 设置参数
stimSizePix = sizedeg * pxlpdg;  % 转换为像素
spatialFreq = 0.7;     % 空间频率(cycles/degree)
spatialPeriodPix = pxlpdg / spatialFreq;  % 空间周期(像素)

% 创建网格
[x, y] = meshgrid(1:stimSizePix, 1:stimSizePix);

% Gabor参数
phase = 0;         % 初相位，可根据需要调整
c = contrast;           % 对比度
sigma = stimSizePix/6;  % 高斯窗口宽度(标准差)，通常设为刺激大小的1/6

% 中心点
centerX = stimSizePix/2;
centerY = stimSizePix/2;

% 正弦光栅部分
sine = sin( ( cosd(ang)*(x-centerX) + sind(ang)*(y-centerY) ) * 2*pi/spatialPeriodPix + phase );

% 高斯窗口部分
gauss = exp( -((x - centerX).^2 + (y - centerY).^2) / (2*sigma^2) );

% 合成 Gabor
gab = (sine .* gauss * c + 1) / 2;  % 归一化到[0,1]范围
end