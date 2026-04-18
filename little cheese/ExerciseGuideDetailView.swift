import SwiftUI

struct ExerciseGuideDetailView: View {
    let item: ExerciseItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                targetAreaCard

                guideSection(
                    title: "开始前先站好",
                    icon: "figure.stand",
                    items: item.guide.startPosition
                )

                guideSection(
                    title: "一步一步做",
                    icon: "list.number",
                    items: item.guide.steps,
                    numbered: true
                )

                guideSection(
                    title: "你做对时会感觉到",
                    icon: "sparkles",
                    items: item.guide.feeling
                )

                guideSection(
                    title: "常见错误提醒",
                    icon: "exclamationmark.triangle",
                    items: item.guide.mistakes
                )

                if let breathing = item.guide.breathing, !breathing.isEmpty {
                    tipCard(
                        title: "呼吸提醒",
                        icon: "wind",
                        content: breathing
                    )
                }

                if let beginnerTip = item.guide.beginnerTip, !beginnerTip.isEmpty {
                    tipCard(
                        title: "给新手的小提醒",
                        icon: "heart",
                        content: beginnerTip
                    )
                }
            }
            .padding(16)
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(item.guide.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(item.guide.shortDescription)
                .font(.body)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                categoryBadge(text: item.category.rawValue)
                categoryBadge(text: "动作引导")
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var targetAreaCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("主要发力部位", systemImage: "figure.strengthtraining.traditional")
                .font(.headline)

            FlexibleTagView(tags: item.guide.targetAreas)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func guideSection(
        title: String,
        icon: String,
        items: [String],
        numbered: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(items.enumerated()), id: \.offset) { index, text in
                    HStack(alignment: .top, spacing: 10) {
                        if numbered {
                            Text("\(index + 1)")
                                .font(.subheadline.weight(.bold))
                                .frame(width: 24, height: 24)
                                .background(Color(.systemGray5))
                                .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color(.systemGray3))
                                .frame(width: 8, height: 8)
                                .padding(.top, 6)
                        }

                        Text(text)
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func tipCard(title: String, icon: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.headline)

            Text(content)
                .font(.body)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func categoryBadge(text: String) -> some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .clipShape(Capsule())
    }
}

// MARK: - 自动换行标签
struct FlexibleTagView: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(rows, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private var rows: [[String]] {
        var result: [[String]] = []
        var currentRow: [String] = []

        for tag in tags {
            if currentRow.count < 3 {
                currentRow.append(tag)
            } else {
                result.append(currentRow)
                currentRow = [tag]
            }
        }

        if !currentRow.isEmpty {
            result.append(currentRow)
        }

        return result
    }
}

#Preview {
    NavigationStack {
        ExerciseGuideDetailView(item: ExerciseGuideLibrary.sampleExercises[0])
    }
}
