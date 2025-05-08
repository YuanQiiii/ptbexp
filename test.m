fprintf('开始检测按键状态，请不要按任何键...\n');
WaitSecs(2); % 等待2秒，确保你没有意外按下键

[keyIsDown, secs, keyCode] = KbCheck;

if keyIsDown
    fprintf('有按键被检测为按下状态！\n');
    stuckKeyCodes = find(keyCode); % 找到所有被按下键的 keyCode 索引
    fprintf('以下 keyCode 索引对应的键被认为是“卡住”的：\n');
    disp(stuckKeyCodes);

    fprintf('尝试获取这些键的名称 (可能不准确或为空)：\n');
    for i = 1:length(stuckKeyCodes)
        try
            keyName = KbName(stuckKeyCodes(i));
            fprintf('KeyCode %d: %s\n', stuckKeyCodes(i), keyName);
        catch
            fprintf('KeyCode %d: 无法获取名称\n', stuckKeyCodes(i));
        end
    end
else
    fprintf('没有检测到按键被按下。如果 KbWait 仍然立即返回，可能问题更复杂。\n');
end