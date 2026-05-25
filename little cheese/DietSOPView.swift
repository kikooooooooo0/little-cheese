import SwiftUI
import PhotosUI

struct DietCheckinRecord: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var dateKey: String
    var date: Date
    var mealType: String
    var content: String
    var imageFilename: String?
    
    // 修改为可选类型，兼容旧数据
    var emoji: String?
    var sopName: String?
    
    // 🆕 V2：这条饮食记录同步到日记里的句子
    // 设成可选，兼容以前已经保存过的旧记录
    var diaryLine: String?
}
// MARK: - 🧀 2. 主视图：极简三餐记录页
struct DietSOPView: View {
    @ObservedObject var state: AppState // 保持和主大管家的联动
    
    // 存储记录
    @AppStorage("littleCheese.dietCheckinRecords")
    private var recordsJSON: String = "[]"
    // 🆕 V2：饮食自动写入今天日记
    // 如果你的日记页已经用了别的 key，之后只需要把这个 key 改成日记页正在用的那个
    @AppStorage("littleCheese.todayDiaryText")
    private var todayDiaryText: String = ""
    // 弹窗控制
    @State private var showingRecordSheet = false
    @State private var selectedMealType = ""
    @State private var todayRecords: [DietCheckinRecord] = []
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                
                mealButtonsSection
                
