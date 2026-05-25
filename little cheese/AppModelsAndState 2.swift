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
    var exerciseDescription: String = ""
    var hadBreakfast: Bool = false
    var hadLunch: Bool = false
    var hadDinner: Bool = false
    var isIndulgenceDay: Bool = false
    var dinnerQuality: DinnerQuality? = nil
}

// MARK: LifeArea START

enum LifeAreaMode: String, Codable {
    case time      // 时间制（用小时/番茄）
    case points    // 积分制
}

// MARK: - Goal（每个生活领域下面的小目标）
struct Goal: Identifiable, Codable {
    let id: UUID
    var title: String
    var points: Int
    var minutes: Int?
    var useMinutes: Bool
    var plannedTimesPerWeek: Int
    var doneTimesThisWeek: Int
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

struct LifeArea: Identifiable, Codable {
    let id: UUID
    var name: String
    var emoji: String
    var colorIndex: Int
    var goals: [Goal]
    var mode: LifeAreaMode
    var targetHours: Double?
    var accumulatedMinutes: Int
    var targetPoints: Int?

    var weeklyScore: Int {
        goals.reduce(0) { partial, goal in
            partial + goal.doneTimesThisWeek * goal.points
        }
    }

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
    
    var breakfastDone: Bool = false
    var lunchDone: Bool = false
    var dinnerDone: Bool = false
    
    var dayName: String {
        let names = ["", "周日", "周一", "周二", "周三", "周四", "周五", "周六"]
        return names[dayOfWeek]
    }
}

struct InboxItem: Identifiable, Hashable, Codable {
    let id: UUID
    var text: String
    var isStarred: Bool
    var createdAt: Date
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
    var question1: String
    var question2: String
    var question3: String
    var isLocked: Bool = true
    var createdAt: Date = Date()
}

// MARK: - 时间块（TimeBlock）
struct TimeBlock: Identifiable, Codable {
    let id: UUID
    var dateString: String
    var start: Date
    var end: Date
    var title: String
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

// MARK: - JournalEntry
import Foundation

struct JournalEntry: Identifiable, Codable {
    let id: UUID
    var dateString: String
    
    var recordText: String
    var talkText: String
    var maybeText: String
    var oneLine: String?
    
    var moodEmoji: String?
    var progressRate: Double?

    var text: String {
        let parts = [
            recordText.trimmingCharacters(in: .whitespacesAndNewlines),
            talkText.trimmingCharacters(in: .whitespacesAndNewlines),
            maybeText.trimmingCharacters(in: .whitespacesAndNewlines)
        ].filter { !$0.isEmpty }
        return parts.joined(separator: "\n\n")
    }

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

    private enum CodingKeys: String, CodingKey {
        case id, dateString, recordText, talkText, maybeText, oneLine, moodEmoji, progressRate, text
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.dateString = try container.decodeIfPresent(String.self, forKey: .dateString) ?? ""
        
