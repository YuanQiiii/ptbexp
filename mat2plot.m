% 扩展的实验数据分析脚本
% 分析三个阶段：明确学习、内隐测试、明确回忆
% 计算各条件下，被试在不同block间准确率的均值和标准差，并为每个主要分析绘制单独的柱状图窗口。

clear; close all; clc;

disp('开始多阶段数据分析 (每个主要分析在单独窗口)...');

% 0. 设置
% -------------------------------------------------------------------------
% 颜色定义
colors.phase1_unexpected_target = [0.7, 0, 0];       % 暗红色 (P1 非预期目标)
colors.phase1_expected_target = [0, 0.6, 0.7];       % 蓝绿色 (P1 预期目标)
colors.phase1_unexpected_distractor = [1, 0.6, 0.6]; % 浅红色 (P1 非预期干扰物)
colors.phase1_expected_distractor = [0.7, 0.9, 1];   % 浅蓝色 (P1 预期干扰物)

colors.phase2_standard = [0.2, 0.5, 0.8];      % 蓝色 (P2 标准)
colors.phase2_deviant = [0.8, 0.2, 0.2];       % 红色 (P2 偏差)

colors.phase3_infrequent = [0.8, 0.4, 0.1];    % 橙色 (P3 非频繁)
colors.phase3_frequent = [0.1, 0.6, 0.3];      % 绿色 (P3 频繁)


% 1. 加载单个参与者的数据
% -------------------------------------------------------------------------
[fileName, filePath] = uigetfile('DATA_*_FINAL.mat', '请选择单个参与者的最终数据文件 (DATA_xxx_FINAL.mat)');
if isequal(fileName, 0)
    disp('用户取消选择，分析中止。');
    return;
end
fullFilePath = fullfile(filePath, fileName);
fprintf('正在加载参与者数据: %s\n', fullFilePath);

try
    loadedData = load(fullFilePath);
    participantID = loadedData.participant.ID; % 获取参与者ID
    expData = loadedData.expData;
catch ME
    error('加载或处理参与者 %s 的数据时出错: %s', fileName, ME.message);
end

disp(['参与者 ', char(participantID),' 数据加载完毕。']);

