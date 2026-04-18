import SwiftUI

// MARK: - 🧠 引擎数据层 (抽离后的独立动作库)

func getSmartWarmupPool(part: Int) -> [FitnessAction] {
    if part == 2 { // 下肢热身：髋 + 臀唤醒
        return [
            FitnessAction(name: "动态臀桥唤醒", targetMuscle: "臀大肌", tip: "不要用腰顶，屁股夹紧发力", emojiIcon: "🌉", steps: ["仰卧屈膝，脚跟踩地", "呼气时顶起臀部，感受屁股发力", "慢慢放下，不要砸回地面"], baseReps: "15 次"),
            FitnessAction(name: "世界最伟大拉伸", targetMuscle: "髋关节活动度", tip: "动作一定要慢，感受髋部和胸椎被打开", emojiIcon: "🌍", steps: ["弓步迈出，同侧手肘尽量靠近地面", "随后同侧手臂向天花板打开，带动胸椎旋转", "回到起始位后重复"], baseReps: "每侧 5 次")
        ].shuffled()
    } else if part == 1 { // 背部热身：脊柱活动 + 肩胛控制
        return [
            FitnessAction(name: "猫牛式脊柱活动", targetMuscle: "脊柱灵活度", tip: "一节一节地活动脊柱，不要只甩脖子", emojiIcon: "🐈", steps: ["四足跪姿，手在肩下，膝在髋下", "吸气时抬头塌腰，胸口打开", "呼气时低头拱背，肚脐向里收"], baseReps: "10 次"),
            FitnessAction(name: "墙天使预热 / 墙滑", targetMuscle: "肩胛控制", tip: "重点不是抬高，而是肋骨别乱翻、肩膀别耸", emojiIcon: "🪽", steps: ["背靠墙站立，上背尽量贴墙", "手臂摆成 W 形，缓慢向上滑到 Y 形", "全程保持脖子放松，感受肩胛顺畅滑动"], baseReps: "8 - 10 次")
        ].shuffled()
    } else { // 核心热身：呼吸控制 + 深层稳定预激活
        return [
            FitnessAction(name: "死虫子预激活", targetMuscle: "深层核心", tip: "下背部必须贴地，不要让腰偷偷拱起来", emojiIcon: "🪲", steps: ["仰卧，双手指天，双腿抬起屈膝 90 度", "先把下背压平地面，再缓慢伸出对侧手脚", "动作做小一点没关系，重点是稳定"], baseReps: "每侧 6 - 8 次"),
            FitnessAction(name: "骨盆呼吸收紧", targetMuscle: "腹横肌 / 骨盆控制", tip: "呼气时轻轻收紧下腹，不要耸肩憋气", emojiIcon: "🌬️", steps: ["仰卧屈膝，双脚踩地，双手放在下腹", "吸气时肋骨打开，呼气时轻轻收紧核心", "感受下腹稳定，而不是大力卷腹"], baseReps: "6 - 8 次呼吸")
        ].shuffled()
    }
}

func getSmartCooldownPool(part: Int) -> [FitnessAction] {
    if part == 2 {
        return [
            FitnessAction(name: "鸽子式臀部拉伸", targetMuscle: "臀大肌", tip: "如果膝盖痛就立刻停止", emojiIcon: "🕊️", steps: ["前腿屈膝横放，后腿伸直", "上半身慢慢趴下感受臀部拉扯"], baseReps: "每侧 45 秒"),
            FitnessAction(name: "大腿前侧站立拉伸", targetMuscle: "股四头肌", tip: "保持身体直立，不要塌腰", emojiIcon: "🦩", steps: ["单手抓住同侧脚踝，将脚跟拉向臀部"], baseReps: "每侧 30 秒")
        ].shuffled()
    } else if part == 1 {
        return [
            FitnessAction(name: "婴儿式背部放松", targetMuscle: "下背阔肌", tip: "尽情感受呼吸，放松全身", emojiIcon: "👶", steps: ["双膝跪地，臀部坐在脚跟，上半身趴下"], baseReps: "1 分钟"),
            FitnessAction(name: "胸部墙壁拉伸", targetMuscle: "胸大肌补偿", tip: "防止练背导致圆肩", emojiIcon: "🚪", steps: ["单手小臂贴住墙面，身体向反方向扭转"], baseReps: "每侧 30 秒")
        ].shuffled()
    } else {
        return [
            FitnessAction(name: "腹部眼镜蛇拉伸", targetMuscle: "腹直肌", tip: "骨盆贴地，肩膀下沉", emojiIcon: "🐍", steps: ["趴在垫子上，双手将上半身撑起"], baseReps: "30 秒"),
            FitnessAction(name: "仰卧脊柱扭转放松", targetMuscle: "下背部", tip: "肩膀不要离开地面", emojiIcon: "🥨", steps: ["仰卧，单腿屈膝跨过身体对侧", "手臂向反方向展开，目光看反方向手指"], baseReps: "每侧 45 秒")
        ].shuffled()
    }
}

