import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - 真正的“小起司”照片日历
// 这是一个自定义的网格日历，能显示每一天的照片缩略图，下方还有本月照片瀑布流

struct CalendarPhotoView: View {
    @ObservedObject var state: AppState

    // 当前日历显示的月份（默认为今天所在的月）
    @State private var currentMonth: Date = Date()

    // 这一周的表头
    private let weekDays = ["日", "一", "二", "三", "四", "五", "六"]

    // 1. 日历格子的布局（7列，带间距）
    private let calendarColumns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    
    // 2. 下方照片流布局：改成单列（就像时间轴一样）
        private let photoColumns = [
            GridItem(.flexible(), spacing: 16) // 只留一个 flexible，就是单列
        ]

    // MARK: - 计算属性

    /// 获取当前月份所有的日期
    private var calendarDays: [Date?] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else { return [] }

        let monthStart = monthInterval.start
        let monthEnd = monthInterval.end
        let startWeekday = calendar.component(.weekday, from: monthStart)
        let offsetDays = startWeekday - 1

        var days: [Date?] = []
        for _ in 0..<offsetDays { days.append(nil) }

        var currentDate = monthStart
        while currentDate < monthEnd {
            days.append(currentDate)
            if let next = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = next
            } else {
                break
            }
        }
        return days
    }

    /// 顶部显示的年月标题
    private var monthYearString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年 M月"
        return f.string(from: currentMonth)
    }
    
    /// ✨ 筛选出“当前月份”的所有照片
    private var currentMonthPhotos: [DailyPhoto] {
        let calendar = Calendar.current
        return state.dailyPhotos.filter { photo in
            guard let date = AppState.df.date(from: photo.dateString) else { return false }
            return calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
        }
        .sorted { $0.dateString > $1.dateString } // 按时间倒序
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                // 1️⃣ 顶部控制栏
                HStack {
                    Button { changeMonth(by: -1) } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.bold())
                            .foregroundColor(.lcTextSecondary)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }

                    Spacer()

                    Text(monthYearString)
                        .font(.system(.title3, design: .rounded).bold()) // 圆润字体
                        .foregroundColor(.lcText)

                    Spacer()

                    Button { changeMonth(by: 1) } label: {
                        Image(systemName: "chevron.right")
                            .font(.body.bold())
                            .foregroundColor(.lcTextSecondary)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)

                // 2️⃣ 星期表头
                HStack(spacing: 0) {
                    ForEach(weekDays, id: \.self) { day in
                        Text(day)
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundColor(.lcTextSecondary.opacity(0.8))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 10)

                // 3️⃣ 滚动区域：日历 + 照片流
                ScrollView {
                    VStack(spacing: 24) {
                        
                        // A. 日历网格
                        LazyVGrid(columns: calendarColumns, spacing: 6) {
                            ForEach(Array(calendarDays.enumerated()), id: \.offset) { index, date in
                                if let date = date {
                                    let ds = AppState.df.string(from: date)
                                    NavigationLink {
                                        PhotoGalleryView(state: state, focusDateString: ds)
                                    } label: {
                                        dayCell(date: date, dateString: ds)
                                    }
                                    .buttonStyle(.plain)
                                } else {
                                    Color.clear.aspectRatio(1.0, contentMode: .fill)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // B. 分割线
                        if !currentMonthPhotos.isEmpty {
                            HStack {
                                Rectangle().fill(Color.lcSoftBlue.opacity(0.3)).frame(height: 1)
                                Text("本月瞬间")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.lcTextSecondary)
                                    .padding(.horizontal, 8)
                                Rectangle().fill(Color.lcSoftBlue.opacity(0.3)).frame(height: 1)
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 10)
                            
                            // C. 照片瀑布流 (复用高颜值卡片)
                            LazyVGrid(columns: photoColumns, spacing: 12) {
                                ForEach(currentMonthPhotos, id: \.id) { photo in
                                    NavigationLink {
                                        JournalDetailView(
                                            state: state,
                                            entry: state.entry(for: photo.dateString)
                                        )
                                    } label: {
                                        waterfallPhotoCard(photo: photo)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 40) // 底部留白
                        }
                    }
                }
            }
            .background(Color.lcBackground.ignoresSafeArea())
            .navigationTitle("记忆日历")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - 组件：日历格子 (Day Cell)

    @ViewBuilder
    private func dayCell(date: Date, dateString: String) -> some View {
        let photos = state.photos(forDateString: dateString)
        let firstPhoto = photos.first
        let hasJournal = (state.entry(for: dateString) != nil)
        let isToday = Calendar.current.isDateInToday(date)
        let dayNumber = Calendar.current.component(.day, from: date)

        ZStack(alignment: .topLeading) {
            GeometryReader { geo in
                if let photo = firstPhoto, let image = makeImageView(from: photo.imageData) {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isToday ? Color.lcCheeseYellow.opacity(0.15) : Color.white)
                }
            }
            .aspectRatio(1.0, contentMode: .fill) // 正方形
            
            // 日期小气泡
            Text("\(dayNumber)")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(isToday ? .white : .lcText)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(isToday ? Color.lcCheeseYellow : (firstPhoto != nil ? Color.white.opacity(0.85) : Color.clear))
                )
                .padding(4)

            // 日记小红点
            if firstPhoto == nil && hasJournal {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle().fill(Color.lcCheeseYellow).frame(width: 6, height: 6).padding(6)
                    }
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isToday ? Color.lcCheeseYellow : Color.clear, lineWidth: 2)
        )
    }
    // MARK: - 组件：单列宽卡片 (Timeline Style) ✨
        // 修正：精准联动日记模版里的“今日一句话”

        @ViewBuilder
        private func waterfallPhotoCard(photo: DailyPhoto) -> some View {
            // 1. 日期显示 (例如 20日 周六)
            let dayString: String = {
                if let d = AppState.df.date(from: photo.dateString) {
                    let f = DateFormatter(); f.dateFormat = "dd"; return f.string(from: d)
                }
                return "--"
            }()
            
            let weekdayString: String = {
                if let d = AppState.df.date(from: photo.dateString) {
                    let f = DateFormatter(); f.locale = Locale(identifier: "zh_CN"); f.dateFormat = "EEE"
                    return f.string(from: d)
                }
                return ""
            }()

            // ✨ 核心修正：直接读取日记里的“今日一句话” ✨
            let captionText: String = {
                // 1. 找到那一天的日记
                if let entry = state.entry(for: photo.dateString) {
                    // 2. 优先显示日记模版里的【今日一句话】
                    if let oneLine = entry.oneLine, !oneLine.isEmpty {
                        return oneLine
                    }
                    
                    // 3. 如果没写一句话，但是写了正文，显示正文开头（保持和时光轴逻辑一致）
                    if !entry.text.isEmpty {
                        return entry.text
                    }
                }
                
                // 4. 如果连日记都没写，才显示默认文案
                return "今天的小起司时刻 🧀"
            }()

            // 整体容器：左边日期 + 右边大卡片
            HStack(alignment: .top, spacing: 12) {
                
                // ——— 左侧：日期指示器 ———
                VStack(alignment: .center, spacing: 2) {
                    Text(dayString)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.lcText)
                    Text(weekdayString)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.lcTextSecondary)
                    
                    // 小竖线装饰
                    Capsule()
                        .fill(Color.lcCheeseYellow.opacity(0.5))
                        .frame(width: 2, height: 20)
                        .padding(.top, 4)
                }
                .frame(width: 44) // 固定宽度
                .padding(.top, 4)

                // ——— 右侧：宽大的内容卡片 ———
                VStack(alignment: .leading, spacing: 0) {
                    
                    // A. 大图区域 (16:9 电影感)
                    ZStack {
                        if let image = makeImageView(from: photo.imageData) {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .aspectRatio(16.0/9.0, contentMode: .fit)
                                .clipped()
                        } else {
                            Rectangle()
                                .fill(Color.lcSoftBlue.opacity(0.1))
                                .aspectRatio(16.0/9.0, contentMode: .fit)
                                .overlay(Image(systemName: "photo").foregroundColor(.lcSoftBlue))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    // B. 文字区域 (显示“今日一句话”)
                    HStack(alignment: .top) {
                        Text(captionText)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.lcText)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                        
                        Spacer()
                    }
                    .padding(.bottom, 4)
                }
                .padding(10)
                .background(Color.lcCardBackground)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
            }
            .padding(.horizontal, 4)
        }
    // MARK: - 逻辑辅助

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: currentMonth) {
            withAnimation { currentMonth = newDate }
        }
    }

    private func makeImageView(from data: Data) -> Image? {
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
}