                summarySection
            }
            .padding()
        }
        .navigationTitle("能量补给 🧀")
        .background(Color.lcBackground.ignoresSafeArea())
        .onAppear {
            loadTodayRecords()
        }
        .sheet(isPresented: $showingRecordSheet) {
            DietRecordSheetView(
                mealType: selectedMealType,
                onSave: { content, image in
                    saveRecord(mealType: selectedMealType, content: content, image: image)
                }
            )
        }
    }
    
    // MARK: - 头部区域
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今天不用完美吃饭")
                .font(.title2.bold())
                .foregroundColor(.lcText)
            
            Text("按时吃、吃饱饭，甚至只是随便吃两口，就已经是很棒的胜利了！拍照或者随便写两句都可以哦。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineSpacing(3)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.lcCardBackground)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 三餐打卡按钮
    private var mealButtonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("去记录")
                .font(.headline.bold())
                .foregroundColor(.lcText)
                .padding(.horizontal, 4)
            
            HStack(spacing: 12) {
                mealButton(title: "早餐", icon: "sun.and.horizon", color: .lcAccentBlue)
                mealButton(title: "午餐", icon: "sun.max.fill", color: .lcYellow)
                mealButton(title: "晚餐", icon: "moon.stars.fill", color: .lcSoftBlue)
            }
        }
    }
    
    private func mealButton(title: String, icon: String, color: Color) -> some View {
        let isDone = todayRecords.contains { $0.mealType == title }
        
        return Button {
            selectedMealType = title
            showingRecordSheet = true
            #if os(iOS)
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            #endif
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isDone ? Color.lcGreen.opacity(0.15) : color.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: isDone ? "checkmark" : icon)
                        .font(.title3.bold())
                        .foregroundColor(isDone ? .lcGreen : color)
                }
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(isDone ? .lcGreen : .lcText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.lcCardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isDone ? Color.lcGreen.opacity(0.4) : Color.clear, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - 今日总结区
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日能量总结 🔋")
                .font(.headline.bold())
                .foregroundColor(.lcText)
                .padding(.horizontal, 4)
                .padding(.top, 10)
            
            if todayRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "takeoutbag.and.cup.and.straw")
                        .font(.largeTitle)
                        .foregroundColor(.lcSoftBlue)
                    Text("今天还没有记录哦，吃点东西吧~")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .background(Color.lcCardBackground)
                .cornerRadius(20)
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(todayRecords) { record in
                        SummaryCard(
                            record: record,
                            onAddPhoto: { image in
                                updateRecordPhoto(record, image: image)
                            },
                            onDelete: {
                                deleteRecord(record)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - 数据处理逻辑
    private func loadTodayRecords() {
        guard let data = recordsJSON.data(using: .utf8),
              let allRecords = try? JSONDecoder().decode([DietCheckinRecord].self, from: data) else {
            todayRecords = []
            return
        }
        
        let todayKey = makeDateKey(Date())
        todayRecords = allRecords.filter { $0.dateKey == todayKey }
        
        // 同步状态给大管家 AppState
        state.isBreakfastDone = todayRecords.contains { $0.mealType == "早餐" }
        state.isLunchDone = todayRecords.contains { $0.mealType == "午餐" }
        state.isDinnerDone = todayRecords.contains { $0.mealType == "晚餐" }
    }
    
    private func saveRecord(mealType: String, content: String, image: UIImage?) {
        var allRecords: [DietCheckinRecord] = []
        if let data = recordsJSON.data(using: .utf8),
           let decoded = try? JSONDecoder().decode([DietCheckinRecord].self, from: data) {
            allRecords = decoded
        }
        
        let todayKey = makeDateKey(Date())
        var imageFilename: String? = nil
        
        // 如果有图片，保存到本地沙盒
        if let image = image {
            imageFilename = saveImageToDocuments(image: image)
        }
        
        let finalContent = content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "吃饱啦！"
            : content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let diaryLine = makeDietDiaryLine(mealType: mealType, content: finalContent)
        
        let newRecord = DietCheckinRecord(
            dateKey: todayKey,
            date: Date(),
            mealType: mealType,
            content: finalContent,
            imageFilename: imageFilename,
            diaryLine: diaryLine
        )
        
        // 如果今天同一餐已经有记录了，可以选择覆盖，也可以直接添加。这里我们选择直接添加（允许多次吃晚餐）
        allRecords.append(newRecord)
        
        if let data = try? JSONEncoder().encode(allRecords),
           let jsonString = String(data: data, encoding: .utf8) {
            recordsJSON = jsonString
        }
        
        // 🆕 V2：新增饮食后，自动写入今天日记
        state.appendDietLineToTodayJournal(diaryLine)
        
        loadTodayRecords() // 刷新视图，并同步首页今日饮食 SOP
    }
    private func deleteRecord(_ record: DietCheckinRecord) {
        guard let data = recordsJSON.data(using: .utf8),
              var allRecords = try? JSONDecoder().decode([DietCheckinRecord].self, from: data) else {
            return
        }
        
        // 1. 从总记录里删除这一条
        allRecords.removeAll { $0.id == record.id }
        
        // 2. 如果这条记录有图片，也顺手把本地图片删掉，避免垃圾文件越来越多
        if let filename = record.imageFilename {
            deleteImageFromDocuments(filename: filename)
        }
        
        // 3. 写回 AppStorage
        if let data = try? JSONEncoder().encode(allRecords),
           let jsonString = String(data: data, encoding: .utf8) {
            recordsJSON = jsonString
        }

        // 🆕 V2：删除饮食记录时，也从今天日记里删掉对应那一句
        if let diaryLine = record.diaryLine {
            state.removeDietLineFromTodayJournal(diaryLine)
        } else {
            // 兼容旧记录：以前没有 diaryLine，就临时按 mealType + content 拼一次
            let fallbackLine = makeDietDiaryLine(mealType: record.mealType, content: record.content)
            state.removeDietLineFromTodayJournal(fallbackLine)
        }

        loadTodayRecords()
        
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    private func updateRecordPhoto(_ record: DietCheckinRecord, image: UIImage) {
        guard let data = recordsJSON.data(using: .utf8),
              var allRecords = try? JSONDecoder().decode([DietCheckinRecord].self, from: data),
              let index = allRecords.firstIndex(where: { $0.id == record.id }) else {
            return
        }
        
        // 1. 保存新照片
        guard let newFilename = saveImageToDocuments(image: image) else {
            return
        }
        
        // 2. 如果原来有旧照片，先删掉旧照片，避免垃圾文件越来越多
        if let oldFilename = allRecords[index].imageFilename {
            deleteImageFromDocuments(filename: oldFilename)
        }
        
        // 3. 把这条记录的照片文件名更新掉
        allRecords[index].imageFilename = newFilename
        
        // 4. 写回 AppStorage
        if let data = try? JSONEncoder().encode(allRecords),
           let jsonString = String(data: data, encoding: .utf8) {
            recordsJSON = jsonString
        }
        
        // 5. 刷新今日总结
        loadTodayRecords()
        
        #if os(iOS)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        #endif
    }
    
    // MARK: - 🆕 V2：饮食日记句子

    private func makeDietDiaryLine(mealType: String, content: String) -> String {
        let cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return "🍽 \(mealType)：\(cleanContent)"
    }

    private func makeDateKey(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

/// MARK: - 🧀 3. 记录卡片组件 (Summary)
struct SummaryCard: View {
    let record: DietCheckinRecord
    let onAddPhoto: (UIImage) -> Void
    let onDelete: () -> Void
    
    @State private var loadedImage: UIImage?
    @State private var selectedPhotoItem: PhotosPickerItem?
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            photoArea
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(record.mealType)
                        .font(.subheadline.bold())
                        .foregroundColor(.lcAccentBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.lcAccentBlue.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Text(record.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                            .font(.caption.bold())
                            .foregroundColor(.red.opacity(0.75))
                            .padding(7)
                            .background(Color.red.opacity(0.08))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("删除这条饮食记录")
                }
                
                Text(record.content)
                    .font(.body)
                    .foregroundColor(.lcText)
                    .lineLimit(3)
                    .padding(.top, 2)
                
                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Label(record.imageFilename == nil ? "补一张照片" : "换照片", systemImage: "photo")
                        .font(.caption.bold())
                        .foregroundColor(.lcAccentBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.lcAccentBlue.opacity(0.08))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color.lcCardBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.02), radius: 6, x: 0, y: 3)
        .onAppear {
            refreshLoadedImage()
        }
        .onChange(of: record.imageFilename) { _, _ in
            refreshLoadedImage()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    loadedImage = uiImage
                    onAddPhoto(uiImage)
                    selectedPhotoItem = nil
                }
            }
        }
    }
    
    private var photoArea: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            Group {
                if let uiImage = loadedImage {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(alignment: .bottomTrailing) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                                .foregroundColor(.lcAccentBlue)
                                .background(Color.white.clipShape(Circle()))
                                .padding(5)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.lcSoftBlue.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .overlay(
                            VStack(spacing: 6) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.title3.bold())
                                Text("补照片")
                                    .font(.caption2.bold())
                            }
                            .foregroundColor(.lcAccentBlue.opacity(0.75))
                        )
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(record.imageFilename == nil ? "补照片" : "更换照片")
    }
    
    private func refreshLoadedImage() {
        if let filename = record.imageFilename {
            loadedImage = loadImageFromDocuments(filename: filename)
        } else {
            loadedImage = nil
        }
    }
}
// MARK: - 🧀 4. 记录打卡弹窗 (带照片选择)
struct DietRecordSheetView: View {
    let mealType: String
    let onSave: (String, UIImage?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var content: String = ""
    
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("今天的\(mealType)怎么样？")
                        .font(.title2.bold())
                        .foregroundColor(.lcText)
                    
                    // 拍照/选图区域
                    PhotosPicker(selection: $selectedItem, matching: .images, photoLibrary: .shared()) {
                        if let selectedImage {
                            Image(uiImage: selectedImage)
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity, minHeight: 200, maxHeight: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.lcSoftBlue.opacity(0.5), lineWidth: 1)
                                )
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "camera.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.lcAccentBlue)
                                Text("拍个照或者选张图吧")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.lcText)
                                Text("如果不拍也没关系")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 180)
                            .background(Color.lcSoftBlue.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }
                    .onChange(of: selectedItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self),
                               let uiImage = UIImage(data: data) {
                                selectedImage = uiImage
                            }
                        }
                    }
                    
                    // 文字记录区域
                    VStack(alignment: .leading, spacing: 8) {
                        Text("碎碎念")
                            .font(.subheadline.bold())
                            .foregroundColor(.secondary)
                        
                        TextField("随便写点什么，比如：吃了半碗粉...", text: $content, axis: .vertical)
                            .lineLimit(3...6)
                            .padding(16)
                            .background(Color.lcCardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.lcSoftBlue.opacity(0.5), lineWidth: 1)
                            )
                    }
                    
                    // 保存按钮
                    Button {
                        onSave(content, selectedImage)
                        #if os(iOS)
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        #endif
                        dismiss()
                    } label: {
                        Text("记好了，摸摸头！")
                            .font(.headline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.lcAccentBlue)
                            .cornerRadius(20)
                            .shadow(color: Color.lcAccentBlue.opacity(0.3), radius: 8, y: 4)
                    }
                    .padding(.top, 10)
                }
                .padding(24)
            }
            .background(Color.lcBackground.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

// MARK: - 🧀 5. 图片存储工具函数
// 因为 @AppStorage 不能直接存大图片，我们把图片存在手机的沙盒文件里，只保存文件名。
func saveImageToDocuments(image: UIImage) -> String? {
    guard let data = image.jpegData(compressionQuality: 0.7) else { return nil }
    let filename = UUID().uuidString + ".jpg"
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
    do {
        try data.write(to: url)
        return filename
    } catch {
        print("图片保存失败: \(error)")
        return nil
    }
}

func loadImageFromDocuments(filename: String) -> UIImage? {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
    if let data = try? Data(contentsOf: url) {
        return UIImage(data: data)
    }
    return nil
}
func deleteImageFromDocuments(filename: String) {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)
    try? FileManager.default.removeItem(at: url)
}
