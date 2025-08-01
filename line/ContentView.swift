//
//  ContentView.swift
//  line
//
//  Created by CoderStar on 2025/7/28.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var activityManager = LiveActivityManager()
    @State private var updateTimer: Timer?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // 标题
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("折线图演示")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        // 简化TrendBadge调用，提供安全的默认值
                        TrendBadge(trend: activityManager.currentData.trend.isEmpty ? "stable" : activityManager.currentData.trend)
                    }
                    
                    Text("支持灵动岛和实时活动的SwiftUI折线图")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // 当前数值显示
                VStack(spacing: 4) {
                    Text("当前数值")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(String(format: "%.1f", activityManager.currentData.currentValue))")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
                
                // 折线图
                VStack(alignment: .leading, spacing: 12) {
                    Text("数据趋势")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    LineChartView(
                        dataPoints: activityManager.currentData.dataPoints.map { CGFloat($0) },
                        lineColor: trendColor(for: activityManager.currentData.trend),
                        lineWidth: 3,
                        showDots: true,
                        animated: true
                    )
                    .frame(height: 200)
                    .padding(.horizontal)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(.horizontal)
                
                // 控制按钮
                VStack(spacing: 12) {
                    // YouTube 登录按钮 (已移至主流程LoginView)
                    // NavigationLink(destination: YouTubeLoginView()) {
                    //     Label("YouTube登录获取Cookie", systemImage: "globe")
                    //         .frame(maxWidth: .infinity)
                    // }
                    // .buttonStyle(.borderedProminent)
                    // .tint(.red)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            activityManager.simulateDataUpdate()
                        }) {
                            Label("更新数据", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            toggleAutoUpdate()
                        }) {
                            Label(updateTimer != nil ? "停止自动更新" : "开始自动更新", 
                                  systemImage: updateTimer != nil ? "pause.fill" : "play.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // 实时活动控制
                    HStack(spacing: 16) {
                        if !activityManager.isActivityActive {
                            Button(action: {
                                activityManager.startLiveActivity()
                            }) {
                                Label("启动实时活动", systemImage: "dot.radiowaves.left.and.right")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        } else {
                            Button(action: {
                                activityManager.stopLiveActivity()
                            }) {
                                Label("停止实时活动", systemImage: "stop.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                }
                .padding(.horizontal)
                
                // 状态信息
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("实时活动状态：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(activityManager.isActivityActive ? "运行中" : "未激活")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(activityManager.isActivityActive ? .green : .gray)
                    }
                    
                    HStack {
                        Text("最后更新：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(DateFormatter.shortTime.string(from: activityManager.currentData.lastUpdated))
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    
                    Text("💡 启动实时活动后，折线图会显示在锁屏界面和灵动岛中")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
                
                Spacer()
            }
        }
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
    
    private func trendColor(for trend: String) -> Color {
        switch trend {
        case "up":
            return .green
        case "down":
            return .red
        default:
            return .blue
        }
    }
}

// 趋势徽章组件
struct TrendBadge: View {
    let trend: String
    
    var body: some View {
        HStack(spacing: 4) {
            Group {
                switch trend {
                case "up":
                    Image(systemName: "arrow.up.right")
                    Text("上涨")
                case "down":
                    Image(systemName: "arrow.down.right")
                    Text("下跌")
                default:
                    Image(systemName: "minus")
                    Text("平稳")
                }
            }
            .font(.caption)
            .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(6)
    }
    
    private var backgroundColor: Color {
        switch trend {
        case "up":
            return .green.opacity(0.1)
        case "down":
            return .red.opacity(0.1)
        default:
            return .blue.opacity(0.1)
        }
    }
    
    private var foregroundColor: Color {
        switch trend {
        case "up":
            return .green
        case "down":
            return .red
        default:
            return .blue
        }
    }
}

// 日期格式化器扩展
extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}


