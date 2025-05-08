% -------------------------------------------------------------------------
% 实验初始化
% -------------------------------------------------------------------------
% 初始化随机数种子
rng('shuffle');
% --- 参与者信息 ---
prompt = {'参与者ID:', '年龄:', '性别 (M/F):', '利手 (L/R):'};
dlgtitle = '参与者信息';
dims = [1 35; 1 35; 1 35; 1 35];
answer = inputdlg(prompt, dlgtitle, dims);
if isempty(answer)
    disp('实验被用户取消。');
    return;
end
participant.ID = answer{1};
participant.Age = str2double(answer{2});
participant.Sex = answer{3};
participant.Handedness = answer{4};

% --- 屏幕和 Psychtoolbox 设置 ---
Screen('Preference', 'SkipSyncTests', 2);
screens = Screen('Screens');
screenNumber = max(screens);
white = WhiteIndex(screenNumber)
black = BlackIndex(screenNumber)
grey = white / 2;
AssertOpenGL;
InitializeMatlabOpenGL;

% 打开一个屏幕窗口
[window, windowRect] = Screen('OpenWindow', screenNumber, grey, [0 0 1600 900]);
% [window, windowRect] = Screen('OpenWindow', screenNumber, grey);
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA'); % 启用 alpha 混合
[xCenter, yCenter] = RectCenter(windowRect);

% --- 时间信息 (单位：秒) ---
expParams.fixationDurRange = [0.750, 1.500]; % 随机注视点持续时间范围
expParams.leadingStimDur = 0.500; % 领先刺激呈现时间
expParams.isiDur = 0.500; % 刺激间间隔时间
expParams.trailingStimDur = 0.500; % 跟随刺激呈现时间
expParams.feedbackDur = 0.500; % 指定反馈持续时间
% --- 反应按键 ---
% 定义按键 (确保这些按键一致，并根据需要进行平衡)
KbName('UnifyKeyNames'); % 使用统一的按键名称

DisableKeysForKbCheck(133); % 笔记本卡键解决,请提前运行test脚本确定卡住的按键

expParams.keys.frequent = KbName('z');
expParams.keys.infrequent = KbName('m');
expParams.keys.weak = KbName('space');
expParams.keys.deviant = KbName('d');
expParams.keys.standard = KbName('s');


% 一些笔记本电脑用户遇到了“按键卡住”的问题：
% 某些按键总是报告为“按下”状态，因此 KbWait 会立即返回，而 KbCheck 总是报告 keyIsDown == 1。
% 这通常是由于特殊功能键造成的。
% 这些按键或系统功能被分配了供应商特定的键码，例如，笔记本电脑盖子的状态（打开/关闭）可能由某个特殊键码报告。
% 只要笔记本电脑盖子是打开的，这个键就会被报告为按下状态。
% 您可以通过传递一个要被 KbCheck 和 KbWait 忽略的键码列表来解决此问题。
% 有关如何执行此操作，请参阅 "help DisableKeysForKbCheck"。

% 被试按下的按键通常也会显示在 Matlab 命令窗口中，用无用的字符垃圾弄乱该窗口。
% 您可以通过禁用对 Matlab 的键盘输入来防止这种情况发生：在脚本的开头添加一个 ListenChar(2);
% 命令，并在脚本的末尾添加一个 ListenChar(0); 命令，以启用/禁用对 Matlab 的按键传输。
% 如果您的脚本中止并且键盘失灵，请按 CTRL+C 以重新启用键盘输入——这与 ListenChar(0) 相同。
% 有关更多信息，请参阅 'help ListenChar'。


% --- 概率结构与转移矩阵 ---
% 视觉矩阵
visMatrix1 = struct('v0_t45', 0.75, 'v0_t135', 0.25, 'v90_t45', 0.25, 'v90_t135', 0.75); % 0°垂直, 90°水平; 45°顺时针, 135°逆时针
visMatrix2 = struct('v0_t45', 0.25, 'v0_t135', 0.75, 'v90_t45', 0.75, 'v90_t135', 0.25);
% 听觉矩阵
audMatrix1 = struct('a1000_t100', 0.75, 'a1000_t160', 0.25, 'a1600_t100', 0.25, 'a1600_t160', 0.75);
audMatrix2 = struct('a1000_t100', 0.25, 'a1000_t160', 0.75, 'a1600_t100', 0.75, 'a1600_t160', 0.25);
% 按照id分配转移矩阵

participantID_num = str2double(regexp(participant.ID, '\d+', 'match')); % 提取ID中的数字部分

if isempty(participantID_num)
    participantID_num = 1;
else
    participantID_num = participantID_num(1);
end

if mod(participantID_num, 4) == 1 % 参与者 1, 5, 9...
    participant.visualMatrix = visMatrix1;
    participant.auditoryMatrix = audMatrix1;
elseif mod(participantID_num, 4) == 2 % 参与者 2, 6, 10...
    participant.visualMatrix = visMatrix2;
    participant.auditoryMatrix = audMatrix2;
elseif mod(participantID_num, 4) == 3 % 参与者 3, 7, 11...
    participant.visualMatrix = visMatrix1;
    participant.auditoryMatrix = audMatrix2;
else % 参与者 4, 8, 12... (mod(X,4)==0)
    participant.visualMatrix = visMatrix2;
    participant.auditoryMatrix = audMatrix1;
end

% --- 刺激参数 ---
% 视觉刺激 (Gabor 光栅)
[ResX, ResY] = Screen('WindowSize', window);
[width, height] = Screen('DisplaySize', window);
visParams.vdist = 50; % 观察距离（单位：cm）
visParams.pxlpdg = deg2pix(1, sqrt(width^2 + height^2)/25.4, ResX, visParams.vdist, ResY/ResX); % 每度像素数

visParams.textTrueDegree = 0.9;
visParams.trueTextSize = visParams.textTrueDegree * visParams.pxlpdg;

Screen('TextSize', window, round(visParams.trueTextSize)); % 字体大小不能为小数


visParams.textDegree = 1;
visParams.textSize = visParams.textDegree * visParams.pxlpdg;

visParams.sizeDeg = 10; % 视角大小 (度)
visParams.spatialFreqCyclesPerDeg = 0.7; % 空间频率 (周/度)，与 mygabor.m 一致
visParams.contrast = 1.0; % 正常试验的对比度
visParams.catchContrast = 0.3; % 捕获试验的对比度
visParams.gaborSigmaFactor = 6; % 高斯窗口标准差与尺寸的比例，与 mygabor.m 一致

% 定义方向 (根据实验描述和 mygabor.m 的定义)
% 领先刺激: 垂直 (0° in description -> 90° in mygabor), 水平 (90° in description -> 0° in mygabor)
% 跟随刺激: 顺时针 (45° in description -> 45° in mygabor), 逆时针 (135° in description -> 135° in mygabor)
visParams.orientations.leading_desc = {'垂直', '水平'}; % 描述性标签
visParams.orientations.leading_mygabor = [90, 0];      % mygabor.m 中的角度
visParams.orientations.trailing_desc = {'顺时针', '逆时针'};
visParams.orientations.trailing_mygabor = [45, 135];

% 预生成 Gabor 纹理
gabor_leading_vert = mygabor(visParams.pxlpdg, visParams.sizeDeg, visParams.orientations.leading_mygabor(1),visParams.contrast); % 垂直
gabor_leading_horz = mygabor(visParams.pxlpdg, visParams.sizeDeg, visParams.orientations.leading_mygabor(2),visParams.contrast); % 水平
gabor_trailing_cw = mygabor(visParams.pxlpdg, visParams.sizeDeg, visParams.orientations.trailing_mygabor(1),visParams.contrast);  % 顺时针
gabor_trailing_ccw = mygabor(visParams.pxlpdg, visParams.sizeDeg, visParams.orientations.trailing_mygabor(2),visParams.contrast); % 逆时针

visParams.textures.leading(1) = Screen('MakeTexture', window, gabor_leading_vert*white);
visParams.textures.leading(2) = Screen('MakeTexture', window, gabor_leading_horz*white);
visParams.textures.trailing(1) = Screen('MakeTexture', window, gabor_trailing_cw*white);
visParams.textures.trailing(2) = Screen('MakeTexture', window, gabor_trailing_ccw*white);

% 捕获试验刺激参数 (较低对比度)

gabor_trailing_cw_catch = mygabor(visParams.pxlpdg, visParams.sizeDeg, visParams.orientations.trailing_mygabor(1), visParams.catchContrast) ;
gabor_trailing_ccw_catch = mygabor(visParams.pxlpdg, visParams.sizeDeg, visParams.orientations.trailing_mygabor(2), visParams.catchContrast);
visParams.textures.trailing_catch(1) = Screen('MakeTexture', window, gabor_trailing_cw_catch  * white);
visParams.textures.trailing_catch(2) = Screen('MakeTexture', window, gabor_trailing_ccw_catch  * white);


