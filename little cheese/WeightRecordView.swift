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
    @State private var selectedDinnerQuality: DinnerQuality = .okay
    @State private var isIndulgenceDay: Bool = false
    @State private var selectedSlimMode: SlimMode = .normal
    @State private var completedSlimItems: Set<String> = []
    
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
                    
                    // 1. 今日减肥陪伴卡片
                    todaySlimPlanCard
                        .padding(.top, 10)

                    // 1.5 本月轻盈报告入口
                    monthlySummaryEntry

                    // 2. 动力看板 (记录天数)
                    motivationHeader

                    // 3. 趋势图（记录 2 天以上显示）
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
                        
                        // 三餐与晚餐状态
                        VStack(alignment: .leading, spacing: 14) {
                            Text("三餐打卡").font(.subheadline.bold())
                            
                            HStack(spacing: 12) {
                                mealToggle(title: "早", isOn: $hadBreakfast, icon: "sun.and.horizon")
                                mealToggle(title: "午", isOn: $hadLunch, icon: "sun.max")
                                mealToggle(title: "晚", isOn: $hadDinner, icon: "moon.stars")
                            }
                            
                            if hadDinner {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("晚餐程度")
                                        .font(.caption.bold())
                                        .foregroundColor(secondaryTextColor)
                                    
                                    HStack(spacing: 10) {
                                        ForEach(DinnerQuality.allCases) { quality in
                                            Button {
                                                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                                    selectedDinnerQuality = quality
                                                }
                                                
                                                #if os(iOS)
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                #endif
                                            } label: {
                                                VStack(spacing: 5) {
                                                    Text(quality.emoji)
                                                        .font(.headline)
                                                    Text(quality.title)
                                                        .font(.system(size: 11, weight: .bold))
                                                        .lineLimit(1)
                                                }
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, 10)
                                                .background(selectedDinnerQuality == quality ? accent.opacity(0.22) : bgColor.opacity(0.45))
                                                .foregroundColor(selectedDinnerQuality == quality ? textColor : secondaryTextColor)
                                                .cornerRadius(15)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color.white.opacity(0.35))
                                .cornerRadius(18)
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
        .navigationTitle("今天变轻一点 🧀")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { hideKeyboard() }
    }
}

// MARK: - 辅助组件与逻辑
extension WeightRecordView {
    private var monthlySummaryEntry: some View {
        NavigationLink {
            MonthlySummaryView(state: state)
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.2), lineWidth: 6)
                        .frame(width: 48, height: 48)
                    
                    Circle()
                        .trim(from: 0, to: min(Double(state.weightRecords.count) / 30.0, 1.0))
                        .stroke(
                            accent,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 48, height: 48)
                    
