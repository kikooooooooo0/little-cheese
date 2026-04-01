import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

// MARK: - View 辅助：收起键盘
extension View {
    func hideKeyboard() {
        #if canImport(UIKit)
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}

// MARK: - LittleCheese Theme Colors



// MARK: - Models
struct TodoItem: Identifiable, Codable, Hashable {
    let id: UUID
    var title: String
    var isDone: Bool

    init(id: UUID = UUID(),
         title: String,
         isDone: Bool = false) {
        self.id = id
        self.title = title
        self.isDone = isDone
    }
}

struct TinyHabit: Identifiable, Codable, Hashable {
    let id: UUID
    /// 触发时刻，例如：「煮鸡蛋的时候」「打开手机的第一刻」
    var trigger: String
    /// 要做的那件小事，例如：「学 1 分钟多邻国」「读一句经济学人」
    var action: String
    /// 每天目标次数（1 = 只需一次，多于 1 = 可以多次）
    var targetCountPerDay: Int
    /// 今天已经完成了几次
    var doneCountToday: Int

    init(
        id: UUID = UUID(),
        trigger: String,
        action: String,
        targetCountPerDay: Int = 1,
        doneCountToday: Int = 0
    ) {
        self.id = id
        self.trigger = trigger
        self.action = action
        self.targetCountPerDay = max(1, targetCountPerDay)
        self.doneCountToday = max(0, doneCountToday)
    }

    /// 是否已经达到今天的目标
    var isDoneToday: Bool {
        doneCountToday >= targetCountPerDay
    }
}
// MARK: - 身体管理模型
enum MealFeeling: String, Codable, CaseIterable {
    case tooMuch = "过饱"
    case perfect = "恰好"
    case light = "清爽"
    case hungry = "没吃饱"
}

// MARK: - 身体管理模型 (升级版)
struct WeightRecord: Identifiable, Codable {
    var id = UUID()
    var date: Date
    var weight: Double
    var didPoop: Bool
    var energyLevel: Double = 3.0
    var exerciseDescription: String = "" // 对应你代码里的 exerciseType
    var hadBreakfast: Bool = false
    var hadLunch: Bool = false
    var hadDinner: Bool = false
    var isIndulgenceDay: Bool = false // 保留这个可爱的功能
}

// MARK: LifeArea START

enum LifeAreaMode: String, Codable {
    case time      // 时间制（用小时/番茄）
    case points    // 积分制
}
// MARK: - Goal（每个生活领域下面的小目标）

struct Goal: Identifiable, Codable {
    let id: UUID

    /// 目标内容，例如「今天吃一份蔬菜」
    var title: String

    /// 积分制：每完成一次拿多少分
    var points: Int

    /// 时间制：每次预计多少分钟（可选）
    var minutes: Int?

    /// true = 用分钟来衡量；false = 用积分来衡量
    var useMinutes: Bool

    /// 本周计划做几次（例如：1 次 / 3 次 / 7 次）
    var plannedTimesPerWeek: Int

    /// 本周已经完成了几次
    var doneTimesThisWeek: Int

    /// 兼容旧逻辑：是否算「本周已完成」
    var completedThisWeek: Bool

    init(
        id: UUID = UUID(),
        title: String,
        points: Int = 5,
        minutes: Int? = nil,
        useMinutes: Bool = false,
        plannedTimesPerWeek: Int = 1,
        doneTimesThisWeek: Int = 0,
        completedThisWeek: Bool = false
    ) {
        self.id = id
        self.title = title
        self.points = points
        self.minutes = minutes
        self.useMinutes = useMinutes
        self.plannedTimesPerWeek = max(1, plannedTimesPerWeek)
        self.doneTimesThisWeek = max(0, doneTimesThisWeek)
        self.completedThisWeek = completedThisWeek
    }
}

// ✅ 就放在新版 Goal 的后面
struct LifeArea: Identifiable, Codable {
    let id: UUID
    var name: String
    var emoji: String

    /// 0,1,2,... 表示选的是第几种颜色
    var colorIndex: Int

    /// 这个领域下面的目标列表
    var goals: [Goal]

    /// 领域模式：积分制 / 时间制
    var mode: LifeAreaMode

    /// （时间制用）本周目标小时数
    var targetHours: Double?

    /// （时间制用）本周累积的分钟数
    var accumulatedMinutes: Int

    /// （可选）这个领域期望的积分
    var targetPoints: Int?

    /// 由「完成次数 × 每次分数」自动计算本周积分
    var weeklyScore: Int {
        goals.reduce(0) { partial, goal in
            partial + goal.doneTimesThisWeek * goal.points
        }
    }


    /// 方便 UI 显示：把分钟换算成小时
    var accumulatedHours: Double {
        Double(accumulatedMinutes) / 60.0
    }

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        goals: [Goal] = [],
        colorIndex: Int = 0,
        mode: LifeAreaMode = .points,
        targetHours: Double? = nil,
        accumulatedMinutes: Int = 0,
        targetPoints: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.goals = goals
        self.colorIndex = colorIndex
        self.mode = mode
        self.targetHours = targetHours
        self.accumulatedMinutes = accumulatedMinutes
        self.targetPoints = targetPoints
    }
}

