import SwiftUI
import SwiftUI

// MARK: - 🧀 今日三餐计划缓存模型
struct TodayDietPlanMeals: Codable {
    var dateKey: String
    var planName: String
    var emoji: String
    var dayNumber: Int
    var breakfast: String
    var lunch: String
    var dinner: String
}

// MARK: - 🧀 今日计划三餐详情弹窗
struct TodayDietPlanMealDetail: Identifiable {
    var id: String { mealType }
    
    var mealType: String
    var mealText: String
    var planName: String
    var emoji: String
    var dayNumber: Int
}

// MARK: - Today View (终极稳固版)
struct TodayView: View {
    @ObservedObject var state: AppState
    
    @State private var viewMode: Int = 0
    @Namespace private var namespace
    @State private var isShowingPomodoroSheet: Bool = false
    @State private var isShowingTinyHabitSheet: Bool = false
    @State private var selectedDietPlanMeal: TodayDietPlanMealDetail? = nil
    @State private var customMealInput: String = "__HIDDEN__"
    @AppStorage("lc_todayLastOpenDateKey") private var lastOpenDateKey: String = ""
    @State private var didCheckDailyReset: Bool = false
    @State private var newTaskTitle: String = ""
    
    @State private var editingTinyHabit: TinyHabit?
    @State private var tinyTrigger: String = ""
    @State private var tinyAction: String = ""
    @State private var tinyTargetCount: Int = 1
    private var todayMealProgress: Int {
        var count = 0
        
        if latestMealRecord(for: "早餐") != nil {
            count += 1
        }
        
        if latestMealRecord(for: "午餐") != nil {
            count += 1
        }
        
        if latestMealRecord(for: "晚餐") != nil {
            count += 1
        }
        
        return count
    }
    // ✨ 新增：今日进度百分比（价值回声）
    private var todayProgressPercentage: Double {
        let totalTasks = Double(state.todayTasks.count)
        let doneTasks = Double(state.todayTasks.filter { $0.isDone }.count)
        
        let totalHabitGoals = Double(state.tinyHabits.reduce(0) { $0 + $1.targetCountPerDay })
        let doneHabitCounts = Double(state.tinyHabits.reduce(0) { $0 + $1.doneCountToday })
        
        let totalDenominator = totalTasks + totalHabitGoals
        let totalNumerator = doneTasks + doneHabitCounts
        
        return totalDenominator > 0 ? totalNumerator / totalDenominator : 0
    }
    
    // ✅ 安全的数据计算
    private var todayTimeUsage: [LifeAreaTimeUsage] {
        state.timeUsageFor(date: Date())
    }