% 听觉刺激 (纯音)
audParams.samplingRate = 44100; % Hz
audParams.duration = 0.500; % 秒, 与 leading/trailingStimDur 一致
audParams.frequencies.leading = [1000, 1600]; % Hz
audParams.frequencies.trailing = [100, 160]; % Hz

% 初始化 PsychPortAudio
InitializePsychSound(1); % 以低延迟模式初始化
audParams.pahandle = PsychPortAudio('Open', [], [], 0, audParams.samplingRate, 2); % 打开默认声音设备, 立体声

% 预生成纯音数据
tone_leading_1000 = mytone(audParams.frequencies.leading(1), audParams.duration, audParams.samplingRate);
tone_leading_1600 = mytone(audParams.frequencies.leading(2), audParams.duration, audParams.samplingRate);
tone_trailing_100 = mytone(audParams.frequencies.trailing(1), audParams.duration, audParams.samplingRate);
tone_trailing_160 = mytone(audParams.frequencies.trailing(2), audParams.duration, audParams.samplingRate);

audParams.waveforms.leading = {tone_leading_1000, tone_leading_1600};
audParams.waveforms.trailing = {tone_trailing_100, tone_trailing_160};

% 捕获试验刺激参数 (较低音量)
audParams.catchVolumeMultiplier = 0.3; % 示例：捕获试验的音量乘数
audParams.waveforms.trailing_catch = {tone_trailing_100 * audParams.catchVolumeMultiplier, ...
    tone_trailing_160 * audParams.catchVolumeMultiplier};

% --- 注视点 ---
fixCrossDegree = 1;
fixCrossDimPix = fixCrossDegree * visParams.pxlpdg; % 注视点大小
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% --- 注意力提示图标 ---
% 加载或创建“眼睛”和“扬声器”图标
[eyeIconImg, ~, alphaEye] = imread('eye.png'); % 确保有图标文件
eyeIconImg(:,:,4) = alphaEye; % 添加alpha通道
visParams.cueTexture = Screen('MakeTexture', window, eyeIconImg);
[speakerIconImg, ~, alphaSpeaker] = imread('speaker.png');
speakerIconImg(:,:,4) = alphaSpeaker;
audParams.cueTexture = Screen('MakeTexture', window, speakerIconImg);
iconDegree = 3;  % 图标视角
iconSize = [iconDegree iconDegree] * visParams.pxlpdg; % 图标尺寸
iconRect = [0 0 iconSize(1) iconSize(2)];
expParams.cueIconPosRect = CenterRectOnPointd(iconRect, xCenter, ResY - 50 - iconSize(2)/2); % 屏幕底部中央


% --- 数据记录设置 ---
expData.explicitLearning = [];
expData.implicitTest = [];
expData.explicitRecall = [];
trialCountGlobal = 0; % 用于唯一的试验ID（如果需要）

% --- Staircase 初始化 (用于内隐测试阶段) ---
% 视觉 Staircase
stairParams.vis.initialDeviant = 20; % 初始视觉偏差量 (度)
stairParams.vis.currentDeviant = stairParams.vis.initialDeviant;
stairParams.vis.stepSizes = [4, 2, 1, 0.5]; % 逐渐减小的步长
stairParams.vis.reversalsToChangeStep = [2, 2, 3]; % 改变步长所需的转向次数 (例如, 前2次转向后用第一个步长，接下来2次用第二个，以此类推)
stairParams.vis.currentStepIndex = 1;
stairParams.vis.nDown = 3; % 3-down
stairParams.vis.nUp = 1;   % 1-up
stairParams.vis.correctStreak = 0; % 连续正确次数
stairParams.vis.reversalCount = 0; % 转向次数
stairParams.vis.lastDirection = 0; % 0=无, 1=向下调整 (变难), -1=向上调整 (变易)
stairParams.vis.deviantHistory = []; % 记录每次试验的偏差量

% 听觉 Staircase
stairParams.aud.initialDeviant = 20; % 初始听觉偏差量 (Hz)
stairParams.aud.currentDeviant = stairParams.aud.initialDeviant;
stairParams.aud.stepSizes = [4, 2, 1, 0.5]; % Hz
stairParams.aud.reversalsToChangeStep = [2, 2, 3];
stairParams.aud.currentStepIndex = 1;
stairParams.aud.nDown = 3;
stairParams.aud.nUp = 1;
stairParams.aud.correctStreak = 0;
stairParams.aud.reversalCount = 0;
stairParams.aud.lastDirection = 0;
stairParams.aud.deviantHistory = [];
% 交互设置初始化
HideCursor; % 隐藏鼠标指针
ListenChar(2); % 防止输入内容进入终端
%
%
%
%
%
%
%
%
%
%
% -------------------------------------------------------------------------
% 知情同意
% -------------------------------------------------------------------------
% 显示一般说明
Screen('TextFont', window, '-:lang=zh-cn');
% 准备显示文本内容
line1 = '欢迎参加本次实验';
line2 = '(按任意键继续)';
% 转换文本为字节数组
text1 = double(line1);
text2 = double(line2);
% 获取文本显示区域大小
bounds1 = Screen('TextBounds', window, text1);
bounds2 = Screen('TextBounds', window, text2);
% 居中显示文本
% 参数：窗口句柄，文本数组，x坐标，y坐标，颜色
Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter , white);
Screen('Flip', window);

KbStrokeWait;


% -------------------------------------------------------------------------
% 解释总体流程和任务
% -------------------------------------------------------------------------
text1 = double('实验包含三个阶段：');
text2 = double('阶段一：学习阶段 - 判断刺激对出现的频繁程度');
text3 = double('阶段二：测试阶段 - 判断目标刺激是标准刺激还是发生了微小偏差');
text4 = double('阶段三：回忆阶段 - 判断在学习阶段中刺激对出现的频繁程度');
text5 = double('(按任意键继续)');
bounds1 = Screen('TextBounds', window, text1);
bounds2 = Screen('TextBounds', window, text2);
bounds3 = Screen('TextBounds', window, text3);
bounds4 = Screen('TextBounds', window, text4);
bounds5 = Screen('TextBounds', window, text5);
Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
Screen('DrawText', window, text4, xCenter - bounds4(3)/2, yCenter + 2 * visParams.textSize, white);
Screen('DrawText', window, text5, xCenter - bounds5(3)/2, yCenter + 3 * visParams.textSize, white);
Screen('Flip', window);
KbStrokeWait;


% -------------------------------------------------------------------------
% 调整耳机音量
% -------------------------------------------------------------------------
text1 = double('现在将播放一些声音来调整您的耳机音量');
text2 = double('请将音量调整到舒适的水平');
text3 = double('(按任意键开始声音测试)');
bounds1 = Screen('TextBounds', window, text1);
bounds2 = Screen('TextBounds', window, text2);
bounds3 = Screen('TextBounds', window, text3);
Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
Screen('Flip', window);
KbStrokeWait;

PsychPortAudio('FillBuffer', audParams.pahandle, [audParams.waveforms.leading{1}; audParams.waveforms.leading{1}]); % 立体声
PsychPortAudio('Start', audParams.pahandle, 0, 0, 1);

text1 = double('音量调整完成了吗？');
text2 = double('(按任意键继续)');
bounds1 = Screen('TextBounds', window, text1);
bounds2 = Screen('TextBounds', window, text2);
Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
Screen('Flip', window);

KbStrokeWait;
PsychPortAudio('Stop', audParams.pahandle);


