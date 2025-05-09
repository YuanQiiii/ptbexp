% 实验数据分析脚本 (单被试，仅含图A和B：准确率均值与标准差柱状图)
% Mean-Std 是基于各条件下，被试在不同block间准确率的均值和标准差。


clear; close all; clc;

disp('开始单被试数据分析 (图A & B)...');

%% 0. 设置
% -------------------------------------------------------------------------
% 颜色定义 (根据Fig. 2)
colors.unexpected_target = [0.7, 0, 0];       % 暗红色
colors.expected_target = [0, 0.6, 0.7];       % 蓝绿色/青色
colors.unexpected_distractor = [1, 0.6, 0.6]; % 浅红色
colors.expected_distractor = [0.7, 0.9, 1];   % 浅蓝色

%% 1. 加载单个参与者的数据
% -------------------------------------------------------------------------
[fileName, filePath] = uigetfile('DATA_*_Phase1_backup.mat', '请选择单个参与者的数据文件');
if isequal(fileName, 0)
    disp('用户取消选择，分析中止。');
    return;
end
fullFilePath = fullfile(filePath, fileName);
fprintf('正在加载参与者数据: %s\n', fullFilePath);

try
    loadedData = load(fullFilePath);

    % 提取Explicit Learning阶段的数据
    if isfield(loadedData, 'expData') && isfield(loadedData.expData, 'explicitLearning') && ~isempty(loadedData.expData.explicitLearning)
        participantID = loadedData.participant.ID; % 获取参与者ID
        trials = loadedData.expData.explicitLearning;

        % 将结构体数组转换为表格，以便更容易处理
        trialsTable = struct2table(trials, 'AsArray', true);
        trialsTable.participantID = repmat(categorical({participantID}), height(trialsTable), 1);

        % 添加其他可能需要的预处理列
        trialsTable.targetExpected = false(height(trialsTable), 1);
        trialsTable.distractorExpected = false(height(trialsTable), 1);
        trialsTable.respondedInfrequent = false(height(trialsTable), 1);

        for iTrial = 1:height(trialsTable)
            if strcmp(trialsTable.responseType{iTrial}, 'infrequent')
                trialsTable.respondedInfrequent(iTrial) = true;
            end
            if strcmp(trialsTable.attentedModality{iTrial}, 'visual')
                trialsTable.targetExpected(iTrial) = trialsTable.visTransitionExpected(iTrial);
                trialsTable.distractorExpected(iTrial) = trialsTable.audTransitionExpected(iTrial);
            elseif strcmp(trialsTable.attentedModality{iTrial}, 'auditory')
                trialsTable.targetExpected(iTrial) = trialsTable.audTransitionExpected(iTrial);
                trialsTable.distractorExpected(iTrial) = trialsTable.visTransitionExpected(iTrial);
            end
        end

        allTrialData = trialsTable;
    else
        error('参与者 %s 的数据文件缺少 expData.explicitLearning 或该字段为空。', fileName);
    end
catch ME
    error('加载或处理参与者 %s 的数据时出错: %s', fileName, ME.message);
end

disp(['参与者 ', char(participantID),' 数据加载和初步处理完毕。']);

% 确保 accuracy 和 isCatchTrial 是逻辑类型
if isnumeric(allTrialData.accuracy)
    allTrialData.accuracy = logical(allTrialData.accuracy);
end
if isnumeric(allTrialData.isCatchTrial)
    allTrialData.isCatchTrial = logical(allTrialData.isCatchTrial);
end

%% 2. 数据筛选 (仅关注非捕获试验)
% -------------------------------------------------------------------------
nonCatchTrials = allTrialData(~allTrialData.isCatchTrial, :);

if isempty(nonCatchTrials)
    disp('数据中没有非捕获试验，分析无法进行。');
    return;
end

% 获取block信息
blockIDs = unique(nonCatchTrials.block);
numBlocks = length(blockIDs);
if numBlocks < 2
    disp('警告: Block数量少于2，基于block的标准差可能无意义或无法计算。将计算总体均值，标准差为0或NaN。');
end

%% 3. 生成图表 (参照Fig. 2 A 和 B)
% -------------------------------------------------------------------------
mainFig = figure('Name', ['分析结果 - 参与者: ', char(participantID)], 'Position', [100, 100, 800, 400]);

% --- Panel A: Target Expectation Accuracy (Mean-Std per block) ---
axA = subplot(1,2,1);
hold(axA, 'on');
title(axA, 'A: 目标预期性');
ylabel(axA, '正确率 (%)');
set(axA, 'XTick', [1, 2], 'XTickLabel', {'非预期目标', '预期目标'}, 'XLim', [0.5, 2.5], 'YLim', [0, 100]);

block_acc_uex_target = [];
block_acc_ex_target = [];

for iBlock = 1:numBlocks
    currentBlock = blockIDs(iBlock);
    blockData = nonCatchTrials(nonCatchTrials.block == currentBlock, :);

    % Unexpected Target Trials
    uex_target_trials_block = blockData(~blockData.targetExpected, :);
    if ~isempty(uex_target_trials_block)
        block_acc_uex_target = [block_acc_uex_target; mean(uex_target_trials_block.accuracy) * 100]; %#ok<AGROW>
    else
        block_acc_uex_target = [block_acc_uex_target; NaN]; % 如果该block没有此类试验
    end

    % Expected Target Trials
    ex_target_trials_block = blockData(blockData.targetExpected, :);
    if ~isempty(ex_target_trials_block)
        block_acc_ex_target = [block_acc_ex_target; mean(ex_target_trials_block.accuracy) * 100]; %#ok<AGROW>
    else
        block_acc_ex_target = [block_acc_ex_target; NaN];
    end
