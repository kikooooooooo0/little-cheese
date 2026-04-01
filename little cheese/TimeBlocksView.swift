import SwiftUI

// 顶部：视图范围切换（今天 / 这周）
enum TimeViewScope: String, CaseIterable {
    case day  = "今天"
    case week = "这周"
}

struct TimeBlocksView: View {

    @ObservedObject var state: AppState

    /// 日 / 周 视图切换
    @State private var scope: TimeViewScope = .day

    /// 是否正在编辑 / 新建时间块
    @State private var isPresentingEditor: Bool = false

    /// 编辑中的标题和时间
    @State private var draftTitle: String = ""
    @State private var draftStart: Date = TimeBlocksView.defaultStartTime()
    @State private var draftEnd: Date = TimeBlocksView.defaultEndTime()
    /// 选中的生活领域（可选）
    @State private var selectedLifeAreaId: UUID? = nil

    /// 用来格式化 “HH:mm”
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "HH:mm"
        return f
    }()
    /// 用来格式化周视图上方的 “E\nMM/dd”
    private static let weekLabelFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "E\nMM/dd"
        return f
    }()

    /// 默认从今天 09:00 开始
    private static func defaultStartTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: now
        ) ?? now
    }

    /// 默认结束时间：10:00
    private static func defaultEndTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        return calendar.date(
            bySettingHour: 10,
            minute: 0,
            second: 0,
            of: now
        ) ?? now.addingTimeInterval(60 * 60)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            let today = Date()
            let todayBlocks = state.timeBlocks(for: today)

            VStack(spacing: 0) {

                // 顶部标题 + 日/周切换
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("时间小砖块")
                                .font(.title2.bold())
                                .foregroundColor(.lcText)

                            Text("像拼图一样，把一天或一周的时间拼成一张小地图。")
                                .font(.subheadline)
                                .foregroundColor(.lcTextSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Picker("", selection: $scope) {
                            ForEach(TimeViewScope.allCases, id: \.self) { s in
                                Text(s.rawValue).tag(s)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }

                    if scope == .day, !todayBlocks.isEmpty {
                        let totalMinutes = totalDuration(of: todayBlocks)
                        Text("今天已规划约 \(totalMinutes) 分钟")
                            .font(.footnote)
                            .foregroundColor(.lcTextSecondary)
                    } else if scope == .week {
                        let weekDates = datesOfThisWeek(reference: today)
                        let total = weekDates.reduce(0) { sum, d in
                            sum + totalDuration(of: state.timeBlocks(for: d))
                        }
                        if total > 0 {
                            Text("本周已拼出约 \(total) 分钟的小砖块")
                                .font(.footnote)
                                .foregroundColor(.lcTextSecondary)
                        } else {
                            Text("这一周还空空的，可以慢慢填上想做的小事。")
                                .font(.footnote)
                                .foregroundColor(.lcTextSecondary)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color.lcBackground)

                Divider()
                    .overlay(Color.lcSoftBlue.opacity(0.5))
                // 主体内容：今天视角 / 本周视角
                ScrollView {
                    if scope == .day {
                        // ✅ 用回原来的「早晨 / 白天 / 夜间」时间线样式
                        dayContent(today: today, todayBlocks: todayBlocks)
                    } else {
                        // ✅ 保留新的周视图（有左侧时间轴 + 网格）
                        weekCalendarGrid(today: today)
                    }
                }


                .background(Color.lcBackground)
            }
            .background(Color.lcBackground.ignoresSafeArea())
            .navigationTitle("时间块")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        startNewBlock()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingEditor) {
                editorSheet
            }
        }
    }

    // MARK: - 「今天」视图内容（早晨 / 白天 / 夜间）

    private func dayContent(today: Date, todayBlocks: [TimeBlock]) -> some View {
        // 三段时间分组
        let morningBlocks   = blocks(in: 6..<12,  of: todayBlocks)  // 06:00 - 12:00
        let afternoonBlocks = blocks(in: 12..<20, of: todayBlocks)  // 12:00 - 20:00
        let nightBlocks     = blocks(in: 20..<24, of: todayBlocks)  // 20:00 - 24:00

        return VStack(alignment: .leading, spacing: 14) {
            if todayBlocks.isEmpty {
                emptyPlaceholder
            } else {
                timeSegmentSection(
                    title: "早晨",
                    timeLabel: "06:00 – 12:00",
                    blocks: morningBlocks
                )

                timeSegmentSection(
                    title: "白天",
                    timeLabel: "12:00 – 20:00",
                    blocks: afternoonBlocks
                )

                timeSegmentSection(
                    title: "夜间",
                    timeLabel: "20:00 – 24:00",
                    blocks: nightBlocks
                )
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
    }
    // MARK: - 「今天」视图：带时间轴 + 横线 + 一列彩色块
    private func dayCalendarView(today: Date, todayBlocks: [TimeBlock]) -> some View {

        let dayStartHour = 6
        let dayEndHour   = 24
        let totalHours   = dayEndHour - dayStartHour
        let rowHeight: CGFloat = 42
        let totalHeight = CGFloat(totalHours) * rowHeight

        let blocks = todayBlocks.sorted { $0.start < $1.start }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "MM月dd日 EEEE"
        let titleText = formatter.string(from: today)

        return VStack(alignment: .leading, spacing: 8) {

            // 顶部日期标题
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(titleText)
                        .font(.headline)
                        .foregroundColor(.lcText)
                    Text("像时间地图一样，看今天的拼图。")
                        .font(.caption)
                        .foregroundColor(.lcTextSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)

            // 下方：左边时间轴 + 右边网格 + 彩色块
            HStack(alignment: .top, spacing: 0) {

                // ⬅️ 左侧时间轴
                VStack(alignment: .trailing, spacing: 0) {
                    ForEach(0...totalHours, id: \.self) { index in
                        let hour = dayStartHour + index
                        let label = String(format: "%02d:00", hour)

                        Text(label)
                            .font(.caption2)
                            .foregroundColor(.lcTextSecondary)
                            .frame(height: rowHeight, alignment: .topTrailing)
                    }
                }
                .frame(width: 50)
                .padding(.top, 4)

                // ➡️ 右侧：一列网格 + 时间块
                GeometryReader { geo in
                    ZStack(alignment: .topLeading) {

                        // 横线网格
                        ForEach(0...totalHours, id: \.self) { index in
                            let y = CGFloat(index) * rowHeight

                            Path { path in
                                path.move(to: CGPoint(x: 0, y: y))
                                path.addLine(to: CGPoint(x: geo.size.width, y: y))
                            }
                            .stroke(
                                Color.lcSoftBlue.opacity(index % 2 == 0 ? 0.35 : 0.18),
                                style: StrokeStyle(
                                    lineWidth: 0.6,
                                    dash: index % 2 == 0 ? [] : [3, 3]
                                )
                            )
                        }

                        // 彩色时间块
                        ForEach(blocks, id: \.id) { block in
                            let pos = verticalPosition(
                                for: block,
                                on: today,
                                startHour: dayStartHour,
                                endHour: dayEndHour,
                                rowHeight: rowHeight
                            )

                            weekBlockCard(block)
                                .frame(height: pos.height)
                                // 用 offset 按「顶部」往下挪，就不会跑出这一列
                                .offset(y: pos.offset)
                                .frame(maxWidth: .infinity, alignment: .topLeading)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        state.deleteTimeBlock(id: block.id)
                                    } label: {
                                        Label("删除", systemImage: "trash")
                                    }
                                }
                        }

                    }
                    .frame(height: totalHeight, alignment: .top)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - 新：真正的周视图（日历布局 + 时间轴 + 横线）
    private func weekCalendarGrid(today: Date) -> some View {

        let weekDates = datesOfThisWeek(reference: today)

        // 设定一天的时间范围：06:00 ~ 24:00
        let dayStartHour = 6
        let dayEndHour   = 24
        let totalHours   = dayEndHour - dayStartHour
        let rowHeight: CGFloat = 42         // 每一小时的高度
        let totalHeight = CGFloat(totalHours) * rowHeight

        // 每天的时间块（提前按开始时间排好）
        let blocksByDay: [(date: Date, blocks: [TimeBlock])] =
            weekDates.map { date in
                let blocks = state.timeBlocks(for: date).sorted { $0.start < $1.start }
                return (date, blocks)
            }

        return ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 6) {

                // 顶部：星期标签行（左边留出时间轴宽度）
                HStack(spacing: 0) {
                    // 给时间轴预留宽度
                    Color.clear
                        .frame(width: 50)

                    ForEach(blocksByDay, id: \.date) { item in
                        let isToday = Calendar.current.isDateInToday(item.date)
                        let text = Self.weekLabelFormatter.string(from: item.date)

                        Text(text)
                            .font(.caption2)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isToday ? Color.lcCheeseYellow.opacity(0.9) : Color.white)
                            )
                            .foregroundColor(isToday ? .lcText : .lcTextSecondary)
                            .shadow(color: .black.opacity(isToday ? 0.08 : 0.03), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.top, 10)

                // 下方：时间轴 + 网格 + 彩色块
                HStack(alignment: .top, spacing: 0) {

                    // ⬅️ 左侧时间轴（06:00, 08:00, …）
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(0...totalHours, id: \.self) { index in
                            let hour = dayStartHour + index
                            let label = String(format: "%02d:00", hour)

                            Text(label)
                                .font(.caption2)
                                .foregroundColor(.lcTextSecondary)
                                .frame(height: rowHeight, alignment: .topTrailing)
                        }
                    }
                    .frame(width: 50)
                    .padding(.top, 4)

                    // ➡️ 右侧：七列日历 + 横线网格
                    GeometryReader { geo in
                        let columnSpacing: CGFloat = 6
                        let columnCount = blocksByDay.count
                        let columnWidth = (geo.size.width
                                           - columnSpacing * CGFloat(max(0, columnCount - 1)))
                                           / CGFloat(max(1, columnCount))

                        ZStack(alignment: .topLeading) {

                            // 🧵 横线网格（像 Google Calendar）
                            ForEach(0...totalHours, id: \.self) { index in
                                let y = CGFloat(index) * rowHeight

                                Path { path in
                                    path.move(to: CGPoint(x: 0, y: y))
                                    path.addLine(to: CGPoint(x: geo.size.width, y: y))
                                }
                                .stroke(
                                    Color.lcSoftBlue.opacity(index % 2 == 0 ? 0.35 : 0.18),
                                    style: StrokeStyle(
                                        lineWidth: 0.6,
                                        dash: index % 2 == 0 ? [] : [3, 3]
                                    )
                                )
                            }

                            // 📅 每一天一列，彩色时间块按时间“挂”在网格上
                            HStack(alignment: .top, spacing: columnSpacing) {
                                ForEach(blocksByDay, id: \.date) { item in
                                    ZStack(alignment: .topLeading) {

                                        ForEach(item.blocks, id: \.id) { block in
                                            let pos = verticalPosition(
                                                for: block,
                                                on: item.date,
                                                startHour: dayStartHour,
                                                endHour: dayEndHour,
                                                rowHeight: rowHeight
                                            )

                                            weekBlockCard(block)
                                                .frame(width: columnWidth - 6, height: pos.height, alignment: .leading)
                                                .offset(y: pos.offset)

                                                .contextMenu {
                                                    Button(role: .destructive) {
                                                        state.deleteTimeBlock(id: block.id)
                                                    } label: {
                                                        Label("删除", systemImage: "trash")
                                                    }
                                                }
                                        }
                                    }
                                    .frame(width: columnWidth,
                                           height: totalHeight,
                                           alignment: .top)
                                }
                            }
                        }
                        .frame(height: totalHeight, alignment: .top)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 20)
            }
        }
    }


    // MARK: - 空状态视图

    private var emptyPlaceholder: some View {
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.lcSoftBlue.opacity(0.45),
                            Color.lcCheeseYellow.opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
                .frame(height: 150)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "clock.badge.plus")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(.white)

                        Text("还没有时间块")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("试着为今天安排一块「专心 LSAT」、一块「做 LittleCheese」、一块「好好休息」吧。")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 16)
                    }
                }

            Text("点击右上角 +，开始拼今天的时间 🧀")
                .font(.caption2)
                .foregroundColor(.lcTextSecondary)
        }
    }

    // MARK: - 时间段分组（今天视图用）

    /// 按开始时间的「小时」把时间块分到某个区间里（例如 6..<12）
    private func blocks(in hourRange: Range<Int>, of allBlocks: [TimeBlock]) -> [TimeBlock] {
        let calendar = Calendar.current
        return allBlocks
            .filter { block in
                let hour = calendar.component(.hour, from: block.start)
                return hourRange.contains(hour)
            }
            .sorted { $0.start < $1.start }
    }

    /// 某一段（例如 6:00-12:00）的整体区域：标题 + 一列时间轴行
    private func timeSegmentSection(
        title: String,
        timeLabel: String,
        blocks: [TimeBlock]
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {

            // 小标题：比如「早晨  06:00–12:00」
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.lcText)

                Text(timeLabel)
                    .font(.caption)
                    .foregroundColor(.lcTextSecondary)
            }
            .padding(.bottom, 2)

            if blocks.isEmpty {
                Text("这一段还空着，可以留给休息或小任务。")
                    .font(.caption2)
                    .foregroundColor(.lcTextSecondary)
                    .padding(.leading, 62) // 大致对齐到时间轴右侧
            } else {
                ForEach(Array(blocks.enumerated()), id: \.element.id) { index, block in
                    timelineRow(
                        block,
                        isFirst: index == 0,
                        isLast: index == blocks.count - 1
                    )
                    .contextMenu {
                        Button(role: .destructive) {
                            state.deleteTimeBlock(id: block.id)
                        } label: {
                            Label("删除这个时间块", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    // MARK: - 时间轴行 + 彩色块（今天视图）

    /// 时间轴上的一行（左边时间标签 + 竖线、圆点，右边卡片）
    private func timelineRow(
        _ block: TimeBlock,
        isFirst: Bool,
        isLast: Bool
    ) -> some View {
        let startStr = Self.timeFormatter.string(from: block.start)

        return HStack(alignment: .top, spacing: 8) {

            // 最左：时间文字（跟随每个时间块）
            Text(startStr)
                .font(.caption2)
                .foregroundColor(.lcTextSecondary)
                .frame(width: 46, alignment: .trailing)
                .padding(.top, 4)

            // 中间：时间线 + 圆点
            VStack(spacing: 0) {
                // 上半段线
                Rectangle()
                    .fill(Color.lcSoftBlue.opacity(isFirst ? 0 : 0.6))
                    .frame(width: 2, height: isFirst ? 0 : 10)
                    .opacity(isFirst ? 0 : 1)

                // 圆点
                Circle()
                    .fill(Color.lcAccentBlue)
                    .frame(width: 10, height: 10)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)

                // 下半段线
                Rectangle()
                    .fill(Color.lcSoftBlue.opacity(isLast ? 0 : 0.6))
                    .frame(width: 2, height: isLast ? 0 : 26)
                    .opacity(isLast ? 0 : 1)
            }
            .frame(width: 16)
            .padding(.top, 2)

            // 右边：彩色卡片，按照时长拉高
            blockCard(block)
        }
    }

    /// 根据时间块所属的 LifeArea 决定颜色（与 GoalsView 保持一致，但更淡）
    private func gradientFor(block: TimeBlock) -> LinearGradient {

        let baseColor: Color = {
            if
                let areaId = block.lifeAreaId,
                let area = state.lifeAreas.first(where: { $0.id == areaId })
            {
                let idx = max(0, min(lifeAreaPalettes.count - 1, area.colorIndex))
                let mainColor = lifeAreaPalettes[idx].first ?? .lcSoftBlue
                return mainColor

            }
            return Color.lcSoftBlue
        }()

        return LinearGradient(
            colors: [
                baseColor.opacity(0.25),
                baseColor.opacity(0.55)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 找到时间块对应的领域 emoji + 名称（周视图用）
    private func lifeAreaInfo(for block: TimeBlock) -> (emoji: String, name: String)? {
        guard
            let areaId = block.lifeAreaId,
            let area = state.lifeAreas.first(where: { $0.id == areaId })
        else {
            return nil
        }
        return (area.emoji, area.name)
    }

    /// 右侧的彩色时间块（更像日历里的彩色砖，时长越长高度越高）
    private func blockCard(_ block: TimeBlock) -> some View {
        let startStr = Self.timeFormatter.string(from: block.start)
        let endStr = Self.timeFormatter.string(from: block.end)
        let minutes = max(1, Int(block.end.timeIntervalSince(block.start) / 60))

        // 根据时长调高度：每 30 分钟增加一格高度
        let units = max(1, minutes / 30)   // 0~30 -> 1，31~60 -> 2，等等
        let baseHeight: CGFloat = 44
        let height = baseHeight + CGFloat(units - 1) * 24

        return VStack(alignment: .leading, spacing: 6) {

            if let info = lifeAreaInfo(for: block) {
                HStack(spacing: 4) {
                    Text(info.emoji)
                    Text(info.name)
                        .font(.caption2)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.25))
                .cornerRadius(999)
            }

            Text(block.title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            HStack(spacing: 4) {
                Text("\(startStr) – \(endStr)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))

                Text("· \(durationDescription(minutes: minutes))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: height)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(gradientFor(block: block))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.35), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 3)
    }

    // MARK: - 编辑 Sheet

    private var editorSheet: some View {
        NavigationStack {
            Form {
                Section("这段时间要做什么？") {
                    TextField("例如：LSAT 学习 / 做 LittleCheese / 散步 + Podcast", text: $draftTitle)
                }
                Section("属于哪个生活领域？") {
                    if state.lifeAreas.isEmpty {
                        Text("还没有设置生活领域，可以先在「目标」页创建 🧀")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Picker("生活领域", selection: Binding(
                            get: {
                                selectedLifeAreaId ?? state.lifeAreas.first?.id
                            },
                            set: { newValue in
                                selectedLifeAreaId = newValue
                            }
                        )) {
                            ForEach(state.lifeAreas) { area in
                                Text("\(area.emoji) \(area.name)")
                                    .tag(area.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section("时间范围") {
                    DatePicker(
                        "开始时间",
                        selection: $draftStart,
                        displayedComponents: [.hourAndMinute]
                    )

                    DatePicker(
                        "结束时间",
                        selection: $draftEnd,
                        displayedComponents: [.hourAndMinute]
                    )

                    Text("你可以任意选择开始和结束，之后统计时我们会按 15 分钟来折算。")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .navigationTitle("新时间块")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        isPresentingEditor = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveBlock()
                    }
                    .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    // MARK: - 动作

    private func startNewBlock() {
        draftTitle = ""
        draftStart = Self.defaultStartTime()
        draftEnd = Self.defaultEndTime()
        selectedLifeAreaId = state.lifeAreas.first?.id
        isPresentingEditor = true
    }

    private func saveBlock() {
        let today = Date()
        state.addTimeBlock(
            for: today,
            start: draftStart,
            end: draftEnd,
            title: draftTitle,
            lifeAreaId: selectedLifeAreaId
        )
        isPresentingEditor = false
    }

    // MARK: - 工具函数

    /// 一天的总分钟数
    private func totalDuration(of blocks: [TimeBlock]) -> Int {
        blocks.reduce(0) { partial, block in
            let minutes = max(0, Int(block.end.timeIntervalSince(block.start) / 60))
            return partial + minutes
        }
    }

    /// 把分钟数转成 “X 小时 Y 分钟”
    private func durationDescription(minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours) 小时 \(mins) 分钟"
        } else if hours > 0 {
            return "\(hours) 小时"
        } else {
            return "\(mins) 分钟"
        }
    }

    /// 给定一个参考日期，返回这一周（周一到周日）的 7 个日期
    private func datesOfThisWeek(reference: Date) -> [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 1 = Sunday, 2 = Monday

        let weekday = calendar.component(.weekday, from: reference)
        let distanceToMonday = (weekday + 5) % 7   // 把周一变成 0
        guard let monday = calendar.date(byAdding: .day, value: -distanceToMonday, to: reference) else {
            return [reference]
        }

        return (0..<7).compactMap {
            calendar.date(byAdding: .day, value: $0, to: monday)
        }
    }
    private func weekBlockCard(_ block: TimeBlock) -> some View {

        let startStr = Self.timeFormatter.string(from: block.start)
        let endStr   = Self.timeFormatter.string(from: block.end)

        return VStack(alignment: .leading, spacing: 4) {

            if let info = lifeAreaInfo(for: block) {
                Text("\(info.emoji) \(info.name)")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))
            }

            Text(block.title)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(2)

            Text("\(startStr) – \(endStr)")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(gradientFor(block: block))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 3, x: 0, y: 2)
    }
    /// 计算时间块在周视图里的纵向位置（距离顶部的 offset 和高度）
    /// 计算时间块在周视图/日视图里的纵向位置（按 15 分钟对齐，并预留一点缝隙）
    /// 计算时间块在周视图/日视图里的纵向位置（按 15 分钟对齐，并预留一点缝隙）
    private func verticalPosition(
        for block: TimeBlock,
        on date: Date,
        startHour: Int,
        endHour: Int,
        rowHeight: CGFloat
    ) -> (offset: CGFloat, height: CGFloat) {

        let calendar = Calendar.current

        let startOfDay = calendar.date(
            bySettingHour: startHour,
            minute: 0,
            second: 0,
            of: date
        ) ?? date

        let endOfDay = calendar.date(
            bySettingHour: endHour,
            minute: 0,
            second: 0,
            of: date
        ) ?? date

        // 把时间块限制在当天的时间范围内
        let clampedStart = max(block.start, startOfDay)
        let clampedEnd   = min(block.end, endOfDay)

        // 精确分钟数
        let minutesFromStart = max(0, Int(clampedStart.timeIntervalSince(startOfDay) / 60))
        let durationMinutes  = max(15, Int(clampedEnd.timeIntervalSince(clampedStart) / 60))

        // ⏱ 按 15 分钟一个格子来对齐
        let slotSize = 15   // 一格 = 15min
        let startSlots = minutesFromStart / slotSize
        let durSlots   = max(1, Int(ceil(Double(durationMinutes) / Double(slotSize))))

        // 一小时 = rowHeight → 一格 = rowHeight / 4
        let slotHeight = rowHeight / 4.0

        // 原始的顶端位置 & 高度（完全贴合格子）
        let rawOffset = CGFloat(startSlots) * slotHeight
        let rawHeight = CGFloat(durSlots) * slotHeight

        // 给每块砖上下各留一点空隙
        let inset: CGFloat = 3       // 想要更紧/更松可以改成 2 或 4
        let height = max(12, rawHeight - inset * 2)
        let offset = rawOffset + inset

        return (offset, height)
    }
}
