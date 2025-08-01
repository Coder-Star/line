//
//  ChartView.swift
//  line
//
//  Created by CoderStar on 2025/7/28.
//

import SwiftUI

struct ChartView: View {
    let selectedFeeling: String
    let onBackToSelection: () -> Void
    let onGoToSettings: () -> Void
    @StateObject private var activityManager = LiveActivityManager()
    @State private var updateTimer: Timer?
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3),
                    Color.pink.opacity(0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 右上角设置按钮
                HStack {
                    Spacer()
                    Button(action: {
                        onGoToSettings()
                    }) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 44, height: 44)
                            )
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 60)
                
                // 标题区域
                VStack(spacing: 12) {
                    if !selectedFeeling.isEmpty {
                        Text(selectedFeeling)
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Text("Select a Feeling")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    
                    // 当前数值显示
                    VStack(spacing: 4) {
                        Text("Current Value")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("\(String(format: "%.1f", activityManager.currentData.currentValue))")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.top, 60)
                .padding(.horizontal, 30)
                
                // 折线图区域
                VStack(alignment: .leading, spacing: 12) {
                    LineChartView(
                        dataPoints: activityManager.currentData.dataPoints.map { CGFloat($0) },
                        lineColor: feelingColor(for: selectedFeeling),
                        lineWidth: 4,
                        showDots: true,
                        animated: true
                    )
                    .frame(height: 250)
                    .padding(.horizontal)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .backdrop(blur: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                }
                .padding(.horizontal, 20)
                
                // 控制按钮
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        Button(action: {
                            activityManager.simulateDataUpdate()
                        }) {
                            Label("Update Data", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle())
                        
                        Button(action: {
                            toggleAutoUpdate()
                        }) {
                            Label(updateTimer != nil ? "Stop Auto" : "Start Auto", 
                                  systemImage: updateTimer != nil ? "pause.fill" : "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(GlassButtonStyle())
                    }
                    
                    // Back to Selection 按钮
                    if !selectedFeeling.isEmpty {
                        Button("Back to Selection") {
                            onBackToSelection()
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(25)
                        .fontWeight(.medium)
                    }
                }
                .padding(.horizontal, 20)
                
                // 状态信息
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Live Activity:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(activityManager.isActivityActive ? "Active" : "Inactive")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(activityManager.isActivityActive ? .green : .gray)
                    }
                    
                    HStack {
                        Text("Last Updated:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(DateFormatter.shortTime.string(from: activityManager.currentData.lastUpdated))
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .onDisappear {
            updateTimer?.invalidate()
        }
    }
    
    private func toggleAutoUpdate() {
        if updateTimer != nil {
            updateTimer?.invalidate()
            updateTimer = nil
        } else {
            updateTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                activityManager.simulateDataUpdate()
            }
        }
    }
    
    private func feelingColor(for feeling: String) -> Color {
        switch feeling {
        case "Calm": return .blue
        case "Connected": return .green
        case "Motivated": return .gray
        case "Stimulated": return .cyan
        case "Focused": return .teal
        case "Light-Hearted": return .mint
        case "Inspired": return .purple
        case "Curious": return .indigo
        default: return .white
        }
    }
}

// 玻璃效果按钮样式
struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .backdrop(blur: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .foregroundColor(.white)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// 背景模糊效果扩展
extension View {
    func backdrop(blur radius: CGFloat) -> some View {
        self.background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .blur(radius: radius / 3)
        )
    }
}

 