% -------------------------------------------------------------------------
% 阶段一：明确学习阶段 (Explicit Learning)
% -------------------------------------------------------------------------
disp('--- 开始分析阶段一：明确学习 ---');
if isfield(expData, 'explicitLearning') && ~isempty(expData.explicitLearning)
    trialsPhase1 = struct2table(expData.explicitLearning, 'AsArray', true);

    % 添加目标预期和干扰物预期列
    trialsPhase1.targetExpected = false(height(trialsPhase1), 1);
    trialsPhase1.distractorExpected = false(height(trialsPhase1), 1);
    for iTrial = 1:height(trialsPhase1)
        if strcmp(trialsPhase1.attentedModality{iTrial}, 'visual')
            trialsPhase1.targetExpected(iTrial) = trialsPhase1.visTransitionExpected(iTrial);
            trialsPhase1.distractorExpected(iTrial) = trialsPhase1.audTransitionExpected(iTrial);
        elseif strcmp(trialsPhase1.attentedModality{iTrial}, 'auditory')
            trialsPhase1.targetExpected(iTrial) = trialsPhase1.audTransitionExpected(iTrial);
            trialsPhase1.distractorExpected(iTrial) = trialsPhase1.visTransitionExpected(iTrial);
        end
    end

    % 确保 accuracy 和 isCatchTrial 是逻辑类型
    if isnumeric(trialsPhase1.accuracy)
        trialsPhase1.accuracy = logical(trialsPhase1.accuracy);
    end
    if isnumeric(trialsPhase1.isCatchTrial)
        trialsPhase1.isCatchTrial = logical(trialsPhase1.isCatchTrial);
    end

    nonCatchTrialsP1 = trialsPhase1(~trialsPhase1.isCatchTrial, :);

    if isempty(nonCatchTrialsP1)
        disp('阶段一数据中没有非捕获试验。');
    else
        blockIDsP1 = unique(nonCatchTrialsP1.block);
        numBlocksP1 = length(blockIDsP1);

        % --- 图1: 阶段一 - 目标预期性准确率 ---
        figure('Name', ['P1 目标预期性 - ', char(participantID)], 'Position', [100, 600, 400, 400]);
        axA = axes;
        hold(axA, 'on');
        title(axA, {'阶段一: 目标预期性', ['参与者: ', char(participantID)]});
        ylabel(axA, '正确率 (%)');
        set(axA, 'XTick', [1, 2], 'XTickLabel', {'非预期目标', '预期目标'}, 'XLim', [0.5, 2.5], 'YLim', [0, 100]);

        block_acc_uex_target = [];
        block_acc_ex_target = [];

        for iB = 1:numBlocksP1
            currentBlockID = blockIDsP1(iB);
            blockData = nonCatchTrialsP1(nonCatchTrialsP1.block == currentBlockID, :);

            uex_target_trials_block = blockData(~blockData.targetExpected, :);
            if ~isempty(uex_target_trials_block)
                block_acc_uex_target = [block_acc_uex_target; mean(uex_target_trials_block.accuracy) * 100];
            else
                block_acc_uex_target = [block_acc_uex_target; NaN];
            end

            ex_target_trials_block = blockData(blockData.targetExpected, :);
            if ~isempty(ex_target_trials_block)
                block_acc_ex_target = [block_acc_ex_target; mean(ex_target_trials_block.accuracy) * 100];
            else
                block_acc_ex_target = [block_acc_ex_target; NaN];
            end
        end

        mean_uex_target = mean(block_acc_uex_target); % 使用 mean
        std_uex_target  = std(block_acc_uex_target);  % 使用 std
        if sum(~isnan(block_acc_uex_target)) < 2, std_uex_target = 0; end

        mean_ex_target = mean(block_acc_ex_target);
        std_ex_target  = std(block_acc_ex_target);
        if sum(~isnan(block_acc_ex_target)) < 2, std_ex_target = 0; end

        barA = bar(axA, [1, 2], [mean_uex_target, mean_ex_target], 0.6);
        barA.FaceColor = 'flat';
        barA.CData(1,:) = colors.phase1_unexpected_target;
        barA.CData(2,:) = colors.phase1_expected_target;

        if ~isnan(mean_uex_target) && ~isnan(mean_ex_target)
            erA = errorbar(axA, [1, 2], [mean_uex_target, mean_ex_target], [std_uex_target, std_ex_target]);
            erA.Color = [0 0 0]; erA.LineStyle = 'none'; erA.LineWidth = 1;
        end
        hold(axA, 'off');

        % --- 图2: 阶段一 - 干扰物预期性准确率 ---
        figure('Name', ['P1 干扰物预期性 - ', char(participantID)], 'Position', [550, 600, 400, 400]);
        axB = axes;
        hold(axB, 'on');
        title(axB, {'阶段一: 干扰物预期性', ['参与者: ', char(participantID)]});
        ylabel(axB, '正确率 (%)');
        set(axB, 'XTick', [1, 2], 'XTickLabel', {'非预期干扰物', '预期干扰物'}, 'XLim', [0.5, 2.5], 'YLim', [0, 100]);

        block_acc_uex_distractor = [];
        block_acc_ex_distractor = [];

        for iB = 1:numBlocksP1
            currentBlockID = blockIDsP1(iB);
            blockData = nonCatchTrialsP1(nonCatchTrialsP1.block == currentBlockID, :);

            uex_dist_trials_block = blockData(~blockData.distractorExpected, :);
            if ~isempty(uex_dist_trials_block)
                block_acc_uex_distractor = [block_acc_uex_distractor; mean(uex_dist_trials_block.accuracy) * 100];
            else
                block_acc_uex_distractor = [block_acc_uex_distractor; NaN];
            end

            ex_dist_trials_block = blockData(blockData.distractorExpected, :);
            if ~isempty(ex_dist_trials_block)
                block_acc_ex_distractor = [block_acc_ex_distractor; mean(ex_dist_trials_block.accuracy) * 100];
            else
                block_acc_ex_distractor = [block_acc_ex_distractor; NaN];
            end
        end

        mean_uex_dist = mean(block_acc_uex_distractor);
        std_uex_dist  = std(block_acc_uex_distractor);
        if sum(~isnan(block_acc_uex_distractor)) < 2, std_uex_dist = 0; end

        mean_ex_dist = mean(block_acc_ex_distractor);
        std_ex_dist  = std(block_acc_ex_distractor);
        if sum(~isnan(block_acc_ex_distractor)) < 2, std_ex_dist = 0; end

        barB = bar(axB, [1, 2], [mean_uex_dist, mean_ex_dist], 0.6);
        barB.FaceColor = 'flat';
        barB.CData(1,:) = colors.phase1_unexpected_distractor;
        barB.CData(2,:) = colors.phase1_expected_distractor;

        if ~isnan(mean_uex_dist) && ~isnan(mean_ex_dist)
            erB = errorbar(axB, [1, 2], [mean_uex_dist, mean_ex_dist], [std_uex_dist, std_ex_dist]);
            erB.Color = [0 0 0]; erB.LineStyle = 'none'; erB.LineWidth = 1;
        end
        hold(axB, 'off');
    end
