import SwiftUI

struct FitnessCoachView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) var dismiss
    
    // 🎚️ 核心时间控制器 (滑动条数据)
    @State private var strengthMinutes: Double = 20
    @State private var cardioMinutes: Double = 20
    
    // 菜单选项状态
    @State private var selectedEquip: Int = 0
    @State private var selectedPart: Int = 0
    @State private var selectedCardio: Int = 1
    
    // 动作生成库
    @State private var generatedRoutine: [String] = []
    @State private var isGenerating: Bool = false
    
    // 选项数据源
    let equips = ["🛋️ 宿舍徒手", "🎒 哑铃弹力带", "🏢 健身房"]
    let parts = ["🎲 帮我决定", "🦋 挺拔背部", "🍑 力量下肢", "🍫 核心收紧"]
    let cardioTypes = ["🧗‍♀️ 爬楼机", "🛸 椭圆机", "🏃‍♀️ 跑步机", "🏊‍♀️ 游泳", "🚴 动感单车", "🚶 散步"]

    var totalMinutes: Int {
        Int(strengthMinutes + cardioMinutes)
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // 1. 顶部标题
                VStack(spacing: 8) {
                    Text("今日运动点单台 🧀")
                        .font(.largeTitle.bold())
                        .foregroundColor(.lcText)
                    Text("总计 \(totalMinutes) 分钟，自由搭配你的多巴胺配方")
                        .font(.subheadline)
                        .foregroundColor(.lcTextSecondary)
                }
                .padding(.top, 20)
                
                // 2. 🎚️ 核心：顺滑的时间分配拉杆
                VStack(spacing: 24) {
                    // 力量训练拉杆
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("🏋️ 无氧 (力量)").font(.headline).foregroundColor(.lcText)
                            Spacer()
                            Text("\(Int(strengthMinutes)) 分钟").font(.title3.bold()).foregroundColor(.lcGreen)
                        }
                        Slider(value: $strengthMinutes, in: 0...90, step: 5)
                            .tint(.lcGreen)
                    }
                    
                    Divider().opacity(0.3)
                    
                    // 有氧训练拉杆
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("🏃‍♀️ 有氧 (心肺)").font(.headline).foregroundColor(.lcText)
                            Spacer()
                            Text("\(Int(cardioMinutes)) 分钟").font(.title3.bold()).foregroundColor(.lcSoftBlue)
                        }
                        Slider(value: $cardioMinutes, in: 0...90, step: 5)
                            .tint(.lcSoftBlue)
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
                .shadow(color: .black.opacity(0.02), radius: 10, y: 5)
                
                // 3. 🎯 智能浮现的点单详情
                if totalMinutes > 0 {
                    VStack(spacing: 24) {
                        // 如果有力量训练，就显示装备和部位
                        if strengthMinutes > 0 {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("力量训练设定：").font(.headline).foregroundColor(.lcTextSecondary)
                                
                                Picker("装备", selection: $selectedEquip) {
                                    ForEach(0..<equips.count, id: \.self) { i in Text(equips[i]).tag(i) }
                                }.pickerStyle(.segmented)
                                
                                Picker("部位", selection: $selectedPart) {
                                    ForEach(0..<parts.count, id: \.self) { i in Text(parts[i]).tag(i) }
                                }.pickerStyle(.segmented)
                            }
                        }
                        
                        // 如果既有力量又有氧，画条漂亮的分割线
                        if strengthMinutes > 0 && cardioMinutes > 0 {
                            Divider().opacity(0.3)
                        }
                        
                        // 如果有有氧训练，就显示有氧项目
                        if cardioMinutes > 0 {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("有氧项目选择：").font(.headline).foregroundColor(.lcTextSecondary)
                                
                                // 用横向滚动让选项显得不那么拥挤
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(0..<cardioTypes.count, id: \.self) { i in
                                            Button {
                                                withAnimation(.spring()) { selectedCardio = i }
                                            } label: {
                                                Text(cardioTypes[i])
                                                    .font(.system(.subheadline, design: .rounded))
                                                    .foregroundColor(selectedCardio == i ? .white : .lcText)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(RoundedRectangle(cornerRadius: 12).fill(selectedCardio == i ? Color.lcAccentBlue : Color.lcBackground))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
                    .shadow(color: .black.opacity(0.02), radius: 10, y: 5)
                    .transition(.opacity)
                }
                
                // 4. 生成按钮
                Button {
                    generateRoutine()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text(totalMinutes == 0 ? "请先拉动时间条 ⏱️" : (generatedRoutine.isEmpty ? "抽取今日训练处方" : "换一套动作试试"))
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(totalMinutes == 0 ? Color.gray.opacity(0.5) : (isGenerating ? Color.lcSoftBlue : Color.lcAccentBlue))
                    .cornerRadius(20)
                }
                .disabled(totalMinutes == 0)
                
                // 5. 生成结果展示区
                if !generatedRoutine.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("👇 你的专属剧本：")
                            .font(.headline)
                            .foregroundColor(.lcTextSecondary)
                        
                        VStack(spacing: 12) {
                            ForEach(generatedRoutine, id: \.self) { action in
                                HStack(alignment: .top) {
                                    Text(action.contains("挥洒") ? "🔥" : "🧀")
                                    Text(action)
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(action.contains("挥洒") ? .lcAccentBlue : .lcText)
                                    Spacer()
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.lcCardBackground))
                            }
                        }
                        
                        // 完成打卡按钮
                        Button {
                            finishAndRecord()
                        } label: {
                            Text("✅ 做完啦！一键记录到日记")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.lcGreen)
                                .cornerRadius(20)
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
    }
    
    // MARK: - 动态脑暴逻辑
    private func generateRoutine() {
        withAnimation(.spring()) { isGenerating = true }
        
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            var newRoutine: [String] = []
            
            // 如果有力量训练，根据时间的长短给出不同数量的动作
            if strengthMinutes > 0 {
                // 决定动作数量：时间越长，动作越多
                let actionCount = strengthMinutes <= 15 ? 2 : (strengthMinutes <= 30 ? 3 : 5)
                
                // 模拟动作库库
                var pool: [String] = []
                if selectedEquip == 0 { // 徒手
                    if selectedPart == 1 { pool = ["猫牛式活动脊柱", "超人飞两头起", "毛巾高位下拉", "婴儿式放松", "俯卧划船"] }
                    else if selectedPart == 2 { pool = ["徒手深蹲", "交替弓步蹲", "臀桥", "大腿前侧拉伸", "宽距相扑蹲"] }
                    else if selectedPart == 3 { pool = ["死虫子", "平板支撑", "俄罗斯挺身", "仰卧卷腹", "侧支撑"] }
                    else { pool = ["开合跳", "徒手深蹲", "平板支撑", "高抬腿", "波比跳退阶"] }
                }
                else if selectedEquip == 1 { // 哑铃/弹力带
                    if selectedPart == 1 { pool = ["弹力带面拉", "哑铃俯身划船", "弹力带直臂下压", "单臂哑铃划船", "弹力带飞鸟"] }
                    else if selectedPart == 2 { pool = ["高脚杯深蹲", "哑铃罗马尼亚硬拉", "弹力带侧步走", "哑铃保加利亚蹲", "负重臀桥"] }
                    else if selectedPart == 3 { pool = ["负重俄罗斯挺身", "哑铃农夫行走", "仰卧卷腹", "负重侧屈", "弹力带抗伸展"] }
                    else { pool = ["哑铃复合推举", "弹力带划船", "哑铃箭步蹲", "高脚杯深蹲", "弹力带弯举"] }
                }
                else { // 健身房
                    if selectedPart == 1 { pool = ["器械高位下拉", "坐姿划船", "直臂下压", "器械反向飞鸟", "引体向上辅助机"] }
                    else if selectedPart == 2 { pool = ["史密斯深蹲", "倒蹬机", "坐姿腿屈伸", "俯卧腿弯举", "哈克深蹲"] }
                    else if selectedPart == 3 { pool = ["悬垂举腿", "绳索卷腹", "健腹轮", "罗马椅挺身", "器械卷腹"] }
                    else { pool = ["器械胸推", "器械高位下拉", "腿举", "坐姿腿弯举", "推肩机"] }
                }
                
                // 随机抽取指定数量的动作（并加上建议组数）
                let shuffledPool = pool.shuffled()
                for i in 0..<min(actionCount, shuffledPool.count) {
                    newRoutine.append("\(shuffledPool[i])（建议 3 组 × 12 次）")
                }
            }
            
            // 💡 如果有有氧训练，直接加在最后作为重头戏！
            if cardioMinutes > 0 {
                let cardioName = cardioTypes[selectedCardio].components(separatedBy: " ").last ?? ""
                newRoutine.append("去👉 \(cardioName) 挥洒 \(Int(cardioMinutes)) 分钟汗水！")
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                generatedRoutine = newRoutine
                isGenerating = false
            }
        }
    }
    
    // MARK: - 自动联动：写入身体记录
    private func finishAndRecord() {
        let todayStr = AppState.df.string(from: Date())
        var recordText = "运动了 \(totalMinutes) 分钟"
        
        // 智能生成好看的摘要
        if strengthMinutes > 0 && cardioMinutes > 0 {
            let equipName = equips[selectedEquip].components(separatedBy: " ").last ?? ""
            let cardioName = cardioTypes[selectedCardio].components(separatedBy: " ").last ?? ""
            recordText = "\(equipName)无氧 + \(cardioName)有氧"
        } else if strengthMinutes > 0 {
            let partName = parts[selectedPart].components(separatedBy: " ").last ?? ""
            recordText = "纯力量日：练\(partName)"
        } else if cardioMinutes > 0 {
            let cardioName = cardioTypes[selectedCardio].components(separatedBy: " ").last ?? ""
            recordText = "纯有氧日：\(cardioName) \(Int(cardioMinutes))分钟"
        }
        
        // 1. 写进 Today
        state.addTodayTask(title: "✅ 极爽多巴胺：\(recordText)")
        
        // 2. 自动更新身体档案 (WeightRecord)
        if let idx = state.weightRecords.firstIndex(where: { AppState.df.string(from: $0.date) == todayStr }) {
            state.weightRecords[idx].exerciseDescription = recordText
        } else {
            let lastWeight = state.weightRecords.last?.weight ?? 0.0
            let newRecord = WeightRecord(date: Date(), weight: lastWeight, didPoop: false, exerciseDescription: recordText)
            state.weightRecords.append(newRecord)
        }
        
        // 3. 收起页面
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
        dismiss()
    }
}
