import Foundation

// MARK: - 动作分类
enum ExerciseCategory: String, Codable, CaseIterable, Hashable {
    case lowerBody = "下半身"
    case upperBody = "上半身"
    case core = "核心"
    case fullBody = "全身"
    case cardio = "有氧"
    case mobility = "活动度"
}

// MARK: - 统一的运动动作数据模型 (豪华插画版)
struct WorkoutActionModel: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: ExerciseCategory
    let targetMuscle: String
    let difficulty: String
    let shortDesc: String
    
    // 🧀 变更点：增加一个主图示 (SF Symbol 名称)
    let mainImage: String
    
    // 图示步骤 (把这里变成具体的 SF Symbol 图标)
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
// MARK: - 动作库数据 (包含我们之前所有的动作，增加了 SF Symbol 占位)
enum WorkoutLibrary {
    static let exercises: [WorkoutActionModel] = [
        // 1. 臀桥
        WorkoutActionModel(
            name: "臀桥",
            category: .lowerBody,
            targetMuscle: "臀部 / 大腿后侧",
            difficulty: "新手友好",
            shortDesc: "最基础也最值得练的臀部动作之一，唤醒沉睡的小起司。",
            // 🧀 变更点：增加一个主图示
            mainImage: "figure.pilates.circle.fill",
            stepImages: ["figure.pilates", "figure.core.training", "figure.cooldown"],
            stepImageDescs: [
                "Step 1：双脚踩稳，仰卧",
                "Step 2：夹臀发力抬起",
                "Step 3：顶端停一秒，缓慢落下"
            ],
            mainTargets: "臀大肌",
            subTargets: "大腿后侧、核心稳定",
            suitableFor: "久坐族、臀部无力、想练翘臀的新手",
            startPosition: [
                "仰卧在垫子上，双膝弯曲",
                "双脚与髋同宽踩地，脚跟靠近臀部",
                "手臂自然平放在身体两侧"
            ],
            executionSteps: [
                "先吸气，感受脚跟踩稳地面的力量",
                "呼气时收紧核心，夹紧臀部，把髋部向上抬起",
                "在最高点停顿 1 秒，用心感受臀部的收缩发热",
                "吸气时缓慢且有控制地放下"
            ],
            commonMistakes: [
                "用腰去顶（腰部过度弯曲），而不是用臀部发力",
                "下放太快，完全失去了肌肉控制"
            ],
            coachTips: "先别急着抬很高，第一步是找到臀部紧绷发力的感觉。宁可慢一点，也不要乱冲次数哦 🧀"
        ),
        
        // 2. 徒手深蹲
        WorkoutActionModel(
            name: "徒手深蹲",
            category: .lowerBody,
            targetMuscle: "大腿前侧 / 臀部",
            difficulty: "基础必练",
            shortDesc: "练腿和屁股的基础动作，稳扎稳打。",
            // 🧀 变更点：增加一个主图示
            mainImage: "figure.strengthtraining.traditional.circle.fill",
            stepImages: ["figure.stand", "figure.strengthtraining.traditional", "figure.stand"],
            stepImageDescs: [
                "Step 1：双脚与肩同宽",
                "Step 2：象往后坐椅子一样往下",
                "Step 3：脚掌踩稳，臀腿发力站起"
            ],
            mainTargets: "大腿前侧、臀大肌",
            subTargets: "核心稳定",
            suitableFor: "想要紧致双腿、提升下肢力量的人",
            startPosition: [
                "双脚打开到与肩差不多宽，脚尖微微朝外",
                "站直，肚子轻轻收住，肩膀放松",
                "双手可以放胸前，帮助保持平衡"
            ],
            executionSteps: [
                "先想象你要往后坐椅子，屁股先往后推",
                "慢慢屈膝往下坐，下去时保持胸口不要塌",
                "蹲到你觉得还稳、还能控制住的位置",
                "脚掌踩稳地面，用臀部和腿发力站起来"
            ],
            commonMistakes: [
                "膝盖一下子冲得太前，自己却控制不住",
                "蹲下时胸口塌掉、背变圆",
                "脚后跟离地，重心跑到前脚掌"
            ],
            coachTips: "先不要追求蹲很低，先把动作做稳。稳，比低更重要 🧀"
        )
    ]
}
