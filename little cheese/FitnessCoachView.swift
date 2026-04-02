import SwiftUI

// MARK: - ✨ 动作数据模型（新增独立计量单位 baseReps）
struct FitnessAction: Identifiable, Hashable {
    let id = UUID()
    var name: String
    let targetMuscle: String
    let tip: String
    let emojiIcon: String
    let steps: [String]
    var activeRest: String? = nil
    var baseReps: String = "" // ✨ 比如："8-12次", "40-60秒"
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
    let parts = ["🎲 帮我决定", "🦋 挺拔背部", "🍑 力量下肢", "🍫 核心收紧"]
    let cardioTypes = ["🧗‍♀️ 爬楼机", "🛸 椭圆机", "🏃‍♀️ 跑步机", "🏊‍♀️ 游泳", "🚴 动感单车", "🚶 散步"]

    var totalMinutes: Int { Int(strengthMinutes + cardioMinutes) }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // 1. 顶部标题
                VStack(spacing: 8) {
                    Text("智能运动引擎 🧠").font(.largeTitle.bold()).foregroundColor(.lcText)
                    Text("精准动作容量：告别无脑 3x12")
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
    
    // MARK: - ✨ UI 子组件：升级版卡片 (精准展示次数)
    private func actionCard(for action: FitnessAction) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                Text(action.emojiIcon).font(.title3)
                VStack(alignment: .leading, spacing: 4) {
                    Text(action.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(action.name.contains("汗水") ? .lcAccentBlue : .lcText)
                    
                    // ✨ 把每组的精准次数单独高亮出来，不挤在名字里
                    if !action.baseReps.isEmpty {
                        Text(action.baseReps)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.lcAccentBlue)
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
    
    // MARK: - 🧠 核心：智能平衡引擎
    private func generateRoutine() {
        withAnimation(.spring()) { isGenerating = true }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            var newPhases: [WorkoutPhase] = []
            
            // 💡 智能计算主训练组数
            let targetSets = strengthMinutes >= 40 ? 4 : (strengthMinutes >= 20 ? 3 : 2)
            
            // ---- PART 1: 热身 ----
            var warmupActions: [FitnessAction] = []
            let wPool = getSmartWarmupPool(part: selectedPart)
            for i in 0..<min(2, wPool.count) {
                if totalMinutes <= 20 && i == 1 { break }
                var action = wPool[i]
                action.baseReps = "1 组 × \(action.baseReps)" // 热身通常只做1组
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
                    // ✨ 魔法拼接：目标组数 + 动作专属的训练容量
                    action.baseReps = "\(targetSets) 组 × \(action.baseReps)"
                    action.activeRest = restPool[i % restPool.count]
                    mainActions.append(action)
                }
                newPhases.append(WorkoutPhase(title: "Part 2 💪 核心容量", subtitle: "动作已做肌群平衡处理", actions: mainActions))
            }
            
            // ---- PART 2.5: 有氧冲击 ----
            if cardioMinutes > 0 {
                let cardioName = cardioTypes[selectedCardio].components(separatedBy: " ").last ?? ""
                let cardioAction = FitnessAction(
                    name: "去 \(cardioName) 挥洒汗水！",
                    targetMuscle: "心肺燃脂", tip: "保持微喘但能说话的心率", emojiIcon: "💦",
                    steps: ["慢速热身 3 分钟", "保持稳定配速", "最后 3 分钟慢慢降速"],
                    baseReps: "\(Int(cardioMinutes)) 分钟" // 有氧专属单位
                )
                newPhases.append(WorkoutPhase(title: "Part 2.5 🏃‍♀️ 燃脂心肺", subtitle: "榨干最后的脂肪", actions: [cardioAction]))
            }
            
            // ---- PART 3: 放松 ----
            var cooldownActions: [FitnessAction] = []
            let cPool = getSmartCooldownPool(part: selectedPart)
            for i in 0..<min(2, cPool.count) {
                if totalMinutes <= 30 && i == 1 { break }
                var action = cPool[i]
                action.baseReps = "1 组 × \(action.baseReps)" // 放松拉伸只做1组
                cooldownActions.append(action)
            }
            newPhases.append(WorkoutPhase(title: "Part 3 🧘‍♀️ 靶向拉伸", subtitle: "哪里酸痛拉哪里", actions: cooldownActions))
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                generatedPhases = newPhases
                isGenerating = false
            }
        }
    }
    
