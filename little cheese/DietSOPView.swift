import SwiftUI

struct DietSOPListView: View {
    @ObservedObject var state: AppState
    @State private var sops = AppState.defaultDietSOPs // 先用默认数据测试
    
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

struct DietSOPExecuteView: View {
    @ObservedObject var state: AppState
    let sop: DietSOP
    @State private var completedSteps: Set<Int> = []
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // 顶部进度
            ZStack(alignment: .leading) {
                Capsule().fill(Color.lcSoftBlue).frame(height: 12)
                GeometryReader { geo in
                    Capsule()
                        .fill(Color.lcYellow)
                        .frame(width: geo.size.width * CGFloat(completedSteps.count) / CGFloat(sop.steps.count), height: 12)
                }
            }
            .frame(height: 12).padding(.horizontal)

            Text("\(sop.emoji) \(sop.name)").font(.title.bold())

            // 步骤列表
            VStack(alignment: .leading, spacing: 16) {
                ForEach(0..<sop.steps.count, id: \.self) { index in
                    Button {
                        if completedSteps.contains(index) {
                            completedSteps.remove(index)
                        } else {
                            completedSteps.insert(index)
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
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()

            Spacer()

            // 完成按钮
            if completedSteps.count == sop.steps.count {
                Button {
                    // 这里未来会联动添加时间块
                    state.addTodayTask(title: "完成了饮食SOP: \(sop.name)")
                    dismiss()
                } label: {
                    Text("喂养成功！奖励一块起司 🧀")
                        .font(.headline).foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding().background(Color.lcAccentBlue).cornerRadius(20)
                }
                .padding()
                .transition(.scale)
            }
        }
        .background(Color.lcBackground.ignoresSafeArea())
    }
}

