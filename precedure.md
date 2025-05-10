**实验整体流程**

1.  **开始实验 (exp.m)**
    1.  收集参与者信息
    2.  Psychtoolbox 初始化 (屏幕, 音频, 按键等)
    3.  参数初始化 (实验参数, 刺激参数, 转移矩阵, **Staircase 参数**)
    4.  知情同意与总体指导语
    5.  音量调整
    6.  按键说明

2.  **阶段一: 明确学习阶段**
    1.  **循环 (Block 1 到 numBlocksPhase1)**
        1.  设置当前 Block 的注意模态 (视觉/听觉) 与按键
        2.  显示 Block 指导语
        3.  为此 Block 生成试验序列 (标准试验 / 捕获试验)
        4.  **循环 (Trial 1 到 trialsPerBlockPhase1)**
            1.  设置当前试验刺激 (领先刺激 / 跟随刺激, 是否为捕获试验?)
            2.  步骤1:呈现注视点
            3.  步骤2:呈现领先刺激 (视觉 + 听觉)
            4.  步骤3:呈现 ISI (刺激间隔)
            5.  步骤4:呈现跟随刺激 (视觉 + 听觉, 可能为捕获试验的弱刺激)
            6.  步骤5:显示反应屏幕 (提示按键: 频繁 / 不频繁 / 弱?)
            7.  收集反应, 计算反应时间 (RT)
            8.  判断回答准确性
            9.  步骤6:呈现反馈 (正确/错误)
            10. 存储当前试验数据
        5.  (试验循环结束)
        6.  如果不是最后一个 Block，则进行 Block 间休息
    2.  (Block 循环结束)
    3.  学习阶段结束指导语

3.  **阶段二: 内隐测试阶段 (阶梯法核心)**
    1.  **循环 (Block 1 到 numBlocksPhase2)**
        1.  设置当前 Block 的注意模态 (视觉/听觉)
        2.  显示 Block 指导语 (提示按键: 偏差 / 标准 / 弱?)
        3.  为此 Block 生成试验序列 (偏差试验 / 标准试验 / 捕获试验)
        4.  **循环 (Trial 1 到 trialsPerBlockPhase2)**
            1.  **A. 设置基础刺激**
                1.  确定领先刺激 (视觉和听觉)
                2.  根据转移概率确定“基础”的跟随刺激 (视觉和听觉)
            2.  **B. 判断试验类型并设置实际跟随刺激**
                1.  **IF (是捕获试验?) THEN**
                    1.  设置相应的捕获刺激 (视觉或听觉刺激弱化)
                    2.  `targetIsDeviantStim = false` (隐式)
                2.  **ELSE (不是捕获试验) THEN**
                    1.  **IF (是偏差试验类型 `trialConditionCode==1`?) THEN**
                        1.  从 `stairParams.vis.currentDeviant` 或 `stairParams.aud.currentDeviant` 获取当前偏差值
                        2.  将偏差值随机加到或减到“基础”跟随刺激上 (仅限当前注意模态)
                        3.  确保调整后的刺激值在合理范围内 (如视觉角度 `mod(..., 180)`, 听觉频率 `>0`)
                        4.  标记 `targetIsDeviantStim = true`
                        5.  如果需要 (如视觉偏差)，动态生成偏差刺激的纹理
                    2.  **ELSE (是标准试验类型) THEN**
                        1.  跟随刺激使用“基础”标准值
                        2.  `targetIsDeviantStim = false` (隐式)
            3.  **C. 执行试验流程**
                1.  步骤1:呈现注视点
                2.  步骤2:呈现领先刺激 (视觉 + 听觉)
                3.  步骤3:呈现 ISI
                4.  步骤4:呈现跟随刺激 (视觉 + 听觉; 此处的跟随刺激可能是标准、偏差或捕获刺激)
                5.  步骤5:显示反应屏幕 (提示按键: 偏差 / 标准 / 弱?)
                6.  收集反应, 计算 RT
                7.  判断回答准确性 (对比参与者反应与预期的正确反应类型：偏差/标准/弱)
                8.  步骤6:呈现反馈 (正确/错误)
            4.  **D. 更新 Staircase (核心逻辑)**
                1.  **IF (不是捕获试验?) THEN**
                    1.  加载当前注意模态的 Staircase 参数到临时结构体 `s` (即 `s = stairParams.vis` 或 `s = stairParams.aud`)
                    2.  **IF (`targetIsDeviantStim == true`?) THEN (目标是偏差刺激)**
                        1.  **IF (回答正确 - Hit?) THEN**
                            1.  `s.correctStreak = s.correctStreak + 1`
                            2.  **IF (`s.correctStreak >= s.nDown`?) THEN**
                                1.  `s.currentDeviant = s.currentDeviant - s.stepSizes(s.currentStepIndex)` (任务变难)
                                2.  确保 `s.currentDeviant` 不小于最小值 (如0.1度或0.5Hz)
                                3.  `s.correctStreak = 0`
                                4.  **IF (`s.lastDirection == -1` (向上) 或 `s.lastDirection == 0` (初始)) THEN**
                                    1.  `s.reversalCount = s.reversalCount + 1`
                                5.  `s.lastDirection = 1` (向下调整)
                        2.  **ELSE (回答错误 - Miss) THEN**
                            1.  `s.currentDeviant = s.currentDeviant + s.stepSizes(s.currentStepIndex)` (任务变易)
                            2.  `s.correctStreak = 0`
                            3.  **IF (`s.lastDirection == 1` (向下) 或 `s.lastDirection == 0` (初始)) THEN**
                                1.  `s.reversalCount = s.reversalCount + 1`
                            4.  `s.lastDirection = -1` (向上调整)
                    3.  **ELSE (`targetIsDeviantStim == false`?) THEN (目标是标准刺激)**
                        1.  **IF (回答错误 - False Alarm?) THEN**
                            1.  `s.currentDeviant = s.currentDeviant + s.stepSizes(s.currentStepIndex)` (任务变易)
                            2.  `s.correctStreak = 0`
                            3.  **IF (`s.lastDirection == 1` (向下) 或 `s.lastDirection == 0` (初始)) THEN**
                                1.  `s.reversalCount = s.reversalCount + 1`
                            4.  `s.lastDirection = -1` (向上调整)
                        2.  **ELSE (回答正确 - Correct Rejection) THEN**
                            1.  Staircase 参数 (如 `s.currentDeviant`, `s.correctStreak`) 通常无变化
                    4.  **更新步长索引**
                        1.  计算 `nextStepChangeThreshold` (基于 `s.currentStepIndex` 和 `s.reversalsToChangeStep` 的累积值)
                        2.  **IF (`s.reversalCount >= nextStepChangeThreshold` AND `s.currentStepIndex < length(s.stepSizes)`?) THEN**
                            1.  `s.currentStepIndex = s.currentStepIndex + 1`
                    5.  检查并确保 `s.currentDeviant` 不小于设定的最小值 (已在调整 `s.currentDeviant` 后立即执行)
                    6.  更新 `s.deviantHistory` (将当前的 `s.currentDeviant` 添加进去)
                    7.  **关键：保存更新后的 `s` 回 `stairParams.vis` 或 `stairParams.aud`**
            5.  **E. 存储当前试验数据** (包括Staircase更新后的信息，如新的 `currentDeviant`)
            6.  **F. 清理动态资源**
                1.  如果为偏差视觉刺激动态创建了纹理，则关闭该纹理
        5.  (试验循环结束)
        6.  如果不是最后一个 Block，则进行 Block 间休息
    2.  (Block 循环结束)
    3.  测试阶段结束指导语

