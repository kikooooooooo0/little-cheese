import SwiftUI

#if os(iOS)
import UIKit
import PhotosUI
#elseif os(macOS)
import AppKit
#endif

// MARK: - 日记流（纯净时间轴版）

struct JournalListView: View {
    @ObservedObject var state: AppState
    
    // 🎨 日记专属莫奈色板
    private let palette: [Color] = [
        Color(hex: "#6CA6CD"),  // 莫奈蓝
        Color(hex: "#87CEEB"),  // 天空蓝
        Color(hex: "#E0C3FC"),  // 淡紫
        Color(hex: "#FFDAB9"),  // 桃色
        Color(hex: "#98FB98"),  // 嫩绿
        Color(hex: "#F0E68C"),  // 绢布黄
        Color(hex: "#D8BFD8"),  // 蓟色
        Color(hex: "#B0E0E6")   // 粉蓝
    ]
    
    /// 按「年月」分组后的日记
    private var groupedByMonth: [(month: String, entries: [JournalEntry])] {
        let dict = Dictionary(grouping: state.journalEntries) { entry in
            String(entry.dateString.prefix(7)) // "2025-12"
        }
        return dict.keys.sorted(by: >).compactMap { key in
            guard let entries = dict[key] else { return nil }
            let sorted = entries.sorted { $0.dateString > $1.dateString }
            return (month: key, entries: sorted)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                
                if state.journalEntries.isEmpty {
                    emptyStateView
                } else {
                    // 按月份遍历
                    ForEach(groupedByMonth, id: \.month) { group in
                        // 1. 月份小标题
                        HStack {
                            Text(formattedMonth(group.month))
                                .font(.headline)
                                .foregroundColor(.lcTextSecondary)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(
                                    Capsule()
                                        .fill(Color.lcCardBackground)
                                        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                                )
                            Spacer()
                        }
                        .padding(.leading, 20)
                        .padding(.top, 16)
                        .padding(.bottom, 12)
                        
                        // 2. 该月的时间轴
                        VStack(spacing: 0) {
                            ForEach(Array(group.entries.enumerated()), id: \.element.id) { index, entry in
                                TimelineRow(
                                    state: state, // 传入 state 以便进入详情
                                    entry: entry,
                                    color: palette[index % palette.count],
                                    isLast: index == group.entries.count - 1
                                )
                            }
                        }
                        .padding(.bottom, 16)
                    }
                }
            }
            .padding(.bottom, 80) // 避让悬浮底栏
        }
        .background(Color.lcBackground.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                NavigationLink {
                    // 新建日记：entry = nil
                    JournalDetailView(state: state, entry: nil)
                } label: {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.lcAccentBlue)
                }
            }
        }
    }
    
    // MARK: - 辅助视图
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(.lcTextSecondary.opacity(0.5))
            Text("这里还是空的")
                .font(.headline)
                .foregroundColor(.lcTextSecondary)
            Text("写下第一篇日记，开始你的时间轴吧 🧀")
                .font(.caption)
                .foregroundColor(.lcTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    private func formattedMonth(_ monthKey: String) -> String {
        let parts = monthKey.split(separator: "-")
        if parts.count == 2 {
            return "\(parts[0])年 \(parts[1])月"
        }
        return monthKey
    }
}

// MARK: - 单个时间轴行组件 (TimelineRow)

struct TimelineRow: View {
    @ObservedObject var state: AppState // 需要这个来传给 DetailView
    let entry: JournalEntry
    let color: Color
    let isLast: Bool
    
    // 日期解析
    private var dayString: String {
        let f = DateFormatter()
        f.dateFormat = "dd"
        if let d = dateFrom(entry.dateString) {
            return f.string(from: d)
        }
        return "--"
    }
    
