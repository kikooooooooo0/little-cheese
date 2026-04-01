import SwiftUI

// MARK: - 本周 Summary 统计模型
struct AreaWeeklyStat: Identifiable {
    let id = UUID()
    let name: String
    let value: Int
    let color: Color
}

struct WeeklySummaryData {
    var timeTop: [AreaWeeklyStat]
    var timeOthersMinutes: Int
    var pointStats: [AreaWeeklyStat]
    var totalPoints: Int
}

// MARK: - Goals View (Future 容器：目标 / 灵光)

struct GoalsView: View {
    @ObservedObject var state: AppState
    
    // 0 = 目标 (Goals), 1 = 灵光 (Sparks)
    // 记住上次的选择
    @AppStorage("lc_futureViewMode") private var viewMode: Int = 0
    
    // 动画命名空间
    @Namespace private var namespace

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - 1. 自定义顶部切换栏 (与过往页保持一致)
                HStack(spacing: 30) {
                    // 按钮 1: 目标
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewMode = 0
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text("目标")
                                .font(.system(size: viewMode == 0 ? 24 : 18))
                                .fontWeight(viewMode == 0 ? .bold : .medium)
                                .foregroundColor(viewMode == 0 ? .lcText : .lcTextSecondary.opacity(0.6))
                            
                            if viewMode == 0 {
                                Capsule()
                                    .fill(Color.lcAccentBlue)
                                    .frame(width: 20, height: 4)
                                    .matchedGeometryEffect(id: "futureIndicator", in: namespace)
                            } else {
                                Capsule().fill(Color.clear).frame(width: 20, height: 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    // 按钮 2: 灵光
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewMode = 1
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text("灵光")
                                .font(.system(size: viewMode == 1 ? 24 : 18))
                                .fontWeight(viewMode == 1 ? .bold : .medium)
                                .foregroundColor(viewMode == 1 ? .lcText : .lcTextSecondary.opacity(0.6))
                            
                            if viewMode == 1 {
                                Capsule()
                                    .fill(Color.lcYellow) // 灵光用黄色
                                    .frame(width: 20, height: 4)
                                    .matchedGeometryEffect(id: "futureIndicator", in: namespace)
                            } else {
                                Capsule().fill(Color.clear).frame(width: 20, height: 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    
                    Spacer() // 标题靠左
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 10)
                .background(Color.lcBackground)
                
                // MARK: - 2. 内容区切换
                ZStack {
                    if viewMode == 0 {
                        // 目标仪表盘
                        GoalsDashboardView(state: state)
                            .transition(.opacity)
                    } else {
                        // 灵光收集箱 (直接复用 InboxView)
                        // 注意：为了避免双重导航栏，我们在 InboxView 内部处理或在这里隐藏
                        InboxView(state: state)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color.lcBackground.ignoresSafeArea())
            // 隐藏系统自带标题，用我们漂亮的自定义 Header
            .navigationBarHidden(true)
        }
    }
}

// MARK: - SubView: 目标仪表盘 (原来的 GoalsView 内容)
// 把原来的逻辑封装在这里，保持代码整洁
struct GoalsDashboardView: View {
    @ObservedObject var state: AppState

    // 状态：生活领域编辑
    @State private var isShowingAddArea = false
    @State private var isShowingEditArea = false
    @State private var areaName: String = ""
    @State private var areaEmoji: String = ""
    @State private var areaColorIndex: Int = 0
    @State private var editingAreaID: UUID?

    // 状态：目标编辑
    @State private var isShowingAddGoal = false
    @State private var isShowingEditGoal = false
    @State private var goalTitle: String = ""
    @State private var goalPoints: Int = 5
    @State private var goalMinutes: Int = 30
    @State private var goalUseMinutes: Bool = false
    @State private var goalPlannedTimes: Int = 1
    @State private var activeAreaIDForGoal: UUID?
    @State private var editingGoalID: UUID?
    
    // 逻辑：计算本周统计
    private func buildWeeklySummary() -> WeeklySummaryData {
        let calendar = Calendar.current
        let now = Date()
        var minutesDict: [UUID: Int] = [:]
        for block in state.timeBlocks {
            guard let areaId = block.lifeAreaId else { continue }
            if calendar.isDate(block.start, equalTo: now, toGranularity: .weekOfYear) {
                let m = max(1, Int(block.end.timeIntervalSince(block.start) / 60))
                minutesDict[areaId, default: 0] += m
            }
        }
        var timeStats: [AreaWeeklyStat] = []
        for area in state.lifeAreas {
            let minutes = minutesDict[area.id] ?? 0
            if minutes > 0 {
                timeStats.append(AreaWeeklyStat(name: area.name, value: minutes, color: colorForIndex(area.colorIndex)))
            }
        }
        timeStats.sort { $0.value > $1.value }
        let timeTop = Array(timeStats.prefix(3))
        let timeOthers = timeStats.dropFirst(3).reduce(0) { $0 + $1.value }

        var pointStats: [AreaWeeklyStat] = []
        var totalPoints = 0
        for area in state.lifeAreas {
            var areaPoints = 0
            for goal in area.goals {
                let times = max(0, goal.doneTimesThisWeek)
                if times > 0 {
                    areaPoints += times * goal.points
                }
            }
            if areaPoints > 0 {
                totalPoints += areaPoints
                pointStats.append(AreaWeeklyStat(name: area.name, value: areaPoints, color: colorForIndex(area.colorIndex)))
            }
        }
        pointStats.sort { $0.value > $1.value }
        return WeeklySummaryData(timeTop: timeTop, timeOthersMinutes: timeOthers, pointStats: pointStats, totalPoints: totalPoints)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 1. 本周 Summary
                summaryCard
                    .padding(.horizontal)
                    .padding(.top, 10)
                
                // 2. 身体管理卡片 (保留入口)
                NavigationLink(destination: WeightRecordView(state: state)) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.lcRed.opacity(0.15))
                                .frame(width: 48, height: 48)
                            Text("⚖️")
                                .font(.title2)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("身体管理")
                                .font(.headline)
                                .foregroundColor(.lcText)
                            Text("记录体重与运动，保持好状态")
                                .font(.caption)
                                .foregroundColor(.lcTextSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.lcTextSecondary.opacity(0.5))
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.lcCardBackground)
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                    )
                }
                .padding(.horizontal)