% -------------------------------------------------------------------------
% 解释按键反应方式
% -------------------------------------------------------------------------
text1 = double('在整个实验过程中，您将使用特定的按键进行反应');
text2 = double('关于使用哪些按键的说明将在每个Block开始前给出');
text3 = double('(按任意键开始第一阶段)');
bounds1 = Screen('TextBounds', window, text1);
bounds2 = Screen('TextBounds', window, text2);
bounds3 = Screen('TextBounds', window, text3);
Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
Screen('Flip', window);
KbStrokeWait;
%
%
%
%
%
% -------------------------------------------------------------------------
% 阶段一：明确学习阶段
% -------------------------------------------------------------------------
% 参数设置
expParams.explicitLearning.numBlocks = 4;
expParams.explicitLearning.trialsPerBlock = 40;
expParams.explicitLearning.catchTrialsPerBlock = 8; % 4个视觉，4个听觉
% 定义Block类型 (交替进行：视觉-听觉-视觉-听觉)
blockOrderPhase1 = repmat({'visual', 'auditory'}, 1, expParams.explicitLearning.numBlocks / 2);
currentTrialOverall = 0; % 用于数据保存的全局试验计数器
for iBlock = 1:expParams.explicitLearning.numBlocks
    attentedModality = blockOrderPhase1{iBlock}; % 'visual' 或 'auditory'

    % 显示Block指导语
    responseKeysThisBlock.frequent = expParams.keys.frequent;
    responseKeysThisBlock.infrequent = expParams.keys.infrequent;

    if strcmp(attentedModality, 'visual')
        taskModalityChinese = '视觉';
    else
        taskModalityChinese = '听觉';
    end

    % 每个Block开始时随机分配 'z' 和 'm' 给“频繁”和“不频繁”
    if rand < 0.5
        % 50%概率交换按键位置
        tempKey = responseKeysThisBlock.frequent;
        responseKeysThisBlock.frequent = responseKeysThisBlock.infrequent;
        responseKeysThisBlock.infrequent = tempKey;
    end


    keyFreqChar = upper(KbName(responseKeysThisBlock.frequent)); % 获取按键字符，转为大写
    keyInfreqChar = upper(KbName(responseKeysThisBlock.infrequent));


    keyWeakChar = upper(KbName(expParams.keys.weak));
    if strcmp(keyWeakChar, 'SPACE')
        keyWeakChar = '空格键';
    end % 更友好的显示



    text0 = [double('Block'),double(num2str(iBlock)),double('/'),double(num2str(expParams.explicitLearning.numBlocks)),double('-----学习阶段'),double(taskModalityChinese),double('任务')];
    text1 = [double('请关注'),double(taskModalityChinese),double('刺激对')];
    text2 = double('判断该类型刺激对是“频繁”出现还是“不频繁”出现');
    text3 = [double('如果认为是“频繁”的，请按') ,double(keyFreqChar),double('键')];
    text4 = [double('如果认为是“不频繁”的，请按'),double(keyInfreqChar),double('键')];
    text5 = double('如果跟随刺激中的一个(视觉或听觉)看起来“弱”(更暗或更小声)');
    text6 = [double('请按'), double(keyWeakChar),double('键')];
    text7 = double('(按任意键开始此Block)');
    bounds0 = Screen('TextBounds', window, text0);
    bounds1 = Screen('TextBounds', window, text1);
    bounds2 = Screen('TextBounds', window, text2);
    bounds3 = Screen('TextBounds', window, text3);
    bounds4 = Screen('TextBounds', window, text4);
    bounds5 = Screen('TextBounds', window, text5);
    bounds6 = Screen('TextBounds', window, text6);
    bounds7 = Screen('TextBounds', window, text7);
    Screen('DrawText', window, text0, xCenter - bounds0(3)/2, yCenter - 2*visParams.textSize, white);
    Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
    Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
    Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
    Screen('DrawText', window, text4, xCenter - bounds4(3)/2, yCenter + 2*visParams.textSize, white);
    Screen('DrawText', window, text5, xCenter - bounds5(3)/2, yCenter + 3*visParams.textSize, white);
    Screen('DrawText', window, text6, xCenter - bounds6(3)/2, yCenter + 4*visParams.textSize, white);
    Screen('DrawText', window, text7, xCenter - bounds7(3)/2, yCenter + 5*visParams.textSize, white);

    if strcmp(attentedModality,'visual')
        cue = visParams.cueTexture;
    else
        cue = audParams.cueTexture;
    end
    Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);

    Screen('Flip', window);

    KbStrokeWait;


    % ---为此Block生成试验---
    % 确定标准试验和捕获试验的数量
    numStandardTrials = expParams.explicitLearning.trialsPerBlock - expParams.explicitLearning.catchTrialsPerBlock;
    numCatchVisual = expParams.explicitLearning.catchTrialsPerBlock / 2;
    numCatchAuditory = expParams.explicitLearning.catchTrialsPerBlock / 2;

    % 0=标准, 1=视觉捕获, 2=听觉捕获
    trialProperties = [zeros(1, numStandardTrials), ones(1, numCatchVisual), ones(1, numCatchAuditory)];
    trialProperties = Shuffle(trialProperties); % 打乱试验类型

    for iTrial = 1:expParams.explicitLearning.trialsPerBlock
        currentTrialOverall = currentTrialOverall + 1;
        isCatchTrial = trialProperties(iTrial) > 0;
        catchModality = 'none';
        if trialProperties(iTrial) == 1
            catchModality = 'visual';
        elseif trialProperties(iTrial) == 2
            catchModality = 'auditory';
        end

        % 随机选择领先刺激 (需要确保所有可能的视觉-听觉组合出现次数大致相等)
        % 为简化，此处完全随机。对于领先刺激V-A对的严格平衡，
        % 您需要预先生成组合列表并打乱。
        visLeadingStimIdx = randi(2); % 1 或 2 (对应垂直或水平)
        audLeadingStimIdx = randi(2); % 1 或 2 (对应1000Hz或1600Hz)

        visLeadingGaborAng = visParams.orientations.leading_mygabor(visLeadingStimIdx);
        audLeadingFreq = audParams.frequencies.leading(audLeadingStimIdx);

        % 根据转移概率确定跟随刺激
        % 视觉
        randProbVis = rand;
        if visLeadingStimIdx == 1 % 领先刺激是“垂直” (mygabor 90°)
            if randProbVis < participant.visualMatrix.v0_t45 % 垂直 -> 顺时针 (45°)
                visTrailingStimIdx = 1; % 顺时针
                visTransitionExpected = true;
            else % 垂直 -> 逆时针 (135°)
                visTrailingStimIdx = 2; % 逆时针
                visTransitionExpected = false;
            end
        else % 领先刺激是“水平” (mygabor 0°)
            if randProbVis < participant.visualMatrix.v90_t135 % 水平 -> 逆时针 (135°)
                visTrailingStimIdx = 2; % 逆时针
                visTransitionExpected = true; % 注意：这里假设 v90_t135 是高概率，如果不是，则visTransitionExpected应为false
            else % 水平 -> 顺时针 (45°)
                visTrailingStimIdx = 1; % 顺时针
                visTransitionExpected = false; % 同样，检查转移矩阵定义
            end
        end
        visTrailingGaborAng = visParams.orientations.trailing_mygabor(visTrailingStimIdx);

        % 听觉
        randProbAud = rand;
        if audLeadingStimIdx == 1 % 领先刺激 1000Hz
            if randProbAud < participant.auditoryMatrix.a1000_t100 % 1000Hz -> 100Hz
                audTrailingStimIdx = 1; % 100Hz
                audTransitionExpected = true;
            else % 1000Hz -> 160Hz
                audTrailingStimIdx = 2; % 160Hz
                audTransitionExpected = false;
            end
        else % 领先刺激 1600Hz
            if randProbAud < participant.auditoryMatrix.a1600_t160 % 1600Hz -> 160Hz
                audTrailingStimIdx = 2; % 160Hz
                audTransitionExpected = true;
            else % 1600Hz -> 100Hz
                audTrailingStimIdx = 1; % 100Hz
                audTransitionExpected = false;
            end
        end
        audTrailingFreq = audParams.frequencies.trailing(audTrailingStimIdx);

        % --- 单个试验流程 ---
        % 1. 注视点
        currentFixationDur = expParams.fixationDurRange(1) + rand * (expParams.fixationDurRange(2) - expParams.fixationDurRange(1));
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2); % 加粗注视点

        % 绘制注意力提示图标
        if strcmp(attentedModality,'visual')
            cue = visParams.cueTexture;
        else
            cue = audParams.cueTexture;
        end
        Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);
        fixationStartTime = Screen('Flip', window);

        % 2. 领先刺激呈现
        while (GetSecs - fixationStartTime) < currentFixationDur
            % 等待注视点持续时间结束
            [~, ~, keyCodeF] = KbCheck;
            if any(keyCodeF)
                break
            end % 调试时允许提前退出
        end
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2); % 保持注视点
        Screen('DrawTexture', window, visParams.textures.leading(visLeadingStimIdx));
        % 绘制注意力提示图标
        if strcmp(attentedModality, 'visual')
            Screen('DrawTexture', window, visParams.cueTexture, [], expParams.cueIconPosRect);
        else
            Screen('DrawTexture', window, audParams.cueTexture, [], expParams.cueIconPosRect);
        end
        Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);
        % 翻转缓冲区,记录时间节点,在此之前填充听觉刺激缓冲区
        PsychPortAudio('FillBuffer', audParams.pahandle, [audParams.waveforms.leading{audLeadingStimIdx}; audParams.waveforms.leading{audLeadingStimIdx}]); % 立体声
        leadingStimStartTime = Screen('Flip', window);
        % 听觉刺激与视觉刺激同时出现
        PsychPortAudio('Start', audParams.pahandle, 1, leadingStimStartTime, 0); % 立即开始, 0表示不等待


        % 3. 刺激间隔 (ISI)
        while (GetSecs - leadingStimStartTime) < expParams.leadingStimDur
            [~, ~, keyCodeI] = KbCheck;
            if any(keyCodeI)
                break
            end
        end
        PsychPortAudio('Stop', audParams.pahandle, 1); % 停止声音，以防万一还在播放
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2); % 保持注视点

        if strcmp(attentedModality, 'visual')
            Screen('DrawTexture', window, visParams.cueTexture, [], expParams.cueIconPosRect);
        else
            Screen('DrawTexture', window, audParams.cueTexture, [], expParams.cueIconPosRect);
        end
        Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);

        isiStartTime = Screen('Flip', window);


        % 4. 跟随刺激呈现
        while (GetSecs - isiStartTime) < expParams.isiDur
            [~, ~, keyCodeT] = KbCheck;
            if any(keyCodeT)
                break
            end
        end
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2); % 保持注视点

        % 选择视觉跟随纹理 (捕获或标准)
        currentVisTrailingTexture = visParams.textures.trailing(visTrailingStimIdx);
        if isCatchTrial && strcmp(catchModality, 'visual')
            currentVisTrailingTexture = visParams.textures.trailing_catch(visTrailingStimIdx);
        end
        Screen('DrawTexture', window, currentVisTrailingTexture);

        % 选择听觉跟随波形 (捕获或标准)
        currentAudTrailingWaveform = audParams.waveforms.trailing{audTrailingStimIdx};
        if isCatchTrial && strcmp(catchModality, 'auditory')
            currentAudTrailingWaveform = audParams.waveforms.trailing_catch{audTrailingStimIdx};
        end
        % 填充听觉刺激缓冲区
        PsychPortAudio('FillBuffer', audParams.pahandle, [currentAudTrailingWaveform; currentAudTrailingWaveform]);

        if strcmp(attentedModality, 'visual')
            Screen('DrawTexture', window, visParams.cueTexture, [], expParams.cueIconPosRect);
        else
            Screen('DrawTexture', window, audParams.cueTexture, [], expParams.cueIconPosRect);
        end
        Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);

        % 听觉和视觉刺激同时产生
        trailingStimStartTime = Screen('Flip', window);
        PsychPortAudio('Start', audParams.pahandle, 1, trailingStimStartTime, 0);

        % 5. 反应屏幕
        while (GetSecs - trailingStimStartTime) < expParams.trailingStimDur
            [~, ~, keyCodeR] = KbCheck;
            if any(keyCodeR)
                break
            end
        end
        PsychPortAudio('Stop', audParams.pahandle, 1);



        text1 = [double('频繁---') ,double(keyFreqChar),double('   不频繁---'),double(keyInfreqChar),double('   弱---'),double(keyWeakChar)];
        bounds1 = Screen('TextBounds', window, text1);
        Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - 30, white);

        if strcmp(attentedModality, 'visual')
            Screen('DrawTexture', window, visParams.cueTexture, [], expParams.cueIconPosRect);
        else
            Screen('DrawTexture', window, audParams.cueTexture, [], expParams.cueIconPosRect);
        end
        Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);
        responseScreenStartTime = Screen('Flip', window);

        % 收集反应
        rt = NaN;
        responseKeyName = 'NaN';
        responseType = 'NaN';
        responded = false;
        while ~responded
            [keyIsDown, secs, keyCode] = KbCheck(-1); % -1 for all devices
            if keyIsDown
                if keyCode(responseKeysThisBlock.frequent)
                    responseType = 'frequent';
                    responseKeyName = KbName(responseKeysThisBlock.frequent);
                elseif keyCode(responseKeysThisBlock.infrequent)
                    responseType = 'infrequent';
                    responseKeyName = KbName(responseKeysThisBlock.infrequent);
                elseif keyCode(expParams.keys.weak)
                    responseType = 'weak';
                    responseKeyName = KbName(expParams.keys.weak);
                elseif keyCode(KbName('ESCAPE')) % 允许ESC退出
                    sca; PsychPortAudio('Close'); error('实验被用户中止。');
                end
                if ~strcmp(responseType, 'NaN')
                    rt = secs - responseScreenStartTime;
                    responded = true; % 退出循环
                end
            end
        end
        while KbCheck(-1)
        end % 等待按键释放

        % 判断准确性
        if isCatchTrial
            correctResponseType = 'weak';
        else % 非捕获试验
            expectedTransition = false;
            if strcmp(attentedModality, 'visual')
                expectedTransition = visTransitionExpected;
            elseif strcmp(attentedModality, 'auditory')
                expectedTransition = audTransitionExpected;
            end
            if expectedTransition % 如果是预期（高概率）转换
                correctResponseType = 'frequent';
            else % 如果是意外（低概率）转换
                correctResponseType = 'infrequent';
            end
        end
        accuracy = strcmp(responseType, correctResponseType);

        % 6. 反馈
        if accuracy
            feedbackColor = [0 255 0]; % 绿色
        else
            feedbackColor = [255 0 0]; % 红色
        end
        Screen('DrawLines', window, allCoords, 4, feedbackColor, [xCenter yCenter], 2);
        feedbackStartTime = Screen('Flip', window);
        WaitSecs(expParams.feedbackDur);

        % --- 存储试验数据 ---
        trialData.phase = 'ExplicitLearning';
        trialData.block = iBlock;
        trialData.trialInBlock = iTrial;
        trialData.trialOverall = currentTrialOverall;
        trialData.attentedModality = attentedModality;
        trialData.visLeadingStim_mygaborAng = visLeadingGaborAng;
        trialData.audLeadingStim_Hz = audLeadingFreq;
        trialData.visTrailingStim_mygaborAng = visTrailingGaborAng;
        trialData.audTrailingStim_Hz = audTrailingFreq;
        trialData.visTransitionExpected = visTransitionExpected;
        trialData.audTransitionExpected = audTransitionExpected;
        trialData.isCatchTrial = isCatchTrial;
        trialData.catchModality = catchModality; % 'visual', 'auditory', or 'none'
        trialData.responseKey = responseKeyName;
        trialData.responseType = responseType; % 'frequent', 'infrequent', 'weak'
        trialData.rt = rt;
        trialData.accuracy = accuracy;
        trialData.fixationDuration = currentFixationDur;
        trialData.assignedFreqKey = KbName(responseKeysThisBlock.frequent); % 记录当前block的按键分配
        trialData.assignedInfreqKey = KbName(responseKeysThisBlock.infrequent);

        if isempty(expData.explicitLearning)
            expData.explicitLearning = trialData;
        else
            expData.explicitLearning(end+1) = trialData;
        end
        % 每N次试验或每个Block结束时自动保存
        if mod(iTrial, 10) == 0 || iTrial == expParams.explicitLearning.trialsPerBlock
            save(sprintf('DATA_%s_Phase1_backup.mat', participant.ID), 'participant', 'expParams', 'expData', 'stairParams');
        end
    end % 结束试验循环

    % Block间休息
    if iBlock < expParams.explicitLearning.numBlocks
        text1 = [double('Block'),double(num2str(iBlock)),double('结束')];
        text2 = double('请稍作休息');
        text3 = double('(按任意键继续)');
        bounds1 = Screen('TextBounds', window, text1);
        bounds2 = Screen('TextBounds', window, text2);
        bounds3 = Screen('TextBounds', window, text3);
        Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
        Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
        Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
        Screen('Flip', window);
        KbStrokeWait;
    end
