% MATLAB 脚本：用于绘制心理物理实验结果图
% 功能：加载实验数据，并根据不同实验阶段绘制准确率、反应时、阶梯阈限等图表。

% --- 初始化 ---
clear; % 清空工作区变量
clc;   % 清空命令行窗口
close all; % 关闭所有已打开的图形窗口

fprintf('开始执行实验数据绘图脚本...\n');

% --- 加载数据 ---
% 提示用户通过对话框选择包含实验数据的 .mat 文件
[fileName, pathName] = uigetfile('*.mat', '请选择您的实验数据文件 (例如 DATA_PARTICIPANTID_FINAL.mat)');

% 检查用户是否取消了文件选择
if isequal(fileName, 0) || isequal(pathName, 0)
    disp('用户取消了文件选择，脚本终止。');
    return;
else
    % 构建完整的文件路径
    fullFilePath = fullfile(pathName, fileName);
    fprintf('正在加载数据文件: %s\n', fullFilePath);
end

% 尝试加载数据文件
try
    loadedData = load(fullFilePath);
    fprintf('数据加载成功。\n');
catch ME % 如果加载失败，则捕获错误信息
    fprintf('加载数据文件失败: %s\n', ME.message);
    fprintf('请确保选择的是正确的 .mat 文件，并且文件未损坏。\n');
    return;
end

% --- 数据校验与提取 ---
% 检查核心数据结构是否存在于加载的数据中
if ~isfield(loadedData, 'expData')
    disp('错误: 加载的数据中未找到核心的 ''expData'' 结构。脚本无法继续。');
    return;
end
expData = loadedData.expData;

% 提取参与者信息 (如果存在)
if isfield(loadedData, 'participant') && isfield(loadedData.participant, 'ID')
    participantID = loadedData.participant.ID;
    fprintf('参与者ID: %s\n', participantID);
else
    participantID = '未知参与者';
    disp('警告: 未找到参与者ID，图表标题将使用默认值。');
end

% 提取阶梯参数 (如果存在，主要用于内隐测试阶段)
stairParams = []; % 初始化
if isfield(loadedData, 'stairParams')
    stairParams = loadedData.stairParams;
end

% --- 绘图参数和颜色定义 ---
% 为不同条件定义颜色，方便区分
colors.visual = [0 0.4470 0.7410];    % 蓝色 (视觉)
colors.auditory = [0.8500 0.3250 0.0980];  % 橙色 (听觉)
colors.frequent = [0.1 0.7 0.1];        % 深绿色 (频繁)
colors.infrequent = [0.8 0.1 0.1];      % 深红色 (不频繁)
colors.deviant = [0.6350 0.0780 0.1840]; % 暗红色 (偏差)
colors.standard = [0.4660 0.6740 0.1880];% 橄榄绿 (标准)
colors.catch = [0.5 0.5 0.5];          % 灰色 (捕获试验)

lineWidth = 1.5; % 定义绘图线条宽度
markerSize = 6;  % 定义标记点大小