// MARK: LifeArea END
// MARK: - SOP 饮食清单模型
struct DietSOP: Identifiable, Codable {
    var id = UUID()
    var name: String        // 清单名字，比如“5分钟战斗早餐”
    var emoji: String       // 代表这个食物的图标
    var steps: [String]     // 具体的步骤，比如 ["喝水", "吃鸡蛋"]
    var isCompleted: Bool = false
}

// MARK: - AppState 饮食扩展
extension AppState {
    // 预设几个 ADHD 友好的无脑清单
    static let defaultDietSOPs: [DietSOP] = [
        DietSOP(name: "5分钟战斗早餐", emoji: "🍳", steps: ["喝 200ml 温水", "剥一个白煮蛋", "吃一小把坚果"]),
        DietSOP(name: "脑力充能午餐", emoji: "🍱", steps: ["先吃一份绿叶菜", "补充优质蛋白质", "拍张照记录起司时刻"]),
        DietSOP(name: "深夜救急补给", emoji: "🥛", steps: ["喝一杯热牛奶", "吃半个香蕉", "放下手机"])
    ]
}


// MARK: - 减肥周食谱模型
struct DailyMealPlan: Identifiable, Codable {
    var id = UUID()
    var dayOfWeek: Int // 1 是周日, 2 是周一...
    var breakfast: String = ""
    var lunch: String = ""
    var dinner: String = ""
    
    // 记录今天是否完成了饮食计划
    var breakfastDone: Bool = false
    var lunchDone: Bool = false
    var dinnerDone: Bool = false
    
    var dayName: String {
        let names = ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return names[dayOfWeek]
    }
}

// 收集箱条目：随手丢想法、任务、灵感
struct InboxItem: Identifiable, Hashable, Codable {
    let id: UUID
    var text: String
    var isStarred: Bool
    var createdAt: Date
    
    // ✨ 新增：提醒日期（如果是 nil 表示没设日期）
    var reminderDate: Date?

    init(
        id: UUID = UUID(),
        text: String,
        isStarred: Bool = false,
        createdAt: Date = Date(),
        reminderDate: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.isStarred = isStarred
        self.createdAt = createdAt
        self.reminderDate = reminderDate
    }
}
// MARK: - 年度问答模型 (时间胶囊)
struct YearEndRecord: Identifiable, Codable {
    var id = UUID()
    var year: Int
    var question1: String // 今年最让你大笑的瞬间？
    var question2: String // 现在的你是什么口味的奶酪？
    var question3: String // 给明年自己的暗号？
    var isLocked: Bool = true // 默认锁住
    var createdAt: Date = Date()
}
// MARK: - 时间块（TimeBlock）

struct TimeBlock: Identifiable, Codable {
    let id: UUID
    /// 用 yyyy-MM-dd 存日期，方便按天筛选（和日记 / 照片一样风格）
    var dateString: String
    /// 具体开始 / 结束时间（含小时分钟）
    var start: Date
    var end: Date
    var title: String

    /// 这个时间块属于哪个生活领域（可选）
    var lifeAreaId: UUID?

    init(
        id: UUID = UUID(),
        dateString: String,
        start: Date,
        end: Date,
        title: String,
        lifeAreaId: UUID? = nil
    ) {
        self.id = id
        self.dateString = dateString
        self.start = start
        self.end = end
        self.title = title
        self.lifeAreaId = lifeAreaId
    }
}


