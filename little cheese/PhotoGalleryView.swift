import SwiftUI

#if os(iOS)
import PhotosUI
import UIKit
#elseif os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

// MARK: - Photo Gallery View（小起司照片画廊）

struct PhotoGalleryView: View {
    
    @ObservedObject var state: AppState
    
    /// ✅ 新增：如果传入某一天的 dateString，就只看这一天的照片；为 nil 则显示全部画廊
    let focusDateString: String?
    
    // ✅ 必须有这个包含 focusDateString 的初始化方法，日历页才能调用它
    init(state: AppState, focusDateString: String? = nil) {
        self.state = state
        self.focusDateString = focusDateString
    }
    
    #if os(iOS)
    /// iOS：相册选中的那一张图片
    @State private var selectedPhotoItem: PhotosPickerItem?
    #endif
    
    /// 是否使用正方形卡片（否则为 16:9）
    @State private var useSquareCards: Bool = true
    
    /// 两列苹果风网格
    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    // MARK: 使用 AppState 里的每日照片，按日期（字符串）倒序排
    private var sortedPhotos: [DailyPhoto] {
        let all = state.dailyPhotos
        let filtered: [DailyPhoto]
        
        if let focus = focusDateString {
            // ✅ 只看某一天的小起司照片
            filtered = all.filter { $0.dateString == focus }
        } else {
            // 正常画廊模式：显示全部
            filtered = all
        }
        
        return filtered.sorted { $0.dateString > $1.dateString }
    }
    
