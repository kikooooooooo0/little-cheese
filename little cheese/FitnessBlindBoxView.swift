import SwiftUI

// MARK: - 盲盒任务的数据结构（写在同一个文件里，最安全！）
struct FitnessTask {
    let name: String
    let emoji: String
    let minutes: Int
}

// MARK: - 盲盒抽取页面
struct FitnessBlindBoxView: View {
    @ObservedObject var state: AppState
    @Environment(\.dismiss) var dismiss
    
    // 🎁 我们的盲盒题库（你可以随时在这里添加奇思妙想）
    let tasks: [FitnessTask] = [
        FitnessTask(name: "伸个大大的懒腰，摸摸天花板", emoji: "🙆", minutes: 1),
        FitnessTask(name: "起立！离开椅子走动一圈", emoji: "🚶", minutes: 1),
        FitnessTask(name: "无敌深蹲 10 次", emoji: "🏋️", minutes: 2),
        FitnessTask(name: "闭上眼睛，做 3 次深呼吸", emoji: "🌬️", minutes: 1),
        FitnessTask(name: "随便放首喜欢的歌，跟着摇摆", emoji: "🎵", minutes: 3),
        FitnessTask(name: "去喝一大杯温水", emoji: "🚰", minutes: 1)
    ]
    
    @State private var currentTask: FitnessTask?
    @State private var isShaking = false

    var body: some View {
        VStack(spacing: 40) {
            Text("🎁 多巴胺微动弹")
                .font(.largeTitle.bold())
                .foregroundColor(.lcText)

            if let task = currentTask {
                // ✨ 状态 B：抽中任务后的卡片
                VStack(spacing: 20) {
                    Text(task.emoji).font(.system(size: 80))
                    Text(task.name)
                        .font(.title2.bold())
                        .foregroundColor(.lcText)
                        .multilineTextAlignment(.center)
                    Text("只需耗时：\(task.minutes) 分钟 🧀")
                        .font(.subheadline)
                        .foregroundColor(.lcTextSecondary)
                }
                .padding(30)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                .transition(.scale.combined(with: .opacity))
                
                // 操作按钮
                VStack(spacing: 16) {
                    Button {
                        // 🚀 核心联动：直接开启番茄钟，自动带上标题和时间！
                        state.startPomodoro(minutes: task.minutes, lifeAreaId: nil, note: "微动弹：\(task.name)", phase: .focus)
                        dismiss()
                    } label: {
                        Text("接受挑战！开启计时 ⏱️")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.lcAccentBlue)
                            .cornerRadius(20)
                    }
                    
                    Button {
                        // 换一个：ADHD 友好的“无痛反悔”机制
                        withAnimation(.spring()) {
                            currentTask = tasks.randomElement()
                        }
                    } label: {
                        Text("不想做这个，换一个")
                            .font(.subheadline)
                            .foregroundColor(.lcTextSecondary)
                            .padding(.top, 8)
                    }
                }
                
            } else {
                // 📦 状态 A：还没抽取的盲盒状态
                VStack(spacing: 20) {
                    Text("❓")
                        .font(.system(size: 80))
                        .rotationEffect(.degrees(isShaking ? 15 : -15))
                        .animation(.easeInOut(duration: 0.1).repeatCount(5, autoreverses: true), value: isShaking)
                    
                    Text("今天身体想怎么动？")
                        .font(.headline)
                        .foregroundColor(.lcTextSecondary)
                }
                .padding(40)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 24).fill(Color.lcCardBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, y: 5)
                
                Button {
                    // 点击盲盒：物理震动 + 延迟开奖效果
                    isShaking = true
                    #if os(iOS)
                    let generator = UIImpactFeedbackGenerator(style: .heavy)
                    generator.impactOccurred()
                    #endif
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                            currentTask = tasks.randomElement()
                            isShaking = false
                        }
                    }
                } label: {
                    Text("点击抽取盲盒 🎁")
                        .font(.headline)
                        .foregroundColor(.lcText)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.lcCheeseYellow)
                        .cornerRadius(20)
                }
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.lcBackground.ignoresSafeArea())
    }
}//
//  FitnessBlindBoxView.swift
//  little cheese
//
//  Created by jdjdind dhdjkd on 2026-04-01.
//

