import SwiftUI

struct MealPlanEditorView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Text("在这里定好这一周的减肥 SOP，\n饿的时候直接看首页，不用再思考 🧀")
                    .font(.caption)
                    .foregroundColor(.lcTextSecondary)
                    .listRowBackground(Color.clear)

                ForEach($state.weeklyMealPlans) { $plan in
                    Section(header: Text(plan.dayName).font(.headline).foregroundColor(.lcAccentBlue)) {
                        HStack {
                            Text("🍳 早餐")
                            TextField("如：鸡蛋 + 香蕉", text: $plan.breakfast)
                                .textFieldStyle(.plain)
                        }
                        HStack {
                            Text("🍱 午餐")
                            TextField("如：鸡胸肉沙拉", text: $plan.lunch)
                        }
                        HStack {
                            Text("🌙 晚餐")
                            TextField("如：香蕉", text: $plan.dinner)
                        }
                    }
                }
            }
            .navigationTitle("七天食谱计划")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .background(Color.lcBackground)
            .scrollContentBackground(.hidden)
        }
    }
}
