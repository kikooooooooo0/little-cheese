import SwiftUI
import Charts

struct WeightRecordView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var state: AppState // 接入大管家
    
    // MARK: - 状态管理
    @State private var weightText: String = ""
    @State private var selectedDate = Date()
    @State private var didPoop: Bool = false
    @State private var energyLevel: Double = 3.0
    @State private var exerciseDescription: String = ""
    @State private var hadBreakfast: Bool = false
    @State private var hadLunch: Bool = false
    @State private var hadDinner: Bool = false
    @State private var isIndulgenceDay: Bool = false
    
    // 配色方案
    private let accent = Color.lcYellow
    private let bgColor = Color.lcBackground
    private let cardBg = Color.lcCardBackground
    private let textColor = Color.lcText
    private let secondaryTextColor = Color.lcTextSecondary

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // 1. 动力看板 (记录天数)
                    motivationHeader
                        .padding(.top, 10)
                    
                    // 2. 趋势图（记录 2 天以上显示）
                    if state.weightRecords.count >= 2 {
                        trendSection
                            .transition(.opacity)
                    }
                    
                    // 3. 核心记录卡片
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text("今日状态").font(.headline).foregroundColor(textColor)
                            Spacer()
                            DatePicker("", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                                .labelsHidden()
                                .scaleEffect(0.9)
                        }
                        
                        // 体重与排便
                        HStack(spacing: 15) {
                            HStack {
                                TextField("0.0", text: $weightText)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .frame(width: 90)
                                Text("kg").font(.headline).foregroundColor(secondaryTextColor)
                            }
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(bgColor.opacity(0.5))
                            .cornerRadius(18)
                            
                            Button {
                                didPoop.toggle()
                                #if os(iOS)
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                #endif
                            } label: {
                                VStack(spacing: 4) {
                                    Text(didPoop ? "💩" : "💨")
                                        .font(.title2)
                                    Text("顺畅").font(.system(size: 10, weight: .bold))
                                }
                                .frame(width: 60, height: 60)
                                .background(didPoop ? Color.brown.opacity(0.2) : bgColor.opacity(0.5))
                                .foregroundColor(didPoop ? .brown : secondaryTextColor)
                                .cornerRadius(18)
                            }
                        }
                        
                        // 三餐打卡
                        VStack(alignment: .leading, spacing: 10) {
                            Text("三餐打卡").font(.subheadline.bold())
                            HStack(spacing: 12) {
                                mealToggle(title: "早", isOn: $hadBreakfast, icon: "sun.and.horizon")
                                mealToggle(title: "午", isOn: $hadLunch, icon: "sun.max")
                                mealToggle(title: "晚", isOn: $hadDinner, icon: "moon.stars")
                            }
                        }
                        
                        // 运动记录
                        VStack(alignment: .leading, spacing: 10) {
                            Text("今日运动").font(.subheadline.bold())
                            TextField("做了什么？(如: 散步 10min)", text: $exerciseDescription)
                                .font(.caption)
                                .padding()
                                .background(bgColor.opacity(0.5))
                                .cornerRadius(12)
                        }
                        
                        // 能量条
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("身体能量指数").font(.subheadline.bold())
                                Spacer()
                                Text(energyEmoji(for: energyLevel)).font(.title3)
                            }
                            Slider(value: $energyLevel, in: 1...5, step: 1)
                                .tint(accent)
                        }
                        
                        Button(action: saveRecord) {
                            Text("把这份爱存起来 🧀")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 15)
                                .background(weightText.isEmpty ? Color.gray.opacity(0.3) : accent)
                                .cornerRadius(20)
                                .shadow(color: accent.opacity(0.2), radius: 8, y: 4)
                        }
                        .disabled(weightText.isEmpty)
                    }
                    .padding(22)
                    .background(cardBg)
                    .cornerRadius(30)
                    .shadow(color: Color.black.opacity(0.03), radius: 15, x: 0, y: 5)
                    
                    // 4. 历史记录
                    historySection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("身体实验室 🧪")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { hideKeyboard() }
    }
}