                    Text("🧀")
                        .font(.title3)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("查看本月轻盈报告")
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    Text("运动、晚餐、守住三环总结")
                        .font(.caption)
                        .foregroundColor(secondaryTextColor)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundColor(secondaryTextColor)
            }
            .padding(18)
            .background(cardBg)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
    
    private var todaySlimPlanCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("今天不用完美")
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .foregroundColor(textColor)
                
                Text("选一个状态，Little Cheese 陪你把今天往变轻的方向推一点点。")
                    .font(.subheadline)
                    .foregroundColor(secondaryTextColor)
                    .lineSpacing(3)
            }
            
            HStack(spacing: 10) {
                ForEach(SlimMode.allCases) { mode in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedSlimMode = mode
                            completedSlimItems.removeAll()
                        }
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        VStack(spacing: 6) {
                            Text(mode.emoji)
                                .font(.title3)
                            Text(mode.title)
                                .font(.system(size: 11, weight: .bold))
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedSlimMode == mode ? accent.opacity(0.25) : bgColor.opacity(0.6))
                        .foregroundColor(selectedSlimMode == mode ? textColor : secondaryTextColor)
                        .cornerRadius(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(selectedSlimMode.planTitle)
                        .font(.headline)
                        .foregroundColor(textColor)
                    
                    Spacer()
                    
                    Text("\(completedSlimItems.count)/\(selectedSlimMode.planItems.count)")
                        .font(.caption.bold())
                        .foregroundColor(secondaryTextColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(bgColor.opacity(0.55))
                        .cornerRadius(999)
                }
                
                ForEach(selectedSlimMode.planItems, id: \.self) { item in
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            if completedSlimItems.contains(item) {
                                completedSlimItems.remove(item)
                            } else {
                                completedSlimItems.insert(item)
                            }
                        }
                        
                        #if os(iOS)
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        #endif
                    } label: {
                        HStack(alignment: .center, spacing: 10) {
                            Image(systemName: completedSlimItems.contains(item) ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(completedSlimItems.contains(item) ? accent : secondaryTextColor)
                            
                            Text(item)
                                .font(.subheadline)
                                .foregroundColor(completedSlimItems.contains(item) ? secondaryTextColor : textColor)
                                .strikethrough(completedSlimItems.contains(item), color: secondaryTextColor)
                            
                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 10)
                        .background(completedSlimItems.contains(item) ? accent.opacity(0.10) : Color.white.opacity(0.25))
                        .cornerRadius(14)
                    }
                    .buttonStyle(.plain)
                }
                
                if completedSlimItems.count == selectedSlimMode.planItems.count {
                    Text("今天已经守住啦，小奶酪记你一功 🧀")
                        .font(.caption.bold())
                        .foregroundColor(textColor)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.45))
            .cornerRadius(20)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [
                    accent.opacity(0.22),
                    Color.pink.opacity(0.10),
                    cardBg
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 6)
    }
    
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
            Text("最近记录")
                .font(.headline)
                .foregroundColor(textColor)

            if state.weightRecords.isEmpty {
                Text("还没有记录，今天存第一颗小奶酪吧 🧀")
                    .font(.caption)
                    .foregroundColor(secondaryTextColor)
                    .frame(maxWidth: .infinity)
                    .frame(height: 100)
                    .background(cardBg)
                    .cornerRadius(15)
            } else {
                ForEach(state.weightRecords.sorted(by: { $0.date > $1.date })) { record in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(record.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundColor(secondaryTextColor)

                            Text("\(String(format: "%.1f", record.weight)) kg")
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundColor(textColor)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            if record.hadBreakfast {
                                Text("🍳")
                            }

                            if record.hadLunch {
                                Text("🍱")
                            }

                            if record.hadDinner {
                                Text(record.dinnerQuality?.emoji ?? "🍲")
                            }

                            Text(energyEmoji(for: record.energyLevel))

                            if record.didPoop {
                                Text("💩")
                            }
                        }
                    }
                    .padding()
                    .background(cardBg)
                    .cornerRadius(15)
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
                Image(systemName: icon)
                    .font(.system(size: 18))

                Text(title)
                    .font(.system(size: 12, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(isOn.wrappedValue ? accent.opacity(0.2) : bgColor.opacity(0.5))
            .foregroundColor(isOn.wrappedValue ? textColor : secondaryTextColor)
            .cornerRadius(15)
        }
        .buttonStyle(.plain)
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
            hadDinner: hadDinner,
            dinnerQuality: hadDinner ? selectedDinnerQuality : nil
        )

        withAnimation(.spring()) {
            state.weightRecords.append(newRecord)
        }

        weightText = ""
        didPoop = false
        energyLevel = 3.0
        exerciseDescription = ""
        hadBreakfast = false
        hadLunch = false
        hadDinner = false
        selectedDinnerQuality = .okay

        hideKeyboard()

        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }

    private func energyEmoji(for level: Double) -> String {
        switch Int(level) {
        case 1:
            return "😫"
        case 2:
            return "🥱"
        case 3:
            return "😐"
        case 4:
            return "🙂"
        case 5:
            return "🤩"
        default:
            return "😐"
        }
    }

    // MARK: - 减肥模式
    private enum SlimMode: String, CaseIterable, Identifiable {
        case tired
        case normal
        case serious

        var id: String { rawValue }

        var title: String {
            switch self {
            case .tired:
                return "很累，别逼我"
            case .normal:
                return "还行，正常来"
            case .serious:
                return "今天想认真一点"
            }
        }

        var emoji: String {
            switch self {
            case .tired:
                return "🥲"
            case .normal:
                return "😐"
            case .serious:
                return "🔥"
            }
        }

        var planTitle: String {
            switch self {
            case .tired:
                return "今天目标：不崩就赢"
            case .normal:
                return "今天目标：稳稳变轻"
            case .serious:
                return "今天目标：认真燃脂"
            }
        }

        var planItems: [String] {
            switch self {
            case .tired:
                return [
                    "喝一杯水",
                    "吃一份蛋白质",
                    "晚上不乱加餐",
                    "散步或拉伸 5 分钟就算赢"
                ]
            case .normal:
                return [
                    "三餐先吃蛋白质",
                    "不喝含糖饮料",
                    "走路或运动 10-15 分钟",
                    "晚上留一个安全零食"
                ]
            case .serious:
                return [
                    "每餐有蛋白质和蔬菜",
                    "主食减一点，不完全不吃",
                    "做 20-30 分钟运动",
                    "晚上 9 点后不吃高热量零食"
                ]
            }
        }
    }
}

// MARK: - 晚餐程度
enum DinnerQuality: String, CaseIterable, Identifiable, Codable {
    case light
    case okay
    case heavy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .light:
            return "轻盈"
        case .okay:
            return "正常"
        case .heavy:
            return "放纵"
        }
    }

    var emoji: String {
        switch self {
        case .light:
            return "🥗"
        case .okay:
            return "🍲"
        case .heavy:
            return "🍰"
        }
    }
}
