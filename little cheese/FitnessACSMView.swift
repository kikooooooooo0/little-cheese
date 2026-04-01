import SwiftUI

struct FitnessACSMView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) var dismiss
    
    // 输入项
    @State private var bodyFat: Double = 25.0
    @State private var muscleLevel: Int = 1
    @State private var targetGoal: Int = 0
    
    // UI 状态
    @State private var isAnalyzing: Bool = false
    @State private var showResult: Bool = false
    
    // 选项数据源
    let muscleTypes = ["☁️ 像云朵一样软绵绵", "🍞 像吐司一样刚刚好", "🧱 像法棍一样邦邦硬"]
    let goals = [
        ("🏃‍♀️", "轻盈燃脂", "甩掉多余负担，让身体轻快起飞"),
        ("🧘‍♀️", "紧致塑形", "不追求暴瘦，想要肉肉更紧实好看"),
        ("🏋️", "力量爆发", "想要充满底气，变身强壮的小起司")
    ]
    
    // 🧠 核心：ACSM 简化版算法（转化为起司配方）
    var recipe: (cardio: Int, strength: Int, advice: String) {
        if targetGoal == 0 { // 燃脂
            if bodyFat > 28 {
                return (4, 1, "ACSM 建议：当前首要任务是提高心肺并消耗热量。多做有氧，力量训练作为辅助维持肌肉不流失即可。")
            } else {
                return (3, 2, "ACSM 建议：你已经做得很棒了！保持有氧消耗的同时，增加一点力量训练能让你瘦得更好看。")
            }
        } else if targetGoal == 1 { // 塑形
            return (2, 3, "ACSM 建议：塑形的核心是『长肌肉』。把重心放在力量训练上，有氧用来保持心肺健康就好啦。")
        } else { // 力量
            return (1, 4, "ACSM 建议：大胆举铁吧！减少长时间的有氧以免影响肌肉合成，充分刺激肌肉并吃够蛋白质！")
        }
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 30) {
                // 1. 顶部标题
                VStack(spacing: 8) {
                    Text("ACSM 身体雷达站 📡")
                        .font(.largeTitle.bold())
                        .foregroundColor(.lcText)
                    Text("不要焦虑数字，只需告诉我你的起点和想要到达的远方")
                        .font(.subheadline)
                        .foregroundColor(.lcTextSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 20)
                
                // 2. 身体现状输入区
                VStack(spacing: 24) {
                    // 体脂率滑动条
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("预估体脂率").font(.headline).foregroundColor(.lcText)
                            Spacer()
                            Text("\(Int(bodyFat))%").font(.title3.bold()).foregroundColor(.lcAccentBlue)
                        }
                        Slider(value: $bodyFat, in: 10...40, step: 1)
                            .tint(.lcAccentBlue)
                        HStack {
                            Text("精瘦").font(.caption).foregroundColor(.lcTextSecondary)
                            Spacer()
                            Text("丰满").font(.caption).foregroundColor(.lcTextSecondary)
                        }
                    }
                    
                    Divider().opacity(0.3)
                    
                    // 肌肉含量选择
                    VStack(alignment: .leading, spacing: 12) {
                        Text("摸摸肚子和胳膊，肌肉含量感觉是？").font(.headline).foregroundColor(.lcText)
                        Picker("肌肉含量", selection: $muscleLevel) {
                            ForEach(0..<muscleTypes.count, id: \.self) { i in
                                Text(muscleTypes[i]).tag(i)
                            }
                        }
                        .pickerStyle(.menu) // 节省空间，下拉选择
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.lcBackground)
                        .cornerRadius(12)
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
                .shadow(color: .black.opacity(0.02), radius: 10, y: 5)
                
                // 3. 目标选择区 (大卡片)
                VStack(alignment: .leading, spacing: 16) {
                    Text("你想获得什么超能力？").font(.headline).foregroundColor(.lcText).padding(.horizontal, 4)
                    
                    ForEach(0..<goals.count, id: \.self) { i in
                        Button {
                            withAnimation(.spring()) { targetGoal = i }
                        } label: {
                            HStack(spacing: 16) {
                                Text(goals[i].0).font(.system(size: 32))
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(goals[i].1).font(.headline).foregroundColor(targetGoal == i ? .lcText : .lcTextSecondary)
                                    Text(goals[i].2).font(.caption).foregroundColor(.lcTextSecondary).lineLimit(2)
                                }
                                Spacer()
                                if targetGoal == i {
                                    Image(systemName: "checkmark.circle.fill").foregroundColor(.lcCheeseYellow).font(.title2)
                                }
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 20).fill(targetGoal == i ? Color.lcCheeseYellow.opacity(0.15) : Color.lcCardBackground))
                            .overlay(RoundedRectangle(cornerRadius: 20).stroke(targetGoal == i ? Color.lcCheeseYellow : Color.clear, lineWidth: 2))
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // 4. 生成配方按钮
                Button {
                    generateRecipe()
                } label: {
                    HStack {
                        Image(systemName: "sparkles")
                        Text(isAnalyzing ? "正在呼叫 ACSM 智库..." : "生成我的专属起司配方")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.lcAccentBlue)
                    .cornerRadius(20)
                    .shadow(color: Color.lcAccentBlue.opacity(0.3), radius: 10, y: 5)
                }
                
                // 5. 结果展示区
                if showResult {
                    VStack(spacing: 20) {
                        Text("🎉 你的本周理想配方 🎉")
                            .font(.title3.bold())
                            .foregroundColor(.lcText)
                        
                        HStack(spacing: 15) {
                            // 有氧模块
                            VStack(spacing: 8) {
                                Text("🏃‍♀️ 有氧起司").font(.subheadline).foregroundColor(.lcTextSecondary)
                                Text("\(recipe.cardio) 天").font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(.lcSoftBlue)
                            }
                            .frame(maxWidth: .infinity).padding().background(Color.lcBackground).cornerRadius(16)
                            
                            Text("+").font(.title).foregroundColor(.lcTextSecondary)
                            
                            // 无氧模块
                            VStack(spacing: 8) {
                                Text("🏋️ 力量起司").font(.subheadline).foregroundColor(.lcTextSecondary)
                                Text("\(recipe.strength) 天").font(.system(size: 28, weight: .black, design: .rounded)).foregroundColor(.lcGreen)
                            }
                            .frame(maxWidth: .infinity).padding().background(Color.lcBackground).cornerRadius(16)
                        }
                        
                        // ACSM 科学建议
                        Text(recipe.advice)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.lcTextSecondary)
                            .padding()
                            .background(Color.lcSoftBlue.opacity(0.1))
                            .cornerRadius(12)
                            
                        // 承上启下的联动按钮
                        Button {
                            dismiss()
                        } label: {
                            Text("收下配方！去【起司数字私教】开练")
                                .font(.headline)
                                .foregroundColor(.lcAccentBlue)
                        }
                        .padding(.top, 8)
                    }
                    .padding(24)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
                    .shadow(color: .lcCheeseYellow.opacity(0.2), radius: 15, y: 5)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                Spacer().frame(height: 40)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.lcBackground.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func generateRecipe() {
        showResult = false
        withAnimation { isAnalyzing = true }
        
        #if os(iOS)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        #endif
        
        // 模拟分析的期待感
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnalyzing = false
                showResult = true
                #if os(iOS)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            }
        }
    }
}