func getActiveRestPool() -> [String] {
    return ["腿下击掌 20 次", "靠墙静蹲休息 30 秒", "站立抱膝走 10 步", "慢速高抬腿 20 次", "深呼吸，喝两口水！", "核心收紧站立 20 秒"]
}

func getSmartCardioActions(minutes: Int, selectedCardioName: String) -> [FitnessAction] {
    if minutes <= 15 {
        return [
            FitnessAction(name: "轻松热身段", targetMuscle: "心肺唤醒", tip: "先把呼吸和节奏找回来，不要一上来就猛冲。", emojiIcon: "🌿", steps: ["先用非常轻松的节奏开始", "保持可以完整说话的呼吸感", "结束时身体微微发热就够了"], baseReps: "\(minutes) 分钟")
        ]
    } else if minutes <= 30 {
        switch selectedCardioName {
        case "椭圆机":
            return [
                FitnessAction(name: "椭圆机热身段", targetMuscle: "心肺唤醒", tip: "先把关节和呼吸带起来，不要急着上强度。", emojiIcon: "🛸", steps: ["匀速踩踏，让身体彻底热开", "呼吸慢慢加深，不要憋气", "感觉到微微发热就对了"], baseReps: "10 分钟", quickStats: ["坡度 10", "阻力 4"]),
                FitnessAction(name: "椭圆机主训练段", targetMuscle: "心肺耐力 / 下肢输出", tip: "这一段是主菜，稳住节奏，不要东一脚西一脚。", emojiIcon: "⚡", steps: ["保持持续输出，呼吸明显变重但还能控制动作", "不要只顾快，阻力顶住更重要", "尽量全程节奏稳定"], baseReps: "\(max(20, minutes - 20)) 分钟", quickStats: ["坡度 12", "阻力 6"]),
                FitnessAction(name: "椭圆机冷却段", targetMuscle: "主动恢复", tip: "最后不是摆烂，是慢慢把身体接回来。", emojiIcon: "🍃", steps: ["放慢节奏，让心率回落", "肩膀放松，不要耸着练", "呼吸慢慢恢复平稳"], baseReps: "10 分钟", quickStats: ["坡度 10", "阻力 2"])
            ]
        case "跑步机":
            return [
                FitnessAction(name: "跑步机热身段", targetMuscle: "心肺唤醒", tip: "先把步频和呼吸找顺。", emojiIcon: "🏃‍♀️", steps: ["坡度 0 - 2", "轻松走或慢跑", "让身体慢慢进入状态"], baseReps: "8 分钟"),
                FitnessAction(name: "跑步机稳态段", targetMuscle: "心肺耐力", tip: "速度不要忽快忽慢，稳住最重要。", emojiIcon: "🔥", steps: ["坡度 3 - 5", "速度提高到微喘但能坚持", "保持均匀节奏"], baseReps: "\(max(12, minutes - 12)) 分钟"),
                FitnessAction(name: "跑步机冷却段", targetMuscle: "主动恢复", tip: "慢慢降速，不要突然跳下跑步机。", emojiIcon: "🍃", steps: ["坡度回到 0 - 1", "速度慢慢降下来", "呼吸恢复平稳"], baseReps: "4 分钟")
            ]
        default:
            return [
                FitnessAction(name: "\(selectedCardioName) 热身段", targetMuscle: "心肺唤醒", tip: "先慢慢热起来。", emojiIcon: "🌿", steps: ["轻松开始", "呼吸打开", "节奏稳定"], baseReps: "8 分钟"),
                FitnessAction(name: "\(selectedCardioName) 稳态段", targetMuscle: "心肺耐力", tip: "保持稳定输出。", emojiIcon: "💦", steps: ["进入主训练节奏", "保持微喘", "不要忽快忽慢"], baseReps: "\(max(12, minutes - 12)) 分钟"),
                FitnessAction(name: "\(selectedCardioName) 冷却段", targetMuscle: "主动恢复", tip: "慢慢收尾。", emojiIcon: "🍃", steps: ["逐渐减速", "恢复呼吸", "完成收尾"], baseReps: "4 分钟")
            ]
        }
    } else {
        switch selectedCardioName {
        case "椭圆机": return [
                FitnessAction(name: "椭圆机热身段", targetMuscle: "心肺唤醒", tip: "先把关节和呼吸带起来。", emojiIcon: "🛸", steps: ["坡度 10", "阻力 4", "匀速踩踏"], baseReps: "10 分钟"),
                FitnessAction(name: "椭圆机主训练段", targetMuscle: "心肺耐力", tip: "稳住节奏。", emojiIcon: "⚡", steps: ["坡度 12", "阻力 6", "保持持续输出"], baseReps: "\(max(20, minutes - 20)) 分钟"),
                FitnessAction(name: "椭圆机冷却段", targetMuscle: "主动恢复", tip: "慢慢把身体接回来。", emojiIcon: "🍃", steps: ["坡度 10", "阻力 2", "放慢节奏"], baseReps: "10 分钟")
            ]
        case "跑步机": return [
                FitnessAction(name: "跑步机热身段", targetMuscle: "心肺唤醒", tip: "先把步伐走顺。", emojiIcon: "🏃‍♀️", steps: ["坡度 2", "轻松快走或慢跑", "让脚步和呼吸进入状态"], baseReps: "10 分钟"),
                FitnessAction(name: "跑步机主训练段", targetMuscle: "下肢耐力", tip: "有训练感，但动作不能散。", emojiIcon: "🔥", steps: ["坡度 6 - 10", "速度提高到明显发热", "保持步频稳定"], baseReps: "\(max(20, minutes - 20)) 分钟"),
                FitnessAction(name: "跑步机冷却段", targetMuscle: "主动恢复", tip: "收尾要体面。", emojiIcon: "🍃", steps: ["坡度 0 - 2", "轻松走", "呼吸恢复平稳"], baseReps: "10 分钟")
            ]
        case "动感单车": return [
                FitnessAction(name: "单车热身段", targetMuscle: "心肺唤醒", tip: "先把腿转顺。", emojiIcon: "🚴", steps: ["低阻力", "轻松踩踏", "热起来"], baseReps: "10 分钟"),
                FitnessAction(name: "单车主训练段", targetMuscle: "大腿输出", tip: "阻力要够，别踩散。", emojiIcon: "⚡", steps: ["中高阻力", "保持稳定踏频", "持续输出"], baseReps: "\(max(20, minutes - 20)) 分钟"),
                FitnessAction(name: "单车冷却段", targetMuscle: "主动恢复", tip: "慢慢松下来。", emojiIcon: "🍃", steps: ["低阻力", "轻松踩踏", "恢复"], baseReps: "10 分钟")
            ]
        case "爬楼机": return [
                FitnessAction(name: "爬楼机热身段", targetMuscle: "臀腿唤醒", tip: "先找到节奏。", emojiIcon: "🧗‍♀️", steps: ["低速热身", "轻扶扶手", "步伐稳定"], baseReps: "8 分钟"),
                FitnessAction(name: "爬楼机主训练段", targetMuscle: "臀腿耐力", tip: "重点是持续。", emojiIcon: "🔥", steps: ["中高速度", "步伐稳定向上", "感受臀腿发力"], baseReps: "\(max(18, minutes - 16)) 分钟"),
                FitnessAction(name: "爬楼机冷却段", targetMuscle: "主动恢复", tip: "把腿救回来。", emojiIcon: "🍃", steps: ["低速恢复", "放慢呼吸", "逐渐结束"], baseReps: "8 分钟")
            ]
        case "散步": return [
                FitnessAction(name: "快走启动段", targetMuscle: "心肺唤醒", tip: "不要急。", emojiIcon: "🚶", steps: ["轻松走", "摆臂自然", "热起来"], baseReps: "10 分钟"),
                FitnessAction(name: "耐力快走段", targetMuscle: "低压燃脂", tip: "重点是持续，不是拼命。", emojiIcon: "🌤️", steps: ["加快步频", "保持能说短句的速度", "可用坡度 3 - 6"], baseReps: "\(max(20, minutes - 20)) 分钟"),
                FitnessAction(name: "散步收尾段", targetMuscle: "主动恢复", tip: "慢慢降下来。", emojiIcon: "🍃", steps: ["逐渐放慢", "放松肩膀", "恢复平稳呼吸"], baseReps: "10 分钟")
            ]
        case "游泳": return [
                FitnessAction(name: "游泳热身段", targetMuscle: "全身唤醒", tip: "先把呼吸和划水找顺。", emojiIcon: "🏊‍♀️", steps: ["轻松游", "动作完整", "不要急"], baseReps: "10 分钟"),
                FitnessAction(name: "游泳主训练段", targetMuscle: "全身协调", tip: "保持节奏感，不要乱扑腾。", emojiIcon: "💦", steps: ["连续游或分段游", "保持稳定呼吸", "每一趟动作尽量完整"], baseReps: "\(max(20, minutes - 20)) 分钟"),
                FitnessAction(name: "游泳放松段", targetMuscle: "主动恢复", tip: "把心率降下来。", emojiIcon: "🍃", steps: ["轻松划水", "拉长呼吸", "慢慢结束"], baseReps: "10 分钟")
            ]
        default: return [
                FitnessAction(name: "\(selectedCardioName) 热身段", targetMuscle: "心肺唤醒", tip: "先热起来。", emojiIcon: "🌿", steps: ["轻松开始", "找呼吸", "找节奏"], baseReps: "10 分钟"),
                FitnessAction(name: "\(selectedCardioName) 主训练段", targetMuscle: "心肺挑战", tip: "进入状态。", emojiIcon: "⚡", steps: ["提高强度", "保持输出", "动作稳定"], baseReps: "\(max(20, minutes - 20)) 分钟"),
                FitnessAction(name: "\(selectedCardioName) 冷却段", targetMuscle: "主动恢复", tip: "慢慢收尾。", emojiIcon: "🍃", steps: ["降低强度", "恢复呼吸", "完成训练"], baseReps: "10 分钟")
            ]
        }
    }
}