end

% 计算均值和标准差 (手动处理NaN)
valid_block_acc_uex_target = block_acc_uex_target(~isnan(block_acc_uex_target));
if isempty(valid_block_acc_uex_target)
    mean_uex_target = NaN;
    std_uex_target  = NaN;
else
    mean_uex_target = mean(valid_block_acc_uex_target);
    if length(valid_block_acc_uex_target) < 2 % std未定义或为0
        std_uex_target  = 0;
    else
        std_uex_target  = std(valid_block_acc_uex_target);
    end
end

valid_block_acc_ex_target = block_acc_ex_target(~isnan(block_acc_ex_target));
if isempty(valid_block_acc_ex_target)
    mean_ex_target = NaN;
    std_ex_target  = NaN;
else
    mean_ex_target = mean(valid_block_acc_ex_target);
    if length(valid_block_acc_ex_target) < 2
        std_ex_target  = 0;
    else
        std_ex_target  = std(valid_block_acc_ex_target);
    end
end

% 如果block数小于2的原始警告仍然适用，std将被设为0
if numBlocks < 2 && isnan(std_uex_target) % 确保如果之前因为有效数据点少于2个而设为0，这里不会覆盖
    std_uex_target = 0;
end
if numBlocks < 2 && isnan(std_ex_target)
    std_ex_target  = 0;
end


bA = bar(axA, [1, 2], [mean_uex_target, mean_ex_target], 0.6);
bA.FaceColor = 'flat';
bA.CData(1,:) = colors.unexpected_target;
bA.CData(2,:) = colors.expected_target;

if ~isnan(mean_uex_target) && ~isnan(mean_ex_target) % 只有在均值有效时才画误差棒
    erA = errorbar(axA, [1, 2], [mean_uex_target, mean_ex_target], [std_uex_target, std_ex_target]);
    erA.Color = [0 0 0];
    erA.LineStyle = 'none';
    erA.LineWidth = 1;
end

hold(axA, 'off');
disp('Panel A (目标预期性准确率 Mean-Std) 已生成。');

% --- Panel B: Distractor Expectation Accuracy (Mean-Std per block) ---
axB = subplot(1,2,2);
hold(axB, 'on');
title(axB, 'B: 干扰物预期性');
ylabel(axB, '正确率 (%)');
set(axB, 'XTick', [1, 2], 'XTickLabel', {'非预期干扰物', '预期干扰物'}, 'XLim', [0.5, 2.5], 'YLim', [0, 100]);

block_acc_uex_distractor = [];
block_acc_ex_distractor = [];

for iBlock = 1:numBlocks
    currentBlock = blockIDs(iBlock);
    blockData = nonCatchTrials(nonCatchTrials.block == currentBlock, :);

    % Unexpected Distractor Trials
    uex_dist_trials_block = blockData(~blockData.distractorExpected, :);
    if ~isempty(uex_dist_trials_block)
        block_acc_uex_distractor = [block_acc_uex_distractor; mean(uex_dist_trials_block.accuracy) * 100]; %#ok<AGROW>
    else
        block_acc_uex_distractor = [block_acc_uex_distractor; NaN];
    end

    % Expected Distractor Trials
    ex_dist_trials_block = blockData(blockData.distractorExpected, :);
    if ~isempty(ex_dist_trials_block)
        block_acc_ex_distractor = [block_acc_ex_distractor; mean(ex_dist_trials_block.accuracy) * 100]; %#ok<AGROW>
    else
        block_acc_ex_distractor = [block_acc_ex_distractor; NaN];
    end
end

% 计算均值和标准差 (手动处理NaN)
valid_block_acc_uex_distractor = block_acc_uex_distractor(~isnan(block_acc_uex_distractor));
if isempty(valid_block_acc_uex_distractor)
    mean_uex_dist = NaN;
    std_uex_dist  = NaN;
else
    mean_uex_dist = mean(valid_block_acc_uex_distractor);
    if length(valid_block_acc_uex_distractor) < 2
        std_uex_dist  = 0;
    else
        std_uex_dist  = std(valid_block_acc_uex_distractor);
    end
end

valid_block_acc_ex_distractor = block_acc_ex_distractor(~isnan(block_acc_ex_distractor));
if isempty(valid_block_acc_ex_distractor)
    mean_ex_dist = NaN;
    std_ex_dist  = NaN;
else
    mean_ex_dist = mean(valid_block_acc_ex_distractor);
    if length(valid_block_acc_ex_distractor) < 2
        std_ex_dist  = 0;
    else
        std_ex_dist  = std(valid_block_acc_ex_distractor);
    end
end

if numBlocks < 2 && isnan(std_uex_dist)
    std_uex_dist = 0;
end
if numBlocks < 2 && isnan(std_ex_dist)
    std_ex_dist  = 0;
end

bB = bar(axB, [1, 2], [mean_uex_dist, mean_ex_dist], 0.6);
bB.FaceColor = 'flat';
bB.CData(1,:) = colors.unexpected_distractor;
bB.CData(2,:) = colors.expected_distractor;

if ~isnan(mean_uex_dist) && ~isnan(mean_ex_dist)
    erB = errorbar(axB, [1, 2], [mean_uex_dist, mean_ex_dist], [std_uex_dist, std_ex_dist]);
    erB.Color = [0 0 0];
    erB.LineStyle = 'none';
    erB.LineWidth = 1;
end

hold(axB, 'off');
disp('Panel B (干扰物预期性准确率 Mean-Std) 已生成。');

disp('单被试分析脚本执行完毕。');