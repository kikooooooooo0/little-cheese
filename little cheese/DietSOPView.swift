import SwiftUI

// MARK: - 1. SOP 列表视图 (也就是主页在找的那把“钥匙”)
struct DietSOPListView: View {
    @ObservedObject var state: AppState
    @State private var sops = AppState.defaultDietSOPs
    
    var body: some View {
        List {
            ForEach(sops) { sop in
                NavigationLink(destination: DietSOPExecuteView(state: state, sop: sop)) {
                    HStack {
                        Text(sop.emoji).font(.title2)
                        VStack(alignment: .leading) {
                            Text(sop.name).font(.headline)
                            Text("\(sop.steps.count) 个小步骤").font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("能量补给清单 🧀")
        .background(Color.lcBackground)
        .scrollContentBackground(.hidden)
    }
}

// MARK: - 2. SOP 执行页面
struct DietSOPExecuteView: View {
    @ObservedObject var state: AppState
    let sop: DietSOP
    @State private var completedSteps: Set<Int> = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            progressHeader
            
            Text("\(sop.emoji) \(sop.name)")
                .font(.title.bold())
                .foregroundColor(.lcText)

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(0..<sop.steps.count, id: \.self) { index in
                        stepRow(index: index)
                    }
                }
                .padding()
            }

            Spacer()
            completionButtonSection
        }
        .background(Color.lcBackground.ignoresSafeArea())
    }

    // MARK: - 子组件
    private var progressHeader: some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.lcSoftBlue).frame(height: 12)
            GeometryReader { geo in
                Capsule()
                    .fill(Color.lcYellow)
                    .frame(width: geo.size.width * CGFloat(completedSteps.count) / CGFloat(sop.steps.count), height: 12)
            }
        }
        .frame(height: 12).padding(.horizontal).padding(.top, 20)
    }

    private func stepRow(index: Int) -> some View {
        Button {
            withAnimation(.spring()) {
                if completedSteps.contains(index) {
                    completedSteps.remove(index)
                } else {
                    completedSteps.insert(index)
                }
            }
        } label: {
            HStack {
                Image(systemName: completedSteps.contains(index) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(completedSteps.contains(index) ? .lcGreen : .lcSoftBlue)
                    .font(.title2)
                Text(sop.steps[index])
                    .foregroundColor(.lcText)
                    .strikethrough(completedSteps.contains(index))
                Spacer()
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(Color.lcCardBackground))
            .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var completionButtonSection: some View {
        if completedSteps.count == sop.steps.count {
            VStack(spacing: 12) {
                Text("太棒了！能量补充完毕 🧀").font(.subheadline).foregroundColor(.lcGreen)

                Button {
                    // 1. 发放成就任务
                    state.addTodayTask(title: "完成了饮食SOP: \(sop.name)")
                    
                    // 2. ✨ 核心联动：自动给主页的三餐圆圈打勾！
                    if sop.name.contains("早餐") { state.isBreakfastDone = true }
                    if sop.name.contains("午餐") { state.isLunchDone = true }
                    if sop.name.contains("晚餐") { state.isDinnerDone = true }
                    
                    // 3. 震动反馈
                    #if os(iOS)
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    #endif
                    
                    dismiss()
                } label: {
                    Text("完成并返回")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.lcAccentBlue)
                        .cornerRadius(20)
                        .shadow(color: Color.lcAccentBlue.opacity(0.3), radius: 10, y: 5)
                }
            }
            .padding()
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
