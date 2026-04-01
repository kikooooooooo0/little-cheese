import SwiftUI

struct PomodoroView: View {

    @ObservedObject var state: AppState

    // ⭐ 当前这一轮想用多久（分钟），通过 Stepper 调整
    @State private var durationMinutes: Int = 25

    // 选中的 LifeArea
    @State private var selectedAreaId: UUID? = nil

    // ⭐ 本次番茄的备注
    @State private var note: String = ""

    // 控制备注输入框是否在编辑中（用来收键盘）
    @FocusState private var isNoteFieldFocused: Bool

    /// 当前界面显示的秒数：
    /// - 如果正在跑，用全局倒计时的秒数；
    /// - 如果没在跑，用「预览」：durationMinutes * 60
    private var secondsToShow: Int {
        if state.isPomodoroRunning {
            return state.pomodoroRemainingSeconds
        } else {
            return durationMinutes * 60
        }
    }
    // 启动按钮的样式：模仿「日记列表」那种胶囊卡片
    private var startButtonBackgroundColor: Color {
        if state.isPomodoroRunning {
            // 进行中：淡一点的蓝色，像被“按下去了”
            return Color.lcAccentBlue.opacity(0.16)
        } else {
            // 未开始：饱和一点的蓝色，像「今天」那条卡片
            return Color.lcAccentBlue
        }
    }

    private var startButtonTextColor: Color {
        state.isPomodoroRunning ? Color.lcAccentBlue : Color.white
    }

    private var startButtonShadowOpacity: Double {
        state.isPomodoroRunning ? 0.08 : 0.20
    }
    // 当前这一轮的总秒数：运行中用全局设置，未开始用本地 Stepper 的值
    private var totalSecondsForProgress: Int {
        if state.isPomodoroRunning {
            return max(1, state.pomodoroDurationMinutes * 60)
        } else {
            return max(1, durationMinutes * 60)
        }
    }

    // 0 ~ 1 的进度值
    private var pomodoroProgress: Double {
        let used = max(0, totalSecondsForProgress - secondsToShow)
        return min(1.0, Double(used) / Double(totalSecondsForProgress))
    }

    // 进度条左侧的小提示文字
    private var progressLabelPrefix: String {
        if state.isPomodoroRunning {
            return "这一块🧀已经融化了…"
        } else {
            return "准备好开始这块🧀了吗？"
        }
    }

    // 右侧：xx:xx / xx:xx
    private var progressLabelSuffix: String {
        let total = totalSecondsForProgress
        let remain = secondsToShow
        let used = max(0, total - remain)

        func mmss(_ sec: Int) -> String {
            let m = max(0, sec) / 60
            let s = max(0, sec) % 60
            return String(format: "%02d:%02d", m, s)
        }

        return "\(mmss(used)) / \(mmss(total))"
    }

    // ✅ 计算今天各领域的时间占比
        private var todayTimeUsage: [LifeAreaTimeUsage] {
            state.timeUsageFor(date: Date())
        }
   
   
    var body: some View {
        ZStack {
            // 背景：LittleCheese 柔和背景
            Color.lcBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    
                    // 顶部：小起司进度条卡片
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.lcSoftBlue.opacity(0.9),
                                    Color.lcCheeseYellow.opacity(0.95)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22)
                                .stroke(Color.white.opacity(0.7), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
                        .frame(height: 150)
                        .overlay {
                            VStack(alignment: .leading, spacing: 14) {
                                
                                // 第一行：🧀 + 标题
                                HStack(alignment: .center, spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.lcCardBackground.opacity(0.18))
                                            .frame(width: 54, height: 54)
                                        
                                        Text("🧀")
                                            .font(.system(size: 34))
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("小起司番茄钟")
                                            .font(.headline.bold())
                                            .foregroundColor(.white)
                                        
                                        Text(state.isPomodoroRunning ? "这一块专心时间正在慢慢融化…" : "给自己一小块专心时间吧。")
                                            .font(.footnote)
                                            .foregroundColor(.white.opacity(0.9))
                                            .lineLimit(2)
                                    }
                                    
                                    Spacer(minLength: 0)
                                }
                                
                                // 第二行：进度条
                                VStack(alignment: .leading, spacing: 4) {
                                    // 小标签：已经过了多少 / 总共多少
                                    HStack {
                                        Text(progressLabelPrefix)
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.9))
                                        
                                        Spacer()
                                        
                                        Text(progressLabelSuffix)
                                            .font(.caption2.monospacedDigit())
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color.lcCardBackground.opacity(0.24))
                                            .frame(height: 10)
                                        
                                        GeometryReader { geo in
                                            let width = geo.size.width * CGFloat(pomodoroProgress)
                                            Capsule()
                                                .fill(Color.lcCardBackground)
                                                .frame(width: max(0, width), height: 10)
                                        }
                                    }
                                    .frame(height: 10)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    
                    
                    // 中间：计时 + 设置的主卡片
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // 标题 + 倒计时
                        VStack(spacing: 8) {
                            Text("番茄钟")
                                .font(.title2.bold())
                                .foregroundColor(.lcText)
                            
                            Text(formatTime(secondsToShow))
                                .font(.system(size: 54, weight: .bold, design: .rounded))
                                .foregroundColor(.lcText)
                        }
                        .frame(maxWidth: .infinity)
                        
