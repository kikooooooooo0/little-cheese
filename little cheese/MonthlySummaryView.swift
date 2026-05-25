import SwiftUI

struct MonthlySummaryView: View {
    @ObservedObject var state: AppState

    private let accent = Color.lcYellow
    private let bgColor = Color.lcBackground
    private let cardBg = Color.lcCardBackground
    private let textColor = Color.lcText
    private let secondaryTextColor = Color.lcTextSecondary

    private var currentMonthRecords: [WeightRecord] {
        let calendar = Calendar.current
        let now = Date()

        return state.weightRecords.filter { record in
            calendar.isDate(record.date, equalTo: now, toGranularity: .month)
        }
    }

    private var daysPassedThisMonth: Int {
        Calendar.current.component(.day, from: Date())
    }

    private var recordDays: Int {
        currentMonthRecords.count
    }

    private var exerciseDays: Int {
        currentMonthRecords.filter {
            !$0.exerciseDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
    }

    private var dinnerScore: Double {
        let dinnerRecords = currentMonthRecords.filter { $0.hadDinner }

        guard !dinnerRecords.isEmpty else { return 0 }

        let total = dinnerRecords.reduce(0.0) { result, record in
            switch record.dinnerQuality {
            case .light:
                return result + 1.0
            case .okay:
                return result + 0.7
            case .heavy:
                return result + 0.35
            case .none:
                return result + 0.5
            }
        }

        return total / Double(dinnerRecords.count)
    }

    private var exerciseProgress: Double {
        guard recordDays > 0 else { return 0 }
        return min(Double(exerciseDays) / Double(recordDays), 1.0)
    }

    private var dinnerProgress: Double {
        min(dinnerScore, 1.0)
    }

    private var stabilityProgress: Double {
        guard daysPassedThisMonth > 0 else { return 0 }
        return min(Double(recordDays) / Double(daysPassedThisMonth), 1.0)
    }

    private var encouragementText: String {
        if recordDays == 0 {
            return "这个月还没开始记录。没关系，小奶酪等你回来 🧀"
        }

        if stabilityProgress >= 0.8 {
            return "这个月你真的有在照顾自己，不是靠狠，是靠一次次回来。"
        }

        if stabilityProgress >= 0.45 {
            return "这个月已经有节奏了，我们不用追求完美，只要继续回来。"
        }

        return "这个月先别责怪自己。能记录几天，就已经是在重新建立秩序。"
    }

    var body: some View {
        ZStack {
            bgColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {

                    headerCard

                    ringCard

                    detailCard

                    gentleSummaryCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle("本月轻盈报告")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("这个月的小奶酪总结")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(textColor)

            Text(encouragementText)
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

    private var ringCard: some View {
        VStack(spacing: 20) {
            HStack {
                Text("三环进度")
                    .font(.headline)
                    .foregroundColor(textColor)

                Spacer()

                Text("\(recordDays) 天记录")
                    .font(.caption.bold())
                    .foregroundColor(secondaryTextColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(bgColor.opacity(0.6))
                    .cornerRadius(999)
            }

            HStack(spacing: 18) {
                SummaryRing(
                    title: "运动",
                    emoji: "🏃‍♀️",
                    progress: exerciseProgress,
                    progressText: "\(exerciseDays)/\(max(recordDays, 1))",
                    ringColor: accent,
                    trackColor: bgColor,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor
                )

                SummaryRing(
                    title: "晚餐",
                    emoji: "🍲",
                    progress: dinnerProgress,
                    progressText: "\(Int(dinnerProgress * 100))%",
                    ringColor: Color.pink.opacity(0.85),
                    trackColor: bgColor,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor
                )

                SummaryRing(
                    title: "稳定",
                    emoji: "🧀",
                    progress: stabilityProgress,
                    progressText: "\(Int(stabilityProgress * 100))%",
                    ringColor: Color.orange.opacity(0.85),
                    trackColor: bgColor,
                    textColor: textColor,
                    secondaryTextColor: secondaryTextColor
                )
            }
        }
        .padding(22)
        .background(cardBg)
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 5)
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("这个月发生了什么")
                .font(.headline)
                .foregroundColor(textColor)

            summaryRow(icon: "calendar", title: "记录天数", value: "\(recordDays) 天")
            summaryRow(icon: "figure.walk", title: "运动天数", value: "\(exerciseDays) 天")
            summaryRow(icon: "moon.stars", title: "晚餐轻盈度", value: "\(Int(dinnerProgress * 100))%")
            summaryRow(icon: "heart.fill", title: "回来记录的稳定度", value: "\(Int(stabilityProgress * 100))%")
        }
        .padding(22)
        .background(cardBg)
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.03), radius: 12, x: 0, y: 5)
    }

    private var gentleSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("下个月不用狠")
                .font(.headline)
                .foregroundColor(textColor)

            Text("我们先追一个很小的目标：每周回来记录 3 次。不是为了控制你，是为了让你重新看见自己。")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(accent.opacity(0.12))
        .cornerRadius(28)
    }

    private func summaryRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(accent)
                .frame(width: 30, height: 30)
                .background(accent.opacity(0.14))
                .cornerRadius(10)

            Text(title)
                .font(.subheadline)
                .foregroundColor(textColor)

            Spacer()

            Text(value)
                .font(.subheadline.bold())
                .foregroundColor(secondaryTextColor)
        }
    }
}

private struct SummaryRing: View {
    let title: String
    let emoji: String
    let progress: Double
    let progressText: String
    let ringColor: Color
    let trackColor: Color
    let textColor: Color
    let secondaryTextColor: Color

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(trackColor.opacity(0.75), lineWidth: 9)

                Circle()
                    .trim(from: 0, to: min(max(progress, 0), 1))
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: 9, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.85), value: progress)

                VStack(spacing: 2) {
                    Text(emoji)
                        .font(.title3)

                    Text(progressText)
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(textColor)
                }
            }
            .frame(width: 84, height: 84)

            Text(title)
                .font(.caption.bold())
                .foregroundColor(secondaryTextColor)
        }
        .frame(maxWidth: .infinity)
    }
}