        let newRecord = try container.decodeIfPresent(String.self, forKey: .recordText)
        if let nr = newRecord, !nr.isEmpty {
            self.recordText = nr
            self.talkText = try container.decodeIfPresent(String.self, forKey: .talkText) ?? ""
            self.maybeText = try container.decodeIfPresent(String.self, forKey: .maybeText) ?? ""
        } else {
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

// A1 START: DailyPhoto 模型
struct DailyPhoto: Identifiable, Codable {
    let id: UUID
    var dateString: String
    var imageData: Data
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

// MARK: - 番茄钟阶段
enum PomodoroPhase: String, Codable {
    case idle
    case focus
    case shortBreak
    case longBreak
}

// MARK: - App State (全局数据中枢)
class AppState: ObservableObject {
    
    // ✨ 新增：今日三餐完成状态（这就是为什么主页会报错的原因，之前丢了！）
    @Published var isBreakfastDone: Bool = UserDefaults.standard.bool(forKey: "lc_isBreakfastDone") { didSet { UserDefaults.standard.set(isBreakfastDone, forKey: "lc_isBreakfastDone") } }
    @Published var isLunchDone: Bool = UserDefaults.standard.bool(forKey: "lc_isLunchDone") { didSet { UserDefaults.standard.set(isLunchDone, forKey: "lc_isLunchDone") } }
    @Published var isDinnerDone: Bool = UserDefaults.standard.bool(forKey: "lc_isDinnerDone") { didSet { UserDefaults.standard.set(isDinnerDone, forKey: "lc_isDinnerDone") } }

    private let weightKey        = "LittleCheese.weightRecords"
    private let todayKey         = "LittleCheese.todayTasks"
    private let lifeAreasKey     = "LittleCheese.lifeAreas"
    private let journalKey       = "LittleCheese.journalEntries"
    private let lastDateKey      = "LittleCheese.lastDate"
    private let tinyHabitsKey    = "LittleCheese.tinyHabits"
    private let inboxKey         = "LittleCheese.inboxItems"
    private let futurePhrasesKey = "LittleCheese.futurePhrases"
    private let photosKey        = "LittleCheese.dailyPhotos"
    private let timeBlocksKey    = "LittleCheese.timeBlocks"

    func entry(for dateString: String) -> JournalEntry? {
        journalEntries.first(where: { $0.dateString == dateString })
    }
    
    @Published var weeklyMealPlans: [DailyMealPlan] = [] {
        didSet {
            if let data = try? JSONEncoder().encode(weeklyMealPlans) {
                UserDefaults.standard.set(data, forKey: "LittleCheese.mealPlans")
            }
        }
    }

    var todayMealPlan: DailyMealPlan? {
        let weekday = Calendar.current.component(.weekday, from: Date())
        return weeklyMealPlans.first(where: { $0.dayOfWeek == weekday })
    }
    
    @Published var weightRecords: [WeightRecord] = [] {
        didSet { saveWeightRecords() }
    }
    
    @Published var tinyHabits: [TinyHabit] = [] {
        didSet { saveTinyHabits() }
    }

    @Published var todayTasks: [TodoItem] = [] {
        didSet { saveTodayTasks() }
    }
    
    @Published var todayMoodEmoji: String = UserDefaults.standard.string(forKey: "LittleCheese.todayMood") ?? "🧀" {
        didSet { UserDefaults.standard.set(todayMoodEmoji, forKey: "LittleCheese.todayMood") }
    }
    
    @Published var lifeAreas: [LifeArea] = [] {
        didSet { saveLifeAreas() }
    }

    @Published var journalEntries: [JournalEntry] = [] {
        didSet { saveJournals() }
    }
    
    func updateJournalEntry(_ newEntry: JournalEntry) {
        guard let index = journalEntries.firstIndex(where: { $0.id == newEntry.id }) else {
            return
        }
        journalEntries[index] = newEntry
    }

    @Published var timeBlocks: [TimeBlock] = [] {
        didSet { saveTimeBlocks() }
    }

    @Published var pomodoroPhase: PomodoroPhase = .idle
    @Published var pomodoroRemainingSeconds: Int = 0
    @Published var isPomodoroRunning: Bool = false
    @Published var pomodoroTotalSeconds: Int = 0
    private var pomodoroTimer: Timer?

    func startPomodoro(
        minutes: Int,
        lifeAreaId: UUID?,
        note: String,
        phase: PomodoroPhase
    ) {
        guard !isPomodoroRunning else { return }

        let clampedMinutes = max(1, minutes)
        let total = clampedMinutes * 60

        let now = Date()
        pomodoroStart = now
        pomodoroEndTime = now.addingTimeInterval(TimeInterval(total))

        pomodoroPhase = phase
        pomodoroDurationMinutes = clampedMinutes
        pomodoroRemainingSeconds = total
        pomodoroTotalSeconds = total
        pomodoroLifeAreaId = lifeAreaId
        pomodoroNote = note
        isPomodoroRunning = true

        pomodoroTimer?.invalidate()

        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] t in
            guard let self = self else {
                t.invalidate()
                return
            }
            self.updatePomodoroRemainingIfNeeded()
            if !self.isPomodoroRunning {
                t.invalidate()
                self.pomodoroTimer = nil
            }
        }
        timer.tolerance = 0.2
        RunLoop.main.add(timer, forMode: .common)
        pomodoroTimer = timer
    }

    func updatePomodoroRemainingIfNeeded() {
        guard isPomodoroRunning,
              let end = pomodoroEndTime else {
            return
        }

        let remaining = Int(end.timeIntervalSinceNow)
        pomodoroRemainingSeconds = max(0, remaining)

        if remaining <= 0 {
            isPomodoroRunning = false
            pomodoroPhase = .idle
            pomodoroRemainingSeconds = 0
            pomodoroTimer?.invalidate()
            pomodoroTimer = nil
            finishPomodoro()
        }
    }

    func pausePomodoro() {
        guard isPomodoroRunning else { return }
        isPomodoroRunning = false
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
    }

    func stopPomodoro() {
        isPomodoroRunning = false
        pomodoroPhase = .idle
        pomodoroRemainingSeconds = 0
        pomodoroTotalSeconds = 0
        pomodoroTimer?.invalidate()
        pomodoroTimer = nil
        pomodoroStart = nil
        pomodoroEndTime = nil
        pomodoroLifeAreaId = nil
        pomodoroNote = ""
    }
    
    @Published var yearEndRecords: [YearEndRecord] = [] {
        didSet { saveYearEndRecords() }
    }
        
    private func saveYearEndRecords() {
        if let data = try? JSONEncoder().encode(yearEndRecords) {
            UserDefaults.standard.set(data, forKey: "LittleCheese.yearEndRecords")
        }
    }

    func isYearEndFestival() -> Bool {
        let components = Calendar.current.dateComponents([.month, .day], from: Date())
        return components.month == 12 && components.day == 31
    }

    @Published var pomodoroStart: Date?
    @Published var pomodoroEndTime: Date?
    @Published var pomodoroLifeAreaId: UUID?
    @Published var pomodoroDurationMinutes: Int = 25
    @Published var pomodoroNote: String = ""

    @Published var inboxItems: [InboxItem] = [] {
        didSet { saveInboxItems() }
    }

    @Published var futurePhrases: [String] = [] {
        didSet { saveFuturePhrases() }
    }
    
    @Published var dailyPhotos: [DailyPhoto] = [] {
        didSet { saveDailyPhotos() }
    }
    
    static let df: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static let defaultTodayTasks: [TodoItem] = [
        TodoItem(title: "为自己做一顿好吃的早餐"),
        TodoItem(title: "学习 20 分钟英语 / LSAT"),
        TodoItem(title: "整理 10 分钟房间")
    ]

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

    static let defaultTinyHabits: [TinyHabit] = [
        TinyHabit(trigger: "煮鸡蛋的时候", action: "打开多邻国学 1 分钟", targetCountPerDay: 1),
        TinyHabit(trigger: "打开手机的第一刻", action: "读一句英语", targetCountPerDay: 1),
        TinyHabit(trigger: "坐下来准备工作时", action: "深呼吸三次", targetCountPerDay: 1)
    ]

    static let defaultFuturePhrases: [String] = [
        "慢慢来，你已经很好了。",
        "我看到你了。",
        "你已经走了很远，我为你骄傲。",
        "进来吧，外面风有点大。",
        "今天能写到这里，就已经很不容易了。",
        "你不是一个人，我在你这边。"
    ]

    init() {
        loadAll()
    }

    private func loadAll() {
        let defaults = UserDefaults.standard
        let todayString = Self.df.string(from: Date())
        let lastDate = defaults.string(forKey: lastDateKey)
        
        checkScheduledInboxItems()
        
        if let data = defaults.data(forKey: lifeAreasKey),
           let decoded = try? JSONDecoder().decode([LifeArea].self, from: data) {
            self.lifeAreas = decoded
        } else {
            self.lifeAreas = Self.defaultLifeAreas
        }

        if let data = defaults.data(forKey: tinyHabitsKey),
           let decoded = try? JSONDecoder().decode([TinyHabit].self, from: data) {
            self.tinyHabits = decoded
        } else {
            self.tinyHabits = Self.defaultTinyHabits
        }

        if let data = defaults.data(forKey: todayKey),
           let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) {
            self.todayTasks = decoded
        } else {
            self.todayTasks = Self.defaultTodayTasks
        }

        if let data = defaults.data(forKey: journalKey),
           let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) {
            self.journalEntries = decoded
        } else {
            self.journalEntries = []
        }
        