                // 3. 生活领域列表
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("生活领域")
                            .font(.title3.bold())
                            .foregroundColor(.lcText)
                        Spacer()
                        if !state.lifeAreas.isEmpty {
                            Button { startAddArea() } label: {
                                Image(systemName: "plus")
                                    .font(.body.bold())
                                    .foregroundColor(.lcAccentBlue)
                                    .padding(8)
                                    .background(Circle().fill(Color.lcSoftBlue.opacity(0.3)))
                            }
                        }
                    }
                    .padding(.horizontal)

                    ForEach(state.lifeAreas) { area in
                        areaCard(for: area)
                            .contextMenu {
                                Button("编辑") { startEditArea(area) }
                                Button("加目标") { startAddGoal(in: area) }
                                Button("删除", role: .destructive) { state.deleteLifeArea(id: area.id) }
                            }
                    }
                    .padding(.horizontal)

                    Button {
                        startAddArea()
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("添加新领域")
                        }
                        .foregroundColor(.lcTextSecondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(Color.lcTextSecondary.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .padding(.bottom, 20)
        }
        .background(Color.lcBackground.ignoresSafeArea())
        .sheet(isPresented: $isShowingAddArea) { areaEditSheet(isEditing: false) }
        .sheet(isPresented: $isShowingEditArea) { areaEditSheet(isEditing: true) }
        .sheet(isPresented: $isShowingAddGoal) { goalEditSheet(isEditing: false) }
        .sheet(isPresented: $isShowingEditGoal) { goalEditSheet(isEditing: true) }
    }

    // MARK: - 子视图 (Dashboard 内部)
    
    private var summaryCard: some View {
        let summary = buildWeeklySummary()
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.lcAccentBlue)
                Text("本周概况")
                    .font(.headline)
                    .foregroundColor(.lcText)
                Spacer()
                if summary.totalPoints > 0 {
                    Text("Total: \(summary.totalPoints)分")
                        .font(.subheadline.bold())
                        .foregroundColor(.lcYellow)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.lcYellow.opacity(0.15))
                        .cornerRadius(8)
                }
            }

            if summary.timeTop.isEmpty && summary.pointStats.isEmpty {
                Text("还没开始记录？设定一个小目标，开始这一周吧！")
                    .font(.caption)
                    .foregroundColor(.lcTextSecondary)
                    .padding(.vertical, 8)
            } else {
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("时间投入").font(.caption).foregroundColor(.lcTextSecondary)
                        let maxMin = max(summary.timeTop.map(\.value).max() ?? 1, 1)
                        ForEach(summary.timeTop) { stat in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(stat.name).font(.caption.bold()).foregroundColor(.lcText)
                                HStack {
                                    Text("\(stat.value)m").font(.caption2).foregroundColor(.lcTextSecondary).frame(width:40,alignment:.leading)
                                    GeometryReader { geo in
                                        let w = geo.size.width * CGFloat(stat.value) / CGFloat(maxMin)
                                        RoundedRectangle(cornerRadius:2).fill(stat.color.opacity(0.75)).frame(width: max(w,4), height:6)
                                    }
                                    .frame(height: 6)
                                }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("成长积分").font(.caption).foregroundColor(.lcTextSecondary)
                        ForEach(summary.pointStats) { stat in
                            HStack {
                                Circle().fill(stat.color).frame(width:6,height:6)
                                Text(stat.name).font(.caption).foregroundColor(.lcText)
                                Spacer()
                                Text("\(stat.value)").font(.caption.bold()).foregroundColor(.lcText)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.lcCardBackground)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
        )
    }

    private func areaCard(for area: LifeArea) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(area.emoji).font(.title3)
                Text(area.name).font(.headline).foregroundColor(.lcText)
                Spacer()
                Capsule().fill(colorForIndex(area.colorIndex).opacity(0.3)).frame(width: 40, height: 4)
            }
            if area.goals.isEmpty {
                Text("暂无目标").font(.caption).foregroundColor(.lcTextSecondary.opacity(0.5))
            } else {
                VStack(spacing: 12) {
                    ForEach(area.goals) { goal in
                        goalRow(goal: goal, area: area)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.lcCardBackground)
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
        )
    }
    
    private func goalRow(goal: Goal, area: LifeArea) -> some View {
        HStack(spacing: 12) {
            Button { state.addOneTimeForGoal(areaID: area.id, goalID: goal.id) } label: {
                let planned = max(1, goal.plannedTimesPerWeek)
                let done = max(0, goal.doneTimesThisWeek)
                Image(systemName: done >= planned ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(done >= planned ? .lcGreen : .lcSoftBlue)
                    .font(.title2)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(goal.title)
                    .font(.subheadline)
                    .foregroundColor(.lcText)
                    .strikethrough(goal.doneTimesThisWeek >= goal.plannedTimesPerWeek, color: .lcTextSecondary.opacity(0.5))
                HStack(spacing: 6) {
                    Text("\(goal.doneTimesThisWeek)/\(goal.plannedTimesPerWeek)")
                    if goal.useMinutes { Text("· \(goal.minutes ?? 0)m") }
                    else { Text("· \(goal.points)pts") }
                }
                .font(.caption2).foregroundColor(.lcTextSecondary)
            }
            Spacer()
        }
        .contextMenu {
            Button("编辑") { startEditGoal(goal, in: area) }
            Button("-1次") { state.removeOneTimeForGoal(areaID: area.id, goalID: goal.id) }
            Button("删除", role: .destructive) { state.deleteGoal(areaID: area.id, goalID: goal.id) }
        }
    }

    // 辅助 & Sheet 逻辑
    private func colorForIndex(_ index: Int) -> Color {
        let idx = max(0, min(lifeAreaPalettes.count - 1, index))
        return lifeAreaPalettes[idx].first ?? .lcYellow
    }
    private func areaEditSheet(isEditing: Bool) -> some View {
        NavigationStack {
            Form {
                Section { TextField("领域名称", text: $areaName); TextField("Emoji", text: $areaEmoji) }
                Section("颜色") { ScrollView(.horizontal) { HStack { ForEach(0..<lifeAreaPalettes.count, id:\.self) { i in Circle().fill(colorForIndex(i)).frame(width:30,height:30).overlay(Circle().stroke(i==areaColorIndex ? Color.lcText : .clear, lineWidth:2)).onTapGesture { areaColorIndex=i } } } } }
            }
            .navigationTitle(isEditing ? "编辑" : "新增")
            .toolbar {
                ToolbarItem(placement:.cancellationAction) { Button("取消") { isShowingAddArea=false; isShowingEditArea=false } }
                ToolbarItem(placement:.confirmationAction) { Button("保存") { saveArea(isEditing:isEditing) }.disabled(areaName.isEmpty) }
            }
        }
    }
    private func goalEditSheet(isEditing: Bool) -> some View {
        NavigationStack {
            Form {
                Section { TextField("目标内容", text: $goalTitle) }
                Section("类型") { Picker("", selection: $goalUseMinutes) { Text("积分").tag(false); Text("时间").tag(true) }.pickerStyle(.segmented) }
                if goalUseMinutes { Section { Stepper("\(goalMinutes) 分钟", value: $goalMinutes, step: 5) } }
                else { Section { Stepper("\(goalPoints) 分", value: $goalPoints) } }
                Section { Stepper("每周 \(goalPlannedTimes) 次", value: $goalPlannedTimes) }
            }
            .navigationTitle(isEditing ? "编辑" : "新增")
            .toolbar {
                ToolbarItem(placement:.cancellationAction) { Button("取消") { isShowingAddGoal=false; isShowingEditGoal=false } }
                ToolbarItem(placement:.confirmationAction) { Button("保存") { saveGoal(isEditing:isEditing) }.disabled(goalTitle.isEmpty) }
            }
        }
    }
    
    // CRUD Actions
    private func startAddArea() { areaName=""; areaEmoji=""; areaColorIndex=0; isShowingAddArea=true }
    private func startEditArea(_ area: LifeArea) { areaName=area.name; areaEmoji=area.emoji; areaColorIndex=area.colorIndex; editingAreaID=area.id; isShowingEditArea=true }
    private func saveArea(isEditing: Bool) {
        let name = areaName.trimmingCharacters(in: .whitespacesAndNewlines); guard !name.isEmpty else { return }
        let emoji = areaEmoji.isEmpty ? "📌" : areaEmoji
        if isEditing, let id = editingAreaID { state.updateLifeArea(id: id, name: name, emoji: emoji, colorIndex: areaColorIndex) }
        else { state.addLifeArea(name: name, emoji: emoji, colorIndex: areaColorIndex) }
        isShowingAddArea=false; isShowingEditArea=false
    }
    private func startAddGoal(in area: LifeArea) { goalTitle=""; goalPoints=5; goalMinutes=30; goalPlannedTimes=1; goalUseMinutes=(area.mode == .time); activeAreaIDForGoal=area.id; isShowingAddGoal=true }
    private func startEditGoal(_ goal: Goal, in area: LifeArea) { editingGoalID=goal.id; goalTitle=goal.title; goalPoints=goal.points; goalMinutes=goal.minutes ?? 30; goalUseMinutes=goal.useMinutes; goalPlannedTimes=goal.plannedTimesPerWeek; activeAreaIDForGoal=area.id; isShowingEditGoal=true }
    private func saveGoal(isEditing: Bool) {
        let title = goalTitle.trimmingCharacters(in: .whitespacesAndNewlines); guard !title.isEmpty, let aid = activeAreaIDForGoal else { return }
        let mins = goalUseMinutes ? goalMinutes : nil
        if isEditing, let gid = editingGoalID { state.updateGoal(areaID: aid, goalID: gid, title: title, points: goalPoints, minutes: mins, useMinutes: goalUseMinutes, plannedTimesPerWeek: goalPlannedTimes) }
        else { state.addGoal(areaID: aid, title: title, points: goalPoints, minutes: mins, useMinutes: goalUseMinutes, plannedTimesPerWeek: goalPlannedTimes) }
        isShowingAddGoal=false; isShowingEditGoal=false
    }
}
