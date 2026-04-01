import SwiftUI

// MARK: - 灵光收集箱 (带日期提醒版)

struct InboxView: View {
    @ObservedObject var state: AppState
    
    // 输入状态
    @State private var newItemTitle: String = ""
    
    // ✨ 新增：选中的日期（nil 表示不设提醒）
    @State private var selectedDate: Date = Date()
    @State private var showDatePicker: Bool = false // 是否展开日期选择器
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            Color.lcBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                
                // 1. 顶部输入区
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        
                        // 📅 日期按钮
                        Button {
                            withAnimation(.spring()) {
                                showDatePicker.toggle()
                                // 如果原来没开启，一点就默认设为明天（因为今天的话直接记Today就好了嘛）
                                if showDatePicker {
                                    selectedDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                                }
                            }
                        } label: {
                            Image(systemName: "calendar")
                                .font(.title3)
                                .foregroundColor(showDatePicker ? .white : .lcTextSecondary)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(showDatePicker ? Color.lcAccentBlue : Color.lcCardBackground)
                                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                                )
                        }
                        
                        // 文本输入框
                        TextField("捕捉一个灵感...", text: $newItemTitle)
                            .padding(12)
                            .background(Color.lcCardBackground)
                            .cornerRadius(12)
                            .focused($isFocused)
                            .submitLabel(.done)
                            .onSubmit {
                                addItem()
                            }
                        
                        // 发送按钮
                        Button {
                            addItem()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(newItemTitle.isEmpty ? .lcTextSecondary.opacity(0.3) : .lcAccentBlue)
                        }
                        .disabled(newItemTitle.isEmpty)
                    }
                    
                    // ✨ 隐藏的日期选择器（点日历图标才出来）
                    if showDatePicker {
                        HStack {
                            Text("预计日期：")
                                .font(.caption)
                                .foregroundColor(.lcTextSecondary)
                            
                            DatePicker(
                                "",
                                selection: $selectedDate,
                                displayedComponents: .date
                            )
                            .labelsHidden()
                            .datePickerStyle(.compact) // 紧凑样式
                            
                            Spacer()
                            
                            // 取消日期按钮
                            Button("不设日期") {
                                withAnimation {
                                    showDatePicker = false
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.lcRed)
                        }
                        .padding(.horizontal, 8)
                        .padding(.top, -4)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .padding()
                .background(Color.lcBackground) // 顶栏背景
                
                // 2. 灵感列表
                if state.inboxItems.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(state.inboxItems) { item in
                            HStack(alignment: .top, spacing: 12) {
                                // 左侧图标：有日期显示日历，没日期显示灯泡
                                ZStack {
                                    if item.reminderDate != nil {
                                        Image(systemName: "calendar")
                                            .foregroundColor(.lcAccentBlue)
                                    } else {
                                        Image(systemName: "lightbulb")
                                            .foregroundColor(.lcYellow)
                                    }
                                }
                                .padding(.top, 4)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.text)
                                        .font(.body)
                                        .foregroundColor(.lcText)
                                        .strikethrough(item.isStarred, color: .lcTextSecondary.opacity(0.5)) // 这里用 star 借代完成状态演示
                                    
                                    // ✨ 显示日期小标签
                                    if let date = item.reminderDate {
                                        HStack(spacing: 4) {
                                            Image(systemName: "clock")
                                            Text(formatDate(date))
                                            Text("自动加入 Today")
                                        }
                                        .font(.caption2)
                                        .foregroundColor(.lcAccentBlue)
                                        .padding(.vertical, 2)
                                        .padding(.horizontal, 6)
                                        .background(Color.lcAccentBlue.opacity(0.1))
                                        .cornerRadius(4)
                                    }
                                }
                                .padding(.vertical, 2)
                            }
                            .listRowBackground(Color.lcCardBackground)
                            .listRowSeparator(.hidden)
                            .padding(.vertical, 4)
                            .swipeActions(edge: .leading) {
                                Button {
                                    moveToToday(item)
                                } label: {
                                    Label("做！", systemImage: "sun.max")
                                }
                                .tint(.lcAccentBlue)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    deleteItem(item)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .onAppear {
            // 进来时不强制弹键盘，避免遮挡
            // isFocused = true
        }
    }
    
    // MARK: - 辅助视图
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.lcYellow.opacity(0.5))
            Text("捕捉未来")
                .font(.headline)
                .foregroundColor(.lcTextSecondary)
            Text("点一下左上角的日历，\n给灵光设个日期，到了那天它会自动提醒你 🧀")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(.lcTextSecondary)
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - 逻辑
    
    private func addItem() {
        let trimmed = newItemTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        withAnimation {
            // 如果开启了日期选择，就传 selectedDate，否则传 nil
            let dateToSave = showDatePicker ? selectedDate : nil
            state.addInboxItem(text: trimmed, date: dateToSave)
            
            // 重置状态
            newItemTitle = ""
            showDatePicker = false
        }
    }
    
    private func deleteItem(_ item: InboxItem) {
        withAnimation {
            state.deleteInboxItem(id: item.id)
        }
    }
    
    private func moveToToday(_ item: InboxItem) {
        withAnimation {
            state.addTodayTask(title: item.text)
            state.deleteInboxItem(id: item.id)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M月d日"
        return f.string(from: date)
    }
}