else
    disp('未找到阶段一 (Explicit Learning) 的数据。');
    figure; title({'阶段一数据缺失', ['参与者: ', char(participantID)]});
end
disp('--- 完成分析阶段一 ---');

% -------------------------------------------------------------------------
% 阶段二：内隐测试阶段 (Implicit Test)
% -------------------------------------------------------------------------
disp('--- 开始分析阶段二：内隐测试 ---');
if isfield(expData, 'implicitTest') && ~isempty(expData.implicitTest)
    trialsPhase2 = struct2table(expData.implicitTest, 'AsArray', true);

    if isnumeric(trialsPhase2.accuracy)
        trialsPhase2.accuracy = logical(trialsPhase2.accuracy);
    end
    if isnumeric(trialsPhase2.isCatchTrial)
        trialsPhase2.isCatchTrial = logical(trialsPhase2.isCatchTrial);
    end
    if isnumeric(trialsPhase2.targetIsDeviantStim)
        trialsPhase2.targetIsDeviantStim = logical(trialsPhase2.targetIsDeviantStim);
    end

    nonCatchTrialsP2 = trialsPhase2(~trialsPhase2.isCatchTrial, :);

    if isempty(nonCatchTrialsP2)
        disp('阶段二数据中没有非捕获试验。');
    else
        modalitiesP2 = {'visual', 'auditory'};
        modalityLabelsP2 = {'视觉注意', '听觉注意'};
        figure_positions_P2 = {[100, 100, 400, 400], [550, 100, 400, 400]};


        for iMod = 1:length(modalitiesP2)
            currentModality = modalitiesP2{iMod};
            modalityLabel = modalityLabelsP2{iMod};

            modalityTrialsP2 = nonCatchTrialsP2(strcmp(nonCatchTrialsP2.attentedModality, currentModality), :);

            if isempty(modalityTrialsP2)
                disp(['阶段二 ', modalityLabel, ' 数据中没有非捕获试验。']);
                figure('Position', figure_positions_P2{iMod});
                title({['阶段二 ', modalityLabel, ' 数据缺失'], ['参与者: ', char(participantID)]});
                continue;
            end

            blockIDsP2_mod = unique(modalityTrialsP2.block);
            numBlocksP2_mod = length(blockIDsP2_mod);

            figure('Name', ['P2 ', modalityLabel, ' - ', char(participantID)], 'Position', figure_positions_P2{iMod});
            axC = axes;
            hold(axC, 'on');
            title(axC, {['阶段二: ', modalityLabel, ' (标准 vs. 偏差)'], ['参与者: ', char(participantID)]});
            ylabel(axC, '正确率 (%)');
            set(axC, 'XTick', [1, 2], 'XTickLabel', {'标准目标', '偏差目标'}, 'XLim', [0.5, 2.5], 'YLim', [0, 100]);

            block_acc_standard = [];
            block_acc_deviant = [];

            for iB = 1:numBlocksP2_mod
                currentBlockID = blockIDsP2_mod(iB);
                blockData = modalityTrialsP2(modalityTrialsP2.block == currentBlockID, :);

                standard_trials_block = blockData(~blockData.targetIsDeviantStim, :);
                if ~isempty(standard_trials_block)
                    block_acc_standard = [block_acc_standard; mean(standard_trials_block.accuracy) * 100];
                else
                    block_acc_standard = [block_acc_standard; NaN];
                end

                deviant_trials_block = blockData(blockData.targetIsDeviantStim, :);
                if ~isempty(deviant_trials_block)
                    block_acc_deviant = [block_acc_deviant; mean(deviant_trials_block.accuracy) * 100];
                else
                    block_acc_deviant = [block_acc_deviant; NaN];
                end
            end

            mean_standard = mean(block_acc_standard);
            std_standard  = std(block_acc_standard);
            if sum(~isnan(block_acc_standard)) < 2, std_standard = 0; end

            mean_deviant = mean(block_acc_deviant);
            std_deviant  = std(block_acc_deviant);
            if sum(~isnan(block_acc_deviant)) < 2, std_deviant = 0; end

            barC = bar(axC, [1, 2], [mean_standard, mean_deviant], 0.6);
            barC.FaceColor = 'flat';
            barC.CData(1,:) = colors.phase2_standard;
            barC.CData(2,:) = colors.phase2_deviant;

            if ~isnan(mean_standard) && ~isnan(mean_deviant)
                erC = errorbar(axC, [1, 2], [mean_standard, mean_deviant], [std_standard, std_deviant]);
                erC.Color = [0 0 0]; erC.LineStyle = 'none'; erC.LineWidth = 1;
            end
            hold(axC, 'off');
        end
    end
