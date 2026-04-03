import SwiftUI

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
        
        @State private var generatedPhases: [WorkoutPhase] = []
        @State private var isGenerating: Bool = false
    @State private var selectedActionDetail: FitnessAction?
    
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
                                        
                                        // 🆕 路线A新增：训练经验等级 (全局适用)
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text("🏅 你的训练经验：").font(.headline).foregroundColor(.lcTextSecondary)
                                            Picker("经验等级", selection: $trainingLevel) {
                                                Text("🐣 新手").tag(0)
                                                Text("🐥 中级").tag(1)
                                                Text("🦅 高手").tag(2)
                                            }.pickerStyle(.segmented)
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
                                    Button { selectedActionDetail = action } label: { actionCard(for: action) }
                                    .buttonStyle(.plain)
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
        .sheet(item: $selectedActionDetail) { action in ActionDetailSheet(action: action) }
    }
    
    // MARK: - UI 子组件：卡片
    private func actionCard(for action: FitnessAction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(action.emojiIcon).font(.title3)
                VStack(alignment: .leading, spacing: 6) {
                    Text(action.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(action.name.contains("汗水") ? .lcAccentBlue : .lcText)
                    
                    // MARK: --- 从这里开始替换 ---
                    HStack(spacing: 8) {
                        // 1. 显示基础容量（如：10 分钟 或 3 组 x 12 次）
                        if !action.baseReps.isEmpty {
                            Text(action.baseReps)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundColor(.lcAccentBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.lcAccentBlue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        // 2. 直接显示具体的阻力、坡度、速度
                        if !action.quickStats.isEmpty {
                            ForEach(action.quickStats, id: \.self) { stat in
                                HStack(spacing: 4) {
                                    // 根据关键词匹配小图标
                                    if stat.contains("阻力") { Image(systemName: "gearshape.fill") }
                                    else if stat.contains("坡度") { Image(systemName: "arrow.up.forward.circle.fill") }
                                    else if stat.contains("速度") { Image(systemName: "gauge.with.needle.fill") }
                                    
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
                    // MARK: --- 替换结束 ---
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
        .padding(16).background(RoundedRectangle(cornerRadius: 20).fill(Color.lcCardBackground))
        .shadow(color: .black.opacity(0.02), radius: 5, y: 2)
    }
    
    // MARK: - 🧠 核心逻辑
    // MARK: - 🧠 核心逻辑 (科学进阶版)
        private func generateRoutine() {
            withAnimation(.spring()) { isGenerating = true }
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            #endif
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                var newPhases: [WorkoutPhase] = []
                
                // 🆕 1. 容量控制：不再只看时间，还要看“训练等级(trainingLevel)”
                let baseSets = strengthMinutes >= 40 ? 4 : (strengthMinutes >= 20 ? 3 : 2)
                // 新手组数打折，高手组数增加
                let targetSets = trainingLevel == 0 ? min(baseSets, 2) : (trainingLevel == 1 ? baseSets : baseSets + 1)
                
                // 🆕 2. 强度控制：根据等级给出 RPE（主观疲劳度）建议
                let rpeGuide = trainingLevel == 0 ? "🐣 RPE 6-7 (做完还能做3个)" : (trainingLevel == 1 ? "🐥 RPE 8 (做完还能做1-2个)" : "🦅 RPE 9-10 (接近力竭极限)")
                
                // ---- PART 1: 热身 ----
                var warmupActions: [FitnessAction] = []
                let wPool = getSmartWarmupPool(part: selectedPart)
                for i in 0..<min(2, wPool.count) {
                    // 假设存在 totalMinutes，如果没有会报错，如果是这样请告诉我
                    if (strengthMinutes + cardioMinutes) <= 20 && i == 1 { break }
                    var action = wPool[i]
                    action.baseReps = "1 组 × \(action.baseReps)"
                    action.intensity = "🌡️ 身体微微发热，关节润滑即可" // 注入强度
                    action.priority = 1
                    warmupActions.append(action)
                }
                newPhases.append(WorkoutPhase(title: "Part 1 🔥 针对性热身", subtitle: "唤醒神经，预防受伤", actions: warmupActions))
                
                // ---- PART 2: 核心训练 ----
                if strengthMinutes > 0 {
                    var mainActions: [FitnessAction] = []
                    let restPool = getActiveRestPool().shuffled()
                    let balancedPool = getSmartBalancedPool(equip: selectedEquip, part: selectedPart)
                    let actionCount = strengthMinutes <= 15 ? 2 : (strengthMinutes <= 30 ? 3 : 4)
                    
                    for i in 0..<min(actionCount, balancedPool.count) {
                        var action = balancedPool[i]
                        action.baseReps = "\(targetSets) 组 × \(action.baseReps)"
                        action.activeRest = restPool[i % restPool.count]
                        action.intensity = rpeGuide // 🆕 注入刚才算好的 RPE 强度
                        action.priority = 2
                        mainActions.append(action)
                    }
                    newPhases.append(WorkoutPhase(title: "Part 2 💪 核心容量", subtitle: "动作已做肌群平衡处理", actions: mainActions))
                }
                
                // ---- PART 2.5: 有氧 ----
                if cardioMinutes > 0 {
                    let cardioName = cardioTypes[selectedCardio].components(separatedBy: " ").last ?? ""
                    let cardioActionsRaw = getSmartCardioActions(
                        minutes: Int(cardioMinutes),
                        selectedCardioName: cardioName
                    )
                    
                    // 🆕 3. 有氧目标：根据 cardioGoal 注入明确的心率/状态指导
                    let cardioIntensity = cardioGoal == 0 ? "🔥燃脂: 心率120-135 (能连贯说话)" : (cardioGoal == 1 ? "❤️心肺: 心率140-160 (说话微喘)" : "⚡冲刺: 间歇爆发 (无法说话)")

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
                    
                    // 把强度注入到每个有氧动作里
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
                
                // ---- PART 3: 放松 ----
                var cooldownActions: [FitnessAction] = []
                let cPool = getSmartCooldownPool(part: selectedPart)
                for i in 0..<min(2, cPool.count) {
                    if (strengthMinutes + cardioMinutes) <= 30 && i == 1 { break }
                    var action = cPool[i]
                    action.baseReps = "1 组 × \(action.baseReps)"
                    action.intensity = "🧘‍♀️ 感受轻微拉扯感，深呼吸" // 注入强度
                    action.priority = 3
                    cooldownActions.append(action)
                }
                newPhases.append(WorkoutPhase(title: "Part 3 🧘‍♀️ 靶向拉伸", subtitle: "哪里酸痛拉哪里", actions: cooldownActions))
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    generatedPhases = newPhases
                    isGenerating = false
                }
            }
        }
    
    
    private func finishAndRecord() {
        let todayStr = AppState.df.string(from: Date())
        var recordText = "运动了 \(totalMinutes) 分钟"
        if strengthMinutes > 0 && cardioMinutes > 0 { recordText = "\(equips[selectedEquip].components(separatedBy: " ").last ?? "")无氧 + \(cardioTypes[selectedCardio].components(separatedBy: " ").last ?? "")有氧" }
        else if strengthMinutes > 0 { recordText = "纯力量：练\(parts[selectedPart].components(separatedBy: " ").last ?? "")" }
        else if cardioMinutes > 0 { recordText = "纯有氧：\(cardioTypes[selectedCardio].components(separatedBy: " ").last ?? "")" }
        
        state.addTodayTask(title: "✅ 极爽多巴胺：\(recordText)")
        if let idx = state.weightRecords.firstIndex(where: { AppState.df.string(from: $0.date) == todayStr }) { state.weightRecords[idx].exerciseDescription = recordText }
        else { state.weightRecords.append(WeightRecord(date: Date(), weight: state.weightRecords.last?.weight ?? 0.0, didPoop: false, exerciseDescription: recordText)) }
        dismiss()
    }
}

// 弹窗动作详解
struct ActionDetailSheet: View {
    let action: FitnessAction
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack { RoundedRectangle(cornerRadius: 24).fill(Color.lcCheeseYellow.opacity(0.2)).frame(height: 200); Text(action.emojiIcon).font(.system(size: 100)).shadow(color: .black.opacity(0.1), radius: 10, y: 10) }.padding(.horizontal).padding(.top, 20)
                    VStack(alignment: .leading, spacing: 12) { HStack { Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange); Text("起司私教避坑指南").font(.headline).foregroundColor(.lcText) }; Text(action.tip).font(.system(.body, design: .rounded)).foregroundColor(.lcTextSecondary).lineSpacing(4) }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.orange.opacity(0.1)).cornerRadius(16).padding(.horizontal)
                    VStack(alignment: .leading, spacing: 16) { Text("动作拆解：").font(.headline).foregroundColor(.lcText); ForEach(0..<action.steps.count, id: \.self) { index in HStack(alignment: .top, spacing: 16) { ZStack { Circle().fill(Color.lcAccentBlue).frame(width: 28, height: 28); Text("\(index + 1)").font(.caption.bold()).foregroundColor(.white) }; Text(action.steps[index]).font(.system(.body, design: .rounded)).foregroundColor(.lcTextSecondary).padding(.top, 4); Spacer() } } }.padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.lcCardBackground).cornerRadius(16).padding(.horizontal)
                }
                .padding(.bottom, 40)
            }
            .background(Color.lcBackground.ignoresSafeArea())
            .navigationTitle(action.name.components(separatedBy: " (").first ?? action.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
        }
        .presentationDetents([.fraction(0.8), .large])
    }
}