// MARK: - JournalEntry（含：今日一句话 oneLine）
import Foundation

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    var dateString: String // yyyy-MM-dd
    
    var recordText: String   // 记录
    var talkText: String     // 聊天
    var maybeText: String    // 也许
    var oneLine: String?     // 今日一句话
    
    // ✨ 新增：联动字段
    var moodEmoji: String?     // 那天的心情，例如 "✨"
    var progressRate: Double?  // 那天的完成百分比，例如 0.85

    // 兼容旧逻辑：合成文本
    var text: String {
        let parts = [
            recordText.trimmingCharacters(in: .whitespacesAndNewlines),
            talkText.trimmingCharacters(in: .whitespacesAndNewlines),
            maybeText.trimmingCharacters(in: .whitespacesAndNewlines)
        ].filter { !$0.isEmpty }
        return parts.joined(separator: "\n\n")
    }

    // 标准初始化
    init(id: UUID = UUID(),
         dateString: String,
         recordText: String = "",
         talkText: String = "",
         maybeText: String = "",
         oneLine: String? = nil,
         moodEmoji: String? = nil,
         progressRate: Double? = nil) {
        self.id = id
        self.dateString = dateString
        self.recordText = recordText
        self.talkText = talkText
        self.maybeText = maybeText
        self.oneLine = oneLine
        self.moodEmoji = moodEmoji
        self.progressRate = progressRate
    }

    // MARK: - Codable 兼容老格式
    private enum CodingKeys: String, CodingKey {
        case id, dateString, recordText, talkText, maybeText, oneLine, moodEmoji, progressRate, text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.dateString = try container.decodeIfPresent(String.self, forKey: .dateString) ?? ""
        
        // 优先读取新格式
        let newRecord = try container.decodeIfPresent(String.self, forKey: .recordText)
        if let nr = newRecord, !nr.isEmpty {
            self.recordText = nr
            self.talkText = try container.decodeIfPresent(String.self, forKey: .talkText) ?? ""
            self.maybeText = try container.decodeIfPresent(String.self, forKey: .maybeText) ?? ""
        } else {
            // 读取旧格式
            self.recordText = try container.decodeIfPresent(String.self, forKey: .text) ?? ""
            self.talkText = ""
            self.maybeText = ""
        }
        
        self.oneLine = try container.decodeIfPresent(String.self, forKey: .oneLine)
        self.moodEmoji = try container.decodeIfPresent(String.self, forKey: .moodEmoji)
        self.progressRate = try container.decodeIfPresent(Double.self, forKey: .progressRate)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(dateString, forKey: .dateString)
        try container.encode(recordText, forKey: .recordText)
        try container.encode(talkText, forKey: .talkText)
        try container.encode(maybeText, forKey: .maybeText)
        try container.encodeIfPresent(oneLine, forKey: .oneLine)
        try container.encodeIfPresent(moodEmoji, forKey: .moodEmoji)
        try container.encodeIfPresent(progressRate, forKey: .progressRate)
    }
}

// A1 START: DailyPhoto 模型（每张照片绑定一天 + 可选标题）
/// 每一张“小起司照片卡片”
struct DailyPhoto: Identifiable, Codable {
    let id: UUID

    /// 和日记一样用 yyyy-MM-dd，这样可以很方便按天查
    var dateString: String

    /// 照片的二进制数据（后面你用 PhotosPicker / 拍照时再填充）
    var imageData: Data

    /// 这张照片自己的小标题（如果为空，将来可以用当日日记的 oneLine 来兜底）
    var caption: String?

    init(
        id: UUID = UUID(),
        dateString: String,
        imageData: Data,
        caption: String? = nil
    ) {
        self.id = id
        self.dateString = dateString
        self.imageData = imageData
        self.caption = caption
    }
}
// A1 END: DailyPhoto 模型

// MARK: - LifeArea Mutating Helpers

extension LifeArea {
    mutating func addGoal(title: String, points: Int) {
        let newGoal = Goal(title: title, points: points)
        goals.append(newGoal)
    }

    mutating func deleteGoal(id: UUID) {
        goals.removeAll { $0.id == id }
    }

    mutating func toggleGoalCompletion(id: UUID) {
        if let index = goals.firstIndex(where: { $0.id == id }) {
            goals[index].completedThisWeek.toggle()
        }
    }
    mutating func resetWeeklyCompletion() {
        for i in goals.indices {
            goals[i].doneTimesThisWeek = 0
            goals[i].completedThisWeek = false
        }
    }

}

// MARK: - App State
// MARK: - 番茄钟阶段（Phase）

enum PomodoroPhase: String, Codable {
    case idle        // 没在计时
    case focus       // 专注中
    case shortBreak  // 短休息
    case longBreak   // 长休息
}


class AppState: ObservableObject {
    private let weightKey        = "LittleCheese.weightRecords"
    // 持久化 Key
    private let todayKey         = "LittleCheese.todayTasks"
    private let lifeAreasKey     = "LittleCheese.lifeAreas"
    private let journalKey       = "LittleCheese.journalEntries"
    private let lastDateKey      = "LittleCheese.lastDate"
    private let tinyHabitsKey    = "LittleCheese.tinyHabits"
    private let inboxKey         = "LittleCheese.inboxItems"
    private let futurePhrasesKey = "LittleCheese.futurePhrases"
    // A2 START: 照片持久化 key
    private let photosKey        = "LittleCheese.dailyPhotos"
    // A2 END
    // ⭐️ 时间块持久化 key
    private let timeBlocksKey    = "LittleCheese.timeBlocks"

    func entry(for dateString: String) -> JournalEntry? {
        journalEntries.first(where: { $0.dateString == dateString })
    }
    // 减肥食谱数据
        @Published var weeklyMealPlans: [DailyMealPlan] = [] {
            didSet {
                if let data = try? JSONEncoder().encode(weeklyMealPlans) {
                    UserDefaults.standard.set(data, forKey: "LittleCheese.mealPlans")
                }
            }
        }

        // 获取今天的食谱
        var todayMealPlan: DailyMealPlan? {
            let weekday = Calendar.current.component(.weekday, from: Date())
            return weeklyMealPlans.first(where: { $0.dayOfWeek == weekday })
        }
    // 对外数据：体重记录
        @Published var weightRecords: [WeightRecord] = [] {
            didSet { saveWeightRecords() }
        }
    // 对外数据：Tiny Habits（小锚点）
    @Published var tinyHabits: [TinyHabit] = [] {
        didSet { saveTinyHabits() }
    }

