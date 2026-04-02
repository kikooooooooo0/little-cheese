import SwiftUI

// MARK: - ✨ 专属动作数据模型 (新增了间隙动作属性)
struct FitnessAction: Identifiable, Hashable {
    let id = UUID()
    var name: String         // 动作名 (加 var 是为了动态拼上几组几次)
    let targetMuscle: String // 目标发力点
    let tip: String          // 注意事项
    let emojiIcon: String    // 视觉引导图标
    let steps: [String]      // 动作步骤分解
    var activeRest: String? = nil // ✨ 间隙动作（超级组）
}

// ✨ 训练阶段模型：用来划分 Part 1, Part 2, Part 3
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
    
    // ✨ 现在的生成结果是一个“分阶段”的列表
    @State private var generatedPhases: [WorkoutPhase] = []
    @State private var isGenerating: Bool = false
    @State private var selectedActionDetail: FitnessAction?
    
    let equips = ["🛋️ 宿舍徒手", "🎒 哑铃弹力带", "🏢 健身房"]
    let parts = ["🎲 帮我决定", "🦋 挺拔背部", "🍑 力量下肢", "🍫 核心收紧"]
    let cardioTypes = ["🧗‍♀️ 爬楼机", "🛸 椭圆机", "🏃‍♀️ 跑步机", "🏊‍♀️ 游泳", "🚴 动感单车", "🚶 散步"]

    var totalMinutes: Int { Int(strengthMinutes + cardioMinutes) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // 1. 顶部标题
                VStack(spacing: 8) {
                    Text("今日运动点单台 🧀").font(.largeTitle.bold()).foregroundColor(.lcText)
                    Text("总计 \(totalMinutes) 分钟，自动为你编排热身、训练与放松")
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
                Button {
                    generateRoutine()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text(totalMinutes == 0 ? "请先拉动时间条 ⏱️" : (generatedPhases.isEmpty ? "生成三段式训练处方" : "重抽一套动作"))
                    }
                    .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding()
                    .background(totalMinutes == 0 ? Color.gray.opacity(0.5) : (isGenerating ? Color.lcSoftBlue : Color.lcAccentBlue))
                    .cornerRadius(20)
                }
                .disabled(totalMinutes == 0)
                
                // 5. ✨ 三段式剧本展示区
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
                                // 阶段标题
                                HStack {
                                    Text(phase.title).font(.title3.bold()).foregroundColor(.lcText)
                                    Spacer()
                                    Text(phase.subtitle).font(.caption).foregroundColor(.lcTextSecondary)
                                }
                                .padding(.bottom, 4)
                                
                                // 阶段动作列表
                                ForEach(phase.actions) { action in
                                    Button {
                                        selectedActionDetail = action
                                    } label: {
                                        actionCard(for: action)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.bottom, 12)
                        }
                        
                        // 完成打卡按钮
                        Button {
                            finishAndRecord()
                        } label: {
                            Text("✅ 做完啦！一键记录到日记")
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
            ActionDetailSheet(action: action)
        }
    }
    
    // MARK: - UI 子组件：升级版起司动作卡片 (带间隙显示)
    private func actionCard(for action: FitnessAction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(action.emojiIcon).font(.title3)
                Text(action.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(action.name.contains("汗水") ? .lcAccentBlue : .lcText)
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundColor(.lcSoftBlue.opacity(0.5))
            }
            
            HStack(spacing: 8) {
                if !action.targetMuscle.isEmpty {
                    Text("🎯 练：\(action.targetMuscle)")
                        .font(.system(size: 11, weight: .bold)).foregroundColor(.lcText)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color.lcCheeseYellow.opacity(0.4)).cornerRadius(6)
                }
            }
            
            // ✨ 如果有间隙动作，特别高亮显示（防止无聊玩手机）
            if let activeRest = action.activeRest {
                HStack(spacing: 6) {
                    Text("🔄 间隙休息：").font(.system(size: 12, weight: .bold)).foregroundColor(.lcAccentBlue)
                    Text(activeRest).font(.system(size: 12, design: .rounded)).foregroundColor(.lcAccentBlue)
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.lcAccentBlue.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [4])))
            }
        }
        .padding(16).background(RoundedRectangle(cornerRadius: 20).fill(Color.lcCardBackground))
        .shadow(color: .black.opacity(0.02), radius: 5, y: 2)
    }
    
    // MARK: - ✨ 核心大脑：生成三段式剧本
    private func generateRoutine() {
        withAnimation(.spring()) { isGenerating = true }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            var newPhases: [WorkoutPhase] = []
            
            // 💡 智能组数计算：根据你选的时间，时间长就 4-5 组，时间短就 2 组
            let targetSets = strengthMinutes >= 40 ? 4 : (strengthMinutes >= 20 ? 3 : 2)
            
            // ---- PART 1: 动态热身 ----
            var warmupActions: [FitnessAction] = []
            let wPool = getWarmupPool().shuffled()
            warmupActions.append(wPool[0])
            if totalMinutes > 20 { warmupActions.append(wPool[1]) } // 时间长就多热身一个
            newPhases.append(WorkoutPhase(title: "Part 1 🔥 唤醒热身", subtitle: "唤醒关节，防止受伤", actions: warmupActions))
            
            // ---- PART 2: 力量训练 (带间隙超级组) ----
            if strengthMinutes > 0 {
                var mainActions: [FitnessAction] = []
                let actionCount = strengthMinutes <= 15 ? 2 : (strengthMinutes <= 30 ? 3 : 4)
                let mPool = getActionPool(equip: selectedEquip, part: selectedPart).shuffled()
                let restPool = getActiveRestPool().shuffled()
                
                for i in 0..<min(actionCount, mPool.count) {
                    var action = mPool[i]
                    // 拼上智能计算的组数
                    action.name = "\(action.name) (\(targetSets)组×12次)"
                    // 随机塞入一个间隙动作
                    action.activeRest = restPool[i % restPool.count]
                    mainActions.append(action)
                }
                newPhases.append(WorkoutPhase(title: "Part 2 💪 核心训练", subtitle: "间隙不要看手机哦", actions: mainActions))
            }
            
            // ---- PART 2.5: 有氧冲击 ----
            if cardioMinutes > 0 {
                let cardioName = cardioTypes[selectedCardio].components(separatedBy: " ").last ?? ""
                let cardioAction = FitnessAction(
                    name: "去 \(cardioName) 挥洒 \(Int(cardioMinutes)) 分钟汗水！",
                    targetMuscle: "心肺燃脂",
                    tip: "注意呼吸节奏，保持心率在燃脂区间（微喘但能断续说话的程度）。",
                    emojiIcon: "💦",
                    steps: ["先用慢速热身 3 分钟", "保持稳定配速，感受身体微微出汗", "最后 3 分钟慢慢降速，平复心率"]
                )
                newPhases.append(WorkoutPhase(title: "Part 2.5 🏃‍♀️ 燃脂心肺", subtitle: "榨干最后的脂肪", actions: [cardioAction]))
            }
            
            // ---- PART 3: 静态放松 ----
            var cooldownActions: [FitnessAction] = []
            let cPool = getCooldownPool().shuffled()
            cooldownActions.append(cPool[0])
            if totalMinutes > 30 { cooldownActions.append(cPool[1]) }
            newPhases.append(WorkoutPhase(title: "Part 3 🧘‍♀️ 拉伸放松", subtitle: "排出乳酸，第二天不酸痛", actions: cooldownActions))
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                generatedPhases = newPhases
                isGenerating = false
            }
        }
    }
    
    // MARK: - 🧠 动作基础库
    private func getWarmupPool() -> [FitnessAction] {
        return [
            FitnessAction(name: "原地小跑振臂 (1分钟)", targetMuscle: "全身唤醒", tip: "轻微出汗即可", emojiIcon: "🏃", steps: ["原地轻松小跑", "双手配合在胸前交叉振臂"]),
            FitnessAction(name: "开合跳 (30次)", targetMuscle: "心肺激活", tip: "落地时膝盖微屈缓冲", emojiIcon: "🤸", steps: ["双脚并拢站立", "跳起时双脚分开，双手举过头顶拍手", "再次跳起还原"]),
            FitnessAction(name: "猫牛式脊柱活动 (10次)", targetMuscle: "脊柱与核心", tip: "动作一定要慢，配合呼吸", emojiIcon: "🐈", steps: ["四足跪姿在瑜伽垫上", "吸气塌腰抬头，呼气拱背低头"]),
            FitnessAction(name: "肩部环绕大风车 (每侧10圈)", targetMuscle: "肩关节", tip: "幅度尽量大，感受肩胛骨的运动", emojiIcon: "🚁", steps: ["双手伸直画大圈", "向前10圈，向后10圈"])
        ]
    }
    
    private func getCooldownPool() -> [FitnessAction] {
        return [
            FitnessAction(name: "大腿前侧拉伸 (每侧30秒)", targetMuscle: "股四头肌", tip: "保持身体直立，不要塌腰", emojiIcon: "🦩", steps: ["单腿站立，手抓住另一只脚的脚踝", "将脚跟拉向臀部，感受大腿前侧拉伸"]),
            FitnessAction(name: "婴儿式背部放松 (1分钟)", targetMuscle: "下背部", tip: "尽情感受呼吸，放松全身", emojiIcon: "👶", steps: ["双膝跪地，臀部坐在脚跟上", "上半身向前趴在地上，双手向前伸展"]),
            FitnessAction(name: "胸部拉伸 (每侧30秒)", targetMuscle: "胸大肌", tip: "肩膀下沉，不要耸肩", emojiIcon: "🚪", steps: ["找一面墙或门框，单手小臂贴住墙", "身体向反方向扭转，感受胸部拉扯"]),
            FitnessAction(name: "鸽子式臀部拉伸 (每侧30秒)", targetMuscle: "臀大肌", tip: "如果膝盖痛就立刻停止或减小幅度", emojiIcon: "🕊️", steps: ["一条腿屈膝横放在身前", "另一条腿向后伸直，上半身慢慢趴下"])
        ]
    }
    
    // 专门给 ADHD 设计的“防玩手机”间隙动作池
    private func getActiveRestPool() -> [String] {
        return [
            "腿下击掌 20 次",
            "原地轻快小跑 30 秒",
            "靠墙静蹲休息 30 秒",
            "站立抱膝走 10 步",
            "慢速高抬腿 20 次",
            "深呼吸，喝两口水，不碰手机！",
            "原地扭胯放松 20 秒"
        ]
    }
    
    private func getActionPool(equip: Int, part: Int) -> [FitnessAction] {
        var pool: [FitnessAction] = []
        if equip == 0 { // 徒手
            if part == 1 || part == 0 {
                pool.append(contentsOf: [
                    FitnessAction(name: "超人飞", targetMuscle: "下背部", tip: "腹部贴紧地面，四肢同时抬起。", emojiIcon: "🦸", steps: ["趴在瑜伽垫上，双手双脚伸直", "呼气，同时抬起双手和双脚，感受下背部收紧", "在最高点停顿1秒，吸气慢慢放下"]),
                    FitnessAction(name: "毛巾高位下拉", targetMuscle: "背阔肌", tip: "双手向外扯紧毛巾，想象将毛巾拉断。", emojiIcon: "🧻", steps: ["双手抓紧毛巾两端，高举过头顶", "双手持续向外用力扯毛巾", "呼气，将毛巾下拉到锁骨位置，背部夹紧"])
                ])
            }
            if part == 2 || part == 0 {
                pool.append(contentsOf: [
                    FitnessAction(name: "徒手深蹲", targetMuscle: "臀腿综合", tip: "膝盖切忌内扣！脚尖与膝盖方向一致。", emojiIcon: "🪑", steps: ["双脚打开与肩同宽，脚尖微向外", "吸气，臀部向后坐下", "大腿与地面平行后，呼气蹬地起身"]),
                    FitnessAction(name: "静态臀桥", targetMuscle: "臀大肌", tip: "用臀部发力顶起，不要用腰椎往上顶。", emojiIcon: "🌉", steps: ["仰卧，双腿屈膝脚掌踩地", "呼气，夹紧屁股将骨盆顶起，身体呈一条直线", "在最高点停顿并持续夹紧臀部"])
                ])
            }
            if part == 3 || part == 0 {
                pool.append(contentsOf: [
                    FitnessAction(name: "死虫子", targetMuscle: "深层核心", tip: "下背部必须死死贴住地面！", emojiIcon: "🪲", steps: ["仰卧，双手伸直指天，双腿屈膝90度抬起", "下背部用力压死地面，不要留缝隙", "呼气，同时伸直左手和右腿（不触地），吸气还原，交替进行"]),
                    FitnessAction(name: "平板支撑", targetMuscle: "整体核心", tip: "收紧腹部和臀部，切忌塌腰！", emojiIcon: "🪵", steps: ["手肘撑地，双脚打开与肩同宽", "夹紧臀部，收紧肚子，身体绷直像一块木板", "保持正常呼吸，腰酸立刻停止"])
                ])
            }
        }
        else if equip == 1 { // 哑铃弹力带
            if part == 1 || part == 0 {
                pool.append(FitnessAction(name: "哑铃俯身划船", targetMuscle: "背阔肌", tip: "背部必须平直，哑铃拉向小腹。", emojiIcon: "🚣", steps: ["双脚微屈，臀部后推，上身前倾至接近平行地面", "背部挺直，双手持哑铃自然下垂", "呼气，手肘贴着身体，将哑铃拉向小腹，感受背部收缩"]))
            }
            if part == 2 || part == 0 {
                pool.append(FitnessAction(name: "罗马尼亚硬拉 (RDL)", targetMuscle: "大腿后侧 / 臀部", tip: "想象臀部向后关车门，哑铃贴着腿部上下。", emojiIcon: "🚪", steps: ["双手拿哑铃，双脚与肩同宽", "背部挺直，小腿不动，臀部使劲向后推", "哑铃顺着大腿滑到膝盖下方，感受大腿后侧强烈拉伸，然后臀部发力顶起"]))
            }
            if part == 3 || part == 0 {
                pool.append(FitnessAction(name: "负重俄罗斯挺身", targetMuscle: "腹外斜肌", tip: "目光跟随哑铃移动，转动的是胸椎。", emojiIcon: "🌪️", steps: ["坐在地上，双腿微微抬起，双手捧住一个哑铃", "身体后倾约45度，收紧核心", "呼气，转动肩膀将哑铃带向身体一侧，吸气回正"]))
            }
        }
        else { // 健身房
            if part == 1 || part == 0 {
                pool.append(FitnessAction(name: "器械高位下拉", targetMuscle: "背阔肌", tip: "不要过度后仰，不要用手臂生拉硬拽。", emojiIcon: "🏗️", steps: ["坐在器械上，大腿卡紧挡板，双手宽握把手", "挺胸，微微后仰", "呼气，手肘向下拉，将把手拉至锁骨位置，感受背阔肌收缩"]))
            }
            if part == 2 || part == 0 {
                pool.append(FitnessAction(name: "倒蹬机 (Leg Press)", targetMuscle: "大腿前侧", tip: "【绝对不要】在顶端完全锁死膝盖！", emojiIcon: "🎢", steps: ["背部贴紧靠垫，双脚放在踏板中间位置", "解开安全锁，吸气慢慢弯曲膝盖让踏板降下", "呼气，脚跟发力推起踏板，切记在膝盖伸直前停下（保留微屈），千万别锁死！"]))
            }
            if part == 3 || part == 0 {
                pool.append(FitnessAction(name: "悬垂举腿", targetMuscle: "下腹部", tip: "不要利用惯性甩腿，尽量卷起骨盆。", emojiIcon: "🐒", steps: ["双手正握单杠，身体自然悬垂，核心微收", "呼气，下腹部发力，带动骨盆和双腿向上卷起", "吸气，控制速度慢慢下放，不要让身体像钟摆一样晃动"]))
            }
        }
        return pool
    }
    
    private func finishAndRecord() {
        let todayStr = AppState.df.string(from: Date())
        var recordText = "运动了 \(totalMinutes) 分钟"
        if strengthMinutes > 0 && cardioMinutes > 0 {
            recordText = "\(equips[selectedEquip].components(separatedBy: " ").last ?? "")无氧 + \(cardioTypes[selectedCardio].components(separatedBy: " ").last ?? "")有氧"
        } else if strengthMinutes > 0 {
            recordText = "纯力量日：练\(parts[selectedPart].components(separatedBy: " ").last ?? "")"
        } else if cardioMinutes > 0 {
            recordText = "纯有氧日：\(cardioTypes[selectedCardio].components(separatedBy: " ").last ?? "")"
        }
        state.addTodayTask(title: "✅ 极爽多巴胺：\(recordText)")
        if let idx = state.weightRecords.firstIndex(where: { AppState.df.string(from: $0.date) == todayStr }) {
            state.weightRecords[idx].exerciseDescription = recordText
        } else {
            let lastWeight = state.weightRecords.last?.weight ?? 0.0
            state.weightRecords.append(WeightRecord(date: Date(), weight: lastWeight, didPoop: false, exerciseDescription: recordText))
        }
        dismiss()
    }
}

