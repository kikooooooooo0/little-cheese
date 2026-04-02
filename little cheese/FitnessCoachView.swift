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
                        if strengthMinutes > 0 {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("力量训练设定：").font(.headline).foregroundColor(.lcTextSecondary)
                                Picker("装备", selection: $selectedEquip) { ForEach(0..<equips.count, id: \.self) { i in Text(equips[i]).tag(i) } }.pickerStyle(.segmented)
                                Picker("部位", selection: $selectedPart) { ForEach(0..<parts.count, id: \.self) { i in Text(parts[i]).tag(i) } }.pickerStyle(.segmented)
                            }
                        }
                        if strengthMinutes > 0 && cardioMinutes > 0 { Divider().opacity(0.3) }
                        if cardioMinutes > 0 {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("有氧项目选择：").font(.headline).foregroundColor(.lcTextSecondary)
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
                            }
                        }
                    }
                    .padding(20).background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
                    .shadow(color: .black.opacity(0.02), radius: 10, y: 5).transition(.opacity)
                }
                
                // 4. 生成按钮
                Button { generateRoutine() } label: {
                    HStack {
                        Image(systemName: "cpu")
                        Text(totalMinutes == 0 ? "请先拉动时间条 ⏱️" : (generatedPhases.isEmpty ? "启动智能训练引擎" : "重新智能生成"))
                    }
                    .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding()
                    .background(totalMinutes == 0 ? Color.gray.opacity(0.5) : (isGenerating ? Color.lcSoftBlue : Color.lcAccentBlue))
                    .cornerRadius(20)
                }
                .disabled(totalMinutes == 0)
                
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
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.name).font(.system(.headline, design: .rounded)).foregroundColor(action.name.contains("汗水") ? .lcAccentBlue : .lcText)
                    if !action.baseReps.isEmpty {
                        Text(action.baseReps).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.lcAccentBlue)
                    }
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
    private func generateRoutine() {
        withAnimation(.spring()) { isGenerating = true }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var newPhases: [WorkoutPhase] = []
            
            let targetSets = strengthMinutes >= 40 ? 4 : (strengthMinutes >= 20 ? 3 : 2)
            
            // ---- PART 1: 热身 ----
            var warmupActions: [FitnessAction] = []
            let wPool = getSmartWarmupPool(part: selectedPart)
            for i in 0..<min(2, wPool.count) {
                if totalMinutes <= 20 && i == 1 { break }
                var action = wPool[i]
                action.baseReps = "1 组 × \(action.baseReps)"
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
                    mainActions.append(action)
                }
                newPhases.append(WorkoutPhase(title: "Part 2 💪 核心容量", subtitle: "动作已做肌群平衡处理", actions: mainActions))
            }
            
            // ---- PART 2.5: 有氧 ----
            if cardioMinutes > 0 {
                let cardioName = cardioTypes[selectedCardio].components(separatedBy: " ").last ?? ""
                let cardioActions = getSmartCardioActions(
                    minutes: Int(cardioMinutes),
                    selectedCardioName: cardioName
                )

                let cardioSubtitle: String
                if cardioMinutes <= 15 {
                    cardioSubtitle = "轻量活动，恢复一下状态"
                } else if cardioMinutes <= 30 {
                    cardioSubtitle = "分段稳态，开始进入节奏"
                } else {
                    switch cardioName {
                    case "椭圆机":
                        cardioSubtitle = "坡度 + 阻力分段输出"
                    case "跑步机":
                        cardioSubtitle = "热身、主训练、冷却三段跑"
                    case "动感单车":
                        cardioSubtitle = "阻力分段，稳定踩完全程"
                    case "爬楼机":
                        cardioSubtitle = "臀腿耐力三段推进"
                    case "散步":
                        cardioSubtitle = "快走耐力，轻压力燃脂"
                    case "游泳":
                        cardioSubtitle = "分段游动，节奏更完整"
                    default:
                        cardioSubtitle = "分段有氧，跟着节奏做完"
                    }
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
                if totalMinutes <= 30 && i == 1 { break }
                var action = cPool[i]
                action.baseReps = "1 组 × \(action.baseReps)"
                cooldownActions.append(action)
            }
            newPhases.append(WorkoutPhase(title: "Part 3 🧘‍♀️ 靶向拉伸", subtitle: "哪里酸痛拉哪里", actions: cooldownActions))
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                generatedPhases = newPhases
                isGenerating = false
            }
        }
    }
    
    // MARK: - 🧠 引擎数据层
    private func getSmartWarmupPool(part: Int) -> [FitnessAction] {
        if part == 2 { // 下肢热身：髋 + 臀唤醒
            return [
                FitnessAction(
                    name: "动态臀桥唤醒",
                    targetMuscle: "臀大肌",
                    tip: "不要用腰顶，屁股夹紧发力",
                    emojiIcon: "🌉",
                    steps: [
                        "仰卧屈膝，脚跟踩地",
                        "呼气时顶起臀部，感受屁股发力",
                        "慢慢放下，不要砸回地面"
                    ],
                    baseReps: "15 次"
                ),
                FitnessAction(
                    name: "世界最伟大拉伸",
                    targetMuscle: "髋关节活动度",
                    tip: "动作一定要慢，感受髋部和胸椎被打开",
                    emojiIcon: "🌍",
                    steps: [
                        "弓步迈出，同侧手肘尽量靠近地面",
                        "随后同侧手臂向天花板打开，带动胸椎旋转",
                        "回到起始位后重复"
                    ],
                    baseReps: "每侧 5 次"
                )
            ].shuffled()
            
        } else if part == 1 { // 背部热身：脊柱活动 + 肩胛控制
            return [
                FitnessAction(
                    name: "猫牛式脊柱活动",
                    targetMuscle: "脊柱灵活度",
                    tip: "一节一节地活动脊柱，不要只甩脖子",
                    emojiIcon: "🐈",
                    steps: [
                        "四足跪姿，手在肩下，膝在髋下",
                        "吸气时抬头塌腰，胸口打开",
                        "呼气时低头拱背，肚脐向里收"
                    ],
                    baseReps: "10 次"
                ),
                FitnessAction(
                    name: "墙天使预热 / 墙滑",
                    targetMuscle: "肩胛控制",
                    tip: "重点不是抬高，而是肋骨别乱翻、肩膀别耸",
                    emojiIcon: "🪽",
                    steps: [
                        "背靠墙站立，上背尽量贴墙",
                        "手臂摆成 W 形，缓慢向上滑到 Y 形",
                        "全程保持脖子放松，感受肩胛顺畅滑动"
                    ],
                    baseReps: "8 - 10 次"
                )
            ].shuffled()
            
        } else { // 核心热身：呼吸控制 + 深层稳定预激活
            return [
                FitnessAction(
                    name: "死虫子预激活",
                    targetMuscle: "深层核心",
                    tip: "下背部必须贴地，不要让腰偷偷拱起来",
                    emojiIcon: "🪲",
                    steps: [
                        "仰卧，双手指天，双腿抬起屈膝 90 度",
                        "先把下背压平地面，再缓慢伸出对侧手脚",
                        "动作做小一点没关系，重点是稳定"
                    ],
                    baseReps: "每侧 6 - 8 次"
                ),
                FitnessAction(
                    name: "骨盆呼吸收紧",
                    targetMuscle: "腹横肌 / 骨盆控制",
                    tip: "呼气时轻轻收紧下腹，不要耸肩憋气",
                    emojiIcon: "🌬️",
                    steps: [
                        "仰卧屈膝，双脚踩地，双手放在下腹",
                        "吸气时肋骨打开，呼气时轻轻收紧核心",
                        "感受下腹稳定，而不是大力卷腹"
                    ],
                    baseReps: "6 - 8 次呼吸"
                )
            ].shuffled()
        }
    }
    
    private func getSmartCooldownPool(part: Int) -> [FitnessAction] {
        if part == 2 {
            return [
                FitnessAction(name: "鸽子式臀部拉伸", targetMuscle: "臀大肌", tip: "如果膝盖痛就立刻停止", emojiIcon: "🕊️", steps: ["前腿屈膝横放，后腿伸直", "上半身慢慢趴下感受臀部拉扯"], baseReps: "每侧 45 秒"),
                FitnessAction(name: "大腿前侧站立拉伸", targetMuscle: "股四头肌", tip: "保持身体直立，不要塌腰", emojiIcon: "🦩", steps: ["单手抓住同侧脚踝，将脚跟拉向臀部"], baseReps: "每侧 30 秒")
            ].shuffled()
        } else if part == 1 {
            return [
                FitnessAction(name: "婴儿式背部放松", targetMuscle: "下背阔肌", tip: "尽情感受呼吸，放松全身", emojiIcon: "👶", steps: ["双膝跪地，臀部坐在脚跟，上半身趴下"], baseReps: "1 分钟"),
                FitnessAction(name: "胸部墙壁拉伸", targetMuscle: "胸大肌补偿", tip: "防止练背导致圆肩", emojiIcon: "🚪", steps: ["单手小臂贴住墙面，身体向反方向扭转"], baseReps: "每侧 30 秒")
            ].shuffled()
        } else {
            return [
                FitnessAction(name: "腹部眼镜蛇拉伸", targetMuscle: "腹直肌", tip: "骨盆贴地，肩膀下沉", emojiIcon: "🐍", steps: ["趴在垫子上，双手将上半身撑起"], baseReps: "30 秒"),
                FitnessAction(name: "仰卧脊柱扭转放松", targetMuscle: "下背部", tip: "肩膀不要离开地面", emojiIcon: "🥨", steps: ["仰卧，单腿屈膝跨过身体对侧", "手臂向反方向展开，目光看反方向手指"], baseReps: "每侧 45 秒")
            ].shuffled()
        }
    }
    
    private func getActiveRestPool() -> [String] {
        return ["腿下击掌 20 次", "靠墙静蹲休息 30 秒", "站立抱膝走 10 步", "慢速高抬腿 20 次", "深呼吸，喝两口水！", "核心收紧站立 20 秒"]
    }
    private func getSmartCardioActions(minutes: Int, selectedCardioName: String) -> [FitnessAction] {
        if minutes <= 15 {
            return [
                FitnessAction(
                    name: "轻松热身段",
                    targetMuscle: "心肺唤醒",
                    tip: "先把呼吸和节奏找回来，不要一上来就猛冲。",
                    emojiIcon: "🌿",
                    steps: [
                        "先用非常轻松的节奏开始",
                        "保持可以完整说话的呼吸感",
                        "结束时身体微微发热就够了"
                    ],
                    baseReps: "\(minutes) 分钟"
                )
            ]
        } else if minutes <= 30 {
            switch selectedCardioName {
            case "椭圆机":
                return [
                    FitnessAction(
                        name: "椭圆机热身段",
                        targetMuscle: "心肺唤醒",
                        tip: "先顺起来，不要急着加阻力。",
                        emojiIcon: "🛸",
                        steps: [
                            "坡度 6",
                            "阻力 3",
                            "保持均匀踩踏，让身体慢慢热起来"
                        ],
                        baseReps: "8 分钟"
                    ),
                    FitnessAction(
                        name: "椭圆机稳态燃脂段",
                        targetMuscle: "心肺耐力",
                        tip: "这段是主训练，稳定比乱冲更重要。",
                        emojiIcon: "💦",
                        steps: [
                            "坡度 8 - 10",
                            "阻力 4 - 5",
                            "保持持续输出，微喘但还能说短句"
                        ],
                        baseReps: "\(max(12, minutes - 12)) 分钟"
                    ),
                    FitnessAction(
                        name: "椭圆机冷却段",
                        targetMuscle: "主动恢复",
                        tip: "最后把呼吸慢慢放下来，不要直接停。",
                        emojiIcon: "🍃",
                        steps: [
                            "坡度 5 - 6",
                            "阻力 2 - 3",
                            "逐渐减速，收尾"
                        ],
                        baseReps: "4 分钟"
                    )
                ]
                
            case "跑步机":
                return [
                    FitnessAction(
                        name: "跑步机热身段",
                        targetMuscle: "心肺唤醒",
                        tip: "先把步频和呼吸找顺。",
                        emojiIcon: "🏃‍♀️",
                        steps: [
                            "坡度 0 - 2",
                            "轻松走或慢跑",
                            "让身体慢慢进入状态"
                        ],
                        baseReps: "8 分钟"
                    ),
                    FitnessAction(
                        name: "跑步机稳态段",
                        targetMuscle: "心肺耐力",
                        tip: "速度不要忽快忽慢，稳住最重要。",
                        emojiIcon: "🔥",
                        steps: [
                            "坡度 3 - 5",
                            "速度提高到微喘但能坚持",
                            "保持均匀节奏"
                        ],
                        baseReps: "\(max(12, minutes - 12)) 分钟"
                    ),
                    FitnessAction(
                        name: "跑步机冷却段",
                        targetMuscle: "主动恢复",
                        tip: "慢慢降速，不要突然跳下跑步机。",
                        emojiIcon: "🍃",
                        steps: [
                            "坡度回到 0 - 1",
                            "速度慢慢降下来",
                            "呼吸恢复平稳"
                        ],
                        baseReps: "4 分钟"
                    )
                ]
                
            default:
                return [
                    FitnessAction(
                        name: "\(selectedCardioName) 热身段",
                        targetMuscle: "心肺唤醒",
                        tip: "先慢慢热起来。",
                        emojiIcon: "🌿",
                        steps: ["轻松开始", "呼吸打开", "节奏稳定"],
                        baseReps: "8 分钟"
                    ),
                    FitnessAction(
                        name: "\(selectedCardioName) 稳态段",
                        targetMuscle: "心肺耐力",
                        tip: "保持稳定输出。",
                        emojiIcon: "💦",
                        steps: ["进入主训练节奏", "保持微喘", "不要忽快忽慢"],
                        baseReps: "\(max(12, minutes - 12)) 分钟"
                    ),
                    FitnessAction(
                        name: "\(selectedCardioName) 冷却段",
                        targetMuscle: "主动恢复",
                        tip: "慢慢收尾。",
                        emojiIcon: "🍃",
                        steps: ["逐渐减速", "恢复呼吸", "完成收尾"],
                        baseReps: "4 分钟"
                    )
                ]
            }
        } else {
            switch selectedCardioName {
            case "椭圆机":
                return [
                    FitnessAction(
                        name: "椭圆机热身段",
                        targetMuscle: "心肺唤醒",
                        tip: "先把关节和呼吸带起来，不要急着上强度。",
                        emojiIcon: "🛸",
                        steps: [
                            "坡度 10",
                            "阻力 4",
                            "匀速踩踏，让身体彻底热开"
                        ],
                        baseReps: "10 分钟"
                    ),
                    FitnessAction(
                        name: "椭圆机主训练段",
                        targetMuscle: "心肺耐力 / 下肢输出",
                        tip: "这一段是主菜，稳住节奏，不要东一脚西一脚。",
                        emojiIcon: "⚡",
                        steps: [
                            "坡度 12",
                            "阻力 6",
                            "保持持续输出，呼吸明显变重但还能控制动作"
                        ],
                        baseReps: "\(max(20, minutes - 20)) 分钟"
                    ),
                    FitnessAction(
                        name: "椭圆机冷却段",
                        targetMuscle: "主动恢复",
                        tip: "最后不是摆烂，是慢慢把身体接回来。",
                        emojiIcon: "🍃",
                        steps: [
                            "坡度 10",
                            "阻力 2",
                            "放慢节奏，让心率回落"
                        ],
                        baseReps: "10 分钟"
                    )
                ]
                
            case "跑步机":
                return [
                    FitnessAction(
                        name: "跑步机热身段",
                        targetMuscle: "心肺唤醒",
                        tip: "先把步伐走顺，别一上来就追速度。",
                        emojiIcon: "🏃‍♀️",
                        steps: [
                            "坡度 2",
                            "轻松快走或慢跑",
                            "让脚步和呼吸进入状态"
                        ],
                        baseReps: "10 分钟"
                    ),
                    FitnessAction(
                        name: "跑步机主训练段",
                        targetMuscle: "下肢耐力 / 心肺挑战",
                        tip: "主训练段要有训练感，但动作不能散。",
                        emojiIcon: "🔥",
                        steps: [
                            "坡度 6 - 10",
                            "速度提高到明显发热、微喘偏强",
                            "保持步频稳定，不要扶太多"
                        ],
                        baseReps: "\(max(20, minutes - 20)) 分钟"
                    ),
                    FitnessAction(
                        name: "跑步机冷却段",
                        targetMuscle: "主动恢复",
                        tip: "慢慢降下来，收尾要体面。",
                        emojiIcon: "🍃",
                        steps: [
                            "坡度 0 - 2",
                            "轻松走",
                            "呼吸恢复平稳"
                        ],
                        baseReps: "10 分钟"
                    )
                ]
                
            case "动感单车":
                return [
                    FitnessAction(
                        name: "单车热身段",
                        targetMuscle: "心肺唤醒",
                        tip: "先把腿转顺，再谈输出。",
                        emojiIcon: "🚴",
                        steps: [
                            "低阻力",
                            "轻松踩踏",
                            "髋和膝盖慢慢热起来"
                        ],
                        baseReps: "10 分钟"
                    ),
                    FitnessAction(
                        name: "单车主训练段",
                        targetMuscle: "心肺耐力 / 大腿输出",
                        tip: "阻力要够，但别把动作踩散。",
                        emojiIcon: "⚡",
                        steps: [
                            "中高阻力",
                            "保持稳定踏频",
                            "进入持续输出状态"
                        ],
                        baseReps: "\(max(20, minutes - 20)) 分钟"
                    ),
                    FitnessAction(
                        name: "单车冷却段",
                        targetMuscle: "主动恢复",
                        tip: "慢慢松下来，不要突然停。",
                        emojiIcon: "🍃",
                        steps: [
                            "低阻力",
                            "轻松踩踏",
                            "让呼吸逐渐恢复"
                        ],
                        baseReps: "10 分钟"
                    )
                ]
                
            case "爬楼机":
                return [
                    FitnessAction(
                        name: "爬楼机热身段",
                        targetMuscle: "臀腿唤醒",
                        tip: "先找到节奏，不要前面就把腿炸掉。",
                        emojiIcon: "🧗‍♀️",
                        steps: [
                            "低速热身",
                            "轻扶扶手",
                            "核心收紧，步伐稳定"
                        ],
                        baseReps: "8 分钟"
                    ),
                    FitnessAction(
                        name: "爬楼机主训练段",
                        targetMuscle: "臀腿耐力 / 心肺挑战",
                        tip: "主训练段重点是持续，不是乱冲。",
                        emojiIcon: "🔥",
                        steps: [
                            "中高速度",
                            "步伐稳定向上",
                            "感受臀腿持续发力"
                        ],
                        baseReps: "\(max(18, minutes - 16)) 分钟"
                    ),
                    FitnessAction(
                        name: "爬楼机冷却段",
                        targetMuscle: "主动恢复",
                        tip: "慢下来，把腿救回来。",
                        emojiIcon: "🍃",
                        steps: [
                            "低速恢复",
                            "放慢呼吸",
                            "逐渐结束"
                        ],
                        baseReps: "8 分钟"
                    )
                ]
                
            case "散步":
                return [
                    FitnessAction(
                        name: "快走启动段",
                        targetMuscle: "心肺唤醒",
                        tip: "先走开，不要急。",
                        emojiIcon: "🚶",
                        steps: [
                            "轻松走",
                            "摆臂自然",
                            "身体慢慢热起来"
                        ],
                        baseReps: "10 分钟"
                    ),
                    FitnessAction(
                        name: "耐力快走段",
                        targetMuscle: "低压燃脂 / 持续耐力",
                        tip: "这一段重点是持续，不是拼命。",
                        emojiIcon: "🌤️",
                        steps: [
                            "加快步频",
                            "保持能说短句的速度",
                            "如果在跑步机可用坡度 3 - 6"
                        ],
                        baseReps: "\(max(20, minutes - 20)) 分钟"
                    ),
                    FitnessAction(
                        name: "散步收尾段",
                        targetMuscle: "主动恢复",
                        tip: "把状态慢慢降下来。",
                        emojiIcon: "🍃",
                        steps: [
                            "逐渐放慢",
                            "放松肩膀",
                            "恢复平稳呼吸"
                        ],
                        baseReps: "10 分钟"
                    )
                ]
                
            case "游泳":
                return [
                    FitnessAction(
                        name: "游泳热身段",
                        targetMuscle: "全身唤醒",
                        tip: "先把呼吸和划水节奏找顺。",
                        emojiIcon: "🏊‍♀️",
                        steps: [
                            "轻松游",
                            "动作完整",
                            "不要急着求快"
                        ],
                        baseReps: "10 分钟"
                    ),
                    FitnessAction(
                        name: "游泳主训练段",
                        targetMuscle: "心肺耐力 / 全身协调",
                        tip: "主训练段保持节奏感，不要乱扑腾。",
                        emojiIcon: "💦",
                        steps: [
                            "连续游或分段游",
                            "保持稳定呼吸",
                            "每一趟动作尽量完整"
                        ],
                        baseReps: "\(max(20, minutes - 20)) 分钟"
                    ),
                    FitnessAction(
                        name: "游泳放松段",
                        targetMuscle: "主动恢复",
                        tip: "最后轻松游，把心率降下来。",
                        emojiIcon: "🍃",
                        steps: [
                            "轻松划水",
                            "拉长呼吸",
                            "慢慢结束"
                        ],
                        baseReps: "10 分钟"
                    )
                ]
                
            default:
                return [
                    FitnessAction(
                        name: "\(selectedCardioName) 热身段",
                        targetMuscle: "心肺唤醒",
                        tip: "先热起来。",
                        emojiIcon: "🌿",
                        steps: ["轻松开始", "找呼吸", "找节奏"],
                        baseReps: "10 分钟"
                    ),
                    FitnessAction(
                        name: "\(selectedCardioName) 主训练段",
                        targetMuscle: "心肺挑战",
                        tip: "进入主训练状态。",
                        emojiIcon: "⚡",
                        steps: ["提高强度", "保持输出", "动作稳定"],
                        baseReps: "\(max(20, minutes - 20)) 分钟"
                    ),
                    FitnessAction(
                        name: "\(selectedCardioName) 冷却段",
                        targetMuscle: "主动恢复",
                        tip: "慢慢收尾。",
                        emojiIcon: "🍃",
                        steps: ["降低强度", "恢复呼吸", "完成训练"],
                        baseReps: "10 分钟"
                    )
                ]
            }
        }
    }
    // 👑 终极强制平衡输出组合（✨ 重构：最强3D核心模块）
    private func getSmartBalancedPool(equip: Int, part: Int) -> [FitnessAction] {
        var pool: [FitnessAction] = []
        
        if part == 2 || part == 0 { // 下肢
            if equip == 2 {
                pool.append(FitnessAction(name: "倒蹬机 (Leg Press)", targetMuscle: "大腿前侧 (推)", tip: "顶端绝对不要锁死膝盖", emojiIcon: "🎢", steps: ["踩实踏板，慢下快推"], baseReps: "10 - 15 次"))
                pool.append(FitnessAction(name: "罗马椅挺身 / 腿弯举", targetMuscle: "大腿后侧 (拉)", tip: "感受大腿后侧拉扯力", emojiIcon: "🪑", steps: ["控制下放速度，臀腿发力拉起"], baseReps: "10 - 12 次"))
                pool.append(FitnessAction(name: "负重臀桥 / 髋推", targetMuscle: "臀大肌 (臀)", tip: "顶峰收缩夹紧屁股", emojiIcon: "🍑", steps: ["用杠铃或哑铃压在髋部，发力向上顶"], baseReps: "8 - 12 次"))
                pool.append(FitnessAction(name: "史密斯深蹲", targetMuscle: "臀腿综合", tip: "核心收紧，脚跟发力", emojiIcon: "🏋️", steps: ["背部挺直，下蹲至大腿平行地面"], baseReps: "8 - 10 次"))
            } else {
                pool.append(FitnessAction(name: "高脚杯深蹲", targetMuscle: "大腿前侧 (推)", tip: "保持挺胸，哑铃贴紧胸口", emojiIcon: "🍷", steps: ["手肘处于双膝之间下蹲"], baseReps: "10 - 15 次"))
                pool.append(FitnessAction(name: "哑铃罗马尼亚硬拉 (RDL)", targetMuscle: "大腿后侧 (拉)", tip: "背部绝对平直，臀部向后推", emojiIcon: "🚪", steps: ["哑铃贴着腿部滑下，感受后侧拉伸"], baseReps: "8 - 10 次"))
                pool.append(FitnessAction(name: "哑铃负重臀桥", targetMuscle: "臀大肌 (臀)", tip: "把哑铃放在小腹上方", emojiIcon: "🍑", steps: ["脚跟踩地，臀部发力向上顶"], baseReps: "12 - 15 次"))
                pool.append(FitnessAction(name: "交替箭步蹲", targetMuscle: "单侧臀腿", tip: "下蹲时前后腿呈90度", emojiIcon: "🚶‍♀️", steps: ["保持上身直立，重心在两腿中间"], baseReps: "每侧 10 次"))
            }
        } else if part == 1 { // 背部：垂直拉 + 水平拉 + 肩胛控制 + 后束补偿
            if equip == 2 {
                pool.append(FitnessAction(
                    name: "器械高位下拉",
                    targetMuscle: "背阔肌 (垂直拉)",
                    tip: "不要过度后仰，先沉肩，再把手肘向下拉",
                    emojiIcon: "🏗️",
                    steps: [
                        "坐稳并固定大腿，核心轻轻收紧",
                        "先想象肩膀远离耳朵，再开始下拉",
                        "把横杆拉向锁骨附近，控制还原"
                    ],
                    baseReps: "10 - 12 次"
                ))
                
                pool.append(FitnessAction(
                    name: "坐姿划船",
                    targetMuscle: "中背部 (水平拉)",
                    tip: "不是用手拉，是用肩胛骨向后收",
                    emojiIcon: "🚣",
                    steps: [
                        "挺胸坐稳，脊柱保持中立",
                        "先轻轻后收肩胛，再带动手肘往后",
                        "停顿 1 秒，慢慢放回"
                    ],
                    baseReps: "10 - 12 次"
                ))
                
                pool.append(FitnessAction(
                    name: "墙天使 / 墙滑",
                    targetMuscle: "肩胛上旋控制",
                    tip: "腰不要乱拱，重点不是抬高，而是贴墙滑动",
                    emojiIcon: "🪽",
                    steps: [
                        "背靠墙站立，后脑勺、上背尽量贴墙",
                        "手臂摆成 W 形，慢慢向上滑到 Y 形",
                        "全程保持肋骨别外翻，感受肩胛顺畅上旋"
                    ],
                    baseReps: "10 - 12 次"
                ))
                
                pool.append(FitnessAction(
                    name: "器械反向飞鸟",
                    targetMuscle: "肩后束 / 姿态补偿",
                    tip: "动作不用太重，重点是打开胸口、稳定肩胛",
                    emojiIcon: "🦋",
                    steps: [
                        "双手握住把手，肩膀下沉",
                        "手臂微屈，向两侧打开",
                        "顶端停顿 1 秒，再慢慢回位"
                    ],
                    baseReps: "15 - 20 次"
                ))
                
            } else {
                pool.append(FitnessAction(
                    name: "弹力带高位下拉",
                    targetMuscle: "背阔肌 (垂直拉)",
                    tip: "先沉肩再下拉，不要耸肩硬拽",
                    emojiIcon: "⚡",
                    steps: [
                        "把弹力带固定在高点",
                        "先让肩膀远离耳朵，再把手肘向下带",
                        "拉到胸口附近后慢慢还原"
                    ],
                    baseReps: "12 - 15 次"
                ))
                
                pool.append(FitnessAction(
                    name: "哑铃俯身划船",
                    targetMuscle: "中背部 (水平拉)",
                    tip: "背部必须平直，手肘朝髋部方向拉",
                    emojiIcon: "🚣",
                    steps: [
                        "臀部后推，上身前倾，核心收紧",
                        "哑铃向小腹两侧拉回",
                        "停顿一下，控制下放"
                    ],
                    baseReps: "10 - 12 次"
                ))
                
                pool.append(FitnessAction(
                    name: "Y-T-W 肩胛唤醒",
                    targetMuscle: "肩胛控制 / 下斜方肌",
                    tip: "动作小一点没关系，重点是控制感，不是甩手",
                    emojiIcon: "🪶",
                    steps: [
                        "俯身或趴姿，手臂依次做 Y、T、W 三个姿势",
                        "每次抬起时想象肩胛向下向后稳定",
                        "全程脖子放松，不要耸肩抢力"
                    ],
                    baseReps: "每种 8 - 10 次"
                ))
                
                pool.append(FitnessAction(
                    name: "弹力带面拉",
                    targetMuscle: "肩后束 / 姿态补偿",
                    tip: "拉向脸部，肘部打开，像摆出一个 W",
                    emojiIcon: "😎",
                    steps: [
                        "弹力带固定在脸部高度",
                        "双手向面部方向拉开，肩胛后收",
                        "停顿 1 秒后慢慢还原"
                    ],
                    baseReps: "15 - 20 次"
                ))
            }
        } else { // ✨✨✨ 全新重构：核心四大稳定支柱 ✨✨✨
            if equip == 2 || equip == 1 { // 有阻力设备 (哑铃/弹力带/健身房)
                pool.append(FitnessAction(name: "死虫子 (Deadbug)", targetMuscle: "抗伸展 / 骨盆控制", tip: "最重要的一点：下背部必须死死钉在地面上！", emojiIcon: "🪲", steps: ["仰卧，双手伸直指天，双腿屈膝90度抬起", "下背部用力压实地面，不能留缝隙", "呼气，同时缓慢伸直对侧手脚（绝不碰地），吸气收回"], baseReps: "每侧 10 - 12 次"))
                pool.append(FitnessAction(name: "帕洛夫推 (Pallof Press)", targetMuscle: "抗旋转", tip: "抵抗阻力不要让身体转动", emojiIcon: "🛡️", steps: ["侧对绳索或弹力带站立，双手将把手拉至胸前", "核心死死收紧抵抗侧向拉力，双手缓慢向前推直", "停顿1秒后，控制身体不转动地收回"], baseReps: "每侧 12 - 15 次"))
                pool.append(FitnessAction(name: "侧支撑 (Side Plank)", targetMuscle: "抗侧屈 / 腹斜肌", tip: "把地面推开，身体像一块钢板", emojiIcon: "📐", steps: ["手肘在肩膀正下方撑地，双腿伸直并拢", "发力将身体撑起，不要塌腰撅屁股", "保持呼吸均匀，感觉下侧腰部在收紧发力"], baseReps: "每侧 30 - 45 秒"))
                pool.append(FitnessAction(name: "中空静力支撑 (Hollow Hold)", targetMuscle: "深层抗伸展", tip: "下背必须压实地面！如果腰酸就把腿抬高一点", emojiIcon: "🥣", steps: ["仰卧，腰部死死压平地面", "双手双脚伸直，并同时微微抬离地面", "保持腹部收紧颤抖，绝不憋气"], baseReps: "30 - 45 秒"))
            } else { // 纯徒手
                pool.append(FitnessAction(name: "死虫子 (Deadbug)", targetMuscle: "抗伸展 / 骨盆控制", tip: "最重要的一点：下背部必须死死钉在地面上！", emojiIcon: "🪲", steps: ["仰卧，双手伸直指天，双腿屈膝90度抬起", "下背部用力压实地面，不能留缝隙", "呼气，同时缓慢伸直对侧手脚（绝不碰地），吸气收回"], baseReps: "每侧 10 - 12 次"))
                pool.append(FitnessAction(name: "鸟狗式 (Bird Dog)", targetMuscle: "多裂肌 / 抗旋转", tip: "想象背上放着一杯水，绝对不能洒", emojiIcon: "🐕", steps: ["四足跪姿在垫子上，保持脊柱中立（不塌腰）", "对侧的手脚向前后【延伸】（注意是前后延伸，不是一味往高抬）", "收紧核心保持身体绝对平稳，不要左摇右晃"], baseReps: "每侧 10 - 12 次"))
                pool.append(FitnessAction(name: "侧支撑 (Side Plank)", targetMuscle: "抗侧屈 / 腹斜肌", tip: "把地面推开，身体像一块钢板", emojiIcon: "📐", steps: ["手肘在肩膀正下方撑地，双腿伸直并拢", "发力将身体撑起，不要塌腰撅屁股", "保持呼吸均匀，感觉下侧腰部在收紧发力"], baseReps: "每侧 30 - 45 秒"))
                pool.append(FitnessAction(name: "中空静力支撑 (Hollow Hold)", targetMuscle: "深层抗伸展", tip: "下背必须压实地面！如果腰酸就把腿抬高一点", emojiIcon: "🥣", steps: ["仰卧，腰部死死压平地面", "双手双脚伸直，并同时微微抬离地面", "保持腹部收紧颤抖，绝不憋气"], baseReps: "30 - 45 秒"))
            }
        }
        
        return pool
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
