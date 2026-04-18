import Foundation

// MARK: - 单个动作的完整引导信息
struct ExerciseGuide: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let shortDescription: String
    let targetAreas: [String]

    let startPosition: [String]
    let steps: [String]
    let feeling: [String]
    let mistakes: [String]
    let breathing: String?
    let beginnerTip: String?
}

// MARK: - 动作分类（以后列表页会用到）
enum ExerciseCategory: String, Codable, CaseIterable, Hashable {
    case lowerBody = "下半身"
    case upperBody = "上半身"
    case core = "核心"
    case fullBody = "全身"
    case cardio = "有氧"
    case mobility = "活动度"
}

// MARK: - 给列表展示用的包装模型
struct ExerciseItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let category: ExerciseCategory
    let guide: ExerciseGuide
}

// MARK: - 先放一小批示例数据，后面我们再继续扩充
enum ExerciseGuideLibrary {
    static let sampleExercises: [ExerciseItem] = [
        ExerciseItem(
            id: "squat_basic",
            name: "徒手深蹲",
            category: .lowerBody,
            guide: ExerciseGuide(
                id: "squat_basic",
                name: "徒手深蹲",
                shortDescription: "练腿和屁股的基础动作，适合新手入门。",
                targetAreas: ["大腿前侧", "臀部", "核心"],

                startPosition: [
                    "双脚打开到与肩差不多宽。",
                    "脚尖微微朝外，不用太夸张。",
                    "站直，肚子轻轻收住，肩膀放松。",
                    "双手可以放胸前，帮助保持平衡。"
                ],

                steps: [
                    "先想象你要往后坐椅子，屁股先往后。",
                    "再慢慢屈膝往下坐，不要着急。",
                    "下去时保持胸口不要塌，眼睛看前方。",
                    "蹲到你觉得还稳、还能控制住的位置就可以。",
                    "脚掌踩稳地面，用臀部和腿发力站起来。",
                    "站起来后身体回到直立。"
                ],

                feeling: [
                    "大腿前侧会发力。",
                    "屁股会参与发力。",
                    "肚子会有一点点紧，帮助你稳住身体。"
                ],

                mistakes: [
                    "膝盖一下子冲得太前，自己却控制不住。",
                    "蹲下时胸口塌掉、背变圆。",
                    "脚后跟离地，重心跑到前脚掌。",
                    "为了蹲更低，硬把自己压下去，结果姿势乱掉。"
                ],

                breathing: "下蹲时吸气，站起来时慢慢呼气。",
                beginnerTip: "先不要追求蹲很低，先把动作做稳。稳，比低更重要。"
            )
        ),

        ExerciseItem(
            id: "rdl_basic",
            name: "哑铃罗马尼亚硬拉",
            category: .lowerBody,
            guide: ExerciseGuide(
                id: "rdl_basic",
                name: "哑铃罗马尼亚硬拉",
                shortDescription: "练臀部和大腿后侧，不是蹲下去，而是屁股往后推。",
                targetAreas: ["臀部", "大腿后侧", "下背稳定"],

                startPosition: [
                    "双脚与髋同宽站好。",
                    "双手各拿一个哑铃，自然放在大腿前。",
                    "膝盖微微弯，不要锁死。",
                    "背部保持自然直，肩膀放松。"
                ],

                steps: [
                    "先把屁股慢慢往后推，就像有人在后面拉你的屁股。",
                    "上半身跟着自然前倾，但背不要弯。",
                    "哑铃贴着腿往下移动，不要离腿太远。",
                    "当你感觉大腿后侧被拉住时，就停下。",
                    "脚掌踩稳地面，用臀部发力把身体带回站直。"
                ],

                feeling: [
                    "大腿后侧会有明显拉伸感。",
                    "站起来时屁股会发力。",
                    "腰是稳住身体，不是主动发力顶起来。"
                ],

                mistakes: [
                    "把动作做成蹲下去，而不是屁股往后推。",
                    "背变圆，用腰硬拉起来。",
                    "哑铃离腿太远，让腰压力变大。",
                    "为了下得更低，硬压自己到失去控制。"
                ],

                breathing: "往下时吸气，站起时呼气。",
                beginnerTip: "先练会“屁股往后推”，比拿更重的哑铃更重要。"
            )
        ),

        ExerciseItem(
            id: "glute_bridge_basic",
            name: "臀桥",
            category: .lowerBody,
            guide: ExerciseGuide(
                id: "glute_bridge_basic",
                name: "臀桥",
                shortDescription: "对新手很友好，主要练屁股。",
                targetAreas: ["臀部", "大腿后侧", "核心"],

                startPosition: [
                    "仰卧在垫子上。",
                    "双膝弯曲，双脚踩地。",
                    "脚跟离屁股不要太远，也不要太近。",
                    "双手自然放身体两侧。"
                ],

                steps: [
                    "先把肚子轻轻收住，腰不要乱顶。",
                    "脚掌踩地，慢慢把屁股抬起来。",
                    "抬到肩、髋、膝差不多一条斜线的位置。",
                    "顶端停一小下，感受屁股夹紧。",
                    "再慢慢放下来，不要直接砸下去。"
                ],

                feeling: [
                    "最明显应该是屁股发力。",
                    "大腿后侧会有一点参与。",
                    "腰不应该是最酸的地方。"
                ],

                mistakes: [
                    "抬起来时用腰猛顶，而不是用屁股发力。",
                    "脚放得太远，结果大腿后侧太累。",
                    "动作太快，上下乱弹。",
                    "顶端没有停留，屁股没真正参与。"
                ],

                breathing: "抬起时呼气，落下时吸气。",
                beginnerTip: "如果总是感觉到腰，很可能是屁股没有先发力。"
            )
        )
    ]
}
