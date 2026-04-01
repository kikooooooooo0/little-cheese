import SwiftUI

struct FitnessCoachView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) var dismiss
    
    // 选项状态
    @State private var selectedEquip: Int = 0
    @State private var selectedPart: Int = 0
    
    // 生成的动作列表
    @State private var generatedRoutine: [String] = []
    @State private var isGenerating: Bool = false
    
    // 数据源配置
    let equips = ["🛋️ 宿舍徒手", "🎒 哑铃+弹力带", "🏢 健身房"]
    let parts = ["🎲 帮我决定", "🦋 挺拔背部", "🍑 力量下肢", "🍫 核心收紧"]

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // 顶部标题
                VStack(spacing: 8) {
                    Text("今日多巴胺配方 🧀")
                        .font(.largeTitle.bold())
                        .foregroundColor(.lcText)
                    Text("不用动脑，选好装备，剩下的交给我")
                        .font(.subheadline)
                        .foregroundColor(.lcTextSecondary)
                }
                .padding(.top, 20)
                
                // 装备与部位选择卡片
                VStack(spacing: 24) {
                    // 1. 选装备
                    VStack(alignment: .leading, spacing: 12) {
                        Text("当前可用装备？").font(.headline).foregroundColor(.lcText)
                        Picker("装备", selection: $selectedEquip) {
                            ForEach(0..<equips.count, id: \.self) { i in
                                Text(equips[i]).tag(i)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // 2. 选部位
                    VStack(alignment: .leading, spacing: 12) {
                        Text("今天想唤醒哪里？").font(.headline).foregroundColor(.lcText)
                        Picker("部位", selection: $selectedPart) {
                            ForEach(0..<parts.count, id: \.self) { i in
                                Text(parts[i]).tag(i)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
                .shadow(color: .black.opacity(0.02), radius: 10, y: 5)
                
                // 生成按钮
                Button {
                    generateRoutine()
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text(generatedRoutine.isEmpty ? "抽取今日训练动作" : "换一组动作")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isGenerating ? Color.lcSoftBlue : Color.lcAccentBlue)
                    .cornerRadius(20)
                }
                
                // 生成结果区
                if !generatedRoutine.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("你的专属动作库：")
                            .font(.headline)
                            .foregroundColor(.lcTextSecondary)
                        
                        VStack(spacing: 12) {
                            ForEach(generatedRoutine, id: \.self) { action in
                                HStack {
                                    Circle().fill(Color.lcCheeseYellow).frame(width: 8, height: 8)
                                    Text(action)
                                        .font(.system(.body, design: .rounded))
                                        .foregroundColor(.lcText)
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
                            Text("✅ 我做完啦！记录身体档案")
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
            }
            .padding(24)
        }
        .background(Color.lcBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - 核心脑暴逻辑：动作生成库
    private func generateRoutine() {
        withAnimation(.spring()) { isGenerating = true }
        
        // 模拟一点点“思考”的延迟，增加盲盒开奖的期待感
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            var newRoutine: [String] = []
            
            // 简单的交叉组合逻辑 (ADHD 友好：每次 3-4 个动作，不要太长)
            if selectedEquip == 0 { // 徒手
                if selectedPart == 1 { newRoutine = ["猫牛式活动脊柱 10次", "超人飞 / 两头起 15次", "毛巾高位下拉 15次", "婴儿式放松 30秒"] }
                else if selectedPart == 2 { newRoutine = ["徒手深蹲 15次", "交替弓步蹲 每侧10次", "臀桥 15次", "大腿前侧拉伸"] }
                else if selectedPart == 3 { newRoutine = ["死虫子 16次", "平板支撑 40秒", "俄罗斯挺身 20次"] }
                else { newRoutine = ["开合跳 30次", "徒手深蹲 15次", "平板支撑 30秒", "原地高抬腿 30秒"] } // 默认全身
            }
            else if selectedEquip == 1 { // 哑铃/弹力带
                if selectedPart == 1 { newRoutine = ["弹力带面拉 15次", "哑铃俯身划船 12次", "弹力带直臂下压 15次"] }
                else if selectedPart == 2 { newRoutine = ["高脚杯深蹲 12次", "哑铃罗马尼亚硬拉 12次", "弹力带侧步走 20步"] }
                else if selectedPart == 3 { newRoutine = ["负重俄罗斯挺身 20次", "哑铃农夫行走 1分钟", "仰卧卷腹 15次"] }
                else { newRoutine = ["哑铃复合深蹲推举 10次", "弹力带划船 15次", "哑铃箭步蹲 10次"] }
            }
            else { // 健身房
                if selectedPart == 1 { newRoutine = ["器械高位下拉 10次", "坐姿划船 12次", "直臂下压 15次", "器械反向飞鸟 12次"] }
                else if selectedPart == 2 { newRoutine = ["杠铃/史密斯深蹲 10次", "倒蹬机 12次", "坐姿腿屈伸 15次"] }
                else if selectedPart == 3 { newRoutine = ["悬垂举腿 12次", "绳索卷腹 15次", "健腹轮 10次"] }
                else { newRoutine = ["椭圆机热身 5分钟", "器械胸推 12次", "器械高位下拉 12次", "腿举 12次"] }
            }
            
            withAnimation(.spring()) {
                generatedRoutine = newRoutine
                isGenerating = false
            }
        }
    }
    
    // MARK: - 自动联动：写入身体记录
    private func finishAndRecord() {
        let todayStr = AppState.df.string(from: Date())
        
        // 生成一句可爱的记录文案，比如 "3.12 健身房 - 挺拔背部"
        let equipName = equips[selectedEquip].components(separatedBy: " ").last ?? ""
        let partName = parts[selectedPart].components(separatedBy: " ").last ?? ""
        let recordText = "\(todayStr.suffix(5)) \(equipName) - \(partName)"
        
        // 1. 自动写入今天 Todo 任务（给你划掉的快感）
        state.addTodayTask(title: "完成了训练：\(recordText)")
        
        // 2. 自动更新身体档案 (WeightRecord)
        if let idx = state.weightRecords.firstIndex(where: { AppState.df.string(from: $0.date) == todayStr }) {
            state.weightRecords[idx].exerciseDescription = recordText
        } else {
            // 如果今天还没建档，就帮用户建一个
            let lastWeight = state.weightRecords.last?.weight ?? 0.0 // 拿上次体重兜底
            let newRecord = WeightRecord(date: Date(), weight: lastWeight, didPoop: false, exerciseDescription: recordText)
            state.weightRecords.append(newRecord)
        }
        
        // 3. 震动反馈
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        
        // 4. 收起页面
        dismiss()
    }
}