// MARK: - 辅助组件与逻辑
extension WeightRecordView {
    
    private var motivationHeader: some View {
        HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text("你已经连续关爱自己")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(state.weightRecords.count)")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(accent)
                    Text("天").font(.headline).foregroundColor(textColor)
                }
            }
            Spacer()
            ZStack {
                Circle().stroke(accent.opacity(0.2), lineWidth: 8).frame(width: 60, height: 60)
                Text("🧀").font(.title)
            }
        }
        .padding(20).background(accent.opacity(0.1)).cornerRadius(25)
    }
    
    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("变化趋势").font(.headline).padding(.leading, 5)
            Chart {
                ForEach(state.weightRecords.suffix(7)) { record in
                    LineMark(
                        x: .value("日期", record.date),
                        y: .value("体重", record.weight)
                    )
                    .foregroundStyle(accent)
                    .interpolationMethod(.catmullRom)
                    
                    AreaMark(
                        x: .value("日期", record.date),
                        y: .value("体重", record.weight)
                    )
                    .foregroundStyle(LinearGradient(colors: [accent.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom))
                }
            }
            .frame(height: 150)
            .chartYScale(domain: (state.weightRecords.map { $0.weight }.min() ?? 40) - 2 ... (state.weightRecords.map { $0.weight }.max() ?? 100) + 2)
        }
        .padding(20).background(cardBg).cornerRadius(25)
    }

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("过往痕迹").font(.headline).padding(.leading, 5)
            if state.weightRecords.isEmpty {
                Text("还没有记录，从今天开始吧 ✨")
                    .font(.caption).foregroundColor(secondaryTextColor)
                    .frame(maxWidth: .infinity).frame(height: 100).background(cardBg).cornerRadius(15)
            } else {
                ForEach(state.weightRecords.sorted(by: { $0.date > $1.date })) { record in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading) {
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption).foregroundColor(secondaryTextColor)
                            Text("\(String(format: "%.1f", record.weight)) kg")
                                .font(.system(.body, design: .rounded).bold())
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            if record.hadBreakfast { Text("🍳") }
                            if record.hadLunch { Text("🍱") }
                            if record.hadDinner { Text("🍲") }
                        }
                        Text(energyEmoji(for: record.energyLevel))
                        if record.didPoop { Text("💩") }
                    }
                    .padding().background(cardBg).cornerRadius(15)
                }
            }
        }
    }
    
    private func mealToggle(title: String, isOn: Binding<Bool>, icon: String) -> some View {
        Button {
            isOn.wrappedValue.toggle()
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 18))
                Text(title).font(.system(size: 12, weight: .bold))
            }
            .frame(maxWidth: .infinity).padding(.vertical, 10)
            .background(isOn.wrappedValue ? accent.opacity(0.2) : bgColor.opacity(0.5))
            .foregroundColor(isOn.wrappedValue ? textColor : secondaryTextColor)
            .cornerRadius(15)
        }.buttonStyle(.plain)
    }

    private func saveRecord() {
        guard let w = Double(weightText) else { return }
        let newRecord = WeightRecord(
            date: selectedDate,
            weight: w,
            didPoop: didPoop,
            energyLevel: energyLevel,
            exerciseDescription: exerciseDescription,
            hadBreakfast: hadBreakfast,
            hadLunch: hadLunch,
            hadDinner: hadDinner
        )
        withAnimation(.spring()) {
            state.weightRecords.append(newRecord)
        }
        // 清空输入
        weightText = ""; didPoop = false; energyLevel = 3.0; exerciseDescription = ""
        hadBreakfast = false; hadLunch = false; hadDinner = false
        hideKeyboard()
        
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    private func energyEmoji(for level: Double) -> String {
        switch Int(level) {
            case 1: return "😫"; case 2: return "🥱"; case 3: return "😐"; case 4: return "🙂"; case 5: return "🤩"
            default: return "😐"
        }
    }
}