        if let data = defaults.data(forKey: "LittleCheese.mealPlans"),
           let decoded = try? JSONDecoder().decode([DailyMealPlan].self, from: data) {
            self.weeklyMealPlans = decoded
        } else {
            self.weeklyMealPlans = (1...7).map { DailyMealPlan(dayOfWeek: $0) }
        }

        if let data = defaults.data(forKey: photosKey),
           let decoded = try? JSONDecoder().decode([DailyPhoto].self, from: data) {
            self.dailyPhotos = decoded
        } else {
            self.dailyPhotos = []
        }
        
        if let data = defaults.data(forKey: weightKey),
           let decoded = try? JSONDecoder().decode([WeightRecord].self, from: data) {
            self.weightRecords = decoded
        }
        
        if let data = defaults.data(forKey: inboxKey),
           let decoded = try? JSONDecoder().decode([InboxItem].self, from: data) {
            self.inboxItems = decoded
        } else {
            self.inboxItems = []
        }

        if let data = defaults.data(forKey: futurePhrasesKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            self.futurePhrases = decoded
        } else {
            self.futurePhrases = Self.defaultFuturePhrases
        }
        
        if let data = defaults.data(forKey: timeBlocksKey),
           let decoded = try? JSONDecoder().decode([TimeBlock].self, from: data) {
            self.timeBlocks = decoded
        } else {
            self.timeBlocks = []
        }