    // 对外数据：Today 任务
    @Published var todayTasks: [TodoItem] = [] {
        didSet { saveTodayTasks() }
    }
    // ✨ 新增：今日快照心情（保存表情符号）
        @Published var todayMoodEmoji: String = UserDefaults.standard.string(forKey: "LittleCheese.todayMood") ?? "🧀" {
            didSet { UserDefaults.standard.set(todayMoodEmoji, forKey: "LittleCheese.todayMood") }
        }
    // 对外数据：生活领域 & 目标
    @Published var lifeAreas: [LifeArea] = [] {
        didSet { saveLifeAreas() }
    }

    // 对外数据：日记
    @Published var journalEntries: [JournalEntry] = [] {
        
        didSet { saveJournals() }
        
    }
    // MARK: - 更新日记条目（给详情页编辑用）
    func updateJournalEntry(_ newEntry: JournalEntry) {
        guard let index = journalEntries.firstIndex(where: { $0.id == newEntry.id }) else {
            return
        }
        journalEntries[index] = newEntry
    }
    // MARK: - 时间块数据

    @Published var timeBlocks: [TimeBlock] = [] {
        didSet { saveTimeBlocks() }
    }

    // MARK: - 番茄钟（全局计时器）

    /// 当前番茄钟阶段
    @Published var pomodoroPhase: PomodoroPhase = .idle

    /// 剩余秒数（比如 25 分钟就是 25 * 60）
    @Published var pomodoroRemainingSeconds: Int = 0

    /// 是否在计时
    @Published var isPomodoroRunning: Bool = false

    /// 这一轮预设的总秒数（用于进度条 / 进度条百分比）
    @Published var pomodoroTotalSeconds: Int = 0

    /// 计时器本体（只在 AppState 里持有）
    private var pomodoroTimer: Timer?

