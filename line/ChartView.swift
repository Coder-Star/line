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
    @StateObject private var sentimentManager = SentimentStreamManager()
    @State private var showConnectionStatus = false
    
    // 缓存状态信息以避免线程问题
    @State private var cachedConnectionStatus = false
    @State private var cachedConnectionError: String?
    @State private var cachedDataCount = 0
    @State private var cachedLastUpdate: String?
    
    var body: some View {
        ZStack {
            // 底层：common_bg背景 - 铺满整个屏幕 (与FeelingView保持一致)
            GeometryReader { geometry in
                Image("common_bg")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geometry.size.width,
                        height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
                    )
                    .clipped()
                    .offset(y: -geometry.safeAreaInsets.top)
            }
            .ignoresSafeArea(.all)
            
            GeometryReader { geometry in
                VStack(spacing: 15) {
                    // 右上角设置按钮
                    HStack {
                        Spacer()
                        Button(action: {
                            onGoToSettings()
                        }) {
                            Image(systemName: "gear")
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
                
                // 顶部信息区域
                HStack {
                    // 左侧：情感名称和当前数值
                    VStack(alignment: .leading, spacing: 4) {
                        if !selectedFeeling.isEmpty {
                            Text(selectedFeeling)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            // 只有在收到真实数据时才显示数值
                            if sentimentManager.latestData != nil || !sentimentManager.dataHistory.isEmpty {
                                Text("\(Int(sentimentManager.getCurrentValue(for: selectedFeeling)))")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("--")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        } else {
                            Text("No Feeling")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    // 右侧：增量和更新时间
                    VStack(alignment: .trailing, spacing: 4) {
                        if let latestData = sentimentManager.latestData {
                            let deltaValue = latestData.sentiment.getValue(for: selectedFeeling)
                            Text(deltaValue >= 0 ? "+\(Int(deltaValue))" : "\(Int(deltaValue))")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(deltaValue >= 0 ? .green : .red)
                            
                            Text("Updated \(formatTimeAgo(latestData.timestamp))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Text("--")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white.opacity(0.5))
                            
                            Text("No updates")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(.horizontal, 30)
                .padding(.top, 10)
                
                // 折线图区域
                VStack(spacing: 20) {
                    // 图表
                    LineChartView(
                        dataPoints: sentimentManager.getDataPoints(for: selectedFeeling).map { CGFloat($0) },
                        lineColor: .white,
                        lineWidth: 4,
                        showDots: true,
                        animated: true,
                        showGrid: false,
                        showValues: false,
                        showReferenceLine: false,
                        referenceValue: 30,
                        minYValue: 0,
                        maxYValue: 100,
                        smoothness: 0.8
                    )
                    .frame(height: 200)
                    .padding(.horizontal, 30)
                    
                    // 时间轴和历史数值
                    VStack(spacing: 8) {
                        HStack {
                            TimeAxisLabel(title: "1 Week", value: getSSEHistoricalValue(period: "oneweek"))
                            Spacer()
                            TimeAxisLabel(title: "1 Day", value: getSSEHistoricalValue(period: "oneday"))
                            Spacer()
                            TimeAxisLabel(title: "12 Hours", value: getSSEHistoricalValue(period: "sixhours"))
                            Spacer()
                            TimeAxisLabel(title: "1 Hour", value: getSSEHistoricalValue(period: "onehour"))
                        }
                        .padding(.horizontal, 30)
                    }
                    
                    // 底部消息
                    if let latestData = sentimentManager.latestData {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Updated \(formatTimeAgo(latestData.timestamp))")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                                .id("bottom-time-\(latestData.timestamp)") // 强制UI更新
                            
                            Text("Latest update received. Your mood is being tracked.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.horizontal, 30)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.top, 20)
                

                
                Spacer()
                
                // 底部返回按钮
                Button("Back to Feeling Selection") {
                    // 断开SSE连接
                    print("🔌 断开SSE连接...")
                    sentimentManager.disconnect()
                    
                    // 停止Live Activity
                    print("⏹️ 停止Live Activity...")
                    sentimentManager.stopAllLiveActivities()
                    
                    // 返回到选择页面
                    onBackToSelection()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .foregroundColor(.black)
                .cornerRadius(28)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("📱 ChartView出现，检查SSE连接状态")
            print("🔍 当前连接状态: \(sentimentManager.isConnected)")
            print("🎯 选中的情感: '\(selectedFeeling)'")
            
            // 更新缓存状态
            updateCachedStatus()
            
            // 强制刷新视图状态，避免布局累积问题
            
            // 启动Live Activity（如果选择了情感）
            if !selectedFeeling.isEmpty {
                print("🚀 启动Live Activity for: \(selectedFeeling)")
                sentimentManager.startLiveActivityForFeeling(selectedFeeling)
            }
            
            // 只有在未连接时才尝试连接，避免重复连接
            if !sentimentManager.isConnected {
                print("🔗 连接状态为false，开始连接SSE")
                sentimentManager.connectToStream()
            } else {
                print("✅ 连接已存在，跳过重复连接")
            }
        }
        .onChange(of: sentimentManager.isConnected) { _ in
            updateCachedStatus()
        }
        .onChange(of: sentimentManager.connectionError) { _ in
            updateCachedStatus()
        }
        .onChange(of: sentimentManager.dataHistory.count) { _ in
            updateCachedStatus()
        }
        .onChange(of: sentimentManager.latestData?.timestamp) { _ in
            updateCachedStatus()
        }
        .onDisappear {
            // 页面消失时的清理工作
            print("📱 ChartView消失，进行清理...")
            sentimentManager.disconnect()
            sentimentManager.stopAllLiveActivities()
        }
        .alert("Connection Status", isPresented: $showConnectionStatus) {
            Button("OK") { }
        } message: {
            VStack(alignment: .leading) {
                Text("Status: \(cachedConnectionStatus ? "Connected" : "Disconnected")")
                if let error = cachedConnectionError {
                    Text("Error: \(error)")
                }
                Text("Data Points: \(cachedDataCount)")
                if let lastUpdate = cachedLastUpdate {
                    Text("Last Update: \(lastUpdate)")
                }
            }
        }
    }
    
    private func formatTimestamp(_ timestamp: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        inputFormatter.timeZone = TimeZone(abbreviation: "UTC") // 服务器返回UTC时间
        
        if let utcDate = inputFormatter.date(from: timestamp) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .none
            outputFormatter.timeStyle = .medium
            outputFormatter.timeZone = TimeZone.current // 转换为本地时间显示
            return outputFormatter.string(from: utcDate)
        }
        return timestamp
    }
    
    private func formatTimeAgo(_ timestamp: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        formatter.timeZone = TimeZone(abbreviation: "UTC") // 服务器返回UTC时间
        
        if let utcDate = formatter.date(from: timestamp) {
            let timeInterval = Date().timeIntervalSince(utcDate)
            let minutes = Int(timeInterval / 60)
            
            if minutes < 1 {
                return "just now"
            } else if minutes < 60 {
                return "\(minutes)min ago"
            } else if minutes < 1440 { // 24小时内
                let hours = minutes / 60
                return "\(hours)hr ago"
            } else {
                let days = minutes / 1440
                return "\(days)d ago"
            }
        }
        return "unknown"
    }
    
    // 更新缓存状态（在主线程执行）
    private func updateCachedStatus() {
        DispatchQueue.main.async {
            cachedConnectionStatus = sentimentManager.isConnected
            cachedConnectionError = sentimentManager.connectionError
            cachedDataCount = sentimentManager.dataHistory.count
            
            if let latest = sentimentManager.latestData {
                cachedLastUpdate = formatTimestamp(latest.timestamp)
            } else {
                cachedLastUpdate = nil
            }
        }
    }
    
    private func getSSEHistoricalValue(period: String) -> Int? {
        // 从SSE数据中获取历史数值，没有数据时返回nil
        guard let latestData = sentimentManager.latestData else { return nil }
        
        switch period {
        case "onehour":
            return latestData.sentiment.onehourbefore.map { Int($0) }
        case "sixhours":
            return latestData.sentiment.sixhoursbefore.map { Int($0) }
        case "oneday":
            return latestData.sentiment.onedaybefore.map { Int($0) }
        case "oneweek":
            return latestData.sentiment.oneweekbefore.map { Int($0) }
        default:
            return nil
        }
    }
}

// MARK: - 时间轴标签组件
struct TimeAxisLabel: View {
    let title: String
    let value: Int?
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            if let value = value {
                Text(value >= 0 ? "+\(value)" : "\(value)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(value >= 0 ? .green : .red)
            } else {
                Text("--")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
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
                    .fill(.ultraThinMaterial)
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

// 移除导致CoreSVG错误的backdrop扩展

 
