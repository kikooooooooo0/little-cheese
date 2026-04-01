// MARK: - LittleCheeseApp 入口（通用：iOS + macOS）

import SwiftUI

@main
struct LittleCheeseApp: App {
    var body: some Scene {
        WindowGroup {
            // 用你那个大号 ContentView（带 TabView、Today、目标、日记）
            ContentView()
        }
    }
}
