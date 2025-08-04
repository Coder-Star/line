//
//  SentimentStreamManager.swift
//  line
//
//  Created by CoderStar on 2025/7/28.
//

import SwiftUI
import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

// MARK: - 数据模型
struct SentimentData: Codable {
    let timestamp: String
    let sentiment: SentimentValues
}

struct SentimentValues: Codable {
    let calm: Double
    let focused: Double
    let motivated: Double
    let lightHearted: Double  // 注意：JSON中是"light-hearted"，需要用CodingKeys映射
    let inspired: Double
    let connected: Double
    let stimulated: Double
    let curious: Double
    let onehourbefore: Double?
    let sixhoursbefore: Double?
    let onedaybefore: Double?
    let oneweekbefore: Double?
    
    enum CodingKeys: String, CodingKey {
        case calm, focused, motivated, inspired, connected, stimulated, curious
        case lightHearted = "light-hearted"
        case onehourbefore, sixhoursbefore, onedaybefore, oneweekbefore
    }
    
    // 获取指定情感对应的数值
    func getValue(for feeling: String) -> Double {
        switch feeling.lowercased() {
        case "calm": return calm
        case "connected": return connected
        case "motivated": return motivated
        case "stimulated": return stimulated
        case "focused": return focused
        case "light-hearted": return lightHearted
        case "inspired": return inspired
        case "curious": return curious
        default: return 0.0
        }
    }
    
    // 获取所有情感数值的数组（用于图表显示）
    var allValues: [Double] {
        return [calm, connected, motivated, stimulated, focused, lightHearted, inspired, curious]
    }
}

// MARK: - SSE数据管理器
class SentimentStreamManager: NSObject, ObservableObject, URLSessionDataDelegate {
    @Published var latestData: SentimentData?
    @Published var dataHistory: [SentimentData] = []
    @Published var isConnected: Bool = false
    @Published var connectionError: String?
    
    // 累加值存储（初始值为30，范围0-100）
    @Published var cumulativeValues: [String: Double] = [
        "calm": 30.0,
        "connected": 30.0,
        "motivated": 30.0,
        "stimulated": 30.0,
        "focused": 30.0,
        "light-hearted": 30.0,
        "inspired": 30.0,
        "curious": 30.0
    ]
    
    // 累加历史数据（用于图表显示）
    @Published var cumulativeHistory: [String: [Double]] = [:]
    
    // Live Activity状态
    @Published var canStartLiveActivity: Bool = false
    
    // 当前选择的情感（用于Live Activity更新）
    @Published var currentSelectedFeeling: String = ""
    
    private var urlSessionTask: URLSessionDataTask?
    private var urlSession: URLSession?
    private let baseURL = "https://timeline-tuner-backend.soc1024.com:5003"
    
    override init() {
        super.init()
        print("🎯 SentimentStreamManager初始化")
        
        // 初始化历史数据，每个情感都有一个初始值30的数据点
        for feeling in ["calm", "connected", "motivated", "stimulated", "focused", "light-hearted", "inspired", "curious"] {
            cumulativeHistory[feeling] = [30.0]
        }
        print("📊 初始化累加历史数据，所有情感初始值为30.0")
        
        connectToStream()
    }
    
    deinit {
        print("🔌 SentimentStreamManager销毁，断开连接")
        disconnect()
    }
    