end % 结束Block循环

text1 = double('学习阶段结束');
text2 = double('(按任意键继续进入测试阶段)');
bounds1 = Screen('TextBounds', window, text1);
bounds2 = Screen('TextBounds', window, text2);
Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
Screen('Flip', window);
KbStrokeWait;
%
%
%
%
%
% -------------------------------------------------------------------------
% 阶段二：内隐测试阶段
% -------------------------------------------------------------------------
expParams.implicitTest.numBlocks = 10;
expParams.implicitTest.trialsPerBlock = 72;
expParams.implicitTest.catchTrialsPerBlock = 8; % 4个视觉，4个听觉
expParams.implicitTest.deviantTrialProportion = 0.50; % 50%的非捕获试验是偏差试验
blockOrderPhase2 = repmat({'visual', 'auditory'}, 1, expParams.implicitTest.numBlocks / 2);



for iBlock = 1:expParams.implicitTest.numBlocks
    attentedModality = blockOrderPhase2{iBlock};
    if strcmp(attentedModality, 'visual')
        taskModalityChinese = '视觉';
    else
        taskModalityChinese = '听觉';
    end

    % 显示Block指导语
    % 'deviant' 和 'standard' 的按键分配也可以进行平衡
    keyDevChar = upper(KbName(expParams.keys.deviant));
    keyStdChar = upper(KbName(expParams.keys.standard));
    keyWeakChar = upper(KbName(expParams.keys.weak));
    if strcmp(keyWeakChar, 'SPACE')
        keyWeakChar = '空格键';
    end
    text0 = [double('Block'),double(num2str(iBlock)),double('/'),double(num2str(expParams.implicitTest.numBlocks)),double('-----测试阶段'),double(taskModalityChinese),double('任务')];
    text1 = [double('请关注'),double(taskModalityChinese),double('刺激对')];
    text2 = double('判断它是“标准”刺激还是发生了微小“偏差”');
    text3 = [double('如果认为是“偏差”的，请按') ,double(keyDevChar),double('键')];
    text4 = [double('如果认为是“标准”的，请按'),double(keyStdChar),double('键')];
    text5 = double('如果跟随刺激中的一个(视觉或听觉)看起来“弱”(更暗或更小声)');
    text6 = [double('请按'), double(keyWeakChar),double('键')];
    text7 = double('(按任意键开始此Block)');
    bounds0 = Screen('TextBounds', window, text0);
    bounds1 = Screen('TextBounds', window, text1);
    bounds2 = Screen('TextBounds', window, text2);
    bounds3 = Screen('TextBounds', window, text3);
    bounds4 = Screen('TextBounds', window, text4);
    bounds5 = Screen('TextBounds', window, text5);
    bounds6 = Screen('TextBounds', window, text6);
    bounds7 = Screen('TextBounds', window, text7);
    Screen('DrawText', window, text0, xCenter - bounds0(3)/2, yCenter - 2*visParams.textSize, white);
    Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
    Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
    Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
    Screen('DrawText', window, text4, xCenter - bounds4(3)/2, yCenter + 2*visParams.textSize, white);
    Screen('DrawText', window, text5, xCenter - bounds5(3)/2, yCenter + 3*visParams.textSize, white);
    Screen('DrawText', window, text6, xCenter - bounds6(3)/2, yCenter + 4*visParams.textSize, white);
    Screen('DrawText', window, text7, xCenter - bounds7(3)/2, yCenter + 5*visParams.textSize, white);

    if strcmp(attentedModality, 'visual')
        Screen('DrawTexture', window, visParams.cueTexture, [], expParams.cueIconPosRect);
    else
        Screen('DrawTexture', window, audParams.cueTexture, [], expParams.cueIconPosRect);
    end
    Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);

    Screen('Flip', window);

    KbStrokeWait;


    % ---为此Block生成试验---
    numNonCatchTrials = expParams.implicitTest.trialsPerBlock - expParams.implicitTest.catchTrialsPerBlock;
    numDeviantTrialsInBlock = round(numNonCatchTrials * expParams.implicitTest.deviantTrialProportion);
    numStandardTrialsInBlock = numNonCatchTrials - numDeviantTrialsInBlock;
    numCatchVisual = expParams.implicitTest.catchTrialsPerBlock / 2;
    numCatchAuditory = expParams.implicitTest.catchTrialsPerBlock / 2;

    % 1=偏差, 2=标准, 3=视觉捕获, 4=听觉捕获
    trialProperties = [ones(1, numDeviantTrialsInBlock), ...
        2*ones(1, numStandardTrialsInBlock), ...
        3*ones(1, numCatchVisual), ...
        4*ones(1, numCatchAuditory)];
    trialProperties = Shuffle(trialProperties); % 打乱

    for iTrial = 1:expParams.implicitTest.trialsPerBlock
        currentTrialOverall = currentTrialOverall + 1;
        trialConditionCode = trialProperties(iTrial);

        isDeviantTrialItself = (trialConditionCode == 1); % 当前试验是否“应该”是偏差试验 (如果非捕获)
        isCatchTrial = (trialConditionCode == 3 || trialConditionCode == 4);
        catchModality = 'none';
        if trialConditionCode == 3; catchModality = 'visual'; end
        if trialConditionCode == 4; catchModality = 'auditory'; end

        % 选择领先刺激 (与阶段一相同，如果需要，确保平衡)
        visLeadingStimIdx = randi(2);
        audLeadingStimIdx = randi(2);
        visLeadingGaborAng = visParams.orientations.leading_mygabor(visLeadingStimIdx);
        audLeadingFreq = audParams.frequencies.leading(audLeadingStimIdx);

        % 根据转移概率确定“基础”跟随刺激 (与阶段一相同)
        % 这个概率结构仍然有效，即使它与当前阶段的任务无关。
        % 视觉
        randProbVis = rand;
        if visLeadingStimIdx == 1 % 垂直
            if randProbVis < participant.visualMatrix.v0_t45; visTrailingBaseIdx = 1; visExpected = true; else; visTrailingBaseIdx = 2; visExpected = false; end
        else % 水平
            if randProbVis < participant.visualMatrix.v90_t135; visTrailingBaseIdx = 2; visExpected = true; else; visTrailingBaseIdx = 1; visExpected = false; end
        end
        visTrailingBaseAng = visParams.orientations.trailing_mygabor(visTrailingBaseIdx);

        % 听觉
        randProbAud = rand;
        if audLeadingStimIdx == 1 % 1000Hz
            if randProbAud < participant.auditoryMatrix.a1000_t100; audTrailingBaseIdx = 1; audExpected = true; else; audTrailingBaseIdx = 2; audExpected = false; end
        else % 1600Hz
            if randProbAud < participant.auditoryMatrix.a1600_t160; audTrailingBaseIdx = 2; audExpected = true; else; audTrailingBaseIdx = 1; audExpected = false; end
        end
        audTrailingBaseFreq = audParams.frequencies.trailing(audTrailingBaseIdx);

        % --- 如果是偏差试验并且模态与注意模态匹配，则应用偏差 ---
        actualVisTrailingAng = visTrailingBaseAng;
        actualAudTrailingFreq = audTrailingBaseFreq;
        currentVisDeviationValue = 0; % 存储实际使用的偏差值
        currentAudDeviationValue = 0;
        targetIsDeviantStim = false; % 标记目标刺激本身是否是偏差刺激

        if isDeviantTrialItself && ~isCatchTrial % 仅对非捕获的偏差试验应用staircase偏差
            if strcmp(attentedModality, 'visual')
                currentVisDeviationValue = stairParams.vis.currentDeviant;
                % 应用偏差 (例如，加或减，决定规则)
                if rand < 0.5; actualVisTrailingAng = visTrailingBaseAng + currentVisDeviationValue;
                else; actualVisTrailingAng = visTrailingBaseAng - currentVisDeviationValue; end
                % 可选：确保方向在合理范围内，例如 mod(orientation, 180)
                actualVisTrailingAng = mod(actualVisTrailingAng, 180); % 确保在0-180度之间
                targetIsDeviantStim = true;
            elseif strcmp(attentedModality, 'auditory')
                currentAudDeviationValue = stairParams.aud.currentDeviant;
                if rand < 0.5; actualAudTrailingFreq = audTrailingBaseFreq + currentAudDeviationValue;
                else; actualAudTrailingFreq = audTrailingBaseFreq - currentAudDeviationValue; end
                if actualAudTrailingFreq <=0; actualAudTrailingFreq = 5; end % 防止频率<=0 Hz
                targetIsDeviantStim = true;
            end
        end

        % --- 为此试验生成刺激 (包括偏差) ---
        % 视觉跟随 (如果偏差，可能需要动态生成)
        if targetIsDeviantStim && strcmp(attentedModality, 'visual')
            visTrailingDeviantGabor = mygabor(visParams.pxlpdg, visParams.sizeDeg, actualVisTrailingAng);
            currentVisTrailingTexture = Screen('MakeTexture', window, visTrailingDeviantGabor*white);
        else % 标准或非注意模态的偏差试验（不应用staircase偏差）
            currentVisTrailingTexture = visParams.textures.trailing(visTrailingBaseIdx); % 标准纹理
        end
        % 如果是视觉捕获试验，则覆盖
        if isCatchTrial && strcmp(catchModality, 'visual')
            currentVisTrailingTexture = visParams.textures.trailing_catch(visTrailingBaseIdx); % 捕获纹理
            if targetIsDeviantStim && strcmp(attentedModality, 'visual'); Screen('Close', currentVisTrailingTexture); end % 如果之前为偏差创建了纹理，先关闭
        end


        % 听觉跟随 (如果偏差，可能需要动态生成)
        if targetIsDeviantStim && strcmp(attentedModality, 'auditory')
            audTrailingDeviantTone = mytone(actualAudTrailingFreq, audParams.duration, audParams.samplingRate);
            currentAudTrailingWaveform = audTrailingDeviantTone;
        else
            currentAudTrailingWaveform = audParams.waveforms.trailing{audTrailingBaseIdx}; % 标准波形
        end
        % 如果是听觉捕获试验，则覆盖
        if isCatchTrial && strcmp(catchModality, 'auditory')
            currentAudTrailingWaveform = audParams.waveforms.trailing_catch{audTrailingBaseIdx}; % 捕获波形
        end


        % --- 试验流程 (与阶段一大致相同) ---
        % 1. 注视点
        currentFixationDur = expParams.fixationDurRange(1) + rand * (expParams.fixationDurRange(2) - expParams.fixationDurRange(1));
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2);
        if ~expParams.useTextCues
            if strcmp(attentedModality, 'visual')
                Screen('DrawTexture', window, visParams.cueTexture, [], expParams.cueIconPosRect);
            else
                Screen('DrawTexture', window, audParams.cueTexture, [], expParams.cueIconPosRect);
            end
            Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);
        else
            %DrawFormattedText(window, sprintf('[注意模态: %s]', taskModalityChinese), 'center', screenYpixels - 70, black);
        end
        fixationStartTime = Screen('Flip', window);

        % 2. 领先刺激
        while (GetSecs - fixationStartTime) < currentFixationDur; [~,~,kF]=KbCheck; if any(kF); break;end; end
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2);
        Screen('DrawTexture', window, visParams.textures.leading(visLeadingStimIdx));

        if strcmp(attentedModality, 'visual')
            Screen('DrawTexture', window, visParams.cueTexture, [], expParams.cueIconPosRect);
        else
            Screen('DrawTexture', window, audParams.cueTexture, [], expParams.cueIconPosRect);
        end
        Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);

        leadingStimStartTime = Screen('Flip', window);
        PsychPortAudio('FillBuffer', audParams.pahandle, [audParams.waveforms.leading{audLeadingStimIdx}; audParams.waveforms.leading{audLeadingStimIdx}]);
        PsychPortAudio('Start', audParams.pahandle, 1, leadingStimStartTime, 0);

        % 3. ISI
        while (GetSecs - leadingStimStartTime) < expParams.leadingStimDur; [~,~,kI]=KbCheck; if any(kI); break;end; end
        PsychPortAudio('Stop', audParams.pahandle, 1);
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2);
        if strcmp(attentedModality, 'visual')
            Screen('DrawTexture', window, visParams.cueTexture, [], expParams.cueIconPosRect);
        else
            Screen('DrawTexture', window, audParams.cueTexture, [], expParams.cueIconPosRect);
        end
        Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);
        isiStartTime = Screen('Flip', window);

        % 4. 跟随刺激
        while (GetSecs - isiStartTime) < expParams.isiDur; [~,~,kT]=KbCheck; if any(kT); break;end; end
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2);
        Screen('DrawTexture', window, currentVisTrailingTexture); % 现在使用可能偏差或捕获的纹理
        PsychPortAudio('FillBuffer', audParams.pahandle, [currentAudTrailingWaveform; currentAudTrailingWaveform]); % 可能偏差/捕获

        if strcmp(attentedModality, 'visual')
            Screen('DrawTexture', window, visParams.cueTexture, [], expParams.cueIconPosRect);
        else
            Screen('DrawTexture', window, audParams.cueTexture, [], expParams.cueIconPosRect);
        end
        Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);

        trailingStimStartTime = Screen('Flip', window);
        PsychPortAudio('Start', audParams.pahandle, 1, trailingStimStartTime, 0);

        % 5. 反应屏幕
        while (GetSecs - trailingStimStartTime) < expParams.trailingStimDur; [~,~,kR]=KbCheck; if any(kR); break;end; end
        PsychPortAudio('Stop', audParams.pahandle, 1);

        text1 = [double('偏差') ,double(keyFreqChar),double('--标准'),double(keyInfreqChar),double('--弱'),double(keyWeakChar)];
        bounds1 = Screen('TextBounds', window, text1);
        Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - 30, white);


        if strcmp(attentedModality, 'visual')
            Screen('DrawTexture', window, visParams.cueTexture, [], expParams.cueIconPosRect);
        else
            Screen('DrawTexture', window, audParams.cueTexture, [], expParams.cueIconPosRect);
        end
        Screen('DrawTexture', window, cue, [], expParams.cueIconPosRect);

        responseScreenStartTime = Screen('Flip', window);

        % 收集反应
        rt = NaN;
        responseKeyName = 'NaN';
        responseType = 'NaN';
        responded = false;
        while ~responded
            [keyIsDown, secs, keyCode] = KbCheck(-1);
            if keyIsDown
                if keyCode(expParams.keys.deviant)
                    responseType = 'deviant'; responseKeyName = KbName(expParams.keys.deviant);
                elseif keyCode(expParams.keys.standard)
                    responseType = 'standard'; responseKeyName = KbName(expParams.keys.standard);
                elseif keyCode(expParams.keys.weak)
                    responseType = 'weak'; responseKeyName = KbName(expParams.keys.weak);
                elseif keyCode(KbName('ESCAPE'))
                    sca; PsychPortAudio('Close'); error('实验被用户中止。');
                end
                if ~strcmp(responseType, 'NaN')
                    rt = secs - responseScreenStartTime;
                    responded = true;
                end
            end
        end
        while KbCheck(-1); end % 等待按键释放

        % 判断准确性 (用于staircase更新和数据记录)
        if isCatchTrial % 捕获试验的正确反应是 'weak'
            correctResponseType = 'weak';
        elseif targetIsDeviantStim % 目标刺激是偏差刺激 (在注意模态中)
            correctResponseType = 'deviant';
        else % 目标刺激是标准刺激 (在注意模态中)
            correctResponseType = 'standard';
        end
        accuracy = strcmp(responseType, correctResponseType);

        % 6. 反馈 (视觉：绿色/红色注视点)
        if accuracy
            feedbackColor = [0 255 0]; % 绿色
        else
            feedbackColor = [255 0 0]; % 红色
        end
        Screen('DrawLines', window, allCoords, 4, feedbackColor, [xCenter yCenter], 2);
        feedbackStartTime = Screen('Flip', window);
        WaitSecs(expParams.feedbackDur);

        % --- 更新 Staircase (仅对非捕获试验，基于对偏差/标准的反应) ---
        staircaseUpdatedThisTrial = false;
        if ~isCatchTrial % 只有非捕获试验才更新staircase
            s = struct(); % 临时结构体
            currentStaircaseModality = '';
            if strcmp(attentedModality, 'visual')
                s = stairParams.vis; currentStaircaseModality = 'visual';
            elseif strcmp(attentedModality, 'auditory')
                s = stairParams.aud; currentStaircaseModality = 'auditory';
            end

            if ~isempty(currentStaircaseModality)
                staircaseUpdatedThisTrial = true;
                if targetIsDeviantStim % 目标是偏差刺激
                    if accuracy % 正确检测到偏差 (Hit)
                        s.correctStreak = s.correctStreak + 1;
                        if s.correctStreak >= s.nDown
                            s.currentDeviant = max(0.1, s.currentDeviant - s.stepSizes(s.currentStepIndex)); % 任务变难
                            s.correctStreak = 0;
                            if s.lastDirection == -1 || s.lastDirection == 0; s.reversalCount = s.reversalCount + 1; end % 从易变难或首次调整为难算转向
                            s.lastDirection = 1; % 向下调整 (变难)
                        end
                    else % 未检测到偏差 (Miss)
                        s.currentDeviant = s.currentDeviant + s.stepSizes(s.currentStepIndex); % 任务变易
                        s.correctStreak = 0;
                        if s.lastDirection == 1 || s.lastDirection == 0; s.reversalCount = s.reversalCount + 1; end % 从难变易或首次调整为易算转向
                        s.lastDirection = -1; % 向上调整 (变易)
                    end
                else % 目标是标准刺激
                    if ~accuracy % 错误地将标准判断为偏差 (False Alarm)
                        s.currentDeviant = s.currentDeviant + s.stepSizes(s.currentStepIndex); % 任务变易 (使偏差更明显)
                        s.correctStreak = 0; % 任何错误都重置连续正确次数
                        if s.lastDirection == 1 || s.lastDirection == 0; s.reversalCount = s.reversalCount + 1; end
                        s.lastDirection = -1;
                        % else: 正确地将标准判断为标准 (Correct Rejection) - 对连续正确次数无影响 (根据3-down-1-up规则)
                    end
                end
                % 根据转向次数更新步长
                nextStepChangeThreshold = 0;
                for k_step = 1:s.currentStepIndex
                    nextStepChangeThreshold = nextStepChangeThreshold + s.reversalsToChangeStep(k_step);
                end
                if s.reversalCount >= nextStepChangeThreshold && s.currentStepIndex < length(s.stepSizes)
                    s.currentStepIndex = s.currentStepIndex + 1;
                end
                s.deviantHistory(end+1) = s.currentDeviant; % 记录当前偏差值

                if strcmp(currentStaircaseModality, 'visual'); stairParams.vis = s;
                elseif strcmp(currentStaircaseModality, 'auditory'); stairParams.aud = s;
                end
            end
        end


        % --- 存储试验数据 ---
        trialData.phase = 'ImplicitTest';
        trialData.block = iBlock;
        trialData.trialInBlock = iTrial;
        trialData.trialOverall = currentTrialOverall;
        trialData.attentedModality = attentedModality;
        % 领先刺激
        trialData.visLeadingStim_mygaborAng = visLeadingGaborAng;
        trialData.audLeadingStim_Hz = audLeadingFreq;
        % 跟随刺激 (“基础”值，即应用偏差之前的值)
        trialData.visTrailingBase_mygaborAng = visTrailingBaseAng;
        trialData.audTrailingBase_Hz = audTrailingBaseFreq;
        % 跟随刺激的预期性 (基于领先刺激和转移概率)
        trialData.visTrailingExpected = visExpected; % 视觉跟随刺激是否预期
        trialData.audTrailingExpected = audExpected; % 听觉跟随刺激是否预期
        % 目标刺激 (注意模态中的跟随刺激)
        trialData.targetIsDeviantStim = targetIsDeviantStim; % 目标刺激本身是否是偏差的
        trialData.targetActualVisAng = actualVisTrailingAng; % 实际呈现的视觉角度
        trialData.targetActualAudFreq = actualAudTrailingFreq; % 实际呈现的听觉频率
        trialData.targetVisDeviationApplied = currentVisDeviationValue; % 应用的视觉偏差量, 0表示非视觉目标或无偏差
        trialData.targetAudDeviationApplied = currentAudDeviationValue; % 应用的听觉偏差量, 0表示非听觉目标或无偏差
        % 捕获试验信息
        trialData.isCatchTrial = isCatchTrial;
        trialData.catchModality = catchModality;
        % 反应和准确性
        trialData.responseKey = responseKeyName;
        trialData.responseType = responseType; % 'deviant', 'standard', 'weak'
        trialData.rt = rt;
        trialData.accuracy = accuracy; % 相对于偏差/标准/弱判断任务的准确性
        % 当前试验后的Staircase值
        trialData.staircaseVisCurrentDeviant = stairParams.vis.currentDeviant;
        trialData.staircaseAudCurrentDeviant = stairParams.aud.currentDeviant;
        trialData.staircaseUpdatedThisTrial = staircaseUpdatedThisTrial;
        % 注视点持续时间
        trialData.fixationDuration = currentFixationDur;

        if isempty(expData.implicitTest)
            expData.implicitTest = trialData;
        else
            expData.implicitTest(end+1) = trialData;
        end

        % 自动保存
        if mod(iTrial, 20) == 0 || iTrial == expParams.implicitTest.trialsPerBlock
            save(sprintf('DATA_%s_Phase2_backup.mat', participant.ID), 'participant', 'expParams', 'expData', 'stairParams');
        end

        % 如果为偏差刺激动态创建了纹理，则清理
        if targetIsDeviantStim && strcmp(attentedModality, 'visual') && exist('currentVisTrailingTexture', 'var') && Screen(currentVisTrailingTexture, 'WindowKind') == -1 % 检查是否为纹理
            Screen('Close', currentVisTrailingTexture);
        end

    end % 结束试验循环

    % Block间休息
    if iBlock < expParams.implicitTest.numBlocks

        text1 = [double('Block'),double(num2str(iBlock)),double('结束')];
        text2 = double('请稍作休息');
        text3 = double('(按任意键继续)');
        bounds1 = Screen('TextBounds', window, text1);
        bounds2 = Screen('TextBounds', window, text2);
        bounds3 = Screen('TextBounds', window, text3);
        Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
        Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
        Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
        Screen('Flip', window);
        KbStrokeWait;

    end