    // MARK: - 🧠 引擎数据层 (每个动作都配上了最科学的次数)
    private func getSmartWarmupPool(part: Int) -> [FitnessAction] {
        if part == 2 {
            return [
                FitnessAction(name: "动态臀桥唤醒", targetMuscle: "臀大肌", tip: "不要用腰顶，屁股夹紧发力", emojiIcon: "🌉", steps: ["仰卧屈膝，脚跟踩地", "快速顶起臀部，慢速放下"], baseReps: "15 次"),
                FitnessAction(name: "世界最伟大拉伸", targetMuscle: "髋关节活动度", tip: "动作一定要慢，感受髋部被打开", emojiIcon: "🌍", steps: ["弓步迈出，同侧手肘尽量触地", "随后同侧手臂向天花板展开扭转胸椎"], baseReps: "每侧 5 次")
            ].shuffled()
        } else {
            return [
                FitnessAction(name: "猫牛式脊柱活动", targetMuscle: "脊柱与核心", tip: "动作缓慢，配合呼吸", emojiIcon: "🐈", steps: ["四足跪姿，吸气塌腰，呼气拱背"], baseReps: "10 次"),
                FitnessAction(name: "肩部环绕大风车", targetMuscle: "肩关节", tip: "幅度尽量大", emojiIcon: "🚁", steps: ["双手伸直画大圈，前后各10圈"], baseReps: "每侧 10 圈")
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
                FitnessAction(name: "全身大字形放松", targetMuscle: "全身神经", tip: "闭上眼睛，什么都不想", emojiIcon: "🧘‍♂️", steps: ["平躺在垫子上，手脚自然分开"], baseReps: "1 分钟")
            ].shuffled()
        }
    }
    
    private func getActiveRestPool() -> [String] {
        return ["腿下击掌 20 次", "靠墙静蹲休息 30 秒", "站立抱膝走 10 步", "慢速高抬腿 20 次", "深呼吸，喝两口水！", "核心收紧站立 20 秒"]
    }
    
    // 👑 终极强制平衡输出组合（精准次数版）
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
        } else if part == 1 { // 背部
            if equip == 2 {
                pool.append(FitnessAction(name: "器械高位下拉", targetMuscle: "背阔肌 (垂直拉)", tip: "不要过度后仰，拉向锁骨", emojiIcon: "🏗️", steps: ["大腿卡紧，背部发力带动手臂"], baseReps: "10 - 12 次"))
                pool.append(FitnessAction(name: "坐姿划船", targetMuscle: "中背部 (水平拉)", tip: "肩胛骨向后收缩夹紧", emojiIcon: "🚣", steps: ["挺胸收腹，手肘贴着肋骨向后拉"], baseReps: "10 - 12 次"))
                pool.append(FitnessAction(name: "器械反向飞鸟", targetMuscle: "肩后束", tip: "改善圆肩驼背神器", emojiIcon: "🦋", steps: ["手臂微屈，向后发力打开"], baseReps: "15 - 20 次"))
            } else {
                pool.append(FitnessAction(name: "弹力带高位下拉", targetMuscle: "背阔肌 (垂直拉)", tip: "找个高点固定弹力带", emojiIcon: "⚡", steps: ["跪姿或站姿，将弹力带拉向胸口"], baseReps: "12 - 15 次"))
                pool.append(FitnessAction(name: "哑铃俯身划船", targetMuscle: "中背部 (水平拉)", tip: "背部必须平直", emojiIcon: "🚣", steps: ["臀部后推，上身前倾，哑铃拉向小腹"], baseReps: "10 - 12 次"))
                pool.append(FitnessAction(name: "弹力带面拉", targetMuscle: "肩后束", tip: "拉向脸部，手臂呈W型", emojiIcon: "😎", steps: ["高度与头齐平，向后挤压肩胛骨"], baseReps: "15 - 20 次"))
            }
        } else { // 核心
            pool.append(FitnessAction(name: "平板支撑", targetMuscle: "整体核心", tip: "切忌塌腰", emojiIcon: "🪵", steps: ["收紧肚子，身体绷直像木板"], baseReps: "40 - 60 秒"))
            pool.append(FitnessAction(name: "死虫子 (Deadbug)", targetMuscle: "深层核心", tip: "下背部必须死死贴住地面", emojiIcon: "🪲", steps: ["对侧手脚伸展，不碰地面"], baseReps: "每侧 10 次"))
            pool.append(FitnessAction(name: "负重俄罗斯挺身", targetMuscle: "腹外斜肌", tip: "转动胸椎而不是手臂", emojiIcon: "🌪️", steps: ["身体后倾45度，左右扭转"], baseReps: "每侧 12 次"))
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
            .navigationTitle(action.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { dismiss() } } }
        }
        .presentationDetents([.fraction(0.8), .large])
    }
}
