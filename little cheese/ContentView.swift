import SwiftUI
#if os(iOS)
import PhotosUI
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - Root ContentView（经典原生底栏：当下 / 过往 / 未来 / 更多）

struct ContentView: View {
    @StateObject private var state = AppState()
    
    // 默认选中第 0 页 (当下)
    @State private var selectedTab: Int = 0
    
    // 配置 TabBar 的外观
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground
        
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.iconColor = UIColor.systemGray3
        itemAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.systemGray3]
        
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            
            // ———— 1. 当下 (Present) ————
            TodayView(state: state)
                .tabItem {
                    Label("当下", systemImage: "sun.max.fill")
                }
                .tag(0)

            // ———— 2. 过往 (Past) ————
            // 现在的结构：时光轴 (Timeline) vs 画廊 (Gallery)
            PastViewContainer(state: state)
                .tabItem {
                    Label("过往", systemImage: "book.closed.fill")
                }
                .tag(1)
            
            // ———— 3. 未来 (Future) ————
            GoalsView(state: state)
                .tabItem {
                    Label("未来", systemImage: "signpost.right.and.left.fill")
                }
                .tag(2)
            
            // ———— 4. 更多 (More) ————
            MoreView(state: state)
                .tabItem {
                    Label("更多", systemImage: "ellipsis.circle.fill")
                }
                .tag(3)
        }
        .tint(Color.lcAccentBlue)
    }
}


// MARK: - “过往”容器 (时光轴 / 画廊 切换 - 文艺标题版)
struct PastViewContainer: View {
    @ObservedObject var state: AppState
    
    // 0 = 时光轴, 1 = 画廊
    // 记住上次的选择 (默认画廊)
    @AppStorage("lc_pastViewMode") private var viewMode: Int = 1
    
    // 动画命名空间 (用于那个滑动的下划线)
    @Namespace private var namespace
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // MARK: - 1. 自定义顶部切换栏 (与未来页保持一致)
                HStack(spacing: 30) {
                    
                    // 按钮 A: 时光轴
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewMode = 0
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Text("时光轴")
                                .font(.system(size: viewMode == 0 ? 24 : 18)) // 选中变大
                                .fontWeight(viewMode == 0 ? .bold : .medium)
                                .foregroundColor(viewMode == 0 ? .lcText : .lcTextSecondary.opacity(0.6))
                            
                            // 选中时的下划线
                            if viewMode == 0 {
                                Capsule()
                                    .fill(Color.lcAccentBlue) // 蓝色代表时光流淌
                                    .frame(width: 20, height: 4)
                                    .matchedGeometryEffect(id: "pastIndicator", in: namespace)
                            } else {
                                // 占位，防止文字跳动
                                Capsule().fill(Color.clear).frame(width: 20, height: 4)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    // 按钮 B: 日历
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                viewMode = 1
                                            }
                                        } label: {
                                            VStack(spacing: 6) {
                                                Text("日历")
                                                    .font(.system(size: viewMode == 1 ? 24 : 18))
                                                    .fontWeight(viewMode == 1 ? .bold : .medium)
                                                    .foregroundColor(viewMode == 1 ? .lcText : .lcTextSecondary.opacity(0.6))
                                                
                                                if viewMode == 1 {
                                                    Capsule()
                                                        .fill(Color.lcYellow) // 黄色代表闪光记忆
                                                        .frame(width: 20, height: 4)
                                                        .matchedGeometryEffect(id: "pastIndicator", in: namespace)
                                                } else {
                                                    Capsule().fill(Color.clear).frame(width: 20, height: 4)
                                                }
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Spacer() // ✨ 补回：把按钮推到左边
                                    } // ✨ 补回：这是 HStack 的结束大括号
                                    .padding(.horizontal, 24)
                                    .padding(.top, 16)
                                    .padding(.bottom, 10)
                                    .background(Color.lcBackground) // ✨ 补回：背景色设置
                // MARK: - 2. 内容区
                                ZStack {
                                    if viewMode == 0 {
                                        JournalListView(state: state)
                                            .transition(.opacity)
                                    } else {
                                        // 🧀 改动：这里原来是 PhotoGalleryView，现在改成日历视图
                                        CalendarPhotoView(state: state)
                                            .transition(.opacity)
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
                        // 隐藏系统自带导航栏，因为我们自己画了 Header
                        .navigationBarHidden(true)
                        .background(Color.lcBackground.ignoresSafeArea())
                    }
                }
            }
// MARK: - “更多”页面 (工具箱 + 收藏)
// MARK: - “更多”页面 (工具箱 + 收藏)
struct MoreView: View {
    @ObservedObject var state: AppState
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    // ✅ 修正了这里的跳转语法
                    NavigationLink(destination: WeightRecordView(state: state)) {
                        Label {
                            Text("身体管理")
                                .font(.body)
                                .foregroundColor(.lcText)
                        } icon: {
                            Image(systemName: "scalemass.fill")
                                .foregroundColor(.lcRed)
                        }
                    }
                    
