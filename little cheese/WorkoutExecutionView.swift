import SwiftUI

// MARK: - 运动执行页 (陪练模式)
struct WorkoutExecutionView: View {
    @ObservedObject var state: AppState
    let action: WorkoutActionModel
    
    @Environment(\.dismiss) var dismiss
    // 运动状态管理
    @State private var currentSet: Int = 1
    @State private var totalSets: Int = 3 // 默认做3组
    @State private var targetReps: Int = 12 // 默认每组12次
    
    // 休息倒计时状态
    @State private var isResting: Bool = false
    @State private var restTimeRemaining: Int = 30
    @State private var timer: Timer? = nil
    
    var body: some View {
        ZStack {
            // 背景色：休息时用安静的浅蓝，运动时用充满活力的浅黄
            (isResting ? Color.lcSoftBlue.opacity(0.2) : Color.lcBackground)
                .ignoresSafeArea()
                .animation(.easeInOut, value: isResting)
            
            VStack(spacing: 30) {
                
                // 1. 顶部：导航与进度
                headerSection
                
                Spacer()
                
                // 2. 核心区：运动中 vs 休息中
                if isResting {
                    restingView
                } else {
                    activeWorkoutView
                }
                
                Spacer()
                
                // 3. 底部：大按钮操作区
                bottomButton
            }
            .padding(.vertical, 20)
        }
        .navigationBarHidden(true)
        .onDisappear {
            stopTimer() // 离开页面时记得关掉定时器
        }
    }
    
    // MARK: - 子视图组件
    
    // 顶部 Header
    private var headerSection: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.lcTextSecondary.opacity(0.6))
            }
            
            Spacer()
            
            // 组数进度药丸
            HStack(spacing: 6) {
                Text("第 \(currentSet) 组")
                    .font(.headline)
                    .foregroundColor(isResting ? .lcAccentBlue : .lcYellow)
                Text("/ 共 \(totalSets) 组")
                    .font(.subheadline)
                    .foregroundColor(.lcTextSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(isResting ? Color.lcAccentBlue.opacity(0.1) : Color.lcCheeseYellow.opacity(0.15))
            )
            
            Spacer()
            
            // 占位，保持居中对齐
            Image(systemName: "xmark.circle.fill")
                .font(.title2)
                .foregroundColor(.clear)
        }
        .padding(.horizontal, 24)
    }
    
    // 运动中视图
    private var activeWorkoutView: some View {
        VStack(spacing: 24) {
            // 动作大图 (占位)
            ZStack {
                Circle()
                    .fill(Color.lcCardBackground)
                    .frame(width: 200, height: 200)
                    .shadow(color: .black.opacity(0.04), radius: 10, y: 5)
                
                Image(systemName: action.stepImages.first ?? "figure.run")
                    .font(.system(size: 80))
                    .foregroundColor(.lcAccentBlue)
            }
            
            VStack(spacing: 12) {
                Text(action.name)
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.lcText)
                
                Text("目标：\(targetReps) 次")
                    .font(.title3.bold())
                    .foregroundColor(.lcTextSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.lcCardBackground)
                    .clipShape(Capsule())
            }
            
            // 教练的温馨提示（只在运动时显示，安抚情绪）
            Text("慢慢来，感受【\(action.mainTargets)】的发力 🧀")
                .font(.subheadline)
                .foregroundColor(.lcTextSecondary)
                .padding(.top, 10)
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // 休息倒计时视图
    private var restingView: some View {
        VStack(spacing: 24) {
            Text("做得很棒！休息一下")
                .font(.headline)
                .foregroundColor(.lcAccentBlue)
            
            // 大号倒计时
            ZStack {
                Circle()
                    .stroke(Color.lcSoftBlue.opacity(0.3), lineWidth: 12)
                    .frame(width: 220, height: 220)
                
                Circle()
                    .trim(from: 0, to: CGFloat(restTimeRemaining) / 30.0) // 假设默认休息30秒
                    .stroke(Color.lcAccentBlue, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 220, height: 220)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1.0), value: restTimeRemaining)
                
                Text("\(restTimeRemaining)")
                    .font(.system(size: 72, weight: .black, design: .rounded))
                    .foregroundColor(.lcText)
            }
            
            if currentSet < totalSets {
                Text("下一组准备：\(action.name)")
                    .font(.subheadline)
                    .foregroundColor(.lcTextSecondary)
            }
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // 底部大按钮
    private var bottomButton: some View {
        VStack {
            if isResting {
                Button {
                    skipRest()
                } label: {
                    Text("跳过休息，直接开始")
                        .font(.headline)
                        .foregroundColor(.lcAccentBlue)
                        .padding(.vertical, 16)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 20).stroke(Color.lcAccentBlue, lineWidth: 2))
                }
            } else {
                Button {
                    finishSet()
                } label: {
                    Text(currentSet >= totalSets ? "完成全部训练 🎉" : "完成本组，休息一下")
                        .font(.headline.bold())
                        .foregroundColor(.white)
                        .padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.lcAccentBlue))
                        .shadow(color: Color.lcAccentBlue.opacity(0.3), radius: 10, y: 5)
                }
            }
        }
        .padding(.horizontal, 30)
    }
    
    // MARK: - 逻辑控制
    
    private func finishSet() {
        // 如果是最后一组，记录到 Today / 日记联动，然后结束
        if currentSet >= totalSets {
            let workoutTitle = "🏋️ 动作已完成：\(action.name) \(totalSets)组 × \(targetReps)次"
            
            state.addTodayTask(title: workoutTitle)
            
            print("训练完成！已记录到今日任务：\(workoutTitle)")
            dismiss()
        } else {
            // 否则进入休息状态
            withAnimation {
                isResting = true
                restTimeRemaining = 30 // 每次休息重置为30秒
            }
            startTimer()
        }
    }
    
    private func skipRest() {
        stopTimer()
        withAnimation {
            isResting = false
            currentSet += 1
        }
    }
    
    private func startTimer() {
        stopTimer() // 确保没有重复的定时器
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if restTimeRemaining > 0 {
                restTimeRemaining -= 1
            } else {
                // 倒计时结束，自动进入下一组
                skipRest()
                #if os(iOS)
                // 震动提示
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                #endif
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// 预览
// 预览
#Preview {
    WorkoutExecutionView(
        state: AppState(),
        action: WorkoutLibrary.exercises[0]
    )
}
