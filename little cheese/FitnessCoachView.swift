import SwiftUI
import Foundation // 🆕 请出 Foundation 库，修复 components 报错
// MARK: - ✨ 动作数据模型
struct FitnessAction: Identifiable, Hashable {
    let id = UUID()
    var name: String
    let targetMuscle: String
    let tip: String
    let emojiIcon: String
    let steps: [String]
    var activeRest: String? = nil
    var baseReps: String = ""
    var quickStats: [String] = []
    
    // 🆕 路线A新增：专业维度
    var intensity: String? = nil    // RPE或心率建议
    var priority: Int = 2            // 优先级：1(复合), 2(辅助), 3(孤立/核心)
    // 🆕 Little Cheese：动作教学扩展
    var difficulty: String = "新手友好"
    var shortIntro: String = ""
    
    var setupSteps: [String] = []        // 起始姿势
    var actionSteps: [String] = []       // 动作执行步骤
    var breathingTip: String = ""        // 呼吸
    
    var commonMistakes: [String] = []    // 常见错误
    var coachTips: [String] = []         // 温柔提醒
    
    var visualSteps: [String] = []       // 图示（先用文字）
    
    var hasGuidedMode: Bool = true       // 是否支持陪练
}
// MARK: - 训练阶段模型
struct WorkoutPhase: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    var actions: [FitnessAction]
}