// 👑 终极强制平衡输出组合（✨ 重构：最强3D核心模块）
func getSmartBalancedPool(equip: Int, part: Int) -> [FitnessAction] {
    var pool: [FitnessAction] = []
    if part == 2 || part == 0 { // 下肢
        if equip == 2 {
            pool.append(FitnessAction(name: "倒蹬机 (Leg Press)", targetMuscle: "大腿前侧 (推)", tip: "顶端绝对不要锁死膝盖", emojiIcon: "🎢", steps: ["踩实踏板，慢下快推"], baseReps: "10 - 15 次"))
            pool.append(FitnessAction(name: "罗马椅挺身 / 腿弯举", targetMuscle: "大腿后侧 (拉)", tip: "感受大腿后侧拉扯力", emojiIcon: "🪑", steps: ["控制下放速度，臀腿发力拉起"], baseReps: "10 - 12 次"))
            pool.append(FitnessAction(name: "负重臀桥 / 髋推", targetMuscle: "臀大肌 (臀)", tip: "顶峰收缩夹紧屁股", emojiIcon: "🍑", steps: ["用杠铃或哑铃压在髋部，发力向上顶"], baseReps: "8 - 12 次"))
            pool.append(FitnessAction(name: "史密斯深蹲", targetMuscle: "臀腿综合", tip: "核心收紧，脚跟发力", emojiIcon: "🏋️", steps: ["背部挺直，下蹲至大腿平行地面"], baseReps: "8 - 10 次"))
        } else {
            pool.append(FitnessAction(name: "高脚杯深蹲", targetMuscle: "大腿前侧 (推)", tip: "保持挺胸，哑铃贴紧胸口", emojiIcon: "🍷", steps: ["手肘处于双膝之间下蹲"], baseReps: "10 - 15 次"))
            pool.append(FitnessAction(name: "哑铃罗马尼亚硬拉 (RDL)", targetMuscle: "大腿后侧 (拉)", tip: "背部绝对平直，臀部向后推", emojiIcon: "🚪", steps: ["哑铃贴着腿部滑下，感受后侧拉伸"], baseReps: "8 - 10 次"))
            pool.append(FitnessAction(name: "哑铃负重臀桥", targetMuscle: "臀大肌 (臀)", tip: "把哑铃放在小腹上方", emojiIcon: "🍑", steps: ["脚跟踩地，臀部发力向上顶"], baseReps: "12 - 15 次"))
            pool.append(FitnessAction(name: "交替箭步蹲", targetMuscle: "单侧臀腿", tip: "下蹲时前后腿呈90度", emojiIcon: "🚶‍♀️", steps: ["保持上身直立，重心在两腿中间"], baseReps: "每侧 10 次"))
        }
    } else if part == 1 { // 背部：垂直拉 + 水平拉 + 肩胛控制 + 后束补偿
        if equip == 2 {
            pool.append(FitnessAction(name: "器械高位下拉", targetMuscle: "背阔肌 (垂直拉)", tip: "不要过度后仰，先沉肩，再把手肘向下拉", emojiIcon: "🏗️", steps: ["坐稳并固定大腿，核心轻轻收紧", "先想象肩膀远离耳朵，再开始下拉", "把横杆拉向锁骨附近，控制还原"], baseReps: "10 - 12 次"))
            pool.append(FitnessAction(name: "坐姿划船", targetMuscle: "中背部 (水平拉)", tip: "不是用手拉，是用肩胛骨向后收", emojiIcon: "🚣", steps: ["挺胸坐稳，脊柱保持中立", "先轻轻后收肩胛，再带动手肘往后", "停顿 1 秒，慢慢放回"], baseReps: "10 - 12 次"))
            pool.append(FitnessAction(name: "墙天使 / 墙滑", targetMuscle: "肩胛上旋控制", tip: "腰不要乱拱，重点不是抬高，而是贴墙滑动", emojiIcon: "🪽", steps: ["背靠墙站立，后脑勺、上背尽量贴墙", "手臂摆成 W 形，慢慢向上滑到 Y 形", "全程保持肋骨别外翻，感受肩胛顺畅上旋"], baseReps: "10 - 12 次"))
            pool.append(FitnessAction(name: "器械反向飞鸟", targetMuscle: "肩后束 / 姿态补偿", tip: "动作不用太重，重点是打开胸口、稳定肩胛", emojiIcon: "🦋", steps: ["双手握住把手，肩膀下沉", "手臂微屈，向两侧打开", "顶端停顿 1 秒，再慢慢回位"], baseReps: "15 - 20 次"))
        } else {
            pool.append(FitnessAction(name: "弹力带高位下拉", targetMuscle: "背阔肌 (垂直拉)", tip: "先沉肩再下拉，不要耸肩硬拽", emojiIcon: "⚡", steps: ["把弹力带固定在高点", "先让肩膀远离耳朵，再把手肘向下带", "拉到胸口附近后慢慢还原"], baseReps: "12 - 15 次"))
            pool.append(FitnessAction(name: "哑铃俯身划船", targetMuscle: "中背部 (水平拉)", tip: "背部必须平直，手肘朝髋部方向拉", emojiIcon: "🚣", steps: ["臀部后推，上身前倾，核心收紧", "哑铃向小腹两侧拉回", "停顿一下，控制下放"], baseReps: "10 - 12 次"))
            pool.append(FitnessAction(name: "Y-T-W 肩胛唤醒", targetMuscle: "肩胛控制 / 下斜方肌", tip: "动作小一点没关系，重点是控制感，不是甩手", emojiIcon: "🪶", steps: ["俯身或趴姿，手臂依次做 Y、T、W 三个姿势", "每次抬起时想象肩胛向下向后稳定", "全程脖子放松，不要耸肩抢力"], baseReps: "每种 8 - 10 次"))
            pool.append(FitnessAction(name: "弹力带面拉", targetMuscle: "肩后束 / 姿态补偿", tip: "拉向脸部，肘部打开，像摆出一个 W", emojiIcon: "😎", steps: ["弹力带固定在脸部高度", "双手向面部方向拉开，肩胛后收", "停顿 1 秒后慢慢还原"], baseReps: "15 - 20 次"))
        }
    } else { // ✨核心四大稳定支柱
        if equip == 2 || equip == 1 {
            pool.append(FitnessAction(name: "死虫子 (Deadbug)", targetMuscle: "抗伸展 / 骨盆控制", tip: "下背部必须死死钉在地面上！", emojiIcon: "🪲", steps: ["仰卧，双手伸直指天，双腿屈膝90度抬起", "下背部用力压实地面，不能留缝隙", "呼气，缓慢伸直对侧手脚，吸气收回"], baseReps: "每侧 10 - 12 次"))
            pool.append(FitnessAction(name: "帕洛夫推 (Pallof Press)", targetMuscle: "抗旋转", tip: "抵抗阻力不要让身体转动", emojiIcon: "🛡️", steps: ["侧对绳索或弹力带站立，双手拉至胸前", "核心死死收紧抵抗侧向拉力，向前推直", "停顿1秒后收回"], baseReps: "每侧 12 - 15 次"))
            pool.append(FitnessAction(name: "侧支撑 (Side Plank)", targetMuscle: "抗侧屈 / 腹斜肌", tip: "把地面推开，身体像一块钢板", emojiIcon: "📐", steps: ["手肘在肩膀正下方撑地", "发力撑起，不要塌腰", "保持呼吸，感觉侧腰收紧"], baseReps: "每侧 30 - 45 秒"))
            pool.append(FitnessAction(name: "中空静力支撑 (Hollow Hold)", targetMuscle: "深层抗伸展", tip: "下背必须压实地面！如果腰酸就把腿抬高一点", emojiIcon: "🥣", steps: ["仰卧，腰部死死压平地面", "双手双脚伸直，微微抬离地面", "保持颤抖，绝不憋气"], baseReps: "30 - 45 秒"))
        } else {
            pool.append(FitnessAction(name: "死虫子 (Deadbug)", targetMuscle: "抗伸展 / 骨盆控制", tip: "下背部必须死死钉在地面上！", emojiIcon: "🪲", steps: ["仰卧，双手伸直指天，双腿屈膝90度抬起", "下背部用力压实地面，不能留缝隙", "呼气，缓慢伸直对侧手脚，吸气收回"], baseReps: "每侧 10 - 12 次"))
            pool.append(FitnessAction(name: "鸟狗式 (Bird Dog)", targetMuscle: "多裂肌 / 抗旋转", tip: "想象背上放着一杯水，绝对不能洒", emojiIcon: "🐕", steps: ["四足跪姿，保持脊柱中立", "对侧手脚向前后延伸", "保持平稳，不要左摇右晃"], baseReps: "每侧 10 - 12 次"))
            pool.append(FitnessAction(name: "侧支撑 (Side Plank)", targetMuscle: "抗侧屈 / 腹斜肌", tip: "把地面推开，身体像一块钢板", emojiIcon: "📐", steps: ["手肘撑地", "发力撑起，不塌腰", "感觉侧腰收紧"], baseReps: "每侧 30 - 45 秒"))
            pool.append(FitnessAction(name: "中空静力支撑 (Hollow Hold)", targetMuscle: "深层抗伸展", tip: "下背必须压实地面！如果腰酸就把腿抬高一点", emojiIcon: "🥣", steps: ["仰卧，腰压平地面", "双手双脚伸直微微抬离地面", "保持颤抖，不憋气"], baseReps: "30 - 45 秒"))
        }
    }
    return buildStructuredWorkout(from: sortActionsByPriority(pool))
}
// MARK: Exercise Model