// MARK: - ✨ 弹窗动作详解放大镜 (保持不变，依旧好用)
struct ActionDetailSheet: View {
    let action: FitnessAction
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 24).fill(Color.lcCheeseYellow.opacity(0.2)).frame(height: 200)
                        Text(action.emojiIcon).font(.system(size: 100)).shadow(color: .black.opacity(0.1), radius: 10, y: 10)
                    }
                    .padding(.horizontal).padding(.top, 20)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                            Text("起司私教避坑指南").font(.headline).foregroundColor(.lcText)
                        }
                        Text(action.tip).font(.system(.body, design: .rounded)).foregroundColor(.lcTextSecondary).lineSpacing(4)
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.orange.opacity(0.1)).cornerRadius(16).padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("动作拆解：").font(.headline).foregroundColor(.lcText)
                        ForEach(0..<action.steps.count, id: \.self) { index in
                            HStack(alignment: .top, spacing: 16) {
                                ZStack {
                                    Circle().fill(Color.lcAccentBlue).frame(width: 28, height: 28)
                                    Text("\(index + 1)").font(.caption.bold()).foregroundColor(.white)
                                }
                                Text(action.steps[index]).font(.system(.body, design: .rounded)).foregroundColor(.lcTextSecondary).padding(.top, 4)
                                Spacer()
                            }
                        }
                    }
                    .padding().frame(maxWidth: .infinity, alignment: .leading).background(Color.lcCardBackground).cornerRadius(16).padding(.horizontal)
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