struct FitnessCoachView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var strengthMinutes: Double = 30
    @State private var cardioMinutes: Double = 0
    
    @State private var selectedEquip: Int = 0
        @State private var selectedPart: Int = 0
        @State private var selectedCardio: Int = 1
        
    // 🆕 路线A新增：状态管理
    @State private var trainingLevel: Int = 0 // 0:🐣新手, 1:🐥中级, 2:🦅高手
    @State private var cardioGoal: Int = 0    // 0:🔥燃脂, 1:❤️心肺, 2:⚡冲刺

    // 🆕 第一步：总训练目标
    @State private var trainingGoal: Int = 1  // 0:🔥减脂燃能 1:🍑塑形线条 2:💪增肌强化 3:🌿恢复减压
    @State private var generatedPhases: [WorkoutPhase] = []
    @State private var isGenerating: Bool = false
    @State private var selectedActionDetail: FitnessAction?
    @State private var selectedWorkoutSession: FitnessAction?

    
    let equips = ["🛋️ 宿舍徒手", "🎒 哑铃弹力带", "🏢 健身房"]
    let parts = ["🎲 帮我决定", "🦋 挺拔背部", "🍑 力量下肢", "🛡️ 稳定核心"] // ✨ 改了名字，强调“稳定”
    let cardioTypes = ["🧗‍♀️ 爬楼机", "🛸 椭圆机", "🏃‍♀️ 跑步机", "🏊‍♀️ 游泳", "🚴 动感单车", "🚶 散步"]

    var totalMinutes: Int { Int(strengthMinutes + cardioMinutes) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // 1. 顶部标题
                VStack(spacing: 8) {
                    Text("智能运动引擎 🧠").font(.largeTitle.bold()).foregroundColor(.lcText)
                    Text("精准容量与肌群平衡：打造最强 3D 核心")
                        .font(.subheadline).foregroundColor(.lcTextSecondary).multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // 2. 时间拉杆
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("🏋️ 无氧 (力量)").font(.headline).foregroundColor(.lcText)
                            Spacer()
                            Text("\(Int(strengthMinutes)) 分钟").font(.title3.bold()).foregroundColor(.lcGreen)
                        }
                        Slider(value: $strengthMinutes, in: 0...90, step: 5).tint(.lcGreen)
                    }
                    Divider().opacity(0.3)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("🏃‍♀️ 有氧 (心肺)").font(.headline).foregroundColor(.lcText)
                            Spacer()
                            Text("\(Int(cardioMinutes)) 分钟").font(.title3.bold()).foregroundColor(.lcSoftBlue)
                        }
                        Slider(value: $cardioMinutes, in: 0...90, step: 5).tint(.lcSoftBlue)
                    }
                }
                .padding(20).background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
                .shadow(color: .black.opacity(0.02), radius: 10, y: 5)
                
                // 3. 点单详情
                if totalMinutes > 0 {
                    VStack(spacing: 24) {
                        
                        // 🆕 第一步：训练目标 (全局适用)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("🎯 这次训练更想要：").font(.headline).foregroundColor(.lcTextSecondary)
                            Picker("训练目标", selection: $trainingGoal) {
                                Text("🔥 减脂").tag(0)
                                Text("🍑 塑形").tag(1)
                                Text("💪 增肌").tag(2)
                                Text("🌿 恢复").tag(3)
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        // 🆕 路线A新增：训练经验等级 (全局适用)
                        VStack(alignment: .leading, spacing: 16) {
                            Text("🏅 你的训练经验：").font(.headline).foregroundColor(.lcTextSecondary)
                            Picker("经验等级", selection: $trainingLevel) {
                                Text("🐣 新手").tag(0)
                                Text("🐥 中级").tag(1)
                                Text("🦅 高手").tag(2)
                            }
                            .pickerStyle(.segmented)
                        }
                        
                        Divider().opacity(0.3)
                        
                        if strengthMinutes > 0 {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("🏋️ 力量训练设定：").font(.headline).foregroundColor(.lcTextSecondary)
                                Picker("装备", selection: $selectedEquip) { ForEach(0..<equips.count, id: \.self) { i in Text(equips[i]).tag(i) } }.pickerStyle(.segmented)
                                Picker("部位", selection: $selectedPart) { ForEach(0..<parts.count, id: \.self) { i in Text(parts[i]).tag(i) } }.pickerStyle(.segmented)
                            }
                        }
                        
                        if strengthMinutes > 0 && cardioMinutes > 0 { Divider().opacity(0.3) }
                        
                        if cardioMinutes > 0 {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("🏃‍♀️ 有氧项目选择：").font(.headline).foregroundColor(.lcTextSecondary)
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(0..<cardioTypes.count, id: \.self) { i in
                                            Button { withAnimation(.spring()) { selectedCardio = i } } label: {
                                                Text(cardioTypes[i]).font(.system(.subheadline, design: .rounded))
                                                    .foregroundColor(selectedCardio == i ? .white : .lcText)
                                                    .padding(.horizontal, 16).padding(.vertical, 10)
                                                    .background(RoundedRectangle(cornerRadius: 12).fill(selectedCardio == i ? Color.lcAccentBlue : Color.lcBackground))
                                            }
                                        }
                                    }
                                }
                                
                                // 🆕 路线A新增：有氧目标
                                Text("🎯 有氧目标：").font(.headline).foregroundColor(.lcTextSecondary).padding(.top, 8)
                                Picker("有氧目标", selection: $cardioGoal) {
                                    Text("🔥 燃脂").tag(0)
                                    Text("❤️ 心肺").tag(1)
                                    Text("⚡ 冲刺").tag(2)
                                }.pickerStyle(.segmented)
                            }
                        }
                    }
                    .padding(20).background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
                    .shadow(color: .black.opacity(0.02), radius: 10, y: 5).transition(.opacity)
                }
                // 4. 专属私教生成按钮
                if totalMinutes > 0 {
                    Button {
                        generateRoutine()
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView().tint(.white)
                                    .padding(.trailing, 8)
                                Text("私教正在排课中...").font(.headline)
                            } else {
                                Text("⚡️ 生成今日专属计划").font(.title3.bold())
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(isGenerating ? Color.lcTextSecondary : Color.lcAccentBlue)
                        .cornerRadius(20)
                        .shadow(color: Color.lcAccentBlue.opacity(0.3), radius: 10, y: 5)
                    }
                    .disabled(isGenerating)
                    .padding(.top, 10)
                }
                // 5. 引擎输出结果展示
                if !generatedPhases.isEmpty {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Text("👇 你的三段式专属剧本：")
                                .font(.headline).foregroundColor(.lcTextSecondary)
                            Spacer()
                            Text("点击卡片查看图解").font(.caption).foregroundColor(.lcAccentBlue)
                        }
                        
                        ForEach(generatedPhases) { phase in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(phase.title).font(.title3.bold()).foregroundColor(.lcText)
                                    Spacer()
                                    Text(phase.subtitle).font(.caption).foregroundColor(.lcTextSecondary)
                                }
                                .padding(.bottom, 4)
                                
                                ForEach(phase.actions) { action in
                                    actionCard(for: action)
                                }
                            }
                            .padding(.bottom, 12)
                        }
                        
                        Button { finishAndRecord() } label: {
                            Text("✅ 肌肉充血了！记录成就")
                                .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding()
                                .background(Color.lcGreen).cornerRadius(20)
                                .shadow(color: Color.lcGreen.opacity(0.3), radius: 10, y: 5)
                        }
                        .padding(.top, 10)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.lcBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedActionDetail) { action in
            ActionDetailSheet(
                action: action,
                onStartGuided: {
                    selectedActionDetail = nil
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        selectedWorkoutSession = action
                    }
                }
            )
        }
        .sheet(item: $selectedWorkoutSession) { action in
                    WorkoutSessionSheet(action: action)
                }
            } // 🧀 关键补丁 1：关上 body 界面的大门

            // MARK: - UI 子组件：卡片
            private func actionCard(for action: FitnessAction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(action.emojiIcon).font(.title3)
                VStack(alignment: .leading, spacing: 6) {
                    Text(action.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(action.name.contains("汗水") ? .lcAccentBlue : .lcText)
                    
                    HStack(spacing: 8) {
                        // 1. 组数 / 次数：点这里直接进入陪练模式
                        if !action.baseReps.isEmpty {
                            Button {
                                selectedActionDetail = action   // ✅ 改成打开动作详情页
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "figure.strengthtraining.traditional")
                                    Text(action.baseReps)
                                }
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(.lcAccentBlue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.lcAccentBlue.opacity(0.12))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        // 2. 直接显示具体的阻力、坡度、速度
                        if !action.quickStats.isEmpty {
                            ForEach(action.quickStats, id: \.self) { stat in
                                HStack(spacing: 4) {
                                    if stat.contains("阻力") {
                                        Image(systemName: "gearshape.fill")
                                    } else if stat.contains("坡度") {
                                        Image(systemName: "arrow.up.forward.circle.fill")
                                    } else if stat.contains("速度") {
                                        Image(systemName: "gauge.with.needle.fill")
                                    }

                                    Text(stat)
                                }
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.lcTextSecondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.lcBackground)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.lcSoftBlue.opacity(0.5), lineWidth: 0.5)
                                )
                            }
                        }
                    }
                    .padding(.vertical, 2)
                
                }
                Spacer()
                Image(systemName: "chevron.right.circle.fill").foregroundColor(.lcSoftBlue.opacity(0.5))
            }
            
            HStack(spacing: 8) {
                            if !action.targetMuscle.isEmpty {
                                Text("🎯 练：\(action.targetMuscle)")
                                    .font(.system(size: 11, weight: .bold)).foregroundColor(.lcText)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.lcCheeseYellow.opacity(0.4)).cornerRadius(6)
                            }
                            
                            // 🆕 路线A新增：显示专业强度 (RPE / 心率)
                            if let intensity = action.intensity {
                                Text(intensity)
                                    .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Color.orange.opacity(0.6)).cornerRadius(6)
                            }
                        }
            if let activeRest = action.activeRest {
                HStack(spacing: 6) {
                    Text("🔄 间隙：").font(.system(size: 12, weight: .bold)).foregroundColor(.lcAccentBlue)
                    Text(activeRest).font(.system(size: 12, design: .rounded)).foregroundColor(.lcAccentBlue)
                }
                .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.lcAccentBlue.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4])))
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 20).fill(Color.lcCardBackground))
        .shadow(color: .black.opacity(0.02), radius: 5, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            selectedActionDetail = action
        }
    }

  
    // MARK: - 🧠 核心逻辑
    private func generateRoutine() {
        withAnimation(.spring()) { isGenerating = true }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var newPhases: [WorkoutPhase] = []
            
            let totalTrainingMinutes = Int(strengthMinutes + cardioMinutes)
            
            // MARK: - 1) 训练容量：组数
            let baseSets = strengthMinutes >= 40 ? 4 : (strengthMinutes >= 20 ? 3 : 2)
            
            let levelAdjustedSets = trainingLevel == 0
            ? min(baseSets, 2)
            : (trainingLevel == 1 ? baseSets : baseSets + 1)
            
            let targetSets: Int
            switch trainingGoal {
            case 0: // 减脂
                targetSets = min(levelAdjustedSets + 1, 5)
            case 1: // 塑形
                targetSets = levelAdjustedSets
            case 2: // 增肌
                targetSets = min(levelAdjustedSets + 1, 5)
            case 3: // 恢复
                targetSets = max(levelAdjustedSets - 1, 1)
            default:
                targetSets = levelAdjustedSets
            }
            
            // MARK: - 2) 次数 / 休息 / 强度提示
            let repGuide: String
            let restGuide: String
            let rpeGuide: String
            
            switch trainingGoal {
            case 0: // 减脂
                repGuide = "12-15次"
                restGuide = "组间休息 30-45 秒"
                rpeGuide = trainingLevel == 0
                ? "🔥 RPE 6-7（微喘，动作不断）"
                : (trainingLevel == 1
                   ? "🔥 RPE 7-8（持续输出，别划水）"
                   : "🔥 RPE 8（有训练感，但别做崩）")
                
            case 1: // 塑形
                repGuide = "10-12次"
                restGuide = "组间休息 45-60 秒"
                rpeGuide = trainingLevel == 0
                ? "🍑 RPE 6-7（动作标准最重要）"
                : (trainingLevel == 1
                   ? "🍑 RPE 7-8（控制发力和节奏）"
                   : "🍑 RPE 8（顶峰收缩要明显）")
                
            case 2: // 增肌
                repGuide = "6-10次"
                restGuide = "组间休息 60-90 秒"
                rpeGuide = trainingLevel == 0
                ? "💪 RPE 7（保留2-3次余力）"
                : (trainingLevel == 1
                   ? "💪 RPE 8（保留1-2次余力）"
                   : "💪 RPE 9（接近力竭，但动作别散）")
                
            case 3: // 恢复
                repGuide = "12-20次"
                restGuide = "组间休息 30-45 秒"
                rpeGuide = "🌿 RPE 5-6（轻中强度，身体找感觉）"
                
            default:
                repGuide = "10-12次"
                restGuide = "组间休息 45-60 秒"
                rpeGuide = "🐥 RPE 7-8（稳定完成）"
            }
            
            // MARK: - 3) 本地小教练：判断动作优先级
            func classifyPriority(for action: FitnessAction) -> Int {
                let text = (action.name + " " + action.targetMuscle).lowercased()
                
                // 复合动作优先级最高
                let compoundKeywords = [
                    "深蹲", "硬拉", "臀推", "弓步", "登阶", "推", "卧推", "俯卧撑",
                    "划船", "下拉", "推举", "引体", "蹲", "row", "press", "squat", "deadlift", "lunge"
                ]
                
                // 核心 / 孤立
                let isolationKeywords = [
                    "卷腹", "平板", "死虫", "bird dog", "侧桥", "臀中肌", "侧平举",
                    "抬腿", "核心", "腹", "rotation", "twist"
                ]
                
                if compoundKeywords.contains(where: { text.contains($0) }) {
                    return 1
                }
                
                if isolationKeywords.contains(where: { text.contains($0) }) {
                    return 3
                }
                
                return 2
            }
            
            // MARK: - 4) 热身
            var warmupActions: [FitnessAction] = []
            let warmupPool = getSmartWarmupPool(part: selectedPart)
            
            for i in 0..<min(2, warmupPool.count) {
                if totalTrainingMinutes <= 20 && i == 1 { break }
                var action = warmupPool[i]
                action.baseReps = "1 组 × 30-45秒 / 10-12次"
                action.intensity = "🌡️ 身体微微发热，关节润滑即可"
                action.priority = 1
                warmupActions.append(action)
            }
            
            newPhases.append(
                WorkoutPhase(
                    title: "Part 1 🔥 针对性热身",
                    subtitle: "唤醒神经，预防受伤",
                    actions: warmupActions
                )
            )
            
            // MARK: - 5) 力量训练主逻辑
            if strengthMinutes > 0 {
                let rawPool = getSmartBalancedPool(equip: selectedEquip, part: selectedPart)
                let restPool = getActiveRestPool().shuffled()
                
                var compoundPool: [FitnessAction] = []
                var accessoryPool: [FitnessAction] = []
                var corePool: [FitnessAction] = []
                
                for var action in rawPool {
                    let p = classifyPriority(for: action)
                    action.priority = p
                    
                    switch p {
                    case 1:
                        compoundPool.append(action)
                    case 3:
                        corePool.append(action)
                    default:
                        accessoryPool.append(action)
                    }
                }
                
                let totalStrengthActions: Int
                if strengthMinutes <= 15 {
                    totalStrengthActions = 2
                } else if strengthMinutes <= 30 {
                    totalStrengthActions = 3
                } else if strengthMinutes <= 45 {
                    totalStrengthActions = 4
                } else {
                    totalStrengthActions = 5
                }
                
                var mainActions: [FitnessAction] = []
                var accessoryActions: [FitnessAction] = []
                var finisherActions: [FitnessAction] = []
                
                // 先塞至少一个复合动作
                if let firstCompound = compoundPool.first {
                    mainActions.append(firstCompound)
                } else if let fallback = rawPool.first {
                    var fixed = fallback
                    fixed.priority = 1
                    mainActions.append(fixed)
                }
                
                // 第二个复合动作：时间够再加
                if totalStrengthActions >= 4, compoundPool.count >= 2 {
                    mainActions.append(compoundPool[1])
                }
                
                // 辅助动作
                let accessoryTargetCount: Int
                if totalStrengthActions <= 2 {
                    accessoryTargetCount = 1
                } else if totalStrengthActions == 3 {
                    accessoryTargetCount = 2
                } else {
                    accessoryTargetCount = 2
                }
                
                for action in accessoryPool.prefix(accessoryTargetCount) {
                    accessoryActions.append(action)
                }
                
                // 核心 / 收尾动作：时间长才给
                if totalStrengthActions >= 4 {
                    for action in corePool.prefix(1) {
                        finisherActions.append(action)
                    }
                }
                if totalStrengthActions >= 5 {
                    for action in corePool.dropFirst().prefix(1) {
                        finisherActions.append(action)
                    }
                }
                
                // 如果动作不够，用 accessory 补齐
                if mainActions.count + accessoryActions.count + finisherActions.count < totalStrengthActions {
                    let usedNames = Set(
                        (mainActions + accessoryActions + finisherActions).map { $0.name }
                    )
                    
                    let fillers = rawPool.filter { !usedNames.contains($0.name) }
                    for action in fillers {
                        if mainActions.count + accessoryActions.count + finisherActions.count >= totalStrengthActions {
                            break
                        }
                        accessoryActions.append(action)
                    }
                }
                
                // 给每个动作注入处方信息
                func decorateStrengthActions(_ actions: [FitnessAction], fallbackRest: String) -> [FitnessAction] {
                    var result: [FitnessAction] = []
                    
                    for (index, var action) in actions.enumerated() {
                        action.baseReps = "\(targetSets) 组 × \(repGuide)"
                        action.activeRest = restPool.isEmpty ? fallbackRest : restPool[index % restPool.count]
                        action.intensity = "\(rpeGuide)｜\(restGuide)"
                        result.append(action)
                    }
                    
                    return result
                }
                
                let decoratedMain = decorateStrengthActions(mainActions, fallbackRest: "组间慢走 + 深呼吸")
                let decoratedAccessory = decorateStrengthActions(accessoryActions, fallbackRest: "甩甩手臂，放松一下")
                let decoratedFinisher = decorateStrengthActions(finisherActions, fallbackRest: "鼻吸口呼，放慢节奏")
                
                if !decoratedMain.isEmpty {
                    newPhases.append(
                        WorkoutPhase(
                            title: "Part 2 💪 主复合动作",
                            subtitle: "先做最重要、最耗能、最值得做的动作",
                            actions: decoratedMain
                        )
                    )
                }
                
                if !decoratedAccessory.isEmpty {
                    newPhases.append(
                        WorkoutPhase(
                            title: "Part 2.2 🍑 辅助塑形",
                            subtitle: "补强弱点，让线条更完整",
                            actions: decoratedAccessory
                        )
                    )
                }
                
                if !decoratedFinisher.isEmpty {
                    newPhases.append(
                        WorkoutPhase(
                            title: "Part 2.3 🛡️ 核心收尾",
                            subtitle: "稳定身体，保护腰背，漂亮收工",
                            actions: decoratedFinisher
                        )
                    )
                }
            }
            
            // MARK: - 6) 有氧
            if cardioMinutes > 0 {
                let cardioName = cardioTypes[selectedCardio].components(separatedBy: " ").last ?? ""
                let cardioActionsRaw = getSmartCardioActions(
                    minutes: Int(cardioMinutes),
                    selectedCardioName: cardioName
                )
                
                let cardioIntensity: String
                if trainingGoal == 3 {
                    cardioIntensity = "🌿恢复: 心率110-125（轻松顺气，越做越舒服）"
                } else if trainingGoal == 2 && cardioGoal == 2 {
                    cardioIntensity = "💪增肌保护: 心率125-140（少量有氧，别影响恢复）"
                } else {
                    switch cardioGoal {
                    case 0:
                        cardioIntensity = "🔥燃脂: 心率120-135（能连贯说话）"
                    case 1:
                        cardioIntensity = "❤️心肺: 心率140-160（说话微喘）"
                    case 2:
                        cardioIntensity = "⚡冲刺: 间歇爆发（无法完整说话）"
                    default:
                        cardioIntensity = "❤️心肺: 稳定输出"
                    }
                }
                
                let cardioSubtitle: String
                if cardioMinutes <= 15 {
                    cardioSubtitle = "轻量活动，恢复一下状态"
                } else if cardioMinutes <= 30 {
                    cardioSubtitle = "分段稳态，开始进入节奏"
                } else {
                    switch cardioName {
                    case "椭圆机": cardioSubtitle = "坡度 + 阻力分段输出"
                    case "跑步机": cardioSubtitle = "热身、主训练、冷却三段跑"
                    case "动感单车": cardioSubtitle = "阻力分段，稳定踩完全程"
                    case "爬楼机": cardioSubtitle = "臀腿耐力三段推进"
                    case "散步": cardioSubtitle = "快走耐力，轻压力燃脂"
                    case "游泳": cardioSubtitle = "分段游动，节奏更完整"
                    default: cardioSubtitle = "分段有氧，跟着节奏做完"
                    }
                }
                
                var cardioActions: [FitnessAction] = []
                for var action in cardioActionsRaw {
                    action.intensity = cardioIntensity
                    action.priority = 1
                    cardioActions.append(action)
                }
                
                newPhases.append(
                    WorkoutPhase(
                        title: "Part 2.5 🏃‍♀️ 智能有氧",
                        subtitle: cardioSubtitle,
                        actions: cardioActions
                    )
                )
            }
            
            // MARK: - 7) 拉伸放松
            var cooldownActions: [FitnessAction] = []
            let cooldownPool = getSmartCooldownPool(part: selectedPart)
            
            for i in 0..<min(2, cooldownPool.count) {
                if totalTrainingMinutes <= 30 && i == 1 { break }
                var action = cooldownPool[i]
                action.baseReps = "1 组 × 30-45秒"
                action.intensity = "🧘‍♀️ 感受轻微拉扯感，深呼吸"
                action.priority = 3
                cooldownActions.append(action)
            }
            
            newPhases.append(
                WorkoutPhase(
                    title: "Part 3 🧘‍♀️ 靶向拉伸",
                    subtitle: "哪里酸痛拉哪里，慢慢收心",
                    actions: cooldownActions
                )
            )
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                generatedPhases = newPhases
                isGenerating = false
            }
        }
    }
    
            private func finishAndRecord() {
                let todayStr = AppState.df.string(from: Date())

                let goalText = {
                    switch trainingGoal {
                    case 0: return "减脂"
                    case 1: return "塑形"
                    case 2: return "增肌"
                    case 3: return "恢复"
                    default: return "训练"
                    }
                }()

                var recordText = "运动了 \(totalMinutes) 分钟"

                if strengthMinutes > 0 && cardioMinutes > 0 {
                    recordText = "\(goalText)：\(equips[selectedEquip].components(separatedBy: " ").last ?? "")无氧 + \(cardioTypes[selectedCardio].components(separatedBy: " ").last ?? "")有氧"
                } else if strengthMinutes > 0 {
                    recordText = "\(goalText)：纯力量，练\(parts[selectedPart].components(separatedBy: " ").last ?? "")"
                } else if cardioMinutes > 0 {
                    recordText = "\(goalText)：纯有氧，\(cardioTypes[selectedCardio].components(separatedBy: " ").last ?? "")"
                }

                state.addTodayTask(title: "✅ 极爽多巴胺：\(recordText)")

                if let idx = state.weightRecords.firstIndex(where: { AppState.df.string(from: $0.date) == todayStr }) {
                    state.weightRecords[idx].exerciseDescription = recordText
                } else {
                    state.weightRecords.append(
                        WeightRecord(
                            date: Date(),
                            weight: state.weightRecords.last?.weight ?? 0.0,
                            didPoop: false,
                            exerciseDescription: recordText
                        )
                    )
                }

                dismiss()
            }
}

    // 弹窗动作详解
