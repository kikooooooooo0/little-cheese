import SwiftUI

struct TodoListWithDateView: View {
    // ✅ 用主 ContentView 传进来的同一个 AppState
    @ObservedObject var state: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // ✅ 按日期分组（目前先用 “今天一组” 模拟）
                    ForEach(groupedDays, id: \.dateKey) { day in
                        HStack(alignment: .top, spacing: 12) {

                            // 左侧：日期竖条
                            VStack(spacing: 4) {
                                Text(day.dayText)
                                    .font(.headline)
                                    .foregroundColor(.lcText)

                                Text(day.weekdayText)
                                    .font(.caption)
                                    .foregroundColor(.lcTextSecondary)
                            }
                            .frame(width: 56)
                            .padding(.vertical, 10)
                            .background(Color.lcSoftBlue.opacity(0.25))
                            .cornerRadius(14)

                            // 右侧：记录卡片
                            VStack(alignment: .leading, spacing: 10) {
                                Text(day.fullDateText)
                                    .font(.subheadline)
                                    .foregroundColor(.lcTextSecondary)

                                // ✅ 左 done | 右 todo
                                HStack(alignment: .top, spacing: 12) {

                                    // 左：Done
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Done")
                                            .font(.caption)
                                            .foregroundColor(.lcTextSecondary)

                                        let doneItems = day.items.filter { $0.isDone }

                                        if doneItems.isEmpty {
                                            Text("（空）")
                                                .font(.caption)
                                                .foregroundColor(.lcTextSecondary.opacity(0.7))
                                        } else {
                                            ForEach(doneItems, id: \.id) { item in
                                                HStack(spacing: 8) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(.lcGreen)

                                                    Text(item.title)
                                                        .foregroundColor(.lcTextSecondary)
                                                        .strikethrough(true, color: .lcTextSecondary)

                                                    Spacer()
                                                }
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    state.toggleTodo(id: item.id)
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    // 中间分割线
                                    Rectangle()
                                        .fill(Color.lcSoftBlue.opacity(0.35))
                                        .frame(width: 1)
                                        .padding(.vertical, 2)

                                    // 右：Todo
                                    VStack(alignment: .leading, spacing: 10) {
                                        Text("Todo")
                                            .font(.caption)
                                            .foregroundColor(.lcTextSecondary)

                                        let todoItems = day.items.filter { !$0.isDone }

                                        if todoItems.isEmpty {
                                            Text("（空）")
                                                .font(.caption)
                                                .foregroundColor(.lcTextSecondary.opacity(0.7))
                                        } else {
                                            ForEach(todoItems, id: \.id) { item in
                                                HStack(spacing: 8) {
                                                    Image(systemName: "circle")
                                                        .foregroundColor(.lcSoftBlue)

                                                    Text(item.title)
                                                        .foregroundColor(.lcText)

                                                    Spacer()
                                                }
                                                .contentShape(Rectangle())
                                                .onTapGesture {
                                                    state.toggleTodo(id: item.id)
                                                }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(12)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .background(Color.lcBackground.ignoresSafeArea())
            .navigationTitle("记录")
        }
    }

    // MARK: - 临时分组数据（先把“长相”做对）
    // 现在我们还没有真正的“历史库”，所以先用 todayTasks 模拟成“今天一组”
    private var groupedDays: [DayGroup] {
        let date = Date()
        return [
            DayGroup(date: date, items: state.todayTasks)
        ]
    }
}

// MARK: - 小模型：一天的分组
private struct DayGroup {
    let date: Date
    let items: [TodoItem]

    var dateKey: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    var dayText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "d"
        return f.string(from: date)
    }

    var weekdayText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "E"
        return f.string(from: date)
    }

    var fullDateText: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年 M月 d日"
        return f.string(from: date)
    }
}
