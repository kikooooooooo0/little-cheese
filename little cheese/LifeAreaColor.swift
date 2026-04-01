import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - 莫奈《撑阳伞的女人》& 深夜起司 主题色卡

extension Color {
    
    // MARK: - 核心动态颜色 (会自动随系统切换)
    
    /// 1. 背景色：白天=云朵暖白 / 黑夜=深邃蓝灰
    static let lcBackground = Color.dynamic(light: "#FAF9F6", dark: "#121212")
    
    /// 2. 卡片背景色：白天=纯白 / 黑夜=柔和的深灰
    /// ⚠️ 以后卡片不要直接用 .white，要用 .lcCardBackground
    static let lcCardBackground = Color.dynamic(light: "#FFFFFF", dark: "#1C1C1E")
    
    /// 3. 主文字：白天=深灰蓝 / 黑夜=柔和米白
    static let lcText = Color.dynamic(light: "#2C3E50", dark: "#EAEAEA")
    
    /// 4. 次级文字：白天=雾霾蓝灰 / 黑夜=浅灰
    static let lcTextSecondary = Color.dynamic(light: "#7F94A3", dark: "#98989E")
    
    /// 5. 核心主色：莫奈天空蓝 (黑夜模式稍微亮一点点，保证看清)
    static let lcAccentBlue = Color.dynamic(light: "#6CA6CD", dark: "#5D9BC7")
    
    /// 6. 辅助蓝色：白天=极淡蓝 / 黑夜=深蓝灰 (用于未选中状态)
    static let lcSoftBlue = Color.dynamic(light: "#DCE6F0", dark: "#2C3038")
    
    /// 7. 成功/完成：草地绿
    static let lcGreen = Color.dynamic(light: "#9ABF89", dark: "#85AD74")
    
    /// 8. 警示/强调：柔和红
    static let lcRed = Color.dynamic(light: "#D98686", dark: "#D97676")
    
    /// 9. 点缀：阳光黄 (Little Cheese 黄)
    static let lcYellow = Color.dynamic(light: "#F2D68C", dark: "#DDBF70")
    
    // 兼容别名
    static let lcCheeseYellow = lcYellow
    static let lcCheese = lcYellow
    static let lcDarkBlue = Color.dynamic(light: "#435E9D", dark: "#7D94D1")
    
    // MARK: - 动态颜色生成器
    
    static func dynamic(light: String, dark: String) -> Color {
        #if os(iOS)
        return Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                UIColor(hex: dark) : UIColor(hex: light)
        })
        #else
        return Color(nsColor: NSColor(name: nil, dynamicProvider: { appearance in
            return appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ?
                NSColor(hex: dark) : NSColor(hex: light)
        }))
        #endif
    }
}

// MARK: - 生活领域渐变色 (LifeArea)
// 这些颜色比较鲜艳，黑夜模式通常可以直接用，或者稍微调整
let lifeAreaPalettes: [[Color]] = [
    // 0 奶油浅米黄
    [Color(hex: "#F1D39A"), Color(hex: "#E2BE7A")],
    // 1 明亮黄
    [Color(hex: "#F2C765"), Color(hex: "#E0B24A")],
    // 2 暖粉色
    [Color(hex: "#E3B8AF"), Color(hex: "#D49F96")],
    // 3 雾紫
    [Color(hex: "#D2B7D2"), Color(hex: "#C39BC4")],
    // 4 莫奈湖水蓝
    [Color(hex: "#67B6DE"), Color(hex: "#4A9CC7")],
    // 5 蓝紫色
    [Color(hex: "#7291C3"), Color(hex: "#5879AC")],
    // 6 深湖蓝
    [Color(hex: "#5B76B9"), Color(hex: "#435E9D")],
    // 7 暗紫蓝
    [Color(hex: "#6C69A8"), Color(hex: "#56528C")]
]

extension LifeArea {
    var gradientColors: [Color] {
        let idx = max(0, min(colorIndex, lifeAreaPalettes.count - 1))
        return lifeAreaPalettes[idx]
    }
    
    var primaryColor: Color {
        gradientColors.first ?? .lcAccentBlue
    }
}

// MARK: - Hex 辅助
#if os(iOS)
extension UIColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
#elseif os(macOS)
extension NSColor {
    convenience init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8) & 0xFF) / 255.0
        let b = CGFloat(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}
#endif

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8) & 0xFF) / 255
        let b = Double(rgb & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