                    NavigationLink(destination: PomodoroView(state: state)) {
                        Label {
                            Text("番茄专注")
                                .font(.body)
                                .foregroundColor(.lcText)
                        } icon: {
                            Image(systemName: "timer")
                                .foregroundColor(.lcCheeseYellow)
                        }
                    }
                    
                    NavigationLink(destination: TimeBlocksView(state: state)) {
                        Label {
                            Text("时间拼图")
                                .font(.body)
                                .foregroundColor(.lcText)
                        } icon: {
                            Image (systemName: "clock.fill")
                                .foregroundColor(.lcAccentBlue)
                        }
                    }
                } header: {
                    Text("工具箱")
                }
                // 新增：饮食 SOP 入口
                                    NavigationLink(destination: DietSOPListView(state: state)) {
                                        Label {
                                            Text("饮食 SOP")
                                                .font(.body)
                                                .foregroundColor(.lcText)
                                        } icon: {
                                            Image(systemName: "fork.knife")
                                                .foregroundColor(.lcYellow)
                                        }
                                    }
                // ✨ 新增：多巴胺盲盒入口
                                    NavigationLink(destination: FitnessBlindBoxView(state: state)) {
                                        Label {
                                            Text("多巴胺微动弹")
                                                .font(.body)
                                                .foregroundColor(.lcText)
                                        } icon: {
                                            Image(systemName: "gift.fill")
                                                .foregroundColor(.lcAccentBlue)
                                        }
                                    }
                // ✨ 新增：起司专属私教
                                    NavigationLink(destination: FitnessCoachView(state: state)) {
                                        Label {
                                            Text("起司数字私教 (ACSM)")
                                                .font(.body)
                                                .foregroundColor(.lcText)
                                        } icon: {
                                            Image(systemName: "figure.run.square.stack")
                                                .foregroundColor(.lcGreen)
                                        }
                                    }
                // 第二组：精神食粮 (已连接)
                Section {
                    NavigationLink(destination: CollectionsView(targetType: .book)) {
                        Label {
                            Text("Book I've read")
                                .font(.body)
                                .foregroundColor(.lcText)
                        } icon: {
                            Image(systemName: "book.fill")
                                .foregroundColor(.brown)
                        }
                    }
                    
                    NavigationLink(destination: CollectionsView(targetType: .music)) {
                        Label {
                            Text("Music I fall in love with")
                                .font(.body)
                                .foregroundColor(.lcText)
                        } icon: {
                            Image(systemName: "music.note")
                                .foregroundColor(.lcRed)
                        }
                    }
                    
                    NavigationLink(destination: CollectionsView(targetType: .movie)) {
                        Label {
                            Text("Movie I would like try again")
                                .font(.body)
                                .foregroundColor(.lcText)
                        } icon: {
                            Image(systemName: "film.fill")
                                .foregroundColor(.indigo)
                        }
                    }
                    
                } header: {
                    Text("精神食粮")
                }
                
                // 第三组：设置
                Section {
                    NavigationLink(destination: SettingsView()) {
                        Label("App 设置", systemImage: "gearshape.fill")
                    }
                }
            }
            .navigationTitle("更多")
            .background(Color.lcBackground)
            .scrollContentBackground(.hidden)
        }
    }
}

// MARK: - 设置页面 (保留)
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("App 设置") {
                    Text("iCloud 同步 (开发中)")
                        .foregroundStyle(.secondary)
                    Text("主题色 (已应用莫奈色)")
                        .foregroundStyle(.secondary)
                }
                
                Section("关于") {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("Little Cheese v1.0")
                            .foregroundStyle(.secondary)
                    }
                    Text("Designed for ADHD Minds 🧀")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("设置")
            .background(Color.lcBackground)
            .scrollContentBackground(.hidden)
        }
    }
}