    private var weekdayString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "EEE" // 周几
        if let d = dateFrom(entry.dateString) {
            return f.string(from: d)
        }
        return ""
    }
    
    private func dateFrom(_ s: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: s)
    }
    
    var body: some View {
            HStack(alignment: .top, spacing: 0) {
                
                // 1. 左侧：日期
                VStack(spacing: 2) {
                    Text(dayString)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.lcText)
                    Text(weekdayString)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.lcTextSecondary)
                }
                .frame(width: 50)
                .padding(.top, 4)
                
                // 2. 中间：轴线
                ZStack(alignment: .top) {
                    if !isLast {
                        Rectangle()
                            .fill(Color.lcSoftBlue.opacity(0.4))
                            .frame(width: 2)
                            .padding(.top, 16)
                            .padding(.bottom, -40)
                    }
                    Circle()
                        .fill(Color.lcCardBackground)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(color, lineWidth: 3))
                        .padding(.top, 12)
                }
                .frame(width: 30)
                
                // 3. 右侧：带勋章的日记卡片
                NavigationLink(destination: JournalDetailView(state: state, entry: entry)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(previewText)
                            .font(.subheadline)
                            .foregroundColor(.lcText)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        // ✨ 核心显示：心情和进度环
                        if entry.moodEmoji != nil || entry.progressRate != nil {
                            HStack(spacing: 10) {
                                if let mood = entry.moodEmoji {
                                    Text(mood)
                                        .font(.caption)
                                        .padding(4)
                                        .background(Circle().fill(Color.white.opacity(0.5)))
                                }
                                
                                if let rate = entry.progressRate {
                                    HStack(spacing: 4) {
                                        ZStack {
                                            Circle().stroke(Color.lcSoftBlue.opacity(0.2), lineWidth: 2)
                                            Circle().trim(from: 0, to: rate)
                                                .stroke(Color.lcCheeseYellow, lineWidth: 2)
                                                .rotationEffect(.degrees(-90))
                                        }
                                        .frame(width: 14, height: 14)
                                        Text("\(Int(rate * 100))%").font(.system(size: 10, weight: .bold))
                                    }
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Capsule().fill(Color.lcSoftBlue.opacity(0.1)))
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.lcCardBackground))
                    .shadow(color: color.opacity(0.15), radius: 6, x: 0, y: 3)
                    .padding(.leading, 8).padding(.trailing, 20).padding(.bottom, 24)
                }
            }
        }
    private var previewText: String {
        if let one = entry.oneLine, !one.isEmpty {
            return one
        }
        if !entry.text.isEmpty {
            return entry.text
        }
        return "（这一天留下了空白的记录）"
    }
}

// MARK: - 详情与写日记页面 (JournalDetailView)
// ⚠️ 你的模版逻辑全部都在这里！

struct JournalDetailView: View {
    @ObservedObject var state: AppState
    
    let entry: JournalEntry?    // 如果是 nil 表示新增
    
    // 🧀 Little Cheese：自动读取今天的饮食打卡
    @AppStorage("littleCheese.dietCheckinRecords") private var dietCheckinJSONString: String = "[]"
    
    // 模板三个输入区（只在“写新日记”时使用）
    @State private var recordText: String = ""   // 今天我想记录下来的事是：
    @State private var talkText: String = ""     // 我想要聊的是：
    @State private var maybeText: String = ""    // 也许，我可以：
    
    @State private var gentlePhrase: String? = nil   // 自动随机出现的一句温柔话语（仅新日记）
    @State private var newFuturePhrase: String = ""  // 用户自己添加未来语句（仅新日记）
    @State private var oneLineText: String = ""
    @State private var baseTextForThisSession: String = ""
    @State private var baseOneLineForThisSession: String? = nil
    
    // 旧日记：是否处于编辑模式
    @State private var isEditingExisting: Bool = false
    
#if os(iOS)
    @State private var journalPhotoItem: PhotosPickerItem?
#endif
    
    // 日期
    private var date: Date {
        if let e = entry,
           let d = AppState.df.date(from: e.dateString) {
            return d
        }
        return Date()
    }
    
    private var dateString: String {
        AppState.df.string(from: date)
    }
    
    private var photosForThisDate: [DailyPhoto] {
        state.dailyPhotos.filter { $0.dateString == dateString }
    }
    
    private var hasAnyContent: Bool {
        let r = recordText.trimmingCharacters(in: .whitespacesAndNewlines)
        let t = talkText.trimmingCharacters(in: .whitespacesAndNewlines)
        let m = maybeText.trimmingCharacters(in: .whitespacesAndNewlines)
        let o = oneLineText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !r.isEmpty || !t.isEmpty || !m.isEmpty || !o.isEmpty
    }
    
    private var allPhrases: [String] {
        let builtin = AppState.defaultFuturePhrases
        let custom = state.futurePhrases
        let combined = builtin + custom
        return combined.isEmpty ? builtin : combined
    }
    