else
    disp('未找到阶段二 (Implicit Test) 的数据。');
    figure; title({'阶段二 (视觉) 数据缺失', ['参与者: ', char(participantID)]});
    figure; title({'阶段二 (听觉) 数据缺失', ['参与者: ', char(participantID)]});
end
disp('--- 完成分析阶段二 ---');

% -------------------------------------------------------------------------
% 阶段三：明确回忆阶段 (Explicit Recall)
% -------------------------------------------------------------------------
disp('--- 开始分析阶段三：明确回忆 ---');
if isfield(expData, 'explicitRecall') && ~isempty(expData.explicitRecall)
    trialsPhase3 = struct2table(expData.explicitRecall, 'AsArray', true);

    if isnumeric(trialsPhase3.accuracy)
        trialsPhase3.accuracy = logical(trialsPhase3.accuracy);
    end
    if isnumeric(trialsPhase3.wasActuallyFrequentInLearning)
        trialsPhase3.wasActuallyFrequentInLearning = logical(trialsPhase3.wasActuallyFrequentInLearning);
    end

    modalitiesP3 = {'visual', 'auditory'};
    modalityLabelsP3 = {'视觉回忆', '听觉回忆'};
    figure_positions_P3 = {[1000, 600, 400, 400], [1000, 100, 400, 400]}; % Adjusted positions for clarity


    for iMod = 1:length(modalitiesP3)
        currentModality = modalitiesP3{iMod};
        modalityLabel = modalityLabelsP3{iMod};

        modalityTrialsP3 = trialsPhase3(strcmp(trialsPhase3.recallModality, currentModality), :);

        if isempty(modalityTrialsP3)
            disp(['阶段三 ', modalityLabel, ' 数据缺失。']);
            figure('Position', figure_positions_P3{iMod});
            title({['阶段三 ', modalityLabel, ' 数据缺失'], ['参与者: ', char(participantID)]});
            continue;
        end

        figure('Name', ['P3 ', modalityLabel, ' - ', char(participantID)], 'Position', figure_positions_P3{iMod});
        axD = axes;
        hold(axD, 'on');
        title(axD, {['阶段三: ', modalityLabel, ' (实际非频繁 vs. 实际频繁)'],['参与者: ', char(participantID)]});
        ylabel(axD, '正确率 (%)');
        set(axD, 'XTick', [1, 2], 'XTickLabel', {'实际非频繁', '实际频繁'}, 'XLim', [0.5, 2.5], 'YLim', [0, 100]);

        infrequent_trials = modalityTrialsP3(~modalityTrialsP3.wasActuallyFrequentInLearning, :);
        frequent_trials   = modalityTrialsP3(modalityTrialsP3.wasActuallyFrequentInLearning, :);

        mean_acc_infrequent = NaN;
        std_acc_infrequent = 0;
        if ~isempty(infrequent_trials)
            mean_acc_infrequent = mean(infrequent_trials.accuracy) * 100;
        end

        mean_acc_frequent = NaN;
        std_acc_frequent = 0;
        if ~isempty(frequent_trials)
            mean_acc_frequent = mean(frequent_trials.accuracy) * 100;
        end

        barD = bar(axD, [1, 2], [mean_acc_infrequent, mean_acc_frequent], 0.6);
        barD.FaceColor = 'flat';
        barD.CData(1,:) = colors.phase3_infrequent;
        barD.CData(2,:) = colors.phase3_frequent;

        if ~isnan(mean_acc_infrequent) && ~isnan(mean_acc_frequent)
            erD = errorbar(axD, [1, 2], [mean_acc_infrequent, mean_acc_frequent], ...
                [std_acc_infrequent, std_acc_frequent]);
            erD.Color = [0 0 0]; erD.LineStyle = 'none'; erD.LineWidth = 1;
        end
        hold(axD, 'off');
    end
else
    disp('未找到阶段三 (Explicit Recall) 的数据。');
    figure; title({'阶段三 (视觉回忆) 数据缺失', ['参与者: ', char(participantID)]});
    figure; title({'阶段三 (听觉回忆) 数据缺失', ['参与者: ', char(participantID)]});
end
disp('--- 完成分析阶段三 ---');

disp('全部分析脚本执行完毕。所有图表已在单独窗口中生成。');