struct Exercise: Identifiable {
    let id: UUID
    let name: String
    
    let category: Category
    let type: ExerciseType
    let equipment: Equipment
    let difficulty: Difficulty
    
    let isCompound: Bool
    
    init(
        id: UUID = UUID(),
        name: String,
        category: Category,
        type: ExerciseType,
        equipment: Equipment,
        difficulty: Difficulty,
        isCompound: Bool
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.type = type
        self.equipment = equipment
        self.difficulty = difficulty
        self.isCompound = isCompound
    }
}

// MARK: Category

enum Category: String, CaseIterable {
    case chest = "胸"
    case back = "背"
    case legs = "腿"
    case shoulders = "肩"
    case arms = "手臂"
    case core = "核心"
}

// MARK: Type

enum ExerciseType: String {
    case compound = "复合动作"
    case isolation = "孤立动作"
}

// MARK: Equipment

enum Equipment: String {
    case barbell = "杠铃"
    case dumbbell = "哑铃"
    case machine = "器械"
    case bodyweight = "自重"
}

// MARK: Difficulty

enum Difficulty: String {
    case beginner = "初级"
    case intermediate = "中级"
    case advanced = "高级"
}
// MARK: Priority

enum ActionPriority: Int {
    case primary = 1      // 核心动作：优先推荐，优先排前面
    case secondary = 2    // 辅助动作：中间层
    case accessory = 3    // 补充动作：收尾/补短板
}