    private var completedItemsForThisDate: [String] {
        let journalDateString = AppState.df.string(from: date)
        let todayString = AppState.df.string(from: Date())
        guard journalDateString == todayString else { return [] }
        return state.todayTasks.filter { $0.isDone }.map { $0.title }
    }
    
    // MARK: - 🧀 自动日记联动：饮食 + 运动
    
    private var dietRecordsForThisDate: [DietCheckinRecord] {
        guard let data = dietCheckinJSONString.data(using: .utf8) else {
            return []
        }
        
        let allRecords = (try? JSONDecoder().decode([DietCheckinRecord].self, from: data)) ?? []
        
        return allRecords
            .filter { $0.dateKey == dateString }
            .sorted { $0.date < $1.date }
    }
    
    private var workoutItemsForThisDate: [String] {
        completedItemsForThisDate.filter { title in
            title.contains("运动") ||
            title.contains("训练") ||
            title.contains("动作") ||
            title.contains("练") ||
            title.contains("🏋️") ||
            title.contains("💪") ||
            title.contains("🔥")
        }
    }
    
    private var autoLifeSummaryLines: [String] {
        var lines: [String] = []
        
        if !dietRecordsForThisDate.isEmpty {
            lines.append("🍽️ 今日饮食")
            for record in dietRecordsForThisDate {
                // 这里修改：用 content 替代 sopName，并根据 mealType 显示不同图标
                let icon = record.mealType == "早餐" ? "☀️" : (record.mealType == "午餐" ? "🍱" : "🌙")
                lines.append("• \(record.mealType)：\(icon) \(record.content)")
            }
        }
        
        // ... 后续代码不变
        if !workoutItemsForThisDate.isEmpty {
            if !lines.isEmpty { lines.append("") }
            lines.append("🏋️ 今日运动")
            for item in workoutItemsForThisDate {
                lines.append("• \(item)")
            }
        }
        
        let usages = state.timeUsageFor(date: date)
        if !usages.isEmpty {
            if !lines.isEmpty { lines.append("") }
            lines.append("⏱️ 今日时间分布")
            for usage in usages {
                lines.append("• \(usage.name)：\(usage.minutes) 分钟")
            }
        }
        
        return lines
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                
                // 日期
                Text(AppState.df.string(from: date))
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                // 顶部问候
                Text("你好啊！")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 4)
                
                // MARK: 今天的小起司照片（只在“写新日记”时显示，可添加 + 缩略图）
                if entry == nil {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("今天的小起司照片")
                                .font(.headline)
                                .foregroundColor(.lcText)
                            Spacer()
#if os(iOS)
                            PhotosPicker(
                                selection: $journalPhotoItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.large)
                            }
#elseif os(macOS)
                            Button {
                                pickPhotoForJournal()
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.large)
                            }