                        // 时长设置
                        VStack(alignment: .leading, spacing: 8) {
                            Text("每个番茄多长？")
                                .font(.subheadline)
                                .foregroundColor(.lcTextSecondary)
                            
                            Stepper("\(durationMinutes) 分钟",
                                    value: $durationMinutes,
                                    in: 5...90,
                                    step: 5)
                            
                            Text("5～90 分钟，每次调 5 分钟。可以根据今天的专注力慢慢调。")
                                .font(.caption)
                                .foregroundColor(.lcTextSecondary)
                        }
                        
                        // 选择 LifeArea（改成一排小药丸）
                        VStack(alignment: .leading, spacing: 8) {
                            Text("把这个番茄算到哪个领域？")
                                .font(.subheadline)
                                .foregroundColor(.lcTextSecondary)
                            
                            if state.lifeAreas.isEmpty {
                                Text("还没有生活领域，可以先在「目标」页添加 🧀")
                                    .font(.footnote)
                                    .foregroundColor(.lcTextSecondary)
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        // 不绑定领域的按钮
                                        let noBindingSelected = (selectedAreaId == nil)
                                        Button {
                                            selectedAreaId = nil
                                        } label: {
                                            HStack(spacing: 4) {
                                                Text("🌱")
                                                Text("不绑定领域")
                                            }
                                            .font(.caption)
                                            .padding(.vertical, 6)
                                            .padding(.horizontal, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 999, style: .continuous)
                                                    .fill(noBindingSelected ? Color.lcSoftBlue.opacity(0.25) : Color.white)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 999, style: .continuous)
                                                    .stroke(noBindingSelected ? Color.lcAccentBlue : Color.lcSoftBlue.opacity(0.4), lineWidth: 1)
                                            )
                                        }
                                        
                                        ForEach(state.lifeAreas) { area in
                                            let isSelected = selectedAreaId == area.id
                                            Button {
                                                selectedAreaId = area.id
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Text(area.emoji)
                                                    Text(area.name)
                                                }
                                                .font(.caption)
                                                .padding(.vertical, 6)
                                                .padding(.horizontal, 10)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                                        .fill(isSelected ? area.primaryColor.opacity(0.9) : Color.white)
                                                )
                                                .foregroundColor(isSelected ? .white : .lcText)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 999, style: .continuous)
                                                        .stroke(
                                                            isSelected ? Color.white.opacity(0.9) : Color.lcSoftBlue.opacity(0.4),
                                                            lineWidth: 1
                                                        )
                                                )
                                                .shadow(color: .black.opacity(isSelected ? 0.12 : 0.02),
                                                        radius: isSelected ? 4 : 1,
                                                        x: 0,
                                                        y: isSelected ? 3 : 1)
                                            }
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                        
                        // 备注
                        VStack(alignment: .leading, spacing: 8) {
                            Text("这一块专心时间要做什么？")
                                .font(.subheadline)
                                .foregroundColor(.lcTextSecondary)
                            
                            TextField("例如：阅读 Barkley 第 3 章 / 写今日日记", text: $note)
                                .textFieldStyle(.roundedBorder)
                                .focused($isNoteFieldFocused)
                        }
                        
                        // 启动按钮
                        Button(action: startPomodoro) {
                            HStack(spacing: 8) {
                                Image(systemName: state.isPomodoroRunning ? "hourglass" : "play.fill")
                                Text(state.isPomodoroRunning ? "番茄进行中…" : "开始这块小起司时间")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 26, style: .continuous)
                                    .fill(startButtonBackgroundColor)
                            )
                            .foregroundColor(startButtonTextColor)
                            .shadow(
                                color: .black.opacity(startButtonShadowOpacity),
                                radius: 10,
                                x: 0,
                                y: 6
                            )
                        }
                        .disabled(state.isPomodoroRunning)
                        
                        // 小提示
                        Text("计时结束时，会自动加上一块时间小砖，并统计到对应生活领域本周的用时。")
                            .font(.footnote)
                            .foregroundColor(.lcTextSecondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.lcCardBackground)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 6)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .contentShape(Rectangle())          // 让整个区域都可点击
        .onTapGesture {
            isNoteFieldFocused = false      // 点空白处收键盘
        }
        .onAppear {
            // 先根据当前时间更新一下剩余秒数
            state.updatePomodoroRemainingIfNeeded()
            
            // 再用上一次的设置做默认值
            durationMinutes = state.pomodoroDurationMinutes
            selectedAreaId = state.pomodoroLifeAreaId
            note = state.pomodoroNote
        }
    }


    // MARK: - 开始一个番茄

    private func startPomodoro() {
        // 如果已经在跑，就不重复开始
        guard !state.isPomodoroRunning else { return }

        // 收起键盘
        isNoteFieldFocused = false

        // 调用 AppState 的全局计时器逻辑
        state.startPomodoro(
            minutes: durationMinutes,
            lifeAreaId: selectedAreaId,
            note: note,
            phase: .focus
        )
    }

    // MARK: - 时间格式化

    private func formatTime(_ sec: Int) -> String {
        let m = max(0, sec) / 60
        let s = max(0, sec) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