% --- 阶段一：明确学习阶段 (Explicit Learning) ---
if isfield(expData, 'explicitLearning') && ~isempty(expData.explicitLearning)
    fprintf('\n--- 正在处理阶段一：明确学习阶段数据 ---\n');
    dataPhase1 = expData.explicitLearning;

    % 获取总的Block数量
    if isfield(dataPhase1, 'block') && ~isempty([dataPhase1.block])
        numBlocksPhase1 = max([dataPhase1.block]);
    else
        disp('警告: 学习阶段数据中缺少 ''block'' 字段或为空。无法按Block分析。');
        numBlocksPhase1 = 0;
    end

    % 初始化存储每个Block数据的变量
    accuracyPerBlockVis = NaN(1, numBlocksPhase1);
    rtPerBlockVis = NaN(1, numBlocksPhase1);
    accuracyPerBlockAud = NaN(1, numBlocksPhase1);
    rtPerBlockAud = NaN(1, numBlocksPhase1);

    % 初始化存储频繁/不频繁判断准确率的变量
    accFrequentVis_Overall = [];
    accInfrequentVis_Overall = [];
    accFrequentAud_Overall = [];
    accInfrequentAud_Overall = [];

    for b = 1:numBlocksPhase1
        % 筛选当前Block的试验
        trialsInBlock = dataPhase1([dataPhase1.block] == b);
        if isempty(trialsInBlock)
            continue; % 如果某个Block没有数据，则跳过
        end

        currentModality = trialsInBlock(1).attentedModality; % 获取当前Block的注意模态

        % 排除捕获试验 (Catch Trials) 进行准确率和反应时分析
        nonCatchTrials = trialsInBlock([trialsInBlock.isCatchTrial] == false);

        if ~isempty(nonCatchTrials)
            % 计算当前Block的平均准确率
            currentBlockAccuracy = mean([nonCatchTrials.accuracy], 'omitnan');
            % 计算当前Block正确反应的平均反应时间
            correctTrials = nonCatchTrials([nonCatchTrials.accuracy] == true);
            if ~isempty(correctTrials)
                currentBlockRT = mean([correctTrials.rt], 'omitnan');
            else
                currentBlockRT = NaN;
            end

            % 根据注意模态存储数据
            if strcmp(currentModality, 'visual')
                accuracyPerBlockVis(b) = currentBlockAccuracy;
                rtPerBlockVis(b) = currentBlockRT;
                % 收集视觉任务中对“频繁”和“不频繁”转换的判断准确性
                for t = 1:length(nonCatchTrials)
                    % 检查试验是否为非捕获试验 (虽然我们已经筛选过，但为了逻辑清晰再次确认)
                    if ~nonCatchTrials(t).isCatchTrial
                        % 判断当前注意模态下的转换是否为预期（高概率）
                        isExpectedTransition = nonCatchTrials(t).visTransitionExpected;
                        if isExpectedTransition % 高概率转换，正确答案是 'frequent'
                            accFrequentVis_Overall = [accFrequentVis_Overall, nonCatchTrials(t).accuracy];
                        else % 低概率转换，正确答案是 'infrequent'
                            accInfrequentVis_Overall = [accInfrequentVis_Overall, nonCatchTrials(t).accuracy];
                        end
                    end
                end
            elseif strcmp(currentModality, 'auditory')
                accuracyPerBlockAud(b) = currentBlockAccuracy;
                rtPerBlockAud(b) = currentBlockRT;
                for t = 1:length(nonCatchTrials)
                    if ~nonCatchTrials(t).isCatchTrial
                        isExpectedTransition = nonCatchTrials(t).audTransitionExpected;
                        if isExpectedTransition
                            accFrequentAud_Overall = [accFrequentAud_Overall, nonCatchTrials(t).accuracy];
                        else
                            accInfrequentAud_Overall = [accInfrequentAud_Overall, nonCatchTrials(t).accuracy];
                        end
                    end
                end
            end
        end
    end

    % 绘制学习阶段准确率随Block变化的曲线
    figure('Name', sprintf('P%s - 学习阶段 - 准确率', participantID), 'NumberTitle', 'off');
    hold on;
    validVisBlocks = find(~isnan(accuracyPerBlockVis)); % 找到有数据的视觉Block
    validAudBlocks = find(~isnan(accuracyPerBlockAud)); % 找到有数据的听觉Block
    if ~isempty(validVisBlocks)
        plot(validVisBlocks, accuracyPerBlockVis(validVisBlocks), 'o-', 'LineWidth', lineWidth, 'Color', colors.visual, 'MarkerSize', markerSize, 'DisplayName', '视觉任务');
    end
    if ~isempty(validAudBlocks)
        plot(validAudBlocks, accuracyPerBlockAud(validAudBlocks), 's-', 'LineWidth', lineWidth, 'Color', colors.auditory, 'MarkerSize', markerSize, 'DisplayName', '听觉任务');
    end
    hold off;
    xlabel('Block 序号');
    ylabel('平均准确率 (非捕获试验)');
    title(sprintf('参与者 %s: 学习阶段准确率（按Block）', participantID));
    legend('show', 'Location', 'best');
    ylim([0 1.1]); % 设置Y轴范围为0到1.1，方便观察
    grid on; % 添加网格线

    % 绘制学习阶段反应时间随Block变化的曲线
    figure('Name', sprintf('P%s - 学习阶段 - 反应时间', participantID), 'NumberTitle', 'off');
    hold on;
    if ~isempty(validVisBlocks)
        plot(validVisBlocks, rtPerBlockVis(validVisBlocks), 'o-', 'LineWidth', lineWidth, 'Color', colors.visual, 'MarkerSize', markerSize, 'DisplayName', '视觉任务');
    end
    if ~isempty(validAudBlocks)
        plot(validAudBlocks, rtPerBlockAud(validAudBlocks), 's-', 'LineWidth', lineWidth, 'Color', colors.auditory, 'MarkerSize', markerSize, 'DisplayName', '听觉任务');
    end
    hold off;
    xlabel('Block 序号');
    ylabel('平均反应时间 (秒, 正确非捕获试验)');
    title(sprintf('参与者 %s: 学习阶段反应时间（按Block）', participantID));
    legend('show', 'Location', 'best');
    % 动态调整Y轴上限，如果所有RT都很小，则上限不会太大
    allRTs = [rtPerBlockVis(~isnan(rtPerBlockVis)), rtPerBlockAud(~isnan(rtPerBlockAud))];
    if ~isempty(allRTs) && any(allRTs > 0)
        ylim([0 max(allRTs)*1.1 + 0.1]); % Y轴从0开始, 留出一点上边距
    else
        ylim([0 1]); % 如果没有有效RT数据，设置一个默认范围
    end
    grid on;

    % 绘制学习阶段对“频繁”与“不频繁”转换判断的总体准确率
    % 注意：这里的准确率是指，当实际是频繁转换时，被试判断为“频繁”的比例（或准确率），反之亦然。
    figure('Name', sprintf('P%s - 学习阶段 - 频繁/不频繁判断准确率', participantID), 'NumberTitle', 'off');
    subplot(1,2,1); % 视觉任务
    meanAccFreqVis = mean(accFrequentVis_Overall, 'omitnan'); % 对实际频繁转换的判断准确率
    meanAccInfreqVis = mean(accInfrequentVis_Overall, 'omitnan'); % 对实际不频繁转换的判断准确率

    if ~isnan(meanAccFreqVis) || ~isnan(meanAccInfreqVis) % 只要有一个不是NaN就尝试绘图
        barDataVis = [meanAccFreqVis, meanAccInfreqVis];
        barLabelsVis = {'对“频繁”转换的判断准确率', '对“不频繁”转换的判断准确率'};
        validBarsVis = ~isnan(barDataVis); % 找到非NaN的数据

        if any(validBarsVis)
            bVis = bar(find(validBarsVis), barDataVis(validBarsVis), 'FaceColor', 'flat');
            % 为有效的柱子设置颜色
            colorMapVis = [colors.frequent; colors.infrequent];
            barColorsVis = colorMapVis(validBarsVis,:);
            for i = 1:size(bVis.CData,1) % bVis.CData 可能因版本而异，确保兼容
                if size(bVis.CData,2) == 3 % R2017b and later
                    bVis.CData(i,:) = barColorsVis(i,:);
                end
            end

            set(gca, 'XTick', 1:sum(validBarsVis), 'XTickLabel', barLabelsVis(validBarsVis));
            ylabel('准确率');
            title('视觉任务');
            ylim([0 1.1]);
            grid on;
            % 在柱状图上显示数值
            for k = 1:length(find(validBarsVis))
                idx = find(validBarsVis);
                text(k, barDataVis(idx(k)), sprintf('%.2f', barDataVis(idx(k))), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            end
        else
            title('视觉任务 (数据不足)');
        end
    else
        title('视觉任务 (数据不足)');
    end

    subplot(1,2,2); % 听觉任务
    meanAccFreqAud = mean(accFrequentAud_Overall, 'omitnan');
    meanAccInfreqAud = mean(accInfrequentAud_Overall, 'omitnan');

    if ~isnan(meanAccFreqAud) || ~isnan(meanAccInfreqAud)
        barDataAud = [meanAccFreqAud, meanAccInfreqAud];
        barLabelsAud = {'对“频繁”转换的判断准确率', '对“不频繁”转换的判断准确率'};
        validBarsAud = ~isnan(barDataAud);

        if any(validBarsAud)
            bAud = bar(find(validBarsAud), barDataAud(validBarsAud), 'FaceColor', 'flat');
            colorMapAud = [colors.frequent; colors.infrequent];
            barColorsAud = colorMapAud(validBarsAud,:);
            for i = 1:size(bAud.CData,1)
                if size(bAud.CData,2) == 3
                    bAud.CData(i,:) = barColorsAud(i,:);
                end
            end
            set(gca, 'XTick', 1:sum(validBarsAud), 'XTickLabel', barLabelsAud(validBarsAud));
            ylabel('准确率');
            title('听觉任务');
            ylim([0 1.1]);
            grid on;
            for k = 1:length(find(validBarsAud))
                idx = find(validBarsAud);
                text(k, barDataAud(idx(k)), sprintf('%.2f', barDataAud(idx(k))), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            end
        else
            title('听觉任务 (数据不足)');
        end
    else
        title('听觉任务 (数据不足)');
    end
    sgtitle(sprintf('参与者 %s: 学习阶段 - 对刺激对实际频率的判断准确率', participantID)); % Super title

else
    disp('提示: 未找到明确学习阶段 (Phase 1) 的数据，跳过相关绘图。');
end


% --- 阶段二：内隐测试阶段 (Implicit Test) ---
if isfield(expData, 'implicitTest') && ~isempty(expData.implicitTest)
    fprintf('\n--- 正在处理阶段二：内隐测试阶段数据 ---\n');
    dataPhase2 = expData.implicitTest;

    % 筛选视觉和听觉Block的试验数据
    visTrialsPhase2 = dataPhase2(strcmp({dataPhase2.attentedModality}, 'visual'));
    audTrialsPhase2 = dataPhase2(strcmp({dataPhase2.attentedModality}, 'auditory'));

    % 绘制阶梯曲线 (Staircase Plot)
    % 视觉阶梯
    if ~isempty(visTrialsPhase2) && isfield(visTrialsPhase2, 'staircaseVisCurrentDeviant')
        figure('Name', sprintf('P%s - 内隐测试 - 视觉阶梯', participantID), 'NumberTitle', 'off');
        % 提取每次试验 *之后* 的偏差值 (即下一次试验将使用的偏差值)
        deviantValuesVis = [visTrialsPhase2.staircaseVisCurrentDeviant];
        plot(1:length(deviantValuesVis), deviantValuesVis, '.-', 'LineWidth', lineWidth, 'Color', colors.visual, 'MarkerSize', markerSize*1.5);
        xlabel('试验序号 (视觉Block内)');
        ylabel('视觉偏差量 (单位: 度)');
        title(sprintf('参与者 %s: 内隐测试 - 视觉阶梯阈限追踪', participantID));
        grid on;
        if any(deviantValuesVis > 0); ylim([0 max(deviantValuesVis)*1.1 + 0.1]); end
    end

    % 听觉阶梯
    if ~isempty(audTrialsPhase2) && isfield(audTrialsPhase2, 'staircaseAudCurrentDeviant')
        figure('Name', sprintf('P%s - 内隐测试 - 听觉阶梯', participantID), 'NumberTitle', 'off');
        deviantValuesAud = [audTrialsPhase2.staircaseAudCurrentDeviant];
        plot(1:length(deviantValuesAud), deviantValuesAud, '.-', 'LineWidth', lineWidth, 'Color', colors.auditory, 'MarkerSize', markerSize*1.5);
        xlabel('试验序号 (听觉Block内)');
        ylabel('听觉偏差量 (单位: Hz)');
        title(sprintf('参与者 %s: 内隐测试 - 听觉阶梯阈限追踪', participantID));
        grid on;
        if any(deviantValuesAud > 0); ylim([0 max(deviantValuesAud)*1.1 + 0.1]); end
    end

    % 分析偏差与标准刺激的判断准确率 (排除捕获试验)
    hitRateVis = NaN; faRateVis = NaN; % 初始化视觉任务的命中率和虚报率
    hitRateAud = NaN; faRateAud = NaN; % 初始化听觉任务的命中率和虚报率

    % 视觉任务分析
    nonCatchVisPhase2 = visTrialsPhase2([visTrialsPhase2.isCatchTrial] == false);
    if ~isempty(nonCatchVisPhase2) && isfield(nonCatchVisPhase2, 'targetIsDeviantStim') && isfield(nonCatchVisPhase2, 'accuracy')
        % 实际为偏差刺激的试验
        actualDeviantVis = nonCatchVisPhase2([nonCatchVisPhase2.targetIsDeviantStim] == true);
        % 实际为标准刺激的试验
        actualStandardVis = nonCatchVisPhase2([nonCatchVisPhase2.targetIsDeviantStim] == false);

        if ~isempty(actualDeviantVis)
            hitRateVis = mean([actualDeviantVis.accuracy], 'omitnan'); % 命中率: 对偏差刺激正确判断为偏差
        end
        if ~isempty(actualStandardVis)
            % 虚报率: 对标准刺激错误判断为偏差 (accuracy 为 false 时表示错误判断)
            faRateVis = mean([actualStandardVis.accuracy] == false, 'omitnan');
        end
    end

    % 听觉任务分析
    nonCatchAudPhase2 = audTrialsPhase2([audTrialsPhase2.isCatchTrial] == false);
    if ~isempty(nonCatchAudPhase2) && isfield(nonCatchAudPhase2, 'targetIsDeviantStim') && isfield(nonCatchAudPhase2, 'accuracy')
        actualDeviantAud = nonCatchAudPhase2([nonCatchAudPhase2.targetIsDeviantStim] == true);
        actualStandardAud = nonCatchAudPhase2([nonCatchAudPhase2.targetIsDeviantStim] == false);

        if ~isempty(actualDeviantAud)
            hitRateAud = mean([actualDeviantAud.accuracy], 'omitnan');
        end
        if ~isempty(actualStandardAud)
            faRateAud = mean([actualStandardAud.accuracy] == false, 'omitnan');
        end
    end

    % 绘制命中率和正确拒绝率 (1-虚报率) 的柱状图
    figure('Name', sprintf('P%s - 内隐测试 - 偏差/标准判断表现', participantID), 'NumberTitle', 'off');
    subplot(1,2,1); % 视觉任务
    if ~isnan(hitRateVis) || ~isnan(faRateVis)
        barDataP2Vis = [hitRateVis, 1-faRateVis]; % 命中率, 正确拒绝率
        barLabelsP2Vis = {'命中率 (偏差)', '正确拒绝率 (标准)'};
        validBarsP2Vis = ~isnan(barDataP2Vis);

        if any(validBarsP2Vis)
            bVisP2 = bar(find(validBarsP2Vis), barDataP2Vis(validBarsP2Vis), 'FaceColor', 'flat');
            colorMapP2Vis = [colors.deviant; colors.standard];
            barColorsP2Vis = colorMapP2Vis(validBarsP2Vis,:);
            for i = 1:size(bVisP2.CData,1)
                if size(bVisP2.CData,2) == 3
                    bVisP2.CData(i,:) = barColorsP2Vis(i,:);
                end
            end
            set(gca, 'XTick', 1:sum(validBarsP2Vis), 'XTickLabel', barLabelsP2Vis(validBarsP2Vis));
            ylabel('比率');
            title('视觉任务');
            ylim([0 1.1]);
            grid on;
            for k = 1:length(find(validBarsP2Vis))
                idx = find(validBarsP2Vis);
                text(k, barDataP2Vis(idx(k)), sprintf('%.2f', barDataP2Vis(idx(k))), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            end
        else
            title('视觉任务 (数据不足)');
        end
    else
        title('视觉任务 (数据不足)');
    end

    subplot(1,2,2); % 听觉任务
    if ~isnan(hitRateAud) || ~isnan(faRateAud)
        barDataP2Aud = [hitRateAud, 1-faRateAud];
        barLabelsP2Aud = {'命中率 (偏差)', '正确拒绝率 (标准)'};
        validBarsP2Aud = ~isnan(barDataP2Aud);

        if any(validBarsP2Aud)
            bAudP2 = bar(find(validBarsP2Aud), barDataP2Aud(validBarsP2Aud), 'FaceColor', 'flat');
            colorMapP2Aud = [colors.deviant; colors.standard];
            barColorsP2Aud = colorMapP2Aud(validBarsP2Aud,:);
            for i = 1:size(bAudP2.CData,1)
                if size(bAudP2.CData,2) == 3
                    bAudP2.CData(i,:) = barColorsP2Aud(i,:);
                end
            end
            set(gca, 'XTick', 1:sum(validBarsP2Aud), 'XTickLabel', barLabelsP2Aud(validBarsP2Aud));
            ylabel('比率');
            title('听觉任务');
            ylim([0 1.1]);
            grid on;
            for k = 1:length(find(validBarsP2Aud))
                idx = find(validBarsP2Aud);
                text(k, barDataP2Aud(idx(k)), sprintf('%.2f', barDataP2Aud(idx(k))), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            end
        else
            title('听觉任务 (数据不足)');
        end
    else
        title('听觉任务 (数据不足)');
    end
    sgtitle(sprintf('参与者 %s: 内隐测试 - 偏差/标准判断表现 (非捕获试验)', participantID));

else
    disp('提示: 未找到内隐测试阶段 (Phase 2) 的数据，跳过相关绘图。');
end


% --- 阶段三：明确回忆阶段 (Explicit Recall) ---
if isfield(expData, 'explicitRecall') && ~isempty(expData.explicitRecall)
    fprintf('\n--- 正在处理阶段三：明确回忆阶段数据 ---\n');
    dataPhase3 = expData.explicitRecall;

    % 筛选视觉和听觉回忆Block的试验数据
    recallVisTrials = dataPhase3(strcmp({dataPhase3.recallModality}, 'visual'));
    recallAudTrials = dataPhase3(strcmp({dataPhase3.recallModality}, 'auditory'));

    % 初始化回忆准确率变量
    recalledAsFreq_Vis_ActualFreq_Acc = NaN;    % 视觉：实际频繁，回忆为频繁的准确率
    recalledAsInfreq_Vis_ActualInfreq_Acc = NaN;% 视觉：实际不频繁，回忆为不频繁的准确率
    recalledAsFreq_Aud_ActualFreq_Acc = NaN;    % 听觉：同上
    recalledAsInfreq_Aud_ActualInfreq_Acc = NaN;% 听觉：同上

    % 视觉回忆分析
    if ~isempty(recallVisTrials) && isfield(recallVisTrials, 'wasActuallyFrequentInLearning') && isfield(recallVisTrials, 'responseType')
        % 实际为频繁的刺激对
        actualFreqVis_Recall = recallVisTrials([recallVisTrials.wasActuallyFrequentInLearning] == true);
        if ~isempty(actualFreqVis_Recall)
            recalledAsFreq_Vis_ActualFreq_Acc = mean(strcmp({actualFreqVis_Recall.responseType}, 'frequent'), 'omitnan');
        end

        % 实际为不频繁的刺激对
        actualInfreqVis_Recall = recallVisTrials([recallVisTrials.wasActuallyFrequentInLearning] == false);
        if ~isempty(actualInfreqVis_Recall)
            recalledAsInfreq_Vis_ActualInfreq_Acc = mean(strcmp({actualInfreqVis_Recall.responseType}, 'infrequent'), 'omitnan');
        end
    end

    % 听觉回忆分析
    if ~isempty(recallAudTrials) && isfield(recallAudTrials, 'wasActuallyFrequentInLearning') && isfield(recallAudTrials, 'responseType')
        actualFreqAud_Recall = recallAudTrials([recallAudTrials.wasActuallyFrequentInLearning] == true);
        if ~isempty(actualFreqAud_Recall)
            recalledAsFreq_Aud_ActualFreq_Acc = mean(strcmp({actualFreqAud_Recall.responseType}, 'frequent'), 'omitnan');
        end

        actualInfreqAud_Recall = recallAudTrials([recallAudTrials.wasActuallyFrequentInLearning] == false);
        if ~isempty(actualInfreqAud_Recall)
            recalledAsInfreq_Aud_ActualInfreq_Acc = mean(strcmp({actualInfreqAud_Recall.responseType}, 'infrequent'), 'omitnan');
        end
    end

    % 绘制回忆阶段准确率的柱状图
    figure('Name', sprintf('P%s - 回忆阶段 - 频率判断准确率', participantID), 'NumberTitle', 'off');
    subplot(1,2,1); % 视觉任务
    if ~isnan(recalledAsFreq_Vis_ActualFreq_Acc) || ~isnan(recalledAsInfreq_Vis_ActualInfreq_Acc)
        barDataRecallVis = [recalledAsFreq_Vis_ActualFreq_Acc, recalledAsInfreq_Vis_ActualInfreq_Acc];
        barLabelsRecallVis = {'回忆“频繁”正确率', '回忆“不频繁”正确率'};
        validBarsRecallVis = ~isnan(barDataRecallVis);

        if any(validBarsRecallVis)
            bRVis = bar(find(validBarsRecallVis), barDataRecallVis(validBarsRecallVis), 'FaceColor', 'flat');
            colorMapRecallVis = [colors.frequent; colors.infrequent];
            barColorsRecallVis = colorMapRecallVis(validBarsRecallVis,:);
            for i = 1:size(bRVis.CData,1)
                if size(bRVis.CData,2) == 3
                    bRVis.CData(i,:) = barColorsRecallVis(i,:);
                end
            end
            set(gca, 'XTick', 1:sum(validBarsRecallVis), 'XTickLabel', barLabelsRecallVis(validBarsRecallVis));
            ylabel('正确回忆比率');
            title('视觉任务');
            ylim([0 1.1]);
            grid on;
            for k = 1:length(find(validBarsRecallVis))
                idx = find(validBarsRecallVis);
                text(k, barDataRecallVis(idx(k)), sprintf('%.2f', barDataRecallVis(idx(k))), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            end
        else
            title('视觉任务 (数据不足)');
        end
    else
        title('视觉任务 (数据不足)');
    end

    subplot(1,2,2); % 听觉任务
    if ~isnan(recalledAsFreq_Aud_ActualFreq_Acc) || ~isnan(recalledAsInfreq_Aud_ActualInfreq_Acc)
        barDataRecallAud = [recalledAsFreq_Aud_ActualFreq_Acc, recalledAsInfreq_Aud_ActualInfreq_Acc];
        barLabelsRecallAud = {'回忆“频繁”正确率', '回忆“不频繁”正确率'};
        validBarsRecallAud = ~isnan(barDataRecallAud);

        if any(validBarsRecallAud)
            bRAud = bar(find(validBarsRecallAud), barDataRecallAud(validBarsRecallAud), 'FaceColor', 'flat');
            colorMapRecallAud = [colors.frequent; colors.infrequent];
            barColorsRecallAud = colorMapRecallAud(validBarsRecallAud,:);
            for i = 1:size(bRAud.CData,1)
                if size(bRAud.CData,2) == 3
                    bRAud.CData(i,:) = barColorsRecallAud(i,:);
                end
            end
            set(gca, 'XTick', 1:sum(validBarsRecallAud), 'XTickLabel', barLabelsRecallAud(validBarsRecallAud));
            ylabel('正确回忆比率');
            title('听觉任务');
            ylim([0 1.1]);
            grid on;
            for k = 1:length(find(validBarsRecallAud))
                idx = find(validBarsRecallAud);
                text(k, barDataRecallAud(idx(k)), sprintf('%.2f', barDataRecallAud(idx(k))), 'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom');
            end
        else
            title('听觉任务 (数据不足)');
        end
    else
        title('听觉任务 (数据不足)');
    end
    sgtitle(sprintf('参与者 %s: 回忆阶段 - 对学习阶段刺激对频率的判断准确率', participantID));

else
    disp('提示: 未找到明确回忆阶段 (Phase 3) 的数据，跳过相关绘图。');
end

fprintf('\n所有可用的图表已生成完毕。\n');
