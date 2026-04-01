import SwiftUI

// MARK: - 1. 数据模型
enum CollectionType: String, Codable, CaseIterable {
    case book = "书籍"
    case music = "音乐"
    case movie = "影视"
    
    var emoji: String {
        switch self {
        case .book: return "📖"
        case .music: return "🎵"
        case .movie: return "🎬"
        }
    }
    
    var title: String {
        switch self {
        case .book: return "Books I've Read"
        case .music: return "Music I Love"
        case .movie: return "Movies & Shows"
        }
    }
}

struct CollectionItem: Identifiable, Codable {
    var id = UUID()
    var type: CollectionType
    var title: String
    var author: String // 作者/歌手/导演
    var rating: Int // 1-5 块奶酪
    var comment: String
    var date: Date
}

// MARK: - 2. 主视图
struct CollectionsView: View {
    let targetType: CollectionType // 进这个页面时，只看哪一种？
    
    @State private var items: [CollectionItem] = []
    @State private var isShowingAddSheet = false
    
    // 颜色适配
    private let cardBg = Color.lcCardBackground
    private let accent = Color.lcAccentBlue
    
    var body: some View {
        ZStack {
            Color.lcBackground.ignoresSafeArea()
            
            if filteredItems.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredItems) { item in
                            ItemCard(item: item)
                                .contextMenu {
                                    Button("删除", role: .destructive) {
                                        deleteItem(item)
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(targetType.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isShowingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddSheet) {
            AddCollectionSheet(type: targetType) { newItem in
                withAnimation {
                    items.insert(newItem, at: 0)
                    saveData()
                }
            }
        }
        .onAppear(perform: loadData)
    }
    
    // MARK: - 辅助视图与逻辑
    
    private var filteredItems: [CollectionItem] {
        items.filter { $0.type == targetType }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.stack.3d.up.slash")
                .font(.system(size: 50))
                .foregroundColor(.lcTextSecondary.opacity(0.3))
            Text("还没有收藏")
                .font(.headline)
                .foregroundColor(.lcTextSecondary)
            Button {
                isShowingAddSheet = true
            } label: {
                Text("记录第一个")
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.lcAccentBlue.opacity(0.1)))
                    .foregroundColor(.lcAccentBlue)
            }
        }
    }
    
    private func deleteItem(_ item: CollectionItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            withAnimation {
                items.remove(at: index)
                saveData()
            }
        }
    }
    
    // 简单的 UserDefaults 存取（为了演示方便，和 AppState 分离）
    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: "lc_collections"),
           let decoded = try? JSONDecoder().decode([CollectionItem].self, from: data) {
            items = decoded
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "lc_collections")
        }
    }
}

// MARK: - 3. 单个卡片组件
struct ItemCard: View {
    let item: CollectionItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // 左侧：封面/图标
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.lcSoftBlue.opacity(0.3))
                    .frame(width: 80, height: 110) // 书本比例
                
                Text(item.type.emoji)
                    .font(.largeTitle)
            }
            
            // 右侧：信息
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.lcText)
                        .lineLimit(2)
                    
                    Text(item.author)
                        .font(.caption)
                        .foregroundColor(.lcTextSecondary)
                }
                
                // 奶酪评分
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { i in
                        Image(systemName: i <= item.rating ? "heart.fill" : "heart")
                            .font(.caption)
                            .foregroundColor(i <= item.rating ? .lcRed : .lcTextSecondary.opacity(0.3))
                    }
                }
                
                if !item.comment.isEmpty {
                    Text(item.comment)
                        .font(.footnote)
                        .foregroundColor(.lcText.opacity(0.8))
                        .lineLimit(3)
                        .padding(.top, 4)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color.lcCardBackground)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

// MARK: - 4. 新增页 Sheet
struct AddCollectionSheet: View {
    let type: CollectionType
    let onSave: (CollectionItem) -> Void
    
    @Environment(\.dismiss) var dismiss
    @State private var title = ""
    @State private var author = ""
    @State private var rating = 5
    @State private var comment = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(type == .book ? "书名" : (type == .music ? "歌名" : "影视名称"), text: $title)
                    TextField(type == .book ? "作者" : (type == .music ? "歌手" : "导演/主演"), text: $author)
                }
                
                Section("我的评价") {
                    HStack {
                        Text("喜好程度")
                        Spacer()
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { i in
                                Image(systemName: i <= rating ? "heart.fill" : "heart")
                                    .foregroundColor(i <= rating ? .lcRed : .gray.opacity(0.3))
                                    .onTapGesture { rating = i }
                            }
                        }
                    }
                    
                    TextField("写一点短评...", text: $comment, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("新增收藏")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let newItem = CollectionItem(
                            type: type,
                            title: title,
                            author: author,
                            rating: rating,
                            comment: comment,
                            date: Date()
                        )
                        onSave(newItem)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
}
