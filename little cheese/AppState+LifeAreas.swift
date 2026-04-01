import SwiftUI

// MARK: - 生活领域配色（给 GoalsView 用）

/// 一组柔和的颜色，用来给 LifeArea 选颜色
let LifeAreaColorPalette: [Color] = [
    .lcSoftBlue,       // 浅蓝
    .lcCheeseYellow,   // 奶酪黄
    .lcAccentBlue,     // 深一点的蓝
    Color.green.opacity(0.7),
    Color.orange.opacity(0.8),
    Color.pink.opacity(0.7),
    Color.purple.opacity(0.7),
    Color.teal.opacity(0.8)
]
// 每个 LifeArea 统一通过这个属性拿“界面颜色”
extension LifeArea {
    var displayColor: Color {
        let idx = max(0, min(LifeAreaColorPalette.count - 1, colorIndex))
        return LifeAreaColorPalette[idx]
    }
}


// MARK: - AppState 针对 LifeArea 的辅助方法

extension AppState {

    // MARK: 生活领域：增删改查 & 排序

    /// 新增一个生活领域
    func addLifeArea(name: String, emoji: String, colorIndex: Int) {
        let area = LifeArea(
            name: name,
            emoji: emoji,
            goals: [],
            colorIndex: colorIndex
        )
        lifeAreas.append(area)
    }

    /// 更新一个生活领域的基本信息
    func updateLifeArea(id: UUID,
                        name: String,
                        emoji: String,
                        colorIndex: Int) {
        guard let index = lifeAreas.firstIndex(where: { $0.id == id }) else { return }
        lifeAreas[index].name = name
        lifeAreas[index].emoji = emoji
        lifeAreas[index].colorIndex = colorIndex
    }

    /// 删除一个生活领域
    func deleteLifeArea(id: UUID) {
        lifeAreas.removeAll { $0.id == id }
    }

    /// 上移 / 下移 生活领域（给 GoalsView 里的 moveArea 用）
    func moveLifeArea(from offsets: IndexSet, to destination: Int) {
        lifeAreas.move(fromOffsets: offsets, toOffset: destination)
    }

    /// 设置某个生活领域的模式（积分制 / 时间制）
    func setLifeAreaMode(id: UUID, mode: LifeAreaMode) {
        guard let index = lifeAreas.firstIndex(where: { $0.id == id }) else { return }
        lifeAreas[index].mode = mode
    }

    /// 设置某个生活领域的目标小时数（时间制时用）
    func setLifeAreaTargetHours(id: UUID, targetHours: Double?) {
        guard let index = lifeAreas.firstIndex(where: { $0.id == id }) else { return }
        lifeAreas[index].targetHours = targetHours
    }



    // MARK: 目标：增删改查 & 勾选

    // 新增目标
    func addGoal(areaID: UUID,
                 title: String,
                 points: Int,
                 minutes: Int?,
                 useMinutes: Bool) {
        guard let index = lifeAreas.firstIndex(where: { $0.id == areaID }) else { return }

        let goal = Goal(
            title: title,
            points: points,
            minutes: minutes,
            useMinutes: useMinutes
        )

        lifeAreas[index].goals.append(goal)
    // 如果你原来有保存函数，就继续调用
    }

    // 更新目标
    func updateGoal(areaID: UUID,
                    goalID: UUID,
                    title: String,
                    points: Int,
                    minutes: Int?,
                    useMinutes: Bool) {
        guard let areaIndex = lifeAreas.firstIndex(where: { $0.id == areaID }) else { return }
        guard let goalIndex = lifeAreas[areaIndex].goals.firstIndex(where: { $0.id == goalID }) else { return }

        lifeAreas[areaIndex].goals[goalIndex].title = title
        lifeAreas[areaIndex].goals[goalIndex].points = points
        lifeAreas[areaIndex].goals[goalIndex].minutes = minutes
        lifeAreas[areaIndex].goals[goalIndex].useMinutes = useMinutes

  
    }

    // MARK: 目标：增删改查 & 勾选

    /// 计算某个领域本周的积分（把 goals 的 weeklyScore 拿出来）
    func weeklyPoints(for areaID: UUID) -> Int {
        guard let area = lifeAreas.first(where: { $0.id == areaID }) else { return 0 }
        return area.weeklyScore
    }

