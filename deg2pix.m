% 视觉角度转像素函数
% 输入参数：
% degree 视觉角度（度）
% inch 屏幕对角线长度（英寸）
% pwidth 水平分辨率（像素）
% vdist 观察距离（厘米）
% ratio 屏幕宽高比（w/h）
% 返回值：转换后的像素值
function pixs=deg2pix(degree, inch, pwidth, vdist, ratio)
screenWidth = inch*2.54 / sqrt(1 + ratio^2);  % 计算水平物理宽度（cm）
pix = screenWidth/pwidth;  % 计算单像素物理宽度（cm）
pixs = round(2 * tan((degree/2) * pi/180) * vdist / pix);  % 公式转换
end