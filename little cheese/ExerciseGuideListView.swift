import SwiftUI

struct ExerciseGuideListView: View {
    private let items = ExerciseGuideLibrary.sampleExercises

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    headerSection

                    VStack(spacing: 12) {
                        ForEach(items) { item in
                            NavigationLink {
                                ExerciseGuideDetailView(item: item)
                            } label: {
                                ExerciseGuideRowCard(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
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
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}
struct ExerciseGuideRowCard: View {
    let item: ExerciseItem

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemGray6))
                    .frame(width: 52, height: 52)

                Image(systemName: iconName(for: item.category))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(item.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }

                Text(item.guide.shortDescription)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 6) {
                    ForEach(item.guide.targetAreas.prefix(3), id: \.self) { area in
                        Text(area)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(Color(.systemGray6))
                            .clipShape(Capsule())
                    }
                }
            }

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func iconName(for category: ExerciseCategory) -> String {
        switch category {
        case .lowerBody:
            return "figure.strengthtraining.traditional"
        case .upperBody:
            return "figure.mixed.cardio"
        case .core:
            return "figure.core.training"
        case .fullBody:
            return "figure.highintensity.intervaltraining"
        case .cardio:
            return "heart.circle"
        case .mobility:
            return "figure.flexibility"
        }
    }
}

#Preview {
    ExerciseGuideListView()
}//
//  ExerciseGuideListView.swift
//  little cheese
//
//  Created by jdjdind dhdjkd on 2026-04-18.
//

