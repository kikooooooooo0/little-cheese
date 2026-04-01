import SwiftUI

// MARK: - Today View (终极稳固版)
struct TodayView: View {
    @ObservedObject var state: AppState
    
    @State private var viewMode: Int = 0
    @Namespace private var namespace
    @State private var isShowingPomodoroSheet: Bool = false
    @State private var isShowingTinyHabitSheet: Bool = false
    @AppStorage("lc_todayLastOpenDateKey") private var lastOpenDateKey: String = ""
    @State private var didCheckDailyReset: Bool = false
    @State private var newTaskTitle: String = ""
    
    @State private var editingTinyHabit: TinyHabit?
    @State private var tinyTrigger: String = ""
    @State private var tinyAction: String = ""
    @State private var tinyTargetCount: Int = 1
    
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
                                    // MARK: --- 联动版：今日饮食 SOP 卡片 ---
                                    VStack(alignment: .leading, spacing: 16) {
                                        HStack {
                                            Text("🍴 今日饮食 SOP").font(.system(.headline, design: .rounded))
                                            Spacer()
                                            NavigationLink(destination: DietSOPListView(state: state)) {
                                                Image(systemName: "pencil.circle.fill")
                                                    .foregroundColor(.lcAccentBlue.opacity(0.6)).font(.title3)
                                            }
                                            Text(getTodayChineseWeekday())
                                                .font(.system(size: 10, weight: .bold)).padding(.horizontal, 8).padding(.vertical, 4)
                                                .background(Color.lcYellow.opacity(0.2)).cornerRadius(8)
                                        }
                                        VStack(spacing: 10) {
                                            mealLinkRow(title: "早餐", food: "待执行 SOP", isDone: state.isBreakfastDone)
                                            Divider().opacity(0.3)
                                            mealLinkRow(title: "午餐", food: "待执行 SOP", isDone: state.isLunchDone)
                                            Divider().opacity(0.3)
                                            mealLinkRow(title: "晚餐", food: "待执行 SOP", isDone: state.isDinnerDone)
                                        }
                                    }
                                    .padding(20).background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
                                    
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
        .onAppear { checkDailyReset() }
        .sheet(isPresented: $isShowingPomodoroSheet) {
            NavigationStack {
                PomodoroView(state: state)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("关闭") { isShowingPomodoroSheet = false } } }
            }
        }
        .sheet(isPresented: $isShowingTinyHabitSheet) { tinyHabitEditor }
    }

    // MARK: - 内部组件和工具函数 (取消了 Extension，更稳固)

    private func mealLinkRow(title: String, food: String, isDone: Bool) -> some View {
        NavigationLink(destination: DietSOPListView(state: state)) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title).font(.caption).foregroundColor(.secondary)
                    Text(isDone ? "能量已补充 🧀" : food).font(.system(.body, design: .rounded).bold())
                        .foregroundColor(isDone ? .lcTextSecondary : .lcText)
                }
                Spacer()
                Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isDone ? .lcGreen : .lcSoftBlue).font(.title2)
            }
        }
        .buttonStyle(.plain)
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