        if lastDate != todayString {
            handleNewDay(previousDateString: lastDate, todayString: todayString)
        }

        defaults.set(todayString, forKey: lastDateKey)
    }

    private func handleNewDay(previousDateString: String?, todayString: String) {
        self.todayTasks = Self.defaultTodayTasks
        resetTinyHabitsForNewDay()

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
        
        // ✨ 新的一天自动把饮食开关关掉，等待新一天的投喂
        isBreakfastDone = false
        isLunchDone = false
        isDinnerDone = false
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
        if let data = try? JSONEncoder().encode(todayTasks) {
            UserDefaults.standard.set(data, forKey: todayKey)
        }
    }

    private func saveLifeAreas() {
        if let data = try? JSONEncoder().encode(lifeAreas) {
            UserDefaults.standard.set(data, forKey: lifeAreasKey)
        }
    }

    private func saveJournals() {
        if let data = try? JSONEncoder().encode(journalEntries) {
            UserDefaults.standard.set(data, forKey: journalKey)
        }
    }

    private func saveFuturePhrases() {
        if let data = try? JSONEncoder().encode(futurePhrases) {
            UserDefaults.standard.set(data, forKey: futurePhrasesKey)
        }
    }

    private func saveTinyHabits() {
        if let data = try? JSONEncoder().encode(tinyHabits) {
            UserDefaults.standard.set(data, forKey: tinyHabitsKey)
        }
    }

    private func saveInboxItems() {
        if let data = try? JSONEncoder().encode(inboxItems) {
            UserDefaults.standard.set(data, forKey: inboxKey)
        }
    }
    
    private func saveWeightRecords() {
        if let data = try? JSONEncoder().encode(weightRecords) {
            UserDefaults.standard.set(data, forKey: weightKey)
        }
    }
    
    func deleteWeightRecord(id: UUID) {
        weightRecords.removeAll { $0.id == id }
    }
    
    func deleteTodayTask(id: UUID) {
        todayTasks.removeAll { $0.id == id }
    }
    
    private func saveDailyPhotos() {
        if let data = try? JSONEncoder().encode(dailyPhotos) {
            UserDefaults.standard.set(data, forKey: photosKey)
        }
    }
    
    func syncTodayStatusToJournal(mood: String, progress: Double) {
        let todayStr = Self.df.string(from: Date())
        if let idx = journalEntries.firstIndex(where: { $0.dateString == todayStr }) {
            journalEntries[idx].moodEmoji = mood
            journalEntries[idx].progressRate = progress
        } else {
            let newEntry = JournalEntry(dateString: todayStr, moodEmoji: mood, progressRate: progress)
            journalEntries.append(newEntry)
        }
    }
   
    // MARK: - 🧀 V2：饮食自动写入今天日记

    func appendDietLineToTodayJournal(_ line: String) {
        let todayDS = AppState.df.string(from: Date())
        let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanLine.isEmpty else { return }
        
        if let index = journalEntries.firstIndex(where: { $0.dateString == todayDS }) {
            var entry = journalEntries[index]
            
            var lines = (entry.oneLine ?? "")
                .components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            // 避免重复写入同一句
            guard !lines.contains(cleanLine) else { return }
            
            lines.append(cleanLine)
            entry.oneLine = lines.joined(separator: "\n")
            journalEntries[index] = entry
        } else {
            let newEntry = JournalEntry(
                dateString: todayDS,
                recordText: "",
                talkText: "",
                maybeText: "",
                oneLine: cleanLine,
                moodEmoji: todayMoodEmoji,
                progressRate: nil
            )
            
            journalEntries.append(newEntry)
        }
    }