    // 新增目标
    func addGoal(areaID: UUID,
                 title: String,
                 points: Int,
                 minutes: Int?,
                 useMinutes: Bool,
                 plannedTimesPerWeek: Int) {
        guard let index = lifeAreas.firstIndex(where: { $0.id == areaID }) else { return }

        let goal = Goal(
            title: title,
            points: points,
            minutes: minutes,
            useMinutes: useMinutes,
            plannedTimesPerWeek: max(1, plannedTimesPerWeek),
            doneTimesThisWeek: 0,
            completedThisWeek: false
        )

        lifeAreas[index].goals.append(goal)
    }

    // 更新目标（不动本周已完成次数）
    func updateGoal(areaID: UUID,
                    goalID: UUID,
                    title: String,
                    points: Int,
                    minutes: Int?,
                    useMinutes: Bool,
                    plannedTimesPerWeek: Int) {
        guard let areaIndex = lifeAreas.firstIndex(where: { $0.id == areaID }) else { return }
        guard let goalIndex = lifeAreas[areaIndex].goals.firstIndex(where: { $0.id == goalID }) else { return }

        lifeAreas[areaIndex].goals[goalIndex].title = title
        lifeAreas[areaIndex].goals[goalIndex].points = points
        lifeAreas[areaIndex].goals[goalIndex].minutes = minutes
        lifeAreas[areaIndex].goals[goalIndex].useMinutes = useMinutes
        lifeAreas[areaIndex].goals[goalIndex].plannedTimesPerWeek = max(1, plannedTimesPerWeek)
    }

    /// 删除某个目标
    func deleteGoal(areaID: UUID, goalID: UUID) {
        guard let index = lifeAreas.firstIndex(where: { $0.id == areaID }) else { return }
        lifeAreas[index].deleteGoal(id: goalID)
    }

    /// 本周 +1 次（用于你在 GoalsView 里点「+」或者勾选一次）
    func addOneTimeForGoal(areaID: UUID, goalID: UUID) {
        guard let areaIndex = lifeAreas.firstIndex(where: { $0.id == areaID }) else { return }
        guard let goalIndex = lifeAreas[areaIndex].goals.firstIndex(where: { $0.id == goalID }) else { return }

        var goal = lifeAreas[areaIndex].goals[goalIndex]
        let planned = max(1, goal.plannedTimesPerWeek)
        goal.doneTimesThisWeek = min(planned, goal.doneTimesThisWeek + 1)
        goal.completedThisWeek = (goal.doneTimesThisWeek > 0)

        lifeAreas[areaIndex].goals[goalIndex] = goal
    }

    /// 本周 −1 次（用于 context menu 里的「减去一次」）
    func removeOneTimeForGoal(areaID: UUID, goalID: UUID) {
        guard let areaIndex = lifeAreas.firstIndex(where: { $0.id == areaID }) else { return }
        guard let goalIndex = lifeAreas[areaIndex].goals.firstIndex(where: { $0.id == goalID }) else { return }

        var goal = lifeAreas[areaIndex].goals[goalIndex]
        goal.doneTimesThisWeek = max(0, goal.doneTimesThisWeek - 1)
        goal.completedThisWeek = (goal.doneTimesThisWeek > 0)

        lifeAreas[areaIndex].goals[goalIndex] = goal
    }

    /// 把这个目标「本周次数」清零
    func resetGoalThisWeek(areaID: UUID, goalID: UUID) {
        guard let areaIndex = lifeAreas.firstIndex(where: { $0.id == areaID }) else { return }
        guard let goalIndex = lifeAreas[areaIndex].goals.firstIndex(where: { $0.id == goalID }) else { return }

        lifeAreas[areaIndex].goals[goalIndex].doneTimesThisWeek = 0
        lifeAreas[areaIndex].goals[goalIndex].completedThisWeek = false
    }

    /// 兼容旧逻辑：如果别的地方还在用「点一下整周完成」
    func toggleGoalCompletion(areaID: UUID, goalID: UUID) {
        guard let areaIndex = lifeAreas.firstIndex(where: { $0.id == areaID }) else { return }
        guard let goalIndex = lifeAreas[areaIndex].goals.firstIndex(where: { $0.id == goalID }) else { return }

        var goal = lifeAreas[areaIndex].goals[goalIndex]
        goal.completedThisWeek.toggle()

        if goal.completedThisWeek {
            // 点成「完成」时，至少算 1 次
            goal.doneTimesThisWeek = max(goal.doneTimesThisWeek, 1)
        } else {
            // 取消勾选时，次数清零
            goal.doneTimesThisWeek = 0
        }

        lifeAreas[areaIndex].goals[goalIndex] = goal
    }


    // MARK: - 时间制领域：根据时间块统计「本周累计时间」