    /// 把 yyyy-MM-dd 变成 “M 月 d 日” 显示用
    private static let displayDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "M 月 d 日"
        return f
    }()
    
    /// 顶部标题
    private var headerTitle: String {
        if let focus = focusDateString,
           let d = AppState.df.date(from: focus) {
            return Self.displayDateFormatter.string(from: d) + " 的小起司照片"
        } else {
            return "照片画廊"
        }
    }
    
    /// 顶部第二行：数量说明
    private var headerSubtitle: String {
        if let focus = focusDateString {
            let count = state.dailyPhotos.filter { $0.dateString == focus }.count
            return "这一天记录了 \(count) 张小起司照片"
        } else {
            return "目前已记录 \(state.dailyPhotos.count) 张小起司照片"
        }
    }
    
    /// 顶部第三行：小提示
    private var headerHint: String {
        if focusDateString != nil {
            return "这是那一天的小起司瞬间，可以和当日的日记一起回看 🧀"
        } else {
            return "以后这里会显示你每天的照片，我们再把它跟日历、日记连在一起 🧀"
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // 顶部控制条：标题 + 比例切换
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(headerTitle)
                            .font(.title2).bold()
                            .foregroundColor(.lcText)
                        
                        Spacer()
                        
                        // 比例切换：正方形 / 16:9
                        Picker("", selection: $useSquareCards) {
                            Text("正方形").tag(true)
                            Text("16:9").tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 160)
                    }
                    
                    Text(headerSubtitle)
                        .font(.subheadline)
                        .foregroundColor(.lcTextSecondary)
                    
                    Text(headerHint)
                        .font(.subheadline)
                        .foregroundColor(.lcTextSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color.lcBackground)
                
                Divider()
                    .overlay(Color.lcSoftBlue.opacity(0.5))
                
                // 照片网格（支持从日历跳过来后自动滚动到指定日期）
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 12) {
                            
                            // 没有任何照片时，显示一张暖暖的占位卡
                            if sortedPhotos.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                LinearGradient(
                                                    colors: [
                                                        Color.lcSoftBlue.opacity(0.35),
                                                        Color.lcCheeseYellow.opacity(0.45)
                                                    ],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
                                            )
                                            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                                            .aspectRatio(useSquareCards ? 1.0 : (16.0/9.0), contentMode: .fit)
                                        
                                        VStack(spacing: 6) {
                                            Image(systemName: "camera.fill")
                                                .imageScale(.large)
                                                .font(.system(size: 20))
                                                .foregroundColor(.white)
                                            
                                            Text("还没有小起司照片")
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.9))
                                        }
                                    }
                                    
                                    Text("拍一张今天的小照片，它会和当日的日记连在一起 🧀")
                                        .font(.caption2)
                                        .foregroundColor(.lcTextSecondary)
                                        .lineLimit(2)
                                }
                            } else {
                                // 有照片时，用真实 dailyPhotos 来画卡片
                                ForEach(sortedPhotos, id: \.id) { photo in
                                    NavigationLink {
                                        JournalDetailView(
                                            state: state,
                                            entry: state.entry(for: photo.dateString)   // ← 看这一天
                                        )
                                    } label: {
                                        photoCard(photo: photo)
                                            .contentShape(Rectangle()) // 让整块可点击
                                            // 👇 长按照片卡片，弹出删除菜单
                                            .contextMenu {
                                                Button(role: .destructive) {
                                                    state.deletePhoto(id: photo.id)
                                                } label: {
                                                    Label("删除这张照片", systemImage: "trash")
                                                }
                                            }
                                    }
                                    .id(photo.id)
                                }
                            }
                            
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                    }
                    .background(Color.lcBackground)
                    .onAppear {
                        // ✅ 自动滚动逻辑：如果是从日历点进来的，就滚到那张照片
                        guard let focus = focusDateString else { return }
                        if let target = sortedPhotos.first(where: { $0.dateString == focus }) {
                            DispatchQueue.main.async {
                                withAnimation {
                                    proxy.scrollTo(target.id, anchor: .center)
                                }
                            }
                        }
                    }
                }
                
            }
            .background(Color.lcBackground.ignoresSafeArea())
            .navigationTitle(focusDateString == nil ? "照片" : "当天照片")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(
                        selection: $selectedPhotoItem,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem(placement: .automatic) {
                    Button {
                        addTestPhoto()
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            #if os(iOS)
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        // 选好图片后，存成今天的一张照片
                        state.addPhoto(for: Date(), imageData: data, caption: nil)
                    }
                }
            }
            #endif
        }
    }
    
    
    // MARK: - 单个照片卡片（使用 DailyPhoto + 日记的今日一句话）
    
    @ViewBuilder
    private func photoCard(photo: DailyPhoto) -> some View {
        
        // 1️⃣ 显示用日期文字（例如：11 月 30 日）
        let dateText: String = {
            if let d = AppState.df.date(from: photo.dateString) {
                return Self.displayDateFormatter.string(from: d)
            } else {
                return photo.dateString
            }
        }()
        
        /// ✅ 如果 focusDateString 刚好等于这张照片的日期，就高亮
        let isHighlight = (focusDateString == photo.dateString)
        
        // 2️⃣ 找这一天的日记「今日一句话」，没有就用照片 caption，再没有就给个兜底
        let oneLine: String = {
            let ds = photo.dateString
            
            // 先从日记里找同一天
            if let entry = state.journalEntries.first(where: { $0.dateString == ds }),
               let line = entry.oneLine?.trimmingCharacters(in: .whitespacesAndNewlines),
               !line.isEmpty {
                return line
            }
            
            // 再尝试用照片自己的 caption
            if let caption = photo.caption?.trimmingCharacters(in: .whitespacesAndNewlines),
               !caption.isEmpty {
                return caption
            }
            
            // 两个都没有，就给一句兜底
            return "今天的小起司时刻"
        }()
        
        VStack(alignment: .leading, spacing: 6) {
            
            ZStack {
                // 🔹 优先显示真实图片；如果没有图，就用原来的渐变卡片
                if let imageView = makeImageView(from: photo.imageData) {
                    imageView
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(useSquareCards ? 1.0 : (16.0/9.0), contentMode: .fit)
                        .clipped()
                        .clipShape(
                            RoundedRectangle(cornerRadius: 12)
                        )
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.lcSoftBlue.opacity(0.35),
                                    Color.lcCheeseYellow.opacity(0.45)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                        .aspectRatio(useSquareCards ? 1.0 : (16.0/9.0), contentMode: .fit)
                    
                    // 渐变卡片的时候，中心给一个小相机 + 日期
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .imageScale(.large)
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        Text(dateText)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            // 👉 ✅ 关键点：如果是从日历点进来的那天，就用小起司黄描边一下
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(isHighlight ? Color.lcCheeseYellow : Color.clear, lineWidth: 2)
            )
            
            // 底边小字（拍立得底边：日期 + 今日一句话）
            Text("\(dateText) · \(oneLine)")
                .font(.caption2)
                .foregroundColor(.lcTextSecondary)
                .lineLimit(2)
        }
    }
    
    
    // MARK: - Data 转平台 Image（iOS / macOS）
    
    private func makeImageView(from data: Data) -> Image? {
        guard !data.isEmpty else { return nil }
        
        #if os(iOS)
        // iPhone / iPad / Catalyst：用 UIImage
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #elseif os(macOS)
        // 真·macOS：用 NSImage
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #else
        return nil
        #endif
    }
    
    // MARK: - macOS：文件选择框选一张照片
    
    #if os(macOS)
    /// 点击右上角 + 按钮，在 macOS 上弹出文件选择框选一张照片
    private func addTestPhoto() {
        let panel = NSOpenPanel()
        panel.title = "选一张小起司的照片"
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.png, .jpeg, .heic, .tiff]
        } else {
            panel.allowedFileTypes = ["png", "jpg", "jpeg", "heic", "tiff"]
        }
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            // 读出图片二进制
            guard let data = try? Data(contentsOf: url) else { return }
            
            // 用“今天”的日期保存一张照片
            state.addPhoto(
                for: Date(),
                imageData: data,
                caption: url.lastPathComponent   // 先用文件名当说明
            )
        }
    }
    #endif
}
