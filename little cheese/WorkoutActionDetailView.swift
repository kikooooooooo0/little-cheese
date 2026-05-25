import SwiftUI


// MARK: - 2. 动作详情主视图
struct WorkoutActionDetailView: View {
    @ObservedObject var state: AppState
    let action: WorkoutActionModel
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        // 使用 NavigationStack 包裹，确保跳转功能正常
        NavigationStack {
            ZStack(alignment: .bottom) {
                Color.lcBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // 1. 顶部：视觉头图与动作标题
                        headerSection
                        
                        // 2. 图示区：横向滑动的步骤卡片
                        visualStepsSection
                        
                        // 3. 详细内容：卡片式拆解
                        VStack(spacing: 20) {
                            targetMusclesCard
                            startPositionCard
                            executionStepsCard
                            mistakesAndTipsSection
                        }
                        .padding(.horizontal, 20)
                        
                        // 底部占位，防止内容被悬浮栏遮挡
                        Spacer().frame(height: 120)
                    }
                    .padding(.top, 16)
                }
                
                // 4. 底部：悬浮操作栏（包含进入陪练页的跳转）
                bottomActionBar
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - [子组件] 顶部头图区
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.lcSoftBlue.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "figure.mind.and.body")
                            .font(.system(size: 60))
                            .foregroundColor(.lcAccentBlue.opacity(0.5))
                    )
                
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.bold())
                        .foregroundColor(.lcText)
                        .padding(12)
                        .background(Color.white.opacity(0.8))
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                }
                .padding(16)
            }
            .padding(.horizontal, 20)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(action.name)
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(.lcText)
                
                HStack(spacing: 8) {
                    tagLabel(text: action.targetMuscle, color: .lcAccentBlue)
                    tagLabel(text: action.difficulty, color: .lcYellow)
                }
                
                Text(action.shortDesc)
                    .font(.subheadline)
                    .foregroundColor(.lcTextSecondary)
                    .lineLimit(2)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - [子组件] 图示步骤区 (颜值升级版)
        private var visualStepsSection: some View {
            VStack(alignment: .leading, spacing: 12) {
                // 给步骤加一个可爱的小标题
                sectionHeader(icon: "eye.fill", title: "动作示范")
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(action.stepImages.enumerated()), id: \.offset) { index, imageName in
                            VStack(alignment: .leading, spacing: 12) {
                                // 每一个步骤的小卡片，背景色用温柔的浅蓝
                                ZStack {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .fill(Color.lcSoftBlue.opacity(0.15))
                                        .frame(width: 180, height: 180)
                                    
                                    // 这里显示图标，将来你画好图了，它就会显示你的画
                                    Image(systemName: imageName)
                                        .font(.system(size: 60))
                                        .foregroundColor(.lcAccentBlue)
                                }
                                .shadow(color: .black.opacity(0.02), radius: 8, y: 4)
                                
                                // 步骤描述文字
                                Text(action.stepImageDescs[index])
                                    .font(.subheadline.bold())
                                    .foregroundColor(.lcText)
                                    .frame(width: 180, alignment: .leading)
                                    .lineLimit(2)
                            }
                        }
                    }
                    .padding(.horizontal, 24) // 让卡片不要贴着屏幕边
                }
            }
        }

        // MARK: - [子组件] 训练目标卡片
        private var targetMusclesCard: some View {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeader(icon: "target", title: "这个动作练哪里")
                
                VStack(alignment: .leading, spacing: 8) {
                    infoRow(label: "🔥 主要训练：", value: action.mainTargets)
                    infoRow(label: "💪 辅助训练：", value: action.subTargets)
                    infoRow(label: "🧀 适合人群：", value: action.suitableFor)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 20).fill(Color.lcCardBackground))
                .shadow(color: .black.opacity(0.02), radius: 10, y: 5)
            }
        }
    // MARK: - [子组件] 准备姿势卡片
    private var startPositionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "figure.stand", title: "开始姿势")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(action.startPosition, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Circle().fill(Color.lcCheeseYellow).frame(width: 6, height: 6).padding(.top, 6)
                        Text(line).font(.subheadline).foregroundColor(.lcText)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.lcCardBackground))
        }
    }

    // MARK: - [子组件] 动作步骤卡片
    private var executionStepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "play.circle.fill", title: "动作步骤")
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(action.executionSteps.enumerated()), id: \.offset) { i, step in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(i + 1)").font(.caption.bold()).foregroundColor(.white)
                            .frame(width: 20, height: 20).background(Circle().fill(Color.lcAccentBlue))
                        Text(step).font(.subheadline).foregroundColor(.lcText)
                    }
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.lcCardBackground))
        }
    }

    // MARK: - [子组件] 错误纠正与小贴士
    private var mistakesAndTipsSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Label("常见错误", systemImage: "exclamationmark.triangle.fill").font(.headline).foregroundColor(.lcRed)
                ForEach(action.commonMistakes, id: \.self) { mistake in
                    HStack(alignment: .top) {
                        Image(systemName: "xmark").font(.caption).foregroundColor(.lcRed).padding(.top, 2)
                        Text(mistake).font(.subheadline)
                    }
                }
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.lcRed.opacity(0.08)))
            
            VStack(alignment: .leading, spacing: 10) {
                Label("教练小声说", systemImage: "lightbulb.fill").font(.headline).foregroundColor(.lcYellow)
                Text(action.coachTips).font(.subheadline).lineSpacing(4)
            }
            .padding(16).frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.lcCheeseYellow.opacity(0.15)))
        }
    }

    // MARK: - [子组件] 底部操作栏 (重要：连接陪练页)
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [.lcBackground.opacity(0), .lcBackground],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)

            HStack(spacing: 16) {
                Button {
                    dismiss()
                } label: {
                    Text("返回动作库")
                        .font(.headline)
                        .foregroundColor(.lcTextSecondary)
                        .frame(width: 120)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.lcSoftBlue.opacity(0.3))
                        )
                }

                NavigationLink {
                    WorkoutExecutionView(state: state, action: action)
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("开始陪我做")
                    }
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.lcAccentBlue)
                    )
                    .shadow(
                        color: Color.lcAccentBlue.opacity(0.3),
                        radius: 8,
                        y: 4
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
            .background(Color.lcBackground)
        }
    }
    // MARK: - 私有辅助工具
    private func tagLabel(text: String, color: Color) -> some View {
        Text(text).font(.caption.bold()).padding(.horizontal, 10).padding(.vertical, 6)
            .background(color.opacity(0.15)).foregroundColor(color).cornerRadius(8)
    }
    
    private func sectionHeader(icon: String, title: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundColor(.lcAccentBlue)
            Text(title).font(.headline).foregroundColor(.lcText)
        }
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 4) {
            Text(label).foregroundColor(.lcTextSecondary)
            Text(value).foregroundColor(.lcText)
        }
    }

    }

    // 预览预览！
    #Preview {
        WorkoutActionDetailView(
            state: AppState(),
            action: WorkoutLibrary.exercises[0]
        )
    }