end % 结束Block循环


text1 = double('测试阶段结束');
text2 = double('(按任意键继续进入回忆阶段)');
bounds1 = Screen('TextBounds', window, text1);
bounds2 = Screen('TextBounds', window, text2);
Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
Screen('Flip', window);
KbStrokeWait;
%
%
%
%
%
% -------------------------------------------------------------------------
% 阶段三：明确回忆阶段
% -------------------------------------------------------------------------

expParams.explicitRecall.numBlocks = 2; % 1个视觉Block，1个听觉Block
expParams.explicitRecall.trialsPerBlock = 8; % 每种可能的刺激对呈现2次 (4种对 * 2次 = 8个试验)

recallBlockOrder = Shuffle({'visual', 'auditory'}); % 随机化视觉/听觉回忆Block的顺序

for iBlock = 1:expParams.explicitRecall.numBlocks
    recallModality = recallBlockOrder{iBlock}; % 'visual' 或 'auditory'
    if strcmp(recallModality, 'visual'); taskModalityChinese = '视觉'; else; taskModalityChinese = '听觉'; end

    % 定义当前模态的所有4种可能的刺激对
    stimulusPairs_definitions = []; % [leading_val, trailing_val]
    pairActualFrequencyStatus = []; % boolean, true if frequent

    if strcmp(recallModality, 'visual')
        L1 = visParams.orientations.leading_mygabor(1); L2 = visParams.orientations.leading_mygabor(2); % 垂直, 水平
        T1 = visParams.orientations.trailing_mygabor(1); T2 = visParams.orientations.trailing_mygabor(2); % 顺时针, 逆时针
        stimulusPairs_definitions = [L1, T1; L1, T2; L2, T1; L2, T2];
        % 根据参与者分配的矩阵判断这些对在学习阶段是否频繁
        % 注意：这里的键名v0_t45, v90_t135等需要与participant.visualMatrix中的字段名完全对应
        % 假设 v0 对应 L1 (垂直), v90 对应 L2 (水平)
        % 假设 t45 对应 T1 (顺时针), t135 对应 T2 (逆时针)
        pairActualFrequencyStatus = [
            (participant.visualMatrix.v0_t45 > 0.5)...  % 垂直 -> 顺时针
            (participant.visualMatrix.v0_t135 > 0.5)...% 垂直 -> 逆时针
            (participant.visualMatrix.v90_t45 > 0.5)... % 水平 -> 顺时针
            (participant.visualMatrix.v90_t135 > 0.5)  % 水平 -> 逆时针
            ];
    elseif strcmp(recallModality, 'auditory')
        L1 = audParams.frequencies.leading(1); L2 = audParams.frequencies.leading(2); % 1000Hz, 1600Hz
        T1 = audParams.frequencies.trailing(1); T2 = audParams.frequencies.trailing(2); % 100Hz, 160Hz
        stimulusPairs_definitions = [L1, T1; L1, T2; L2, T1; L2, T2];
        pairActualFrequencyStatus = [
            (participant.auditoryMatrix.a1000_t100 > 0.5)... % 1000Hz -> 100Hz
            (participant.auditoryMatrix.a1000_t160 > 0.5)...% 1000Hz -> 160Hz
            (participant.auditoryMatrix.a1600_t100 > 0.5)... % 1600Hz -> 100Hz
            (participant.auditoryMatrix.a1600_t160 > 0.5)  % 1600Hz -> 160Hz
            ];
    end

    % 创建8个试验 (每个刺激对呈现2次)
    trialPairIndices = [1:4, 1:4]; % 对应 stimulusPairs_definitions 的行号
    trialPairIndices = Shuffle(trialPairIndices); % 随机化试验顺序

    % 显示Block指导语 (频繁/不频繁的按键可以固定，或像阶段一那样随机化)
    keyFreqRecallChar = upper(KbName(expParams.keys.frequent)); % 或使用新的按键
    keyInfreqRecallChar = upper(KbName(expParams.keys.infrequent));

    text0 = [double('回忆阶段--'),double(taskModalityChinese),double('任务')];
    text1 = [double('您将看到/听到一个'),double(taskModalityChinese),double('刺激对')];
    text2 = double('请判断这个刺激对在初始学习阶段是“频繁”出现还是“不频繁”出现');
    text3 = [double('如果认为是“频繁”的，请按') ,double(keyFreqRecallChar),double('键')];
    text4 = [double('如果认为是“不频繁”的，请按 '),double(keyInfreqRecallChar),double('键')];
    text5 = double('(按任意键开始此Block)');
    bounds0 = Screen('TextBounds', window, text0);
    bounds1 = Screen('TextBounds', window, text1);
    bounds2 = Screen('TextBounds', window, text2);
    bounds3 = Screen('TextBounds', window, text3);
    bounds4 = Screen('TextBounds', window, text4);
    bounds5 = Screen('TextBounds', window, text5);
    Screen('DrawText', window, text0, xCenter - bounds0(3)/2, yCenter - 2*visParams.textSize, white);
    Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
    Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
    Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
    Screen('DrawText', window, text4, xCenter - bounds4(3)/2, yCenter + 2*visParams.textSize, white);
    Screen('DrawText', window, text5, xCenter - bounds5(3)/2, yCenter + 3*visParams.textSize, white);

    Screen('Flip', window);
    KbStrokeWait;

    for iTrial = 1:expParams.explicitRecall.trialsPerBlock
        currentTrialOverall = currentTrialOverall + 1;
        currentPairDefIdx = trialPairIndices(iTrial); % 获取要呈现的刺激对的定义索引

        currentLeadingStimValue = stimulusPairs_definitions(currentPairDefIdx, 1);
        currentTrailingStimValue = stimulusPairs_definitions(currentPairDefIdx, 2);
        thisPairWasFrequentInLearning = pairActualFrequencyStatus(currentPairDefIdx);

        % 获取正确的纹理/波形索引
        if strcmp(recallModality, 'visual')
            visLeadRecallIdx = find(visParams.orientations.leading_mygabor == currentLeadingStimValue);
            visTrailRecallIdx = find(visParams.orientations.trailing_mygabor == currentTrailingStimValue);
            audLeadRecallIdx = randi(2); % 无关刺激，但仍呈现
            audTrailRecallIdx = randi(2);% 无关刺激
        else % auditory
            audLeadRecallIdx = find(audParams.frequencies.leading == currentLeadingStimValue);
            audTrailRecallIdx = find(audParams.frequencies.trailing == currentTrailingStimValue);
            visLeadRecallIdx = randi(2); % 无关刺激
            visTrailRecallIdx = randi(2); % 无关刺激
        end

        % --- 试验流程 (更简单：注视点, 领先, ISI, 跟随, 反应。无捕获, 无反馈) ---
        % 1. 注视点
        currentFixationDur = expParams.fixationDurRange(1) + rand * (expParams.fixationDurRange(2) - expParams.fixationDurRange(1));
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2);
        fixationStartTime = Screen('Flip', window);

        % 2. 领先刺激 (同时呈现视觉和听觉，但只有一个与任务相关)
        while (GetSecs - fixationStartTime) < currentFixationDur; [~,~,kF]=KbCheck; if any(kF); break;end; end
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2);
        Screen('DrawTexture', window, visParams.textures.leading(visLeadRecallIdx));
        leadingStimStartTime = Screen('Flip', window);
        PsychPortAudio('FillBuffer', audParams.pahandle, [audParams.waveforms.leading{audLeadRecallIdx}; audParams.waveforms.leading{audLeadRecallIdx}]);
        PsychPortAudio('Start', audParams.pahandle, 1, leadingStimStartTime, 0);

        % 3. ISI
        while (GetSecs - leadingStimStartTime) < expParams.leadingStimDur; [~,~,kI]=KbCheck; if any(kI); break;end; end
        PsychPortAudio('Stop', audParams.pahandle, 1);
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2);
        isiStartTime = Screen('Flip', window);

        % 4. 跟随刺激
        while (GetSecs - isiStartTime) < expParams.isiDur; [~,~,kT]=KbCheck; if any(kT); break;end; end
        Screen('DrawLines', window, allCoords, 4, black, [xCenter yCenter], 2);
        Screen('DrawTexture', window, visParams.textures.trailing(visTrailRecallIdx));
        PsychPortAudio('FillBuffer', audParams.pahandle, [audParams.waveforms.trailing{audTrailRecallIdx}; audParams.waveforms.trailing{audTrailRecallIdx}]);
        trailingStimStartTime = Screen('Flip', window);
        PsychPortAudio('Start', audParams.pahandle, 1, trailingStimStartTime, 0);

        % 5. 反应屏幕
        while (GetSecs - trailingStimStartTime) < expParams.trailingStimDur; [~,~,kR]=KbCheck; if any(kR); break;end; end
        PsychPortAudio('Stop', audParams.pahandle, 1);
        %DrawFormattedText(window, sprintf('这个刺激对在学习阶段是 频繁 (%s) 还是 不频繁 (%s)?', ...
        % keyFreqRecallChar, keyInfreqRecallChar), 'center', 'center', black);
        responseScreenStartTime = Screen('Flip', window);

        % 收集反应
        rt = NaN;  responseKeyName = 'NaN'; responseType = 'NaN';
        responded = false;
        while ~responded
            [keyIsDown, secs, keyCode] = KbCheck(-1);
            if keyIsDown
                if keyCode(expParams.keys.frequent) % 使用与阶段一相同的按键变量或定义新的
                    responseType = 'frequent'; responseKeyName = KbName(expParams.keys.frequent);
                elseif keyCode(expParams.keys.infrequent)
                    responseType = 'infrequent'; responseKeyName = KbName(expParams.keys.infrequent);
                elseif keyCode(KbName('ESCAPE'))
                    sca; PsychPortAudio('Close'); error('实验被用户中止。');
                end
                if ~strcmp(responseType, 'NaN')
                    rt = secs - responseScreenStartTime;
                    responded = true;
                end
            end
        end
        while KbCheck(-1); end % 等待按键释放

        % 判断准确性
        if thisPairWasFrequentInLearning
            accuracy = strcmp(responseType, 'frequent');
        else
            accuracy = strcmp(responseType, 'infrequent');
        end

        % 此阶段无反馈

        % --- 存储试验数据 ---
        trialData.phase = 'ExplicitRecall';
        trialData.block = iBlock;
        trialData.recallModality = recallModality;
        trialData.trialInBlock = iTrial;
        trialData.trialOverall = currentTrialOverall;
        trialData.presentedPair_LeadingValue = currentLeadingStimValue; % 记录实际值 (角度/频率)
        trialData.presentedPair_TrailingValue = currentTrailingStimValue;
        trialData.wasActuallyFrequentInLearning = thisPairWasFrequentInLearning;
        trialData.responseKey = responseKeyName;
        trialData.responseType = responseType; % 'frequent', 'infrequent'
        trialData.rt = rt;
        trialData.accuracy = accuracy;
        trialData.fixationDuration = currentFixationDur;

        if isempty(expData.explicitRecall)
            expData.explicitRecall = trialData;
        else
            expData.explicitRecall(end+1) = trialData;
        end
    end % 结束试验循环

    % 自动保存
    save(sprintf('DATA_%s_Phase3_backup.mat', participant.ID), 'participant', 'expParams', 'expData', 'stairParams');

    if iBlock < expParams.explicitRecall.numBlocks
        text1 = [double('Block'),double(num2str(iBlock)),double('结束')];
        text2 = double('请稍作休息');
        text3 = double('(按任意键继续)');
        bounds1 = Screen('TextBounds', window, text1);
        bounds2 = Screen('TextBounds', window, text2);
        bounds3 = Screen('TextBounds', window, text3);
        Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
        Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
        Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
        Screen('Flip', window);
        KbStrokeWait;
    end