4.  **阶段三: 明确回忆阶段**
    1.  **循环 (Block 1 到 numBlocksPhase3)**
        1.  设置当前 Block 的回忆模态 (视觉/听觉)
        2.  显示 Block 指导语
        3.  为此 Block 生成试验对序列 (呈现学习阶段所有可能的刺激对)
        4.  **循环 (Trial 1 到 trialsPerBlockPhase3)**
            1.  设置当前要呈现的刺激对 (领先刺激 / 跟随刺激)
            2.  步骤1:呈现注视点
            3.  步骤2:呈现领先刺激
            4.  步骤3:呈现 ISI
            5.  步骤4:呈现跟随刺激
            6.  步骤5:显示反应屏幕 (提示按键: 频繁 / 不频繁?)
            7.  收集反应, 计算 RT
            8.  判断回答准确性 (对比参与者反应与该刺激对在学习阶段的实际频率)
            9.  存储当前试验数据 (此阶段通常无反馈)
        5.  (试验循环结束)
        6.  如果不是最后一个 Block，则进行 Block 间休息
    2.  (Block 循环结束)
    3.  回忆阶段结束

5.  **实验结束**
    1.  显示结束语, 感谢参与
    2.  保存最终的实验数据 (包括所有阶段的数据和最终的 `stairParams`)
    3.  清理 Psychtoolbox 资源 (关闭屏幕, 音频, 恢复键盘等)
    4.  退出

**使用此纯文字流程图进行检查的关键点：**

* **变量的传递和更新：** 确保在阶梯法逻辑中，所有从 `stairParams` 加载到临时结构体 `s` 的值，在被修改后，这个完整的 `s` 结构体被正确地写回 `stairParams`。
* **条件分支的完整性：** 检查所有的 IF/ELSE 条件是否覆盖了所有可能的情况，并且每个分支的逻辑都是正确的。
* **循环的执行：** 确保循环（Block循环和Trial循环）的起始和终止条件正确，并且循环内部的逻辑按预期执行。
* **Staircase状态的持久性：** Staircase的状态（如`currentDeviant`, `reversalCount`, `currentStepIndex`等）是否正确地在试验间保持和更新。
* **偏差的应用：** 偏差是否只在非捕获的、被指定为“偏差”类型的试验中，并且只对当前注意的模态应用。
* **数据记录：** 确保所有相关的变量（包括阶梯法参数和试验过程中的关键决策变量）都被准确记录下来。