#endif
                        }
                        
                        if photosForThisDate.isEmpty {
                            Text("今天还没有照片，点右上角的 + 添加一张小起司照片。")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photosForThisDate, id: \.id) { photo in
                                        if let image = makeImageView(from: photo.imageData) {
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 120, height: 120)
                                                .clipped()
                                                .cornerRadius(12)
                                                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
                                        } else {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(Color.lcSoftBlue.opacity(0.2))
                                                .frame(width: 120, height: 120)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                
                // MARK: 两种模式切换
                if let entry = entry {
                    // =========🌙 查看【旧日记】模式 =========
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // 顶部展示区
                        HStack(alignment: .top, spacing: 16) {
                            // 左边照片
                            VStack(alignment: .leading, spacing: 8) {
                                ZStack {
                                    if let photo = state.dailyPhotos.first(where: { $0.dateString == entry.dateString }),
                                       let imageView = makeImageView(from: photo.imageData) {
                                        imageView
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 200, height: 200)
                                            .clipped()
                                            .cornerRadius(16)
                                            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                                    } else {
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.lcSoftBlue.opacity(0.2))
                                            .frame(width: 200, height: 200)
                                            .overlay(Text("这一天没有照片").font(.caption).foregroundColor(.secondary))
                                    }
                                }
                                
                                if isEditingExisting {
                                    TextField("今天的小起司时刻", text: $oneLineText)
                                        .font(.footnote)
                                        .textFieldStyle(.roundedBorder)
                                } else {
                                    Text(entry.oneLine ?? "今天的小起司时刻")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                            // 右边总结卡片
                            todaySummaryCard()
                        }
                        
                        // ✨ 插入自动回顾卡片（分离显示，不污染正文）
                                                autoLifeSummaryCard()

                                                // 正文
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("这一天的日记")
                                                        .font(.headline)
                                                        .foregroundColor(.primary)
                            
                            if isEditingExisting {
                                TextEditor(text: $recordText)
                                    .frame(minHeight: 160)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.06)))
                            } else {
                                Text(recordText.isEmpty ? "这一天还没有正式写日记。" : recordText)
                                    .font(.body)
                                    .padding(12)
                                    .background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.06)))
                            }
                        }
                    }
                } else {
                    // =========☀️ 写【新日记】模式 (包含你的模版) =========
                    
                    autoLifeSummaryCard()
                    
                    // 1. 今日一句话
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今日一句话（可选）")
                            .font(.subheadline).foregroundColor(.secondary)
                        TextField("例如：今天笑出声了。", text: $oneLineText)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding().background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.gray.opacity(0.3)))
                    
                    // 2. 模版：记录
                    VStack(alignment: .leading, spacing: 8) {
                        Text("今天我想记录下来的事是：").font(.headline)
                        TextEditor(text: $recordText)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
                    }
                    .padding().background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.gray.opacity(0.3)))
                    
                    // 3. 模版：聊天
                    VStack(alignment: .leading, spacing: 8) {
                        Text("我想要聊的是：").font(.headline)
                        TextEditor(text: $talkText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
                    }
                    .padding().background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.gray.opacity(0.3)))
                    
                    // 4. 模版：也许我可以
                    VStack(alignment: .leading, spacing: 8) {
                        Text("也许，我可以：").font(.headline)
                        TextEditor(text: $maybeText)
                            .frame(minHeight: 80)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.secondary.opacity(0.08)))
                    }
                    .padding().background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.gray.opacity(0.3)))
                    
                    // 温柔话语
                    if let phrase = gentlePhrase, !phrase.isEmpty {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "sparkles")
                            Text(phrase).font(.subheadline)
                        }
                        .padding().background(RoundedRectangle(cornerRadius: 16).fill(Color.secondary.opacity(0.08)))
                    }
                    
                    Button(hasAnyContent ? "保存日记" : "今天先到这里了") {
                        autoSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 8)
                }
                
            }
            .padding()
        }
        .scrollDismissesKeyboard(.interactively)
        .onTapGesture { hideKeyboard() }
        .navigationTitle("日记")
        .toolbar {
            if entry != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditingExisting ? "完成" : "编辑") {
                        if isEditingExisting { saveExistingEdits() }
                        withAnimation { isEditingExisting.toggle() }
                    }
                }
            }
        }
        .onAppear {
            loadFromEntry()
            if entry == nil {
                pickRandomPhraseIfNeeded()
                // 读取之前的草稿基准
                let dateString = AppState.df.string(from: date)
                if let existing = state.journalEntries.first(where: { $0.dateString == dateString }) {
                    baseTextForThisSession = existing.text
                    baseOneLineForThisSession = existing.oneLine
                } else {
                    baseTextForThisSession = ""
                    baseOneLineForThisSession = nil
                }
            }
        }
        .onChange(of: recordText, initial: false) { _, _ in autoSave() }
        .onChange(of: talkText, initial: false) { _, _ in autoSave() }
        .onChange(of: maybeText, initial: false) { _, _ in autoSave() }
        .onChange(of: oneLineText, initial: false) { _, _ in autoSave() }
#if os(iOS)
        .onChange(of: journalPhotoItem, initial: false) { _, newItem in
            guard let item = newItem else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    state.addPhoto(for: date, imageData: data, caption: nil)
                }
                await MainActor.run { journalPhotoItem = nil }
            }
        }