    private var dateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f.string(from: Date())
    }
    // MARK: - 🧀 今日饮食联动数据
    @AppStorage("littleCheese.dietCheckinRecords") private var dietCheckinJSONString: String = "[]"

    // 🧀 从饮食计划页同步来的今日三餐计划
    @AppStorage("littleCheese.todayDietPlanMeals") private var todayDietPlanMealsJSONString: String = ""
    
    private var todayDateKey: String {
        makeDateKey(Date())
    }
    
    private var todayDietRecords: [DietCheckinRecord] {
        guard let data = dietCheckinJSONString.data(using: .utf8) else {
            return []
        }
        
        let allRecords = (try? JSONDecoder().decode([DietCheckinRecord].self, from: data)) ?? []
        return allRecords.filter { $0.dateKey == todayDateKey }
    }
    private var todayDietPlanMeals: TodayDietPlanMeals? {
        guard let data = todayDietPlanMealsJSONString.data(using: .utf8),
              let meals = try? JSONDecoder().decode(TodayDietPlanMeals.self, from: data),
              meals.dateKey == todayDateKey else {
            return nil
        }
        
        return meals
    }
    private var todayMealDoneCount: Int {
        let mealTypes = Set(todayDietRecords.map { $0.mealType })
        return ["早餐", "午餐", "晚餐"].filter { mealTypes.contains($0) }.count
    }
    
    private var completedMealCount: Int {
        var count = 0
        
        if latestMealRecord(for: "早餐") != nil {
            count += 1
        }
        
        if latestMealRecord(for: "午餐") != nil {
            count += 1
        }
        
        if latestMealRecord(for: "晚餐") != nil {
            count += 1
        }
        
        return count
    }
    
    private var todayMealProgressText: String {
        if todayMealDoneCount == 0 {
            return "今天还没开始补能量"
        } else if todayMealDoneCount < 3 {
            return "今日饮食 \(todayMealDoneCount)/3 已完成"
        } else {
            return "三餐稳稳接住啦"
        }
    }
    
    private func latestMealRecord(for mealType: String) -> DietCheckinRecord? {
        todayDietRecords
            .filter { $0.mealType == mealType }
            .sorted { $0.date > $1.date }
            .first
    }
    private func plannedMealText(for mealType: String) -> String? {
        guard let meals = todayDietPlanMeals else { return nil }
        
        let rawText: String
        switch mealType {
        case "早餐":
            rawText = meals.breakfast
        case "午餐":
            rawText = meals.lunch
        case "晚餐":
            rawText = meals.dinner
        default:
            return nil
        }
        
        return cleanMealDisplayText(rawText)
    }

    private func cleanMealDisplayText(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let range = trimmed.range(of: "：") {
            return String(trimmed[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if let range = trimmed.range(of: ":") {
            return String(trimmed[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return trimmed
    }

    private func plannedMealDetail(for mealType: String) -> TodayDietPlanMealDetail? {
        guard let meals = todayDietPlanMeals,
              let mealText = plannedMealText(for: mealType) else {
            return nil
        }
        
        return TodayDietPlanMealDetail(
            mealType: mealType,
            mealText: mealText,
            planName: meals.planName,
            emoji: meals.emoji,
            dayNumber: meals.dayNumber
        )
    }
    
    private func makeDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    private func syncTodayMealFlagsFromRecords() {
        if latestMealRecord(for: "早餐") != nil {
            state.isBreakfastDone = true
        }
        
        if latestMealRecord(for: "午餐") != nil {
            state.isLunchDone = true
        }
        
        if latestMealRecord(for: "晚餐") != nil {
            state.isDinnerDone = true
        }
    }
    private func completePlannedMeal(_ meal: TodayDietPlanMealDetail) {
        var records = loadDietCheckinRecordsForTodayView()
        let todayKey = makeDateKey(Date())
        
        let newRecord = DietCheckinRecord(
            dateKey: todayKey,
            date: Date(),
            mealType: meal.mealType,
            content: meal.mealText,
            imageFilename: nil,
            emoji: meal.emoji,
            sopName: "\(meal.planName) Day \(meal.dayNumber)：\(meal.mealText)"
        )
        
        // 🧀 如果已经选过，就替换，而不是不更新
        records.removeAll {
            $0.dateKey == todayKey &&
            $0.mealType == meal.mealType
        }
        
        records.append(newRecord)
        saveDietCheckinRecordsForTodayView(records)
        
        // MARK: - 🧀 真正更新 Today 首页显示内容
        if var meals = todayDietPlanMeals {
            
            switch meal.mealType {
            case "早餐":
                meals.breakfast = meal.mealText
                
            case "午餐":
                meals.lunch = meal.mealText
                
            case "晚餐":
                meals.dinner = meal.mealText
                
            default:
                break
            }
            
            // 保存回 AppStorage
            if let data = try? JSONEncoder().encode(meals),
               let jsonString = String(data: data, encoding: .utf8) {
                todayDietPlanMealsJSONString = jsonString
            }
        }
        
        // MARK: - 状态更新
        if meal.mealType == "早餐" {
            state.isBreakfastDone = true
        }
        
        if meal.mealType == "午餐" {
            state.isLunchDone = true
        }
        
        if meal.mealType == "晚餐" {
            state.isDinnerDone = true
        }
        
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        
        selectedDietPlanMeal = nil
    }

    private func loadDietCheckinRecordsForTodayView() -> [DietCheckinRecord] {
        guard let data = dietCheckinJSONString.data(using: .utf8) else {
            return []
        }
        
        return (try? JSONDecoder().decode([DietCheckinRecord].self, from: data)) ?? []
    }

    private func saveDietCheckinRecordsForTodayView(_ records: [DietCheckinRecord]) {
        guard let data = try? JSONEncoder().encode(records),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }
        
        dietCheckinJSONString = jsonString
    }
    // MARK: - 🧹 清理旧版饮食计划 Todo
    private func cleanLegacyDietTodoTasks() {
        let legacyTaskIDs = state.todayTasks
            .filter { task in
                let title = task.title
                
                // 旧版自动生成的饮食任务：例如
                // 🌙 7 天减脂法 Day 1：早餐：两个鸡蛋...
                // 🍴 饮食已完成：🌙 7 天减脂法...
                // 饮食打卡：🥚 短期轻断食
                return title.contains("饮食打卡：")
                    || title.contains("饮食已完成：")
                    || title.contains("7 天减脂法 Day")
                    || title.contains("7天减脂法 Day")
                    || title.contains("11 天交替计划 Day")
                    || title.contains("11天交替计划 Day")
                    || (
                        title.contains("Day")
                        && (
                            title.contains("早餐")
                            || title.contains("午餐")
                            || title.contains("晚餐")
                        )
                    )
            }
            .map { $0.id }
        
        for id in legacyTaskIDs {
            state.deleteTodayTask(id: id)
        }
    }
    var body: some View {
        NavigationStack {
            ZStack {
                Color.lcBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // 1. 顶部 Header
                    VStack(alignment: .leading, spacing: 16) {
                        Text(dateString)
                            .font(.system(size: 34, weight: .black, design: .rounded))
                            .foregroundColor(.lcText)
                        
                        // ✨ 今日状态面板
                        HStack(spacing: 0) {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle().stroke(Color.lcSoftBlue.opacity(0.3), lineWidth: 4).frame(width: 44, height: 44)
                                    Circle().trim(from: 0, to: todayProgressPercentage)
                                        .stroke(Color.lcCheeseYellow, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                        .frame(width: 44, height: 44)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.spring(), value: todayProgressPercentage)
                                    Text("\(Int(todayProgressPercentage * 100))%")
                                        .font(.system(size: 10, weight: .bold, design: .rounded)).foregroundColor(.lcText)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("未来贡献").font(.system(size: 12, weight: .bold, design: .rounded))
                                    Text(todayProgressPercentage >= 1.0 ? "全满啦！" : "喂养中...")
                                        .font(.system(size: 10)).foregroundColor(.lcTextSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Rectangle().fill(Color.lcTextSecondary.opacity(0.1)).frame(width: 1, height: 30).padding(.horizontal, 12)
                            
                            VStack(alignment: .trailing, spacing: 6) {
                                Text("当前状态").font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.lcTextSecondary).padding(.trailing, 4)
                                HStack(spacing: 5) {
                                    let moods = ["😶‍🌫️", "😶", "🤓", "😢", "🤔", "😃"]
                                    ForEach(moods, id: \.self) { emoji in
                                        Text(emoji).font(.system(size: 20)).frame(width: 32, height: 32)
                                            .background(ZStack {
                                                if state.todayMoodEmoji == emoji { Circle().fill(Color.lcCheeseYellow.opacity(0.3)) }
                                                else { Circle().fill(Color.lcBackground.opacity(0.5)) }
                                            })
                                            .onTapGesture {
                                                state.todayMoodEmoji = emoji
                                                state.syncTodayStatusToJournal(mood: emoji, progress: todayProgressPercentage)
                                                #if os(iOS)
                                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                #endif
                                            }
                                    }
                                }
                            }
                        }
                        .padding(.vertical, 12).padding(.horizontal, 16)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.lcCardBackground))
                        .shadow(color: .black.opacity(0.02), radius: 8, x: 0, y: 4)
                        
                        HStack(spacing: 24) {
                            modeButton(title: "今日", index: 0)
                            modeButton(title: "习惯", index: 1)
                            Spacer()
                        }
                    }
                    .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 12)
                    
                    // 2. 内容区
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 28) {
                            if viewMode == 0 {
                                VStack(spacing: 24) {
                                    // MARK: --- 🧀 强联动版：今日饮食 SOP 卡片 ---
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack(alignment: .center) {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("🍴 今日饮食 SOP")
                                                    .font(.system(.headline, design: .rounded))
                                                    .foregroundColor(.lcText)
                                                
                                                Text(todayMealProgressText)
                                                    .font(.caption)
                                                    .foregroundColor(.lcTextSecondary)
                                            }
                                            
                                            Spacer()
                                            
                                            ZStack {
                                                Circle()
                                                    .stroke(Color.lcSoftBlue.opacity(0.35), lineWidth: 5)
                                                    .frame(width: 42, height: 42)
                                                
                                                Circle()
                                                    .trim(from: 0, to: CGFloat(todayMealProgress))
                                                    .stroke(
                                                        Color.lcCheeseYellow,
                                                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                                    )
                                                    .frame(width: 42, height: 42)
                                                    .rotationEffect(.degrees(-90))
                                                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: todayMealProgress)
                                                
                                                Text("\(todayMealDoneCount)/3")
                                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                                    .foregroundColor(.lcText)
                                            }
                                            
                                            NavigationLink(destination: DietSOPView(state: state)) {
                                                Image(systemName: "plus.circle.fill")
                                                    .foregroundColor(.lcAccentBlue.opacity(0.75))
                                                    .font(.title3)
                                            }
                                            
                                            Text(getTodayChineseWeekday())
                                                .font(.system(size: 10, weight: .bold))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.lcYellow.opacity(0.2))
                                                .cornerRadius(8)
                                        }
                                        
                                        VStack(spacing: 10) {
                                            mealLinkRow(
                                                title: "早餐",
                                                fallback: todayDietPlanMeals?.breakfast ?? "去选一个低成本早餐",
                                                record: latestMealRecord(for: "早餐"),
                                                isDone: latestMealRecord(for: "早餐") != nil || state.isBreakfastDone
                                            )
                                            
                                            Divider().opacity(0.3)
                                            
                                            mealLinkRow(
                                                title: "午餐",
                                                fallback: todayDietPlanMeals?.lunch ?? "帮身体补一点蛋白质",
                                                record: latestMealRecord(for: "午餐"),
                                                isDone: latestMealRecord(for: "午餐") != nil || state.isLunchDone
                                            )
                                            
                                            Divider().opacity(0.3)
                                            
                                            mealLinkRow(
                                                title: "晚餐",
                                                fallback: todayDietPlanMeals?.dinner ?? "晚餐不用完美，稳住就好",
                                                record: latestMealRecord(for: "晚餐"),
                                                isDone: latestMealRecord(for: "晚餐") != nil || state.isDinnerDone
                                            )
                                        }
                                        
                                        if todayMealDoneCount > 0 {
                                            dietSummaryPill
                                        }
                                    }
                                    .padding(20)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24)
                                            .fill(Color.lcCardBackground)
                                    )
                                    journalSection
                                    
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("任务流").font(.system(.headline, design: .rounded)).foregroundColor(.lcText.opacity(0.7))
                                        VStack(spacing: 0) {
                                            if state.todayTasks.isEmpty {
                                                Text("点击下方添加任务...").font(.caption).foregroundColor(.secondary.opacity(0.5)).padding(.vertical)
                                            } else {
                                                ForEach(Array(state.todayTasks.enumerated()), id: \.element.id) { index, task in
                                                    TodayTaskTimelineRow(
                                                        task: task, isLast: index == state.todayTasks.count - 1,
                                                        onToggle: { state.toggleTodo(id: task.id) },
                                                        onDelete: { state.deleteTodayTask(id: task.id) },
                                                        onStartPomodoro: { state.pomodoroNote = "专注：\(task.title)"; isShowingPomodoroSheet = true }
                                                    )
                                                }
                                            }
                                            addTaskInput
                                        }
                                    }
                                }
                                .padding(.top, 12)
                            } else {
                                VStack(spacing: 24) {
                                    let totalMinutes = todayTimeUsage.reduce(0) { $0 + $1.minutes }
                                    if totalMinutes > 0 { todayEnergyCard(total: totalMinutes) }
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("习惯锚点").font(.system(.headline, design: .rounded)).foregroundColor(.lcText.opacity(0.7))
                                        habitSection
                                    }
                                }
                                .padding(.top, 12)
                            }
                            Spacer().frame(height: 100)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            checkDailyReset()
            syncTodayMealFlagsFromRecords()
            cleanLegacyDietTodoTasks()
        }
        .onChange(of: dietCheckinJSONString) {
            syncTodayMealFlagsFromRecords()
            cleanLegacyDietTodoTasks()
        }
        .sheet(isPresented: $isShowingPomodoroSheet) {
            NavigationStack {
                PomodoroView(state: state)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { isShowingPomodoroSheet = false } } }
            }
        }
        .sheet(isPresented: $isShowingTinyHabitSheet) {
            tinyHabitEditor
        }
        .sheet(item: $selectedDietPlanMeal) { meal in
            plannedMealDetailSheet(meal)
        }
    }

    
    // MARK: - 内部组件和工具函数 (取消了 Extension，更稳固)
    @ViewBuilder
    private func mealLinkRow(
        title: String,
        fallback: String,
        record: DietCheckinRecord?,
        isDone: Bool
    ) -> some View {
        let plannedDetail = plannedMealDetail(for: title)
        let plannedText = plannedDetail?.mealText
        
        let displayText = record == nil
            ? (plannedText ?? fallback)
            : "\(record?.emoji ?? "🧀") \(record?.sopName ?? "能量已补充")"
        
        let subtitleText: String = {
            if isDone {
                return "已完成，记到今天啦"
            }
            
            if let plannedDetail {
                return "\(plannedDetail.planName) · Day \(plannedDetail.dayNumber)"
            }
            
            return "点进去选择一个 SOP"
        }()
        
        if let plannedDetail {
            Button {
                selectedDietPlanMeal = plannedDetail
            } label: {
                mealRowContent(
                    title: title,
                    displayText: displayText,
                    subtitleText: subtitleText,
                    isDone: isDone
                )
            }
            .buttonStyle(.plain)
        } else {
            NavigationLink(destination: BodyRecordView(state: state)) {
                mealRowContent(
                    title: title,
                    displayText: displayText,
                    subtitleText: subtitleText,
                    isDone: isDone
                )
            }
            .buttonStyle(.plain)
        }
    }
    private func mealRowContent(
        title: String,
        displayText: String,
        subtitleText: String,
        isDone: Bool
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isDone ? Color.lcGreen.opacity(0.16) : Color.lcSoftBlue.opacity(0.45))
                    .frame(width: 38, height: 38)
                
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isDone ? .lcGreen : .lcAccentBlue.opacity(0.65))
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundColor(.secondary)
                
                Text(displayText)
                    .font(.system(.body, design: .rounded).bold())
                    .foregroundColor(isDone ? .lcText : .lcTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(subtitleText)
                    .font(.caption2)
                    .foregroundColor(.lcTextSecondary.opacity(0.75))
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(.lcTextSecondary.opacity(0.35))
        }
    }
    private func plannedMealDetailSheet(_ meal: TodayDietPlanMealDetail) -> some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(meal.mealType)计划")
                            .font(.title2.bold())
                            .foregroundColor(.lcText)
                        
                        Text("\(meal.emoji) \(meal.planName) · Day \(meal.dayNumber)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.lcTextSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("写下你实际吃了什么")
                            .font(.headline.weight(.bold))
                                .foregroundColor(.lcText)
                        
                        Text("不用完全照计划，今天能被记录下来，就已经很棒了。")
                            .font(.subheadline)
                            .foregroundColor(.lcTextSecondary)
                            .lineSpacing(3)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(Color.lcYellow.opacity(0.16))
                    )
                    
                    Button {
                        customMealInput = ""
                    } label: {
                        HStack(spacing: 14) {
                            
                            ZStack {
                                Circle()
                                    .fill(Color.lcYellow.opacity(0.18))
                                    .frame(width: 44, height: 44)
                                
                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(.lcYellow)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("自己输入")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.lcText)
                                
                                Text("今天实际吃了什么")
                                    .font(.caption)
                                    .foregroundColor(.lcTextSecondary)
                            }
                            
                            Spacer()
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.white.opacity(0.92))
                        )
                    }
                    .buttonStyle(.plain)

                    if customMealInput != "__HIDDEN__" {
                        
                        VStack(spacing: 14) {
                            
                            TextField(
                                "比如：麻辣烫 + 无糖豆浆",
                                text: $customMealInput,
                                axis: .vertical
                            )
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                            )
                            
                            Button {
                                let input = customMealInput.trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                guard !input.isEmpty else { return }
                                
                                let completedMeal = TodayDietPlanMealDetail(
                                    mealType: meal.mealType,
                                    mealText: input,
                                    planName: meal.planName,
                                    emoji: meal.emoji,
                                    dayNumber: meal.dayNumber
                                )
                                
                                completePlannedMeal(completedMeal)
                                
                                customMealInput = "__HIDDEN__"
                            } label: {
                                Text("记到今天")
                                    .font(.headline.weight(.bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color.lcGreen)
                                    )
                            }
                        }
                        .padding(.top, 10)
                    }
                   
                    
                    Button {
                        customMealInput = meal.mealText
                    } label: {
                        Label("用原计划填入", systemImage: "wand.and.stars")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.lcAccentBlue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 18)
                                    .fill(Color.lcSoftBlue.opacity(0.32))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(22)
            }
            .background(Color.lcBackground.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        customMealInput = ""
                        selectedDietPlanMeal = nil
                    }
                }
            }
        }
    }
    private func mealOptions(from text: String) -> [String] {
        let separators = CharacterSet(charactersIn: "/／、，,")
        
        let options = text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        return options.isEmpty ? [text] : options
    }
    private var dietSummaryPill: some View {
        HStack(spacing: 8) {
            Image(systemName: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundColor(.lcCheeseYellow)
            
            Text(todayMealDoneCount >= 3 ? "今天的饮食闭环完成啦" : "已经完成 \(todayMealDoneCount) 餐，不用完美也在前进")
                .font(.caption.weight(.semibold))
                .foregroundColor(.lcTextSecondary)
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.lcYellow.opacity(0.16))
        )
    }
    
    private func getTodayChineseWeekday() -> String {
        let date = Date()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date).replacingOccurrences(of: "星期", with: "周")
    }

    private var journalSection: some View {
        let todayDS = AppState.df.string(from: Date())
        let journal = state.journalEntries.first(where: { $0.dateString == todayDS })
        return NavigationLink(destination: JournalDetailView(state: state, entry: journal)) {
            HStack(spacing: 16) {
                Circle().fill(Color.lcCheeseYellow.opacity(0.1)).frame(width: 54, height: 54)
                    .overlay(Image(systemName: "quote.bubble.fill").foregroundColor(.lcCheeseYellow))
                VStack(alignment: .leading, spacing: 4) {
                    Text(journal?.oneLine ?? "捕捉这一刻的心情...").font(.system(.subheadline, design: .rounded).bold()).foregroundColor(.lcText).lineLimit(1)
                    Text("此刻记忆").font(.system(size: 11, design: .rounded)).foregroundColor(.lcTextSecondary.opacity(0.6))
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.lcTextSecondary.opacity(0.3))
            }
            .padding(16).background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
        }
        .buttonStyle(.plain)
    }

    private var habitSection: some View {
        VStack(spacing: 16) {
            if state.tinyHabits.isEmpty {
                Button("添加第一个习惯") { isShowingTinyHabitSheet = true }.padding().foregroundColor(.lcTextSecondary)
            } else {
                VStack(spacing: 12) {
                    ForEach(state.tinyHabits) { habit in
                        HStack {
                            Image(systemName: habit.isDoneToday ? "checkmark.circle.fill" : "circle.fill")
                                .foregroundColor(habit.isDoneToday ? .lcGreen : .lcCheeseYellow.opacity(0.6)).font(.system(size: 20))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(habit.action).font(.system(.body, design: .rounded).bold())
                                    .foregroundColor(habit.isDoneToday ? .lcTextSecondary : .lcText)
                                Text("触发：\(habit.trigger)").font(.system(.caption, design: .rounded)).foregroundColor(.lcTextSecondary.opacity(0.7))
                            }
                            Spacer()
                            Text("\(habit.doneCountToday)/\(habit.targetCountPerDay)")
                                .font(.system(.caption, design: .monospaced).bold())
                                .foregroundColor(habit.isDoneToday ? .lcGreen : .lcTextSecondary)
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(habit.isDoneToday ? Color.lcGreen.opacity(0.1) : Color.clear).cornerRadius(6)
                        }
                        .padding().background(RoundedRectangle(cornerRadius: 20).fill(Color.lcCardBackground))
                        .contentShape(RoundedRectangle(cornerRadius: 20))
                        .contextMenu {
                            Button(role: .destructive) { withAnimation(.spring()) { state.deleteTinyHabit(id: habit.id) } } label: { Label("放弃这个习惯", systemImage: "trash") }
                            Button {
                                editingTinyHabit = habit; tinyTrigger = habit.trigger; tinyAction = habit.action; tinyTargetCount = habit.targetCountPerDay
                                isShowingTinyHabitSheet = true
                            } label: { Label("修改计划", systemImage: "pencil") }
                        }
                        .onTapGesture { state.toggleTinyHabit(id: habit.id) }
                    }
                }
                Button(action: {
                    editingTinyHabit = nil; tinyTrigger = ""; tinyAction = ""; tinyTargetCount = 1
                    isShowingTinyHabitSheet = true
                }) {
                    HStack { Image(systemName: "plus.circle.fill"); Text("新增习惯锚点") }
                        .padding().frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.lcTextSecondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5])))
                }.buttonStyle(.plain).padding(.top, 8)
            }
        }
    }

    private func todayEnergyCard(total: Int) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("今日时间分布").font(.system(.subheadline, design: .rounded).bold())
                Spacer()
                Text("共 \(total) 分钟").font(.caption).padding(6).background(Color.lcAccentBlue.opacity(0.1)).cornerRadius(8)
            }
            GeometryReader { geo in
                HStack(spacing: 2) {
                    ForEach(todayTimeUsage) { usage in
                        let w = geo.size.width * (Double(usage.minutes) / Double(total))
                        if w > 1 { RoundedRectangle(cornerRadius: 2).fill(usage.color).frame(width: w - 1) }
                    }
                }
            }.frame(height: 8)
        }
        .padding(20).background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
    }

    private func modeButton(title: String, index: Int) -> some View {
        Button { withAnimation { viewMode = index } } label: {
            VStack(spacing: 6) {
                Text(title).font(.system(size: viewMode == index ? 24 : 18, weight: .bold)).foregroundColor(viewMode == index ? .lcText : .secondary)
                if viewMode == index { Capsule().fill(Color.lcCheeseYellow).frame(width: 20, height: 4).matchedGeometryEffect(id: "tab", in: namespace) }
            }
        }.buttonStyle(.plain)
    }

    private var addTaskInput: some View {
        HStack {
            Image(systemName: "plus.circle").foregroundColor(.lcAccentBlue)
            TextField("记录三件事...", text: $newTaskTitle).onSubmit {
                if !newTaskTitle.isEmpty { state.addTodayTask(title: newTaskTitle); newTaskTitle = "" }
            }
        }.padding()
    }

    private func checkDailyReset() {
        let today = AppState.df.string(from: Date())
        if lastOpenDateKey != today { state.todayTasks.removeAll(); lastOpenDateKey = today }
    }

    private var tinyHabitEditor: some View {
        NavigationStack {
            Form {
                Section(header: Text("习惯动作").font(.system(.caption, design: .rounded))) { TextField("想要做的一件小事...", text: $tinyAction).padding(.vertical, 4) }
                Section(header: Text("触发锚点").font(.system(.caption, design: .rounded))) { TextField("在什么时候做？（例如：刷牙后）", text: $tinyTrigger).padding(.vertical, 4) }
                Section(header: Text("目标次数").font(.system(.caption, design: .rounded))) { Stepper("每天完成 \(tinyTargetCount) 次", value: $tinyTargetCount, in: 1...10) }
                Section { Text("提示：小习惯成功的秘诀是“微小”。哪怕只是做一个俯卧撑，或者读一行书，只要开始了就是胜利 🧀").font(.caption).foregroundColor(.lcTextSecondary) }
            }
            .navigationTitle(editingTinyHabit == nil ? "新增习惯锚点" : "调整习惯计划")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { isShowingTinyHabitSheet = false } }
                ToolbarItem(placement: .confirmationAction) { Button("保存") { saveTinyHabit(); isShowingTinyHabitSheet = false }.disabled(tinyAction.isEmpty || tinyTrigger.isEmpty) }
            }
        }
    }

    private func saveTinyHabit() {
        if let habit = editingTinyHabit { state.updateTinyHabit(id: habit.id, trigger: tinyTrigger, action: tinyAction, targetCountPerDay: tinyTargetCount) }
        else { state.addTinyHabit(trigger: tinyTrigger, action: tinyAction, targetCountPerDay: tinyTargetCount) }
        editingTinyHabit = nil; tinyTrigger = ""; tinyAction = ""; tinyTargetCount = 1
    }
} // <--- TodayView 结构体在这里干净利落地结束！

// MARK: - 独立组件 (放在所有大括号最外面)
struct TodayTaskTimelineRow: View {
    let task: TodoItem; let isLast: Bool; let onToggle: () -> Void; let onDelete: () -> Void; var onStartPomodoro: () -> Void
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle().fill(task.isDone ? Color.lcGreen : Color.lcSoftBlue).frame(width: 12, height: 12)
                if !isLast { Rectangle().fill(Color.lcSoftBlue.opacity(0.3)).frame(width: 2) }
            }
            HStack {
                Text(task.title).strikethrough(task.isDone).foregroundColor(task.isDone ? .secondary : .primary)
                Spacer()
                if !task.isDone { Button(action: onStartPomodoro) { Image(systemName: "timer").foregroundColor(.lcCheeseYellow) } }
                Button(action: onToggle) { Image(systemName: task.isDone ? "checkmark.circle.fill" : "circle").foregroundColor(task.isDone ? .lcGreen : .lcSoftBlue) }
            }.padding(.bottom, 24)
        }.onTapGesture { onToggle() }.contextMenu { Button("删除", role: .destructive) { onDelete() } }
    }
}