end % 结束Block循环

% -------------------------------------------------------------------------
% 实验结束
% -------------------------------------------------------------------------
text1 = [double('实验完成!')];
text2 = double('感谢您的参与');
text3 = double('(正在保存数据...)');
bounds1 = Screen('TextBounds', window, text1);
bounds2 = Screen('TextBounds', window, text2);
bounds3 = Screen('TextBounds', window, text3);
Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
Screen('Flip', window);


% 最终保存所有数据
dataFileName = sprintf('DATA_%s_FINAL.mat', participant.ID);
try
    save(dataFileName, 'participant', 'expParams', 'expData', 'stairParams');
    text1 = [double('感谢您的参与')];
    text2 = [double('数据已成功保存至：'),double(dataFileName)];
    text3 = double('(按任意键退出)');
    bounds1 = Screen('TextBounds', window, text1);
    bounds2 = Screen('TextBounds', window, text2);
    bounds3 = Screen('TextBounds', window, text3);
    Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
    Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
    Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
catch ME
    text1 = [double('感谢您的参与')];
    text2 = [double('保存数据时发生错误:'),double(ME.message)];
    text3 = double('(按任意键退出)');
    bounds1 = Screen('TextBounds', window, text1);
    bounds2 = Screen('TextBounds', window, text2);
    bounds3 = Screen('TextBounds', window, text3);
    Screen('DrawText', window, text1, xCenter - bounds1(3)/2, yCenter - visParams.textSize, white);
    Screen('DrawText', window, text2, xCenter - bounds2(3)/2, yCenter + 0, white);
    Screen('DrawText', window, text3, xCenter - bounds3(3)/2, yCenter + visParams.textSize, white);
    % 尝试用包含错误信息的文件名保存
    save(sprintf('DATA_%s_FINAL_SAVE_ERROR.mat', participant.ID), 'participant', 'expParams', 'expData', 'stairParams');
end

Screen('Flip', window);
KbStrokeWait;

% 清理
sca;
PsychPortAudio('Close', audParams.pahandle);
ShowCursor; % 显示鼠标指针
ListenChar(0); % 重新启用对Matlab命令窗口的键盘输入

