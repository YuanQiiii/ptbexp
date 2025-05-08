function tone = mytone(freq, dur, sr)
% mytone - 生成基本正弦纯音
%
% 输入参数:
%   freq - 频率(Hz)
%   dur  - 持续时间(秒)
%   sr   - 采样率(Hz)
%
% 输出参数:
%   tone - 生成的纯音信号

% 创建时间向量
t = 0:1/sr:dur-1/sr;

% 生成正弦波
tone = sin(2*pi*freq*t); % 生成正弦波，使用公式 A*sin(2πft) ,A在没有这里使用,可以对生成的信号×特定系数实现
end