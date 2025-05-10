% MATLAB 脚本：将实验数据从 .mat 转换为 .xlsx

% --- 用户交互：选择 .mat 文件 ---
[matFileName, matPathName] = uigetfile('*.mat', '选择 .mat 数据文件');
if isequal(matFileName, 0)
    disp('用户选择了取消');
    return;
else
    fullMatFileName = fullfile(matPathName, matFileName);
    disp(['用户已选择：', fullMatFileName]);
end

% --- 加载 .mat 文件 ---
try
    loadedData = load(fullMatFileName);
    disp('成功加载 .mat 文件。');

    % 检查预期的 'expData' 变量是否存在
    if ~isfield(loadedData, 'expData')
        disp('错误：加载的 .mat 文件不包含 ''expData'' 变量。');
        disp('请选择一个由 exp.m 生成的有效数据文件。');
        % 列出文件中的可用变量以供调试
        disp('在文件中找到的变量：');
        disp(fields(loadedData));
        return;
    end

    % 检查参与者 ID 是否可用于命名 Excel 文件
    if isfield(loadedData, 'participant') && isfield(loadedData.participant, 'ID')
        participantID = loadedData.participant.ID;
    else
        % 如果未找到参与者 ID，则创建一个通用 ID
        [~, name, ~] = fileparts(matFileName);
        participantID = name; % 使用 .mat 文件名（不含扩展名）作为备用名称
        disp('警告：找不到 participant.ID。将使用 MAT 文件名作为 Excel 输出文件名。');
    end

catch ME
    disp(['加载 .mat 文件时出错：', ME.message]);
    return;
end

% --- 准备 Excel 文件名 ---
excelFileName = fullfile(matPathName, ['转换后数据_', participantID, '.xlsx']);

% --- 处理并写入每个阶段的数据 ---
dataPhases = {'explicitLearning', 'implicitTest', 'explicitRecall'}; % 数据阶段名称可以根据需要翻译或保持英文，这里保持英文以便与变量名对应
phaseDataExists = false; % 标记是否存在阶段数据

for i = 1:length(dataPhases)
    currentPhase = dataPhases{i};

    if isfield(loadedData.expData, currentPhase) && ~isempty(loadedData.expData.(currentPhase))
        try
            % 将结构体数组转换为表格
            dataTable = struct2table(loadedData.expData.(currentPhase));

            % 将表格写入 Excel 文件中的工作表
            writetable(dataTable, excelFileName, 'Sheet', currentPhase);
            disp(['成功将阶段 ''', currentPhase, ''' 的数据写入工作表：', currentPhase]);
            phaseDataExists = true;
        catch ME_write
            disp(['写入阶段 ''', currentPhase, ''' 的数据时出错：', ME_write.message]);
            % 如果是特定的已知错误，例如字段名问题，请提供更多详细信息
            if contains(ME_write.identifier, 'InvalidSheetName')
                disp('这可能是由于阶段名称中包含 Excel 工作表不允许的无效字符。');
            elseif contains(ME_write.identifier, 'MATLAB:table:DuplicateVariableNames')
                disp('这可能是由于数据结构中存在重复的字段名。');
            end
        end
    else
        disp(['未找到阶段 ''', currentPhase, ''' 的数据，或该字段为空。正在跳过。']);
    end
end

if phaseDataExists
    disp(['所有可用数据已成功转换并保存到：', excelFileName]);
else
    disp('在预期的任何阶段（explicitLearning, implicitTest, explicitRecall）中均未找到数据。');
    disp('未创建 Excel 文件，或者文件可能为空。');
    % 如果错误地创建了空的 Excel 文件，则尝试删除它
    if exist(excelFileName, 'file')
        try
            delete(excelFileName);
            disp(['已删除空的 Excel 文件：', excelFileName]);
        catch ME_delete
            disp(['无法删除可能为空的 Excel 文件：', ME_delete.message]);
        end
    end
end

disp('脚本执行完毕。');