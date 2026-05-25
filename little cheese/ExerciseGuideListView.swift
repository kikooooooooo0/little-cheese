import SwiftUI

struct ExerciseGuideListView: View {
    @ObservedObject var state: AppState

    // 🧀 使用统一的新数据源
    private let items = WorkoutLibrary.exercises

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection

                    VStack(spacing: 12) {
                        ForEach(items) { item in
                            NavigationLink {
                                WorkoutActionDetailView(state: state, action: item)
                            } label: {
                                ExerciseGuideRowCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color.lcBackground)
            .navigationTitle("动作引导")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今天做什么？")
                .font(.title2)
                .fontWeight(.bold)

            Text("不用记术语，也不用慌。点开一个动作，我会一步一步带你做。")
                .font(.body)
                .foregroundColor(.lcTextSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lcCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
// MARK: - 列表卡片 UI
struct ExerciseGuideRowCard: View {
    let item: WorkoutActionModel

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.lcSoftBlue.opacity(0.3))
                    .frame(width: 52, height: 52)

                Image(systemName: iconName(for: item.category))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.lcAccentBlue)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.lcText)

                    Spacer()

                    Text(item.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.lcCheeseYellow.opacity(0.2))
                        .foregroundColor(.lcYellow)
                        .clipShape(Capsule())
                }

                Text(item.shortDesc)
                    .font(.subheadline)
                    .foregroundColor(.lcTextSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    Text(item.targetMuscle)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.gray.opacity(0.1))
                        .foregroundColor(.lcTextSecondary)
                        .clipShape(Capsule())
                }
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.gray.opacity(0.5))
                .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lcCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.02), radius: 5, y: 2)
    }

    private func iconName(for category: ExerciseCategory) -> String {
        switch category {
        case .lowerBody: return "figure.strengthtraining.traditional"
        case .upperBody: return "figure.mixed.cardio"
        case .core: return "figure.core.training"
        case .fullBody: return "figure.highintensity.intervaltraining"
        case .cardio: return "heart.circle"
        case .mobility: return "figure.flexibility"
        }
    }
}

#Preview {
    ExerciseGuideListView(state: AppState())
}