    /// 重新根据 `timeBlocks` 计算所有生活领域「本周累计分钟数」
    /// 然后由 LifeArea.accumulatedHours 自动换算成小时显示
    func recalcLifeAreaTimeForThisWeek() {
        let calendar = Calendar.current
        let now = Date()

        // 本周的起止时间（例如从周一 00:00 到下周一 00:00）
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else { return }
        let weekStart = weekInterval.start
        let weekEnd   = weekInterval.end

        // 1️⃣ 先把所有领域的累计分钟数清零
        for i in lifeAreas.indices {
            lifeAreas[i].accumulatedMinutes = 0
        }

        // 2️⃣ 遍历所有时间块，把「落在本周」的按领域累加
        for block in timeBlocks {
            // 必须有绑定的领域
            guard
                let areaId = block.lifeAreaId,
                let areaIndex = lifeAreas.firstIndex(where: { $0.id == areaId })
            else {
                continue
            }

            // 我们用 start 时间来判断是不是本周的时间块
            let start = block.start
            guard start >= weekStart && start < weekEnd else {
                continue
            }

            // 原始分钟数
            let rawMinutes = max(0, Int(block.end.timeIntervalSince(block.start) / 60))

            // 🔸 按 15 分钟为单位做四舍五入（和界面提示保持一致）
            // 例如 7 分钟 → 15，22 分钟 → 30，38 分钟 → 45
            let roundedMinutes = Int((Double(rawMinutes) / 15.0).rounded()) * 15

            lifeAreas[areaIndex].accumulatedMinutes += roundedMinutes
        }
    }
   
    // MARK: - 今日时间块统计（Top3 + Others）

    /// 返回某一天按生活领域分组的用时（Top3 + Others）
    /// 只统计时间块，不统计番茄钟（保持“手账风”轻量感）
    func timeUsageFor(date: Date) -> [LifeAreaTimeUsage] {

        // 1️⃣ 取出这一天的所有时间块
        let blocks = timeBlocks.filter { Calendar.current.isDate($0.start, inSameDayAs: date) }
        guard !blocks.isEmpty else { return [] }

        // 2️⃣ 按领域 ID 累积分钟数
        var usageDict: [UUID: Int] = [:]   // areaID -> minutes

        for block in blocks {
            guard let areaId = block.lifeAreaId else { continue }

            // 🔐 先算时长（秒）
            let duration = block.end.timeIntervalSince(block.start)

            // ① 过滤掉「结束时间 ≤ 开始时间」的脏数据
            if duration <= 0 { continue }

            // ② 再加一道上限保护（比如超过 18 小时就当作异常丢弃）
            if duration > 18 * 60 * 60 {
                continue
            }

            // ③ 换算成分钟，并至少记 1 分钟
            let minutes = max(1, Int(round(duration / 60)))

            usageDict[areaId, default: 0] += minutes
        }


        // 3️⃣ 转成 (area, minutes) 数组
        var rawUsages: [(area: LifeArea, minutes: Int)] = []

        for (id, minutes) in usageDict {
            if let area = lifeAreas.first(where: { $0.id == id }) {
                rawUsages.append((area, minutes))
            }
        }

        guard !rawUsages.isEmpty else { return [] }

        // 4️⃣ 按分钟数排序
        rawUsages.sort { $0.minutes > $1.minutes }

        // 5️⃣ Top3
        let top3 = rawUsages.prefix(3)

        // 6️⃣ Others
        let othersMinutes = rawUsages.dropFirst(3).reduce(0) { $0 + $1.minutes }

        // 7️⃣ 转成 UI 用的 LifeAreaTimeUsage（统一用 LifeArea 的 displayColor）
        var result: [LifeAreaTimeUsage] = top3.map { tuple in
            return LifeAreaTimeUsage(
                name: tuple.area.name,
                minutes: tuple.minutes,
                color: tuple.area.primaryColor   // ← 使用 LifeArea 正宗颜色
            )
        }


        // 8️⃣ 如果还有其他领域，加一条 Others
        if othersMinutes > 0 {
            result.append(
                LifeAreaTimeUsage(
                    name: "Others",
                    minutes: othersMinutes,
                    color: Color.gray.opacity(0.4)
                )
            )
        }

        return result
    }

}   // ⬅️ 保留这一个大括号，结束最外层的 extension AppState
// MARK: - 今日时间统计模型（用于 Journal 页面）

struct LifeAreaTimeUsage: Identifiable {
    let id = UUID()
    let name: String
    let minutes: Int
    let color: Color
}