    // MARK: - 连接SSE流
    func connectToStream() {
        // 如果已经有活跃连接且正在运行，直接返回
        if urlSessionTask != nil && urlSessionTask?.state == .running {
            print("⚠️ 检测到活跃连接，跳过重复连接")
            return
        }
        
        // 清理旧连接（如果存在）
        if urlSessionTask != nil {
            print("🧹 清理旧连接")
            urlSessionTask?.cancel()
            urlSessionTask = nil
        }
        
        guard let url = URL(string: "\(baseURL)/sentiment/stream") else {
            print("❌ 无效的SSE URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        request.setValue("_fAyMKD19I7PmBeTg8p_N9sbdEzJVVkqatWTNwbW26w", forHTTPHeaderField: "X-API-Key")
        
        print("🔄 正在连接SSE流: \(url)")
        
        // 创建支持流式数据的URLSession配置和Delegate
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 0
        config.timeoutIntervalForResource = 0
        
        urlSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        urlSessionTask = urlSession?.dataTask(with: request)
        
        urlSessionTask?.resume()
    }
    
    // MARK: - 处理SSE数据
    private func processSSEData(_ data: Data) {
        let dataString = String(data: data, encoding: .utf8) ?? ""
        if !dataString.isEmpty {
            print("📦 收到SSE原始数据: \(dataString)")
        }
        let lines = dataString.components(separatedBy: .newlines)
        
        for line in lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)) // 移除 "data: " 前缀
                
                // 跳过心跳数据
                if jsonString.contains("\"type\": \"heartbeat\"") {
                    print("💓 收到心跳数据")
                    continue
                }
                
                // 解析情感数据
                if let jsonData = jsonString.data(using: .utf8) {
                    do {
                        let sentimentData = try JSONDecoder().decode(SentimentData.self, from: jsonData)
                        DispatchQueue.main.async { [weak self] in
                            guard let self = self else { return }
                            self.latestData = sentimentData
                            self.dataHistory.append(sentimentData)
                            
                            // 将增量值累加到当前值上
                            self.updateCumulativeValues(with: sentimentData.sentiment)
                            
                            // 保留最近100条记录
                            if self.dataHistory.count > 100 {
                                self.dataHistory.removeFirst()
                            }
                            
                            print("📊 收到新的情感增量数据: \(sentimentData.sentiment)")
                            print("📈 累加后的当前值: \(self.cumulativeValues)")
                            
                            // 触发Live Activity更新
                            self.updateLiveActivityForCurrentFeeling(with: sentimentData.sentiment)
                        }
                    } catch {
                        print("❌ 解析JSON失败: \(error)")
                    }
                }
            }
        }
    }
    
    // MARK: - 断开连接
    func disconnect() {
        urlSessionTask?.cancel()
        urlSessionTask = nil
        
        // 清除当前选择的情感
        currentSelectedFeeling = ""
        
        DispatchQueue.main.async { [weak self] in
            self?.isConnected = false
        }
        print("🔌 SSE连接已断开")
        print("🗑️ 已清除当前选择的情感")
    }
    
    // MARK: - 重新连接
    func reconnect() {
        print("🔄 开始重新连接")
        disconnect()
        // 稍微延长等待时间，确保旧连接完全断开
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            print("🔗 重新连接等待结束，开始新连接")
            self.connectToStream()
        }
    }
    
    // MARK: - 更新累加值
    private func updateCumulativeValues(with deltaValues: SentimentValues) {
        print("🔢 开始累加计算...")
        
        // 将增量值累加到当前累加值上
        let feelings = ["calm", "connected", "motivated", "stimulated", "focused", "light-hearted", "inspired", "curious"]
        
        for feeling in feelings {
            let oldValue = cumulativeValues[feeling, default: 30.0]
            let delta = deltaValues.getValue(for: feeling)
            let rawNewValue = oldValue + delta
            
            // 限制数值在0-100范围内
            let newValue = min(max(rawNewValue, 0.0), 100.0)
            cumulativeValues[feeling] = newValue
            
            if rawNewValue != newValue {
                print("📊 \(feeling): \(oldValue) + \(delta) = \(rawNewValue) → 边界限制为 \(newValue)")
            } else {
                print("📊 \(feeling): \(oldValue) + \(delta) = \(newValue)")
            }
        }
        
        // 存储到累加历史中（用于图表）
        for feeling in feelings {
            if cumulativeHistory[feeling] == nil {
                cumulativeHistory[feeling] = [30.0] // 确保有初始值
            }
            let currentValue = cumulativeValues[feeling] ?? 30.0
            cumulativeHistory[feeling]?.append(currentValue)
            
            print("📈 添加\(feeling)历史数据点: \(currentValue)")
            
            // 保留最近50个数据点
            if let count = cumulativeHistory[feeling]?.count, count > 50 {
                cumulativeHistory[feeling]?.removeFirst()
            }
        }
        
        print("✅ 累加计算完成")
    }
    
    // MARK: - Live Activity更新
    private func updateLiveActivityForCurrentFeeling(with deltaValues: SentimentValues) {
        // 只更新当前选择的情感的Live Activity
        guard !currentSelectedFeeling.isEmpty else {
            print("⚠️ 没有选择的情感，跳过Live Activity更新")
            return
        }
        
        let feeling = currentSelectedFeeling.lowercased()
        let currentValue = cumulativeValues[feeling] ?? 30.0
        let deltaValue = deltaValues.getValue(for: feeling)
        let dataPoints = cumulativeHistory[feeling] ?? [30.0]
        
        print("🔔 更新Live Activity - \(currentSelectedFeeling): \(currentValue) (\(deltaValue >= 0 ? "+" : "")\(deltaValue))")
        
        // 更新现有的Live Activity
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            Task { @MainActor in
                let activities = Activity<LineChartAttributes>.activities
                for activity in activities {
                    let contentState = LineChartAttributes.ContentState(
                        selectedFeeling: currentSelectedFeeling, // 使用原始大小写
                        currentValue: currentValue,
                        deltaValue: deltaValue,
                        dataPoints: dataPoints,
                        oneHourBefore: deltaValues.onehourbefore,
                        sixHoursBefore: deltaValues.sixhoursbefore,
                        oneDayBefore: deltaValues.onedaybefore,
                        oneWeekBefore: deltaValues.oneweekbefore,
                        lastUpdated: Date()
                    )
                    
                    await activity.update(using: contentState)
                    print("🔄 已更新Live Activity: \(currentSelectedFeeling)")
                }
            }
        }
        #endif
    }
    
    // MARK: - 启动Live Activity（供外部调用）
    func startLiveActivityForFeeling(_ feeling: String) {
        // 记录当前选择的情感
        currentSelectedFeeling = feeling
        
        let currentValue = getCurrentValue(for: feeling)
        let deltaValue = 0.0 // 启动时没有增量
        let dataPoints = cumulativeHistory[feeling.lowercased()] ?? [30.0]
        
        print("🚀 启动\(feeling)的Live Activity，当前值: \(currentValue)")
        print("📝 设置当前选择的情感为: \(currentSelectedFeeling)")
        
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            Task { @MainActor in
                do {
                    let attributes = LineChartAttributes(appName: "Mood Tracker")
                    let contentState = LineChartAttributes.ContentState(
                        selectedFeeling: feeling,
                        currentValue: currentValue,
                        deltaValue: deltaValue,
                        dataPoints: dataPoints,
                        oneHourBefore: latestData?.sentiment.onehourbefore,
                        sixHoursBefore: latestData?.sentiment.sixhoursbefore,
                        oneDayBefore: latestData?.sentiment.onedaybefore,
                        oneWeekBefore: latestData?.sentiment.oneweekbefore,
                        lastUpdated: Date()
                    )
                    
                    let activity = try Activity<LineChartAttributes>.request(
                        attributes: attributes,
                        contentState: contentState
                    )
                    
                    print("✅ Live Activity已启动: \(activity.id)")
                    canStartLiveActivity = true
                } catch {
                    print("❌ 启动Live Activity失败: \(error)")
                }
            }
        }
        #endif
    }
    
    // MARK: - 停止所有Live Activity
    func stopAllLiveActivities() {
        print("⏹️ 正在停止所有Live Activity...")
        
        // 清除当前选择的情感
        currentSelectedFeeling = ""
        print("🗑️ 已清除当前选择的情感")
        
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            Task { @MainActor in
                let activities = Activity<LineChartAttributes>.activities
                for activity in activities {
                    await activity.end(dismissalPolicy: .immediate)
                    print("✅ 已停止Live Activity: \(activity.id)")
                }
                canStartLiveActivity = false
            }
        }
        #endif
    }
    
    // MARK: - 获取特定情感的历史数据点（用于图表）
    func getDataPoints(for feeling: String, limit: Int = 20) -> [Double] {
        let feelingKey = feeling.lowercased() == "light-hearted" ? "light-hearted" : feeling.lowercased()
        
        // 只有在收到真实数据时才返回数据点，否则返回空数组
        guard latestData != nil || !dataHistory.isEmpty else {
            print("📈 没有真实数据，返回空数组")
            return []
        }
        
        let historyData = cumulativeHistory[feelingKey] ?? []
        let result = Array(historyData.suffix(limit))
        print("📈 获取\(feeling)的数据点: \(result)")
        return result
    }
    
    // MARK: - 获取当前情感数值（累加后的值，范围0-100）
    func getCurrentValue(for feeling: String) -> Double {
        let feelingKey = feeling.lowercased() == "light-hearted" ? "light-hearted" : feeling.lowercased()
        
        // 只有在收到真实数据时才返回累加值，否则返回0
        guard latestData != nil || !dataHistory.isEmpty else {
            return 0.0
        }
        
        let value = cumulativeValues[feelingKey] ?? 30.0
        return min(max(value, 0.0), 100.0) // 确保在0-100范围内
    }
}

// MARK: - URLSessionDataDelegate
extension SentimentStreamManager {
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        
        print("📡 收到SSE响应，状态码: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 {
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = true
                self?.connectionError = nil
                print("✅ SSE连接成功")
            }
            completionHandler(.allow)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = false
                self?.connectionError = "HTTP错误: \(httpResponse.statusCode)"
                print("❌ SSE HTTP错误: \(httpResponse.statusCode)")
            }
            completionHandler(.cancel)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("📨 URLSessionDataDelegate收到数据，大小: \(data.count) 字节")
        processSSEData(data)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didCompleteWithError error: Error?) {
        if let error = error {
            DispatchQueue.main.async { [weak self] in
                self?.isConnected = false
                self?.connectionError = "连接错误: \(error.localizedDescription)"
                print("❌ SSE连接错误: \(error)")
            }
        } else {
            print("📡 SSE连接正常结束")
        }
    }
} 
