import SwiftUI

struct WorkoutSessionView: View {
    
    let exerciseName: String
    let totalSets: Int
    let repsPerSet: Int
    
    @State private var currentSet = 1
    @State private var currentReps = 0
    
    var body: some View {
        VStack(spacing: 30) {
            
            // 动作名
            Text(exerciseName)
                .font(.title)
                .fontWeight(.bold)
            
            // 组数
            Text("第 \(currentSet) / \(totalSets) 组")
                .font(.headline)
            
            // 次数进度
            Text("已完成：\(currentReps) / \(repsPerSet)")
                .font(.title2)
            
            // +1 按钮
            Button(action: {
                if currentReps < repsPerSet {
                    currentReps += 1
                }
            }) {
                Text("做完一次 +1")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.yellow)
                    .cornerRadius(12)
            }
            
            // 下一组
            Button(action: {
                if currentSet < totalSets {
                    currentSet += 1
                    currentReps = 0
                }
            }) {
                Text("完成这一组 → 下一组")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.pink)
                    .cornerRadius(12)
            }
            
            Spacer()
        }
        .padding()
    }
}//
//  WorkoutSessionView.swift
//  little cheese
//
//  Created by jdjdind dhdjkd on 2026-04-18.
//

