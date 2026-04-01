import SwiftUI

struct WeeklyReviewView: View {
    // 🚨 这里一定要是 AppState，和你 ContentView 里的类型一致
    @ObservedObject var state: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("本周回顾")
                    .font(.largeTitle.bold())

                Text("这里以后可以放：本周完成了什么、遇到哪些困难、下周的三个重点。")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                List {
                    Section("这个星期的亮点") {
                        Text("✅ 完成了一些重要的事情")
                        Text("✅ 有好好照顾自己（哪怕只是一点点）")
                    }

                    Section("下周我想关注的") {
                        Text("• 最想完成的一件事")
                        Text("• 容易分心的场景")
                    }
                }
            }
            .navigationTitle("回顾")
        }
    }
}
