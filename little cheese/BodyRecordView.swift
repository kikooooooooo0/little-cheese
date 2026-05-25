import SwiftUI

struct BodyRecordView: View {
    @ObservedObject var state: AppState
    
    private let accent = Color.lcYellow
    private let bgColor = Color.lcBackground
    private let cardBg = Color.lcCardBackground
    private let textColor = Color.lcText
    private let secondaryTextColor = Color.lcTextSecondary
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                
                headerCard
                
                VStack(spacing: 14) {
                    NavigationLink {
                        DietSOPView(state: state)
                    } label: {
                        BodyRecordFeatureCard(
                            emoji: "🍽",
                            title: "今日吃了什么",
                            subtitle: "早餐、午餐、晚餐，拍照或随手写都可以",
                            footnote: "自动同步到今日饮食 SOP / 日记",
                            tint: .lcYellow
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        ExerciseGuideListView(state: state)
                    } label: {
                        BodyRecordFeatureCard(
                            emoji: "💪",
                            title: "今日练了什么",
                            subtitle: "不知道做什么就点进来，小奶酪带你选动作",
                            footnote: "动作详情 / 陪练模式入口",
                            tint: .lcAccentBlue
                        )
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink {
                        WeightRecordView(state: state)
                    } label: {
                        BodyRecordFeatureCard(
                            emoji: "⚖️",
                            title: "身体状态小记录",
                            subtitle: "体重、能量、排便、晚餐程度，一起存起来",
                            footnote: "用于本月轻盈报告",
                            tint: .lcSoftBlue
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                gentleReminderCard
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(bgColor.ignoresSafeArea())
        .navigationTitle("今日身体记录 🧀")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("今天不用完美")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(textColor)
            
            Text("这里不是审判你吃了什么、练了多少的地方。这里只负责帮你把今天轻轻接住。")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .lineSpacing(4)
            
            HStack(spacing: 8) {
                smallTag("低压力")
                smallTag("可拍照")
                smallTag("可补记")
            }
            .padding(.top, 4)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    Color.lcYellow.opacity(0.24),
                    Color.pink.opacity(0.10),
                    cardBg
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(30)
        .shadow(color: Color.black.opacity(0.04), radius: 14, x: 0, y: 6)
    }
    
    private var gentleReminderCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🧀 小奶酪提醒")
                .font(.headline)
                .foregroundColor(textColor)
            
            Text("你不需要每天都像健身博主一样生活。能记录下来，就已经是在照顾自己。")
                .font(.subheadline)
                .foregroundColor(secondaryTextColor)
                .lineSpacing(4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(cardBg)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
    
    private func smallTag(_ text: String) -> some View {
        Text(text)
            .font(.caption.bold())
            .foregroundColor(textColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.45))
            .clipShape(Capsule())
    }
}

struct BodyRecordFeatureCard: View {
    let emoji: String
    let title: String
    let subtitle: String
    let footnote: String
    let tint: Color
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(width: 58, height: 58)
                
                Text(emoji)
                    .font(.system(size: 28))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.lcText)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.lcTextSecondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(footnote)
                    .font(.caption.bold())
                    .foregroundColor(tint)
                    .padding(.top, 2)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.lcTextSecondary.opacity(0.65))
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.lcCardBackground)
        .cornerRadius(24)
        .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
}

#Preview {
    NavigationStack {
        BodyRecordView(state: AppState())
    }
}//
//  BodyRecordView.swift
//  little cheese
//
//  Created by jdjdind dhdjkd on 2026-05-25.
//