    /// 开始一轮番茄钟
    /// 开始一轮新的番茄钟
    func startPomodoro(
        minutes: Int,
        lifeAreaId: UUID?,
        note: String,
        phase: PomodoroPhase   // ← 这里改成这个
    ) {

        // 如果正在跑，就不重复开始
        guard !isPomodoroRunning else { return }

        // 防止传 0 或负数
        let clampedMinutes = max(1, minutes)
        let total = clampedMinutes * 60

        // ⭐ 时间锚点：开始 & 结束
        let now = Date()
        pomodoroStart = now
        pomodoroEndTime = now.addingTimeInterval(TimeInterval(total))

        // 保存这轮的元数据
        pomodoroPhase = phase
        pomodoroDurationMinutes = clampedMinutes
        pomodoroRemainingSeconds = total
        pomodoroTotalSeconds = total
        pomodoroLifeAreaId = lifeAreaId
        pomodoroNote = note
        isPomodoroRunning = true

        // 停掉旧的 Timer
        pomodoroTimer?.invalidate()

        // 创建新的 Timer：每秒根据「当前时间」刷新，而不是 -1
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else {
                t.invalidate()
                return
            }

            // 用当前时间 + endTime 算剩余
            self.updatePomodoroRemainingIfNeeded()

            // 如果已经结束 / 停止了，就把 timer 关掉
            if !self.isPomodoroRunning {
                t.invalidate()
                self.pomodoroTimer = nil
            }
        }

        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        pomodoroTimer = timer
    }

    /// 根据当前时间刷新剩余秒数（支持熄屏后“补上时间”）
    func updatePomodoroRemainingIfNeeded() {
        guard isPomodoroRunning,
              let end = pomodoroEndTime else {
            return
        }

        let remaining = Int(end.timeIntervalSinceNow)
        pomodoroRemainingSeconds = max(0, remaining)

        // ⏰ 时间到了
        if remaining <= 0 {
            isPomodoroRunning = false
            pomodoroPhase = .idle
            pomodoroRemainingSeconds = 0

            pomodoroTimer?.invalidate()
            pomodoroTimer = nil

            // 用你原来的逻辑生成时间块 / 记分
            finishPomodoro()
        }
    }

    /// 暂停（不清零倒计时数字，只是停表）
    func pausePomodoro() {
        guard isPomodoroRunning else { return }
        isPomodoroRunning = false
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        // 注意：不清空 pomodoroStart / pomodoroEndTime / 剩余秒数
        // 将来如果你想做“继续”，还能利用这些信息
    }

    /// 彻底停止并清空这一轮（不会生成时间块）
    func stopPomodoro() {
        isPomodoroRunning = false
        pomodoroPhase = .idle
        pomodoroRemainingSeconds = 0
        pomodoroTotalSeconds = 0

        pomodoroTimer?.invalidate()
        pomodoroTimer = nil

        // 清空这轮元数据
        pomodoroStart = nil
        pomodoroEndTime = nil
        pomodoroLifeAreaId = nil
        pomodoroNote = ""
    }
    // 年度问答存储
        @Published var yearEndRecords: [YearEndRecord] = [] {
            didSet { saveYearEndRecords() }
        }
        
        // 保存函数
        private func saveYearEndRecords() {
            if let data = try? JSONEncoder().encode(yearEndRecords) {
                UserDefaults.standard.set(data, forKey: "LittleCheese.yearEndRecords")
            }
        }

        // ✨ 铁律：检查今天是不是 12 月 31 日
        func isYearEndFestival() -> Bool {
            let components = Calendar.current.dateComponents([.month, .day], from: Date())
            return components.month == 12 && components.day == 31
        }


    // MARK: - 番茄钟状态（只在内存里用，不做持久化）
    @Published var pomodoroStart: Date?               // 本轮番茄开始时间
    @Published var pomodoroEndTime: Date?             // 本轮番茄预计结束时间（新）
    @Published var pomodoroLifeAreaId: UUID?
    @Published var pomodoroDurationMinutes: Int = 25
    @Published var pomodoroNote: String = ""          // 这一轮番茄的备注




    // 对外数据：收集箱（大脑随手丢东西的地方）
    @Published var inboxItems: [InboxItem] = [] {
        didSet { saveInboxItems() }
    }

    // 对外数据：未来温柔话语（“未来的我想说”）
    @Published var futurePhrases: [String] = [] {
        didSet { saveFuturePhrases() }
    }
    // A3 START: 每日照片（以后照片墙 / 日历都会用到）
    @Published var dailyPhotos: [DailyPhoto] = [] {
        didSet { saveDailyPhotos() }
    }
    // A3 END
    

    // 日期格式
    static let df: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    // 默认 Today 任务
    static let defaultTodayTasks: [TodoItem] = [
        TodoItem(title: "为自己做一顿好吃的早餐"),
        TodoItem(title: "学习 20 分钟英语 / LSAT"),
        TodoItem(title: "整理 10 分钟房间")
    ]

    // 默认 Life Areas + Goals
    static let defaultLifeAreas: [LifeArea] = [
        LifeArea(
            name: "健康",
            emoji: "🥦",
            goals: [
                Goal(title: "今天吃一份蔬菜", points: 5),
                Goal(title: "不喝含糖饮料", points: 5),
                Goal(title: "走路 10 分钟", points: 3)
            ]
        ),
        LifeArea(
            name: "英语",
            emoji: "📺",
            goals: [
                Goal(title: "看 20 分钟英语美剧", points: 5),
                Goal(title: "跟读 10 句台词", points: 8)
            ]
        )
    ]

    /// 默认 Tiny Habits 小锚点
    static let defaultTinyHabits: [TinyHabit] = [
        TinyHabit(
            trigger: "煮鸡蛋的时候",
            action: "打开多邻国学 1 分钟",
            targetCountPerDay: 1
        ),
        TinyHabit(
            trigger: "打开手机的第一刻",
            action: "读一句英语",
            targetCountPerDay: 1
        ),
        TinyHabit(
            trigger: "坐下来准备工作时",
            action: "深呼吸三次",
            targetCountPerDay: 1
        )
    ]

    /// 默认的未来温柔话语
    static let defaultFuturePhrases: [String] = [
        "慢慢来，你已经很好了。",
        "我看到你了。",
        "你已经走了很远，我为你骄傲。",
        "进来吧，外面风有点大。",
        "今天能写到这里，就已经很不容易了。",
        "你不是一个人，我在你这边。"
    ]

    // MARK: - 初始化

    init() {
        loadAll()
    }

    // MARK: - 加载 & 日期处理

    private func loadAll() {
        let defaults = UserDefaults.standard
        let todayString = Self.df.string(from: Date())
        let lastDate = defaults.string(forKey: lastDateKey)
        // 每次启动 App 都检查一下有没有到期的灵光
                checkScheduledInboxItems()
        // Life Areas
        if let data = defaults.data(forKey: lifeAreasKey),
           let decoded = try? JSONDecoder().decode([LifeArea].self, from: data) {
            self.lifeAreas = decoded
        } else {
            self.lifeAreas = Self.defaultLifeAreas
        }

        // Tiny Habits
        if let data = defaults.data(forKey: tinyHabitsKey),
           let decoded = try? JSONDecoder().decode([TinyHabit].self, from: data) {
            self.tinyHabits = decoded
        } else {
            self.tinyHabits = Self.defaultTinyHabits
        }

        // Today Tasks
        if let data = defaults.data(forKey: todayKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            self.todayTasks = decoded
        } else {
            self.todayTasks = Self.defaultTodayTasks
        }

        // Journals
        if let data = defaults.data(forKey: journalKey),
           let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            self.journalEntries = decoded
        } else {
            self.journalEntries = []
        }
        // 加载食谱，如果没有，初始化 7 天
                if let data = defaults.data(forKey: "LittleCheese.mealPlans"),
                   let decoded = try? JSONDecoder().decode([DailyMealPlan].self, from: data) {
                    self.weeklyMealPlans = decoded
                } else {
                    // 初始化默认计划
                    self.weeklyMealPlans = (1...7).map { DailyMealPlan(dayOfWeek: $0) }
                }

                // A4 START: Daily Photos (这是你文件里原本就有的代码，接在下面即可)
                if let data = defaults.data(forKey: photosKey),
                   let decoded = try? JSONDecoder().decode([DailyPhoto].self, from: data) {
                    self.dailyPhotos = decoded
                }
        // A4 START: Daily Photos
        if let data = defaults.data(forKey: photosKey),
           let decoded = try? JSONDecoder().decode([DailyPhoto].self, from: data) {
            self.dailyPhotos = decoded
        } else {
            self.dailyPhotos = []
        }
        // A4 END: Daily Photos
        // Weight Records 加载
                if let data = defaults.data(forKey: weightKey),
                   let decoded = try? JSONDecoder().decode([WeightRecord].self, from: data) {
                    self.weightRecords = decoded
                }
        // Inbox
        if let data = defaults.data(forKey: inboxKey),
           let decoded = try? JSONDecoder().decode([InboxItem].self, from: data) {
            self.inboxItems = decoded
        } else {
            self.inboxItems = []
        }

        // Future Phrases
        if let data = defaults.data(forKey: futurePhrasesKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.futurePhrases = decoded
        } else {
            self.futurePhrases = Self.defaultFuturePhrases
        }
        // ⭐️ Time Blocks（时间块）
        if let data = defaults.data(forKey: timeBlocksKey),
           let decoded = try? JSONDecoder().decode([TimeBlock].self, from: data) {
            self.timeBlocks = decoded
        } else {
            self.timeBlocks = []   // 第一次使用
        }

        // 如果是新的一天
        if lastDate != todayString {
            handleNewDay(previousDateString: lastDate, todayString: todayString)
        }

        // 记录今天
        defaults.set(todayString, forKey: lastDateKey)
    }

    private func handleNewDay(previousDateString: String?, todayString: String) {
        // 1）重置 Today 任务
        self.todayTasks = Self.defaultTodayTasks

        // 2）重置 Tiny Habits 计数
        resetTinyHabitsForNewDay()

        // 3）如果跨周，重置 weekly
        if let prev = previousDateString,
           let prevDate = Self.df.date(from: prev),
           let todayDate = Self.df.date(from: todayString) {

            let cal = Calendar.current
            let prevWeek = cal.component(.weekOfYear, from: prevDate)
            let prevYear = cal.component(.yearForWeekOfYear, from: prevDate)
            let thisWeek = cal.component(.weekOfYear, from: todayDate)
            let thisYear = cal.component(.yearForWeekOfYear, from: todayDate)

            if prevWeek != thisWeek || prevYear != thisYear {
                resetWeeklyGoals()
            }
        } else {
            resetWeeklyGoals()
        }
    }

    private func resetWeeklyGoals() {
        for i in lifeAreas.indices {
            lifeAreas[i].resetWeeklyCompletion()
        }
    }

    private func resetTinyHabitsForNewDay() {
        for i in tinyHabits.indices {
            tinyHabits[i].doneCountToday = 0
        }
    }

    // MARK: - 持久化

    private func saveTodayTasks() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(todayTasks) {
            UserDefaults.standard.set(data, forKey: todayKey)
        }
    }

    private func saveLifeAreas() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(lifeAreas) {
            UserDefaults.standard.set(data, forKey: lifeAreasKey)
        }
    }

    private func saveJournals() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(journalEntries) {
            UserDefaults.standard.set(data, forKey: journalKey)
        }
    }

    private func saveFuturePhrases() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(futurePhrases) {
            UserDefaults.standard.set(data, forKey: futurePhrasesKey)
        }
    }

    private func saveTinyHabits() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(tinyHabits) {
            UserDefaults.standard.set(data, forKey: tinyHabitsKey)
        }
    }

    private func saveInboxItems() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(inboxItems) {
            UserDefaults.standard.set(data, forKey: inboxKey)
        }
    }
    private func saveWeightRecords() {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(weightRecords) {
                UserDefaults.standard.set(data, forKey: weightKey)
            }
        }
    // 删除一条体重记录
        func deleteWeightRecord(id: UUID) {
            weightRecords.removeAll { $0.id == id }
        }
    // 删除一条今日任务
        func deleteTodayTask(id: UUID) {
            todayTasks.removeAll { $0.id == id }
        }
    // A5 START: 保存每日照片
    private func saveDailyPhotos() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(dailyPhotos) {
            UserDefaults.standard.set(data, forKey: photosKey)
        }
    }
    // ✨ 核心联动函数：把当下的状态搬运进日记模型
        func syncTodayStatusToJournal(mood: String, progress: Double) {
            let todayStr = Self.df.string(from: Date())
            
            if let idx = journalEntries.firstIndex(where: { $0.dateString == todayStr }) {
                // 如果今天已经有日记了，更新它
                journalEntries[idx].moodEmoji = mood
                journalEntries[idx].progressRate = progress
            } else {
                // 如果今天还没写日记，先帮用户建一个带心情的“空壳”
                let newEntry = JournalEntry(dateString: todayStr, moodEmoji: mood, progressRate: progress)
                journalEntries.append(newEntry)
            }
        }
    // MARK: - 保存时间块
    private func saveTimeBlocks() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(timeBlocks) {
            UserDefaults.standard.set(data, forKey: timeBlocksKey)
        }
    }

    // A5 END


    // MARK: - Today 任务操作

    func addTodayTask(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = TodoItem(title: trimmed)
        todayTasks.append(item)
    }

    func deleteTodayTask(at offsets: IndexSet) {
        todayTasks.remove(atOffsets: offsets)
    }



    func toggleTodo(id: UUID) {
        if let idx = todayTasks.firstIndex(where: { $0.id == id }) {
            todayTasks[idx].isDone.toggle()
        }
    }


    func updateTodayTask(id: UUID, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let index = todayTasks.firstIndex(where: { $0.id == id }) {
            todayTasks[index].title = trimmed
        }
    }

    
    // MARK: - Tiny Habits 操作

    func addTinyHabit(trigger: String, action: String, targetCountPerDay: Int) {
        let t = trigger.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = action.trimmingCharacters(in: .whitespacesAndNewlines)
        let count = max(1, targetCountPerDay)
        guard !t.isEmpty, !a.isEmpty else { return }
        let habit = TinyHabit(trigger: t, action: a, targetCountPerDay: count)
        tinyHabits.append(habit)
    }

    func updateTinyHabit(id: UUID, trigger: String, action: String, targetCountPerDay: Int) {
        let t = trigger.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = action.trimmingCharacters(in: .whitespacesAndNewlines)
        let count = max(1, targetCountPerDay)
        guard !t.isEmpty, !a.isEmpty else { return }

        if let index = tinyHabits.firstIndex(where: { $0.id == id }) {
            tinyHabits[index].trigger = t
            tinyHabits[index].action  = a
            tinyHabits[index].targetCountPerDay = count
            if tinyHabits[index].doneCountToday > count {
                tinyHabits[index].doneCountToday = count
            }
        }
    }

    func toggleTinyHabit(id: UUID) {
        guard let index = tinyHabits.firstIndex(where: { $0.id == id }) else { return }
        var habit = tinyHabits[index]

        if habit.targetCountPerDay <= 1 {
            habit.doneCountToday = (habit.doneCountToday == 0) ? 1 : 0
        } else {
            if habit.doneCountToday < habit.targetCountPerDay {
                habit.doneCountToday += 1
            } else {
                habit.doneCountToday = habit.targetCountPerDay
            }
        }

        tinyHabits[index] = habit
    }

    func deleteTinyHabit(id: UUID) {
        tinyHabits.removeAll { $0.id == id }
    }

    // MARK: - 时间块操作

    /// 某一天的时间块（按开始时间排序）
    func timeBlocks(for date: Date) -> [TimeBlock] {
        let ds = Self.df.string(from: date)
        return timeBlocks
            .filter { $0.dateString == ds }
            .sorted { $0.start < $1.start }
    }

    /// 为某一天添加一个时间块（允许任意开始 / 结束时间）
    func addTimeBlock(
        for date: Date,
        start: Date,
        end: Date,
        title: String,
        lifeAreaId: UUID? = nil
    ) {
        let ds = Self.df.string(from: date)

        // 如果用户不小心把开始 / 结束颠倒了，这里自动纠正
        let realStart = min(start, end)
        let realEnd = max(start, end)

        let trimmedTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let finalTitle = trimmedTitle.isEmpty ? "未命名时间块" : trimmedTitle

        let block = TimeBlock(
            dateString: ds,
            start: realStart,
            end: realEnd,
            title: finalTitle,
            lifeAreaId: lifeAreaId
        )
        timeBlocks.append(block)

        // ✅ 每次新增时间块后，重新统计一次「本周各领域的累计时间」
        recalcLifeAreaTimeForThisWeek()
    }

    /// 番茄钟结束：根据开始时间自动生成一个时间块（带备注）
    func finishPomodoro() {
        // 必须有开始时间，才能计算结束时间
        guard let start = pomodoroStart else { return }

        let minutes = pomodoroDurationMinutes
        let end = start.addingTimeInterval(TimeInterval(minutes * 60))

        // 1️⃣ 基础标题：看有没有绑定某个 LifeArea
        let baseTitle: String
        if let areaId = pomodoroLifeAreaId,
           let area = lifeAreas.first(where: { $0.id == areaId }) {
            baseTitle = "\(area.emoji) \(area.name) · 番茄钟"
        } else {
            baseTitle = "番茄钟专注"
        }

        // 2️⃣ 把备注拼接进去（如果有的话）
        let notePart = pomodoroNote
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let finalTitle: String
        if notePart.isEmpty {
            finalTitle = baseTitle
        } else {
            // 例如：🥦 健康 · 番茄钟 — 读完 Barkley 第 3 章
            finalTitle = "\(baseTitle) — \(notePart)"
        }

        // 3️⃣ 调用 addTimeBlock，真正生成一块时间砖
        addTimeBlock(
            for: start,
            start: start,
            end: end,
            title: finalTitle,
            lifeAreaId: pomodoroLifeAreaId
        )

        // 4️⃣ 清空番茄状态，准备下一轮
        pomodoroStart = nil
        pomodoroLifeAreaId = nil
        pomodoroNote = ""
    }

    /// 删除一个时间块
    func deleteTimeBlock(id: UUID) {
        timeBlocks.removeAll { $0.id == id }

        // ✅ 删除后也重新统计一次
        recalcLifeAreaTimeForThisWeek()
    }





    // MARK: - Journal 操作（含 oneLine）

    func journal(for date: Date) -> JournalEntry? {
        let ds = Self.df.string(from: date)
        return journalEntries.first { $0.dateString == ds }
    }

    func journalText(for date: Date) -> String {
        journal(for: date)?.text ?? ""
    }

    func upsertJournal(for date: Date, text: String, oneLine: String? = nil) {
        let ds = Self.df.string(from: date)
        if let idx = journalEntries.firstIndex(where: { $0.dateString == ds }) {
            // 已经有这一天的日记 → 更新内容
            journalEntries[idx].recordText = text
            journalEntries[idx].oneLine = oneLine
        } else {
            let entry = JournalEntry(
                dateString: ds,
                recordText: text,
                talkText: "",
                maybeText: "",
                oneLine: oneLine
            )
            journalEntries.append(entry)
        }

    }

    func updateJournal(for date: Date, text: String, oneLine: String? = nil) {
        upsertJournal(for: date, text: text, oneLine: oneLine)
    }

    func deleteJournal(id: UUID) {
        journalEntries.removeAll { $0.id == id }
    }

    // MARK: - Future Phrases 操作

    func addFuturePhrase(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !futurePhrases.contains(trimmed) {
            futurePhrases.append(trimmed)
        }
    }

    // MARK: - Inbox 操作

        // ✨ 升级版：支持传入日期
        func addInboxItem(text: String, date: Date? = nil) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            
            let item = InboxItem(text: trimmed, reminderDate: date)
            // 新增的放在最上面
            inboxItems.insert(item, at: 0)
        }

        func toggleInboxStar(id: UUID) {
            if let index = inboxItems.firstIndex(where: { $0.id == id }) {
                inboxItems[index].isStarred.toggle()
            }
        }

        func deleteInboxItem(id: UUID) {
            inboxItems.removeAll { $0.id == id }
        }

        func moveInboxItemToToday(id: UUID) {
            guard let item = inboxItems.first(where: { $0.id == id }) else { return }
            // 允许 Today 超过 3 个吗？手动移动的我们宽松一点，或者你也可以保留限制
            addTodayTask(title: item.text)
            deleteInboxItem(id: id)
        }

        // ✨ 魔法函数：检查有没有“到期”的灵光，自动搬运到今天
        func checkScheduledInboxItems() {
            let todayStart = Calendar.current.startOfDay(for: Date())
            
            // 找到所有“有日期”且“日期 <= 今天”的灵光
            let dueItems = inboxItems.filter { item in
                guard let date = item.reminderDate else { return false }
                // 只要是今天或之前的（防止漏掉昨天的），都算到期
                return Calendar.current.startOfDay(for: date) <= todayStart
            }
            
            guard !dueItems.isEmpty else { return }
            
            // 执行搬运
            for item in dueItems {
                // 1. 加到 Today
                addTodayTask(title: item.text)
                // 2. 从 Inbox 删掉
                deleteInboxItem(id: item.id)
            }
            
            print("🧀 自动搬运了 \(dueItems.count) 个到期的灵光到今天！")
        }

    // A6 START: Daily Photos 操作
    /// 某一天所有照片（给日历 / 照片墙用）
    func photos(for date: Date) -> [DailyPhoto] {
        let ds = Self.df.string(from: date)
        return dailyPhotos.filter { $0.dateString == ds }
    }

    /// 根据 dateString 取照片（比如从日历那边已经有字符串）
    func photos(forDateString ds: String) -> [DailyPhoto] {
        return dailyPhotos.filter { $0.dateString == ds }
    }

    /// 新增一张照片（后面你从 PhotosPicker 拿到 Data 后，直接丢进来）
    func addPhoto(for date: Date, imageData: Data, caption: String? = nil) {
        let ds = Self.df.string(from: date)
        let photo = DailyPhoto(dateString: ds, imageData: imageData, caption: caption)
        dailyPhotos.append(photo)
    }

    /// 修改一张照片的标题（不动图片本身）
    func updatePhotoCaption(id: UUID, caption: String?) {
        guard let index = dailyPhotos.firstIndex(where: { $0.id == id }) else { return }
        dailyPhotos[index].caption = caption
    }

    /// 删除一张照片
    func deletePhoto(id: UUID) {
        dailyPhotos.removeAll { $0.id == id }
    }
    // A6 END: Daily Photos 操作
}

//  AppModelsAndState.swift
//  little cheese
//
//  Created by jdjdind dhdjkd on 2025-11-30.
//