// MARK: FitnessAction Priority Engine

func getPriority(for action: FitnessAction) -> ActionPriority {
    let name = action.name

    let primaryKeywords = [
        "深蹲", "高脚杯深蹲", "史密斯深蹲",
        "硬拉", "罗马尼亚硬拉", "RDL",
        "臀桥", "髋推",
        "高位下拉", "下拉",
        "划船", "坐姿划船", "俯身划船",
        "倒蹬机", "Leg Press",
        "箭步蹲"
    ]

    let secondaryKeywords = [
        "面拉", "反向飞鸟",
        "墙天使", "墙滑", "Y-T-W",
        "帕洛夫推", "Pallof Press",
        "死虫子", "Deadbug",
        "鸟狗式", "Bird Dog"
    ]

    if primaryKeywords.contains(where: { name.contains($0) }) {
        return .primary
    }

    if secondaryKeywords.contains(where: { name.contains($0) }) {
        return .secondary
    }

    return .accessory
}

func sortActionsByPriority(_ actions: [FitnessAction]) -> [FitnessAction] {
    return actions.sorted { left, right in
        let leftPriority = getPriority(for: left).rawValue
        let rightPriority = getPriority(for: right).rawValue

        if leftPriority != rightPriority {
            return leftPriority < rightPriority
        }

        return left.name < right.name
    }
}
// MARK: Structured Action Picker

func buildStructuredWorkout(from actions: [FitnessAction]) -> [FitnessAction] {
    let primary = actions.filter { getPriority(for: $0) == .primary }.shuffled()
    let secondary = actions.filter { getPriority(for: $0) == .secondary }.shuffled()
    let accessory = actions.filter { getPriority(for: $0) == .accessory }.shuffled()

    var result: [FitnessAction] = []

    if let onePrimary = primary.first {
        result.append(onePrimary)
    }

    if let oneSecondary = secondary.first {
        result.append(oneSecondary)
    }

    if let oneAccessory = accessory.first {
        result.append(oneAccessory)
    }

    // 如果某一层没有动作，就从剩余动作里随机补位，最多补到 3 个
    if result.count < 3 {
        let usedNames = Set(result.map { $0.name })
        let fallback = actions
            .filter { !usedNames.contains($0.name) }
            .shuffled()

        for action in fallback {
            if result.count >= 3 { break }
            result.append(action)
        }
    }

    return result
}
