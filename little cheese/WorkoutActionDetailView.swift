import SwiftUI

// MARK: - 1. 运动动作数据模型
// (这一部分定义了动作的所有信息：名称、肌肉、步骤、提示等)
struct WorkoutActionModel: Identifiable {
    let id = UUID()
    let name: String
    let targetMuscle: String
    let difficulty: String
    let shortDesc: String
    
    // 图示步骤 (目前使用系统内置符号占位)
    let stepImages: [String]
    let stepImageDescs: [String]
    
    // 详细拆解信息
    let mainTargets: String
    let subTargets: String
    let suitableFor: String
    
    let startPosition: [String]
    let executionSteps: [String]
    let commonMistakes: [String]
    let coachTips: String
}

// 默认的“臀桥”示例数据
let sampleGluteBridge = WorkoutActionModel(
    name: "臀桥",
    targetMuscle: "臀部 / 大腿后侧",
    difficulty: "新手友好",
    shortDesc: "这是最基础也最值得练的臀部动作之一，唤醒沉睡的小起司。",
    stepImages: ["figure.pilates", "figure.core.training", "figure.cooldown"],
    stepImageDescs: [
        "Step 1：双脚踩稳，膝盖朝前",
        "Step 2：夹臀发力，抬起髋部",
        "Step 3：顶点停一秒，缓慢落下"
    ],
    mainTargets: "臀大肌",
    subTargets: "大腿后侧、核心稳定",
    suitableFor: "久坐族、臀部无力、想练翘臀的新手",
    startPosition: [
        "仰卧在垫子上，双膝弯曲",
        "双脚与髋同宽踩地，脚跟靠近臀部",
        "手臂自然平放在身体两侧",
        "下巴微收，腰部自然贴地，不要主动拱起来"
    ],
    executionSteps: [
        "先吸气，感受脚跟踩稳地面的力量",
        "呼气时收紧核心，夹紧臀部，把髋部向上抬起",
        "抬至肩膀、髋部、膝盖接近一条直线",
        "在最高点停顿 1 秒，用心感受臀部的收缩发热",
        "吸气时缓慢且有控制地放下，不要整个人砸向地面"
    ],
    commonMistakes: [
        "用腰去顶（腰部过度弯曲），而不是用臀部发力",
        "抬起时膝盖不自觉向外翻或向内扣",
        "下放太快，完全失去了肌肉控制"
    ],
    coachTips: "先别急着抬很高，第一步是找到臀部紧绷发力的感觉。如果总感觉腰酸，先把幅度做小一点。宁可慢一点，也不要乱冲次数哦 🧀"
)

// MARK: - 2. 动作详情主视图
struct WorkoutActionDetailView: View {
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
    
    // MARK: - [子组件] 图示步骤区
    private var visualStepsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(action.stepImages.enumerated()), id: \.offset) { index, imageName in
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.lcCardBackground)
                            .frame(width: 160, height: 160)
                            .overlay(Image(systemName: imageName).font(.largeTitle).foregroundColor(.lcSoftBlue))
                            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
                        
                        Text(action.stepImageDescs[index])
                            .font(.caption)
                            .foregroundColor(.lcTextSecondary)
                            .frame(width: 160, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - [子组件] 训练目标卡片
    private var targetMusclesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(icon: "target", title: "这个动作练哪里")
            VStack(alignment: .leading, spacing: 6) {
                infoRow(label: "主要训练：", value: action.mainTargets)
                infoRow(label: "辅助训练：", value: action.subTargets)
                infoRow(label: "适合人群：", value: action.suitableFor)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.lcCardBackground))
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
            LinearGradient(colors: [.lcBackground.opacity(0), .lcBackground], startPoint: .top, endPoint: .bottom).frame(height: 20)
            HStack(spacing: 16) {
                Button { dismiss() } label: {
                    Text("返回动作库").font(.headline).foregroundColor(.lcTextSecondary)
                        .frame(width: 120).padding(.vertical, 16)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.lcSoftBlue.opacity(0.3)))
                }
                
                // ✨ 这里就是通往“执行模式”的传送门！
                NavigationLink(destination: WorkoutExecutionView(action: action)) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("开始陪我做")
                    }
                    .font(.headline.bold()).foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 16)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color.lcAccentBlue))
                    .shadow(color: Color.lcAccentBlue.opacity(0.3), radius: 8, y: 4)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 30).background(Color.lcBackground)
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
    WorkoutActionDetailView(action: sampleGluteBridge)
}