// MARK: - 弹窗动作详解 (已拆解，修复 Xcode 大脑宕机问题)
struct ActionDetailSheet: View {
    let action: FitnessAction
    let onStartGuided: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        heroSection       // 🧀 1. 顶部图标
                        tipSection        // 🧀 2. 避坑指南
                        stepsSection      // 🧀 3. 动作拆解
                    }
                    .padding(.bottom, 24)
                }
                
                bottomButtonSection       // 🧀 4. 底部陪练按钮
            }
            .background(Color.lcBackground.ignoresSafeArea())
            .navigationTitle(action.name.components(separatedBy: " (").first ?? action.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .presentationDetents([.fraction(0.8), .large])
    }

    // MARK: - 下面是把原本写在一堆的积木，拆分成了 4 个独立小块
    
    // 🧀 1. 顶部大图标区域
    private var heroSection: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.lcCheeseYellow.opacity(0.2))
                .frame(height: 200)

            Text(action.emojiIcon)
                .font(.system(size: 100))
                .shadow(color: .black.opacity(0.1), radius: 10, y: 10)
        }
        .padding(.horizontal)
        .padding(.top, 20)
    }

    // 🧀 2. 避坑指南区域
    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text("起司私教避坑指南")
                    .font(.headline)
                    .foregroundColor(.lcText)
            }

            Text(action.tip)
                .font(.system(.body, design: .rounded))
                .foregroundColor(.lcTextSecondary)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // 🧀 3. 动作拆解区域
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("动作拆解：")
                .font(.headline)
                .foregroundColor(.lcText)

            ForEach(0..<action.steps.count, id: \.self) { index in
                HStack(alignment: .top, spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.lcAccentBlue)
                            .frame(width: 28, height: 28)

                        Text("\(index + 1)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }

                    Text(action.steps[index])
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.lcTextSecondary)
                        .padding(.top, 4)

                    Spacer()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lcCardBackground)
        .cornerRadius(16)
        .padding(.horizontal)
    }

    // 🧀 4. 底部陪练按钮区域
    private var bottomButtonSection: some View {
        VStack(spacing: 12) {
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onStartGuided()
                }
            } label: {
                Text("开始陪练 🟡")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.lcYellow)
                    .cornerRadius(16)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 20)
        .background(Color.lcBackground)
    }
}
// ☝️ 替换到此结束！下面的 WorkoutSessionSheet 完全不用动！

                // MARK: - 陪练模式弹窗 (现在它独立自由啦！)
                struct WorkoutSessionSheet: View {
            let action: FitnessAction
        @Environment(\.dismiss) var dismiss

        @State private var currentSet: Int = 1
        @State private var currentRep: Int = 0

        private var totalSets: Int {
            extractSets(from: action.baseReps)
        }

        private var totalReps: Int {
            extractReps(from: action.baseReps)
        }

        var body: some View {
            NavigationStack {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(action.name.components(separatedBy: " (").first ?? action.name)
                            .font(.title2.bold())
                            .foregroundColor(.lcText)

                        Text("第 \(currentSet) / \(totalSets) 组")
                            .font(.headline)
                            .foregroundColor(.lcAccentBlue)
                    }
                    .padding(.top, 20)

                    VStack(spacing: 12) {
                        Text("已完成")
                            .font(.subheadline)
                            .foregroundColor(.lcTextSecondary)

                        Text("\(currentRep) / \(totalReps)")
                            .font(.system(size: 44, weight: .black, design: .rounded))
                            .foregroundColor(.lcAccentBlue)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.lcCardBackground)
                    )

                    if !action.steps.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("这一组怎么做")
                                .font(.headline)
                                .foregroundColor(.lcText)

                            ForEach(action.steps.prefix(4), id: \.self) { step in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.lcAccentBlue)
                                    Text(step)
                                        .foregroundColor(.lcTextSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.lcCardBackground)
                        )
                    }

                    Button {
                        if currentRep < totalReps {
                            currentRep += 1
                        }
                    } label: {
                        Text("做完一次 +1")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lcAccentBlue)
                            .cornerRadius(18)
                    }

                    Button {
                        if currentSet < totalSets {
                            currentSet += 1
                            currentRep = 0
                        } else {
                            dismiss()
                        }
                    } label: {
                        Text(currentSet < totalSets ? "完成这一组 → 下一组" : "训练完成 ✅")
                            .font(.headline)
                            .foregroundColor(.lcAccentBlue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lcAccentBlue.opacity(0.1))
                            .cornerRadius(18)
                    }

                    Spacer()
                }
                .padding(24)
                .background(Color.lcBackground.ignoresSafeArea())
                .navigationTitle("陪你开练")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("关闭") { dismiss() }
                    }
                }
            }
            .presentationDetents([.large])
        }

        private func extractSets(from text: String) -> Int {
            let matches = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
            return matches.first ?? 3
        }

                private func extractReps(from text: String) -> Int {
                            let matches = text.components(separatedBy: CharacterSet.decimalDigits.inverted)
                                .compactMap { Int($0) }

                            if matches.count >= 2 {
                                return matches[1]
                            } else {
                                return 12
                            }
                        }
                    }

            