    func removeDietLineFromTodayJournal(_ line: String) {
        let todayDS = AppState.df.string(from: Date())
        let cleanLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleanLine.isEmpty else { return }
        guard let index = journalEntries.firstIndex(where: { $0.dateString == todayDS }) else { return }
        
        var entry = journalEntries[index]
        
        let lines = (entry.oneLine ?? "")
            .components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != cleanLine }
        
        entry.oneLine = lines.joined(separator: "\n")
        journalEntries[index] = entry
    }

    private func saveTimeBlocks() {
        if let data = try? JSONEncoder().encode(timeBlocks) {
            UserDefaults.standard.set(data, forKey: timeBlocksKey)
        }
    }

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
    func timeBlocks(for date: Date) -> [TimeBlock] {
        let ds = Self.df.string(from: date)
        return timeBlocks
            .filter { $0.dateString == ds }
            .sorted { $0.start < $1.start }
    }

    func addTimeBlock(for date: Date, start: Date, end: Date, title: String, lifeAreaId: UUID? = nil) {
        let ds = Self.df.string(from: date)
        let realStart = min(start, end)
        let realEnd = max(start, end)
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = trimmedTitle.isEmpty ? "未命名时间块" : trimmedTitle

        let block = TimeBlock(dateString: ds, start: realStart, end: realEnd, title: finalTitle, lifeAreaId: lifeAreaId)
        timeBlocks.append(block)
        
        // 如果你需要调用 recalcLifeAreaTimeForThisWeek()，请确保它在 AppState+LifeAreas.swift 里定义了
        // recalcLifeAreaTimeForThisWeek()
    }

    func finishPomodoro() {
        guard let start = pomodoroStart else { return }
        let minutes = pomodoroDurationMinutes
        let end = start.addingTimeInterval(TimeInterval(minutes * 60))

        let baseTitle: String
        if let areaId = pomodoroLifeAreaId, let area = lifeAreas.first(where: { $0.id == areaId }) {
            baseTitle = "\(area.emoji) \(area.name) · 番茄钟"
        } else {
            baseTitle = "番茄钟专注"
        }

        let notePart = pomodoroNote.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = notePart.isEmpty ? baseTitle : "\(baseTitle) — \(notePart)"

        addTimeBlock(for: start, start: start, end: end, title: finalTitle, lifeAreaId: pomodoroLifeAreaId)

        pomodoroStart = nil
        pomodoroLifeAreaId = nil
        pomodoroNote = ""
    }

    func deleteTimeBlock(id: UUID) {
        timeBlocks.removeAll { $0.id == id }
        // recalcLifeAreaTimeForThisWeek()
    }

    // MARK: - Journal 操作
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
            journalEntries[idx].recordText = text
            journalEntries[idx].oneLine = oneLine
        } else {
            let entry = JournalEntry(dateString: ds, recordText: text, talkText: "", maybeText: "", oneLine: oneLine)
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
    func addInboxItem(text: String, date: Date? = nil) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let item = InboxItem(text: trimmed, reminderDate: date)
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
        addTodayTask(title: item.text)
        deleteInboxItem(id: id)
    }

    func checkScheduledInboxItems() {
        let todayStart = Calendar.current.startOfDay(for: Date())
        let dueItems = inboxItems.filter { item in
            guard let date = item.reminderDate else { return false }
            return Calendar.current.startOfDay(for: date) <= todayStart
        }
        
        guard !dueItems.isEmpty else { return }
        
        for item in dueItems {
            addTodayTask(title: item.text)
            deleteInboxItem(id: item.id)
        }
        print("🧀 自动搬运了 \(dueItems.count) 个到期的灵光到今天！")
    }

    // MARK: - Daily Photos 操作
    func photos(for date: Date) -> [DailyPhoto] {
        let ds = Self.df.string(from: date)
        return dailyPhotos.filter { $0.dateString == ds }
    }

    func photos(forDateString ds: String) -> [DailyPhoto] {
        return dailyPhotos.filter { $0.dateString == ds }
    }

    func addPhoto(for date: Date, imageData: Data, caption: String? = nil) {
        let ds = Self.df.string(from: date)
        let photo = DailyPhoto(dateString: ds, imageData: imageData, caption: caption)
        dailyPhotos.append(photo)
    }

    func updatePhotoCaption(id: UUID, caption: String?) {
        guard let index = dailyPhotos.firstIndex(where: { $0.id == id }) else { return }
        dailyPhotos[index].caption = caption
    }

    func deletePhoto(id: UUID) {
        dailyPhotos.removeAll { $0.id == id }
    }
} // <--- AppState 完美结束
