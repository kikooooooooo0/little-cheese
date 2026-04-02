import SwiftUI

// MARK: - ✨ 专属动作数据模型 (升级了图解字段)
struct FitnessAction: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let targetMuscle: String // 目标发力点
    let tip: String          // 注意事项
    let emojiIcon: String    // 视觉引导图标
    let steps: [String]      // 动作步骤分解
}

struct FitnessCoachView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var strengthMinutes: Double = 20
    @State private var cardioMinutes: Double = 20
    
    @State private var selectedEquip: Int = 0
    @State private var selectedPart: Int = 0
    @State private var selectedCardio: Int = 1
    
    @State private var generatedRoutine: [FitnessAction] = []
    @State private var isGenerating: Bool = false
    
    // ✨ 新增：当前选中的动作，用于弹出详情弹窗
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
                    Text("总计 \(totalMinutes) 分钟，自由搭配你的多巴胺配方")
                        .font(.subheadline).foregroundColor(.lcTextSecondary)
                }
                .padding(.top, 20)
                
                // 2. 时间分配拉杆
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
                
                // 3. 智能点单详情
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
                        Text(totalMinutes == 0 ? "请先拉动时间条 ⏱️" : (generatedRoutine.isEmpty ? "抽取今日训练处方" : "换一套动作试试"))
                    }
                    .font(.headline).foregroundColor(.white).frame(maxWidth: .infinity).padding()
                    .background(totalMinutes == 0 ? Color.gray.opacity(0.5) : (isGenerating ? Color.lcSoftBlue : Color.lcAccentBlue))
                    .cornerRadius(20)
                }
                .disabled(totalMinutes == 0)
                
                // 5. 生成结果展示区
                if !generatedRoutine.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("👇 你的专属动作指导：")
                                .font(.headline).foregroundColor(.lcTextSecondary)
                            Spacer()
                            Text("点击卡片查看图解").font(.caption).foregroundColor(.lcAccentBlue)
                        }
                        
                        VStack(spacing: 16) {
                            ForEach(generatedRoutine) { action in
                                // ✨ 让卡片变成可以点击的按钮
                                Button {
                                    selectedActionDetail = action
                                } label: {
                                    actionCard(for: action)
                                }
                                .buttonStyle(.plain)
                            }
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
        // ✨ 绑定弹窗：只要 selectedActionDetail 有值，就会从底部滑出详情页
        .sheet(item: $selectedActionDetail) { action in
            ActionDetailSheet(action: action)
        }
    }
    
    // MARK: - UI 子组件：起司动作卡片
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
            
            if !action.targetMuscle.isEmpty {
                HStack {
                    Text("🎯 发力点：\(action.targetMuscle)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.lcText)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.lcCheeseYellow.opacity(0.4)).cornerRadius(8)
                }
            }
        }
        .padding(16).background(RoundedRectangle(cornerRadius: 20).fill(Color.lcCardBackground))
        .shadow(color: .black.opacity(0.02), radius: 5, y: 2)
    }
    
    private func generateRoutine() {
        withAnimation(.spring()) { isGenerating = true }
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            var newRoutine: [FitnessAction] = []
            
            if strengthMinutes > 0 {
                let actionCount = strengthMinutes <= 15 ? 2 : (strengthMinutes <= 30 ? 3 : 5)
                let pool = getActionPool(equip: selectedEquip, part: selectedPart)
                let shuffledPool = pool.shuffled()
                
                for i in 0..<min(actionCount, shuffledPool.count) {
                    let action = shuffledPool[i]
                    let actionWithName = FitnessAction(
                        name: "\(action.name) (3组×12次)",
                        targetMuscle: action.targetMuscle,
                        tip: action.tip,
                        emojiIcon: action.emojiIcon,
                        steps: action.steps
                    )
                    newRoutine.append(actionWithName)
                }
            }
            
            if cardioMinutes > 0 {
                let cardioName = cardioTypes[selectedCardio].components(separatedBy: " ").last ?? ""
                newRoutine.append(FitnessAction(
                    name: "去 \(cardioName) 挥洒 \(Int(cardioMinutes)) 分钟汗水！",
                    targetMuscle: "心肺系统 / 全身燃脂",
                    tip: "注意呼吸节奏，保持心率在燃脂区间（微喘但能断续说话的程度）。",
                    emojiIcon: "💦",
                    steps: ["先用慢速热身 3 分钟", "保持稳定配速，感受身体微微出汗", "最后 3 分钟慢慢降速，平复心率"]
                ))
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                generatedRoutine = newRoutine
                isGenerating = false
            }
        }
    }
    
    // MARK: - 🧠 超级动作库（加入了拆解步骤）
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
                    FitnessAction(name: "徒手深蹲", targetMuscle: "臀腿综合", tip: "膝盖切忌内扣！脚尖与膝盖方向一致。", emojiIcon: "🪑", steps: ["双脚打开与肩同宽，脚尖微向外", "吸气，臀部向后坐下，就像找一把隐形的椅子", "大腿与地面平行后，呼气蹬地起身"]),
                    FitnessAction(name: "静态臀桥", targetMuscle: "臀大肌", tip: "用臀部发力顶起，不要用腰椎往上顶。", emojiIcon: "🌉", steps: ["仰卧，双腿屈膝脚掌踩地", "呼气，夹紧屁股将骨盆顶起，身体呈一条直线", "在最高点停顿并持续夹紧臀部"])
                ])
            }
            if part == 3 || part == 0 {
                pool.append(contentsOf: [
                    FitnessAction(name: "死虫子 (Deadbug)", targetMuscle: "深层核心", tip: "下背部必须死死贴住地面！", emojiIcon: "🪲", steps: ["仰卧，双手伸直指天，双腿屈膝90度抬起", "下背部用力压死地面，不要留缝隙", "呼气，同时伸直左手和右腿（不触地），吸气还原，交替进行"]),
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

// MARK: - ✨ 全新组件：从底部弹出的“动作详解放大镜”
struct ActionDetailSheet: View {
    let action: FitnessAction
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. 占位图解（以后有了真图可以替换这里）
                    ZStack {
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.lcCheeseYellow.opacity(0.2))
                            .frame(height: 200)
                        
                        // 💡 提示：如果你以后有自己的动图或图片，把下面这行注释打开并填上图片名
                        // Image("你的图片名字").resizable().scaledToFit()
                        
                        // 目前使用大号 Emoji 作为视觉引导
                        Text(action.emojiIcon)
                            .font(.system(size: 100))
                            .shadow(color: .black.opacity(0.1), radius: 10, y: 10)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    // 2. 核心避坑指南
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.orange)
                            Text("起司私教避坑指南").font(.headline).foregroundColor(.lcText)
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
                    
                    // 3. 步骤拆解（Notion 风格）
                    VStack(alignment: .leading, spacing: 16) {
                        Text("动作拆解：").font(.headline).foregroundColor(.lcText)
                        
                        ForEach(0..<action.steps.count, id: \.self) { index in
                            HStack(alignment: .top, spacing: 16) {
                                // 步骤序号
                                ZStack {
                                    Circle().fill(Color.lcAccentBlue).frame(width: 28, height: 28)
                                    Text("\(index + 1)").font(.caption.bold()).foregroundColor(.white)
                                }
                                // 步骤文字
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
                .padding(.bottom, 40)
            }
            .background(Color.lcBackground.ignoresSafeArea())
            .navigationTitle(action.name.components(separatedBy: "(").first ?? action.name) // 只显示动作名，去掉组数
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        // 允许半屏拖动（如果支持的 iOS 版本够高的话）
        .presentationDetents([.fraction(0.8), .large])
    }
}