#endif
    }
    
    // MARK: - 逻辑方法
    
    private func buildCombinedText() -> String {
            var parts: [String] = []
            
            let r = recordText.trimmingCharacters(in: .whitespacesAndNewlines)
            let t = talkText.trimmingCharacters(in: .whitespacesAndNewlines)
            let m = maybeText.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !r.isEmpty { parts.append(r) }
            if !t.isEmpty { parts.append(t) }
            if !m.isEmpty { parts.append(m) }
            
            return parts.joined(separator: "\n\n")
        }
    private func loadFromEntry() {
        guard let entry = entry else { return }
        recordText = entry.text
        talkText = ""
        maybeText = ""
        oneLineText = entry.oneLine ?? ""
    }
    
    private func pickRandomPhraseIfNeeded() {
        guard gentlePhrase == nil else { return }
        guard !allPhrases.isEmpty else { return }
        gentlePhrase = allPhrases.randomElement()
    }
    
    private func autoSave() {
        let combined = buildCombinedText().trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOne = oneLineText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var finalText = baseTextForThisSession
        var finalOneLine = baseOneLineForThisSession
        
        if !combined.isEmpty {
            if finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                finalText = combined
            } else {
                finalText += "\n\n" + combined
            }
        }
        
        if !trimmedOne.isEmpty {
            finalOneLine = trimmedOne
        }
        
        if finalText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && finalOneLine == nil {
            return
        }
        
        state.updateJournal(for: date, text: finalText, oneLine: finalOneLine)
    }
    
    private func saveExistingEdits() {
        let trimmedText = recordText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOne = oneLineText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedText.isEmpty && trimmedOne.isEmpty { return }
        state.updateJournal(for: date, text: trimmedText, oneLine: trimmedOne.isEmpty ? nil : trimmedOne)
    }
    private func autoLifeSummaryCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.lcCheeseYellow)
                
                Text("今天 Little Cheese 自动记下了")
                    .font(.headline)
                    .foregroundColor(.lcText)
            }
            
            if autoLifeSummaryLines.isEmpty {
                Text("今天还没有饮食或运动记录。没关系，空白也是一种真实生活。")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(autoLifeSummaryLines, id: \.self) { line in
                        if line.isEmpty {
                            Spacer().frame(height: 4)
                        } else if line.hasPrefix("🍽️") || line.hasPrefix("🏋️") || line.hasPrefix("⏱️") {
                            Text(line)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.lcText)
                                .padding(.top, 4)
                        } else {
                            Text(line)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.lcYellow.opacity(0.13))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.lcYellow.opacity(0.35), lineWidth: 1)
        )
    }
    
    private func todaySummaryCard() -> some View {
        let usages = state.timeUsageFor(date: date)
        let completed = completedItemsForThisDate
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("今天完成的事：").font(.subheadline).fontWeight(.medium).foregroundColor(.primary)
            if !completed.isEmpty {
                ForEach(completed, id: \.self) { item in
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "checkmark.circle.fill").font(.caption).foregroundColor(.accentColor)
                        Text(item).font(.footnote).fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                Text("今天还没有勾掉的任务～").font(.footnote).foregroundColor(.secondary)
            }
            
            Divider().padding(.top, 4)
            
            Text("时间分布：").font(.subheadline).fontWeight(.medium).foregroundColor(.secondary)
            if !usages.isEmpty {
                handDrawnUsageList(usages: usages)
            } else {
                Text("暂无记录").font(.footnote).foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func handDrawnUsageList(usages: [LifeAreaTimeUsage]) -> some View {
        let maxMinutes = max(usages.map(\.minutes).max() ?? 1, 1)
        let maxBarWidth: CGFloat = 100
        let minBarWidth: CGFloat = 6
        
        VStack(alignment: .leading, spacing: 8) {
            ForEach(usages) { usage in
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("• \(usage.name)").font(.caption).foregroundColor(.primary)
                        let ratio = CGFloat(usage.minutes) / CGFloat(maxMinutes)
                        let barWidth = minBarWidth + (maxBarWidth - minBarWidth) * ratio
                        RoundedRectangle(cornerRadius: 999).fill(usage.color.opacity(0.75)).frame(width: barWidth, height: 8)
                    }
                    Text("\(usage.minutes)m").font(.caption2).foregroundColor(.secondary).padding(.leading, 10)
                }
            }
        }
    }
    
    private func makeImageView(from data: Data) -> Image? {
        guard !data.isEmpty else { return nil }
#if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
#elseif os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
#else
        return nil
#endif
    }
    
#if os(macOS)
    private func pickPhotoForJournal() {
        // macOS pick logic placeholder
    }
#endif
}
