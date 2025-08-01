import Foundation
import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

// 数据模型
struct ChartData {
    var dataPoints: [Double]
    var title: String
    var currentValue: Double
    var trend: String
    var lastUpdated: Date
    
    init(dataPoints: [Double] = [], 
         title: String = "数据趋势", 
         currentValue: Double = 0,
         trend: String = "stable",
         lastUpdated: Date = Date()) {
        self.dataPoints = dataPoints
        self.title = title
        self.currentValue = currentValue
        self.trend = trend
        self.lastUpdated = lastUpdated
    }
}

@MainActor
class LiveActivityManager: ObservableObject {
    @Published var currentData: ChartData = ChartData()
    @Published var isActivityActive: Bool = false
    @Published var activityError: String?
    
    #if canImport(ActivityKit)
    // 真实的ActivityKit实现
    @available(iOS 16.1, *)
    private var currentActivity: Activity<LineChartAttributes>?
    #else
    // 模拟实现
    private var simulatedActivityId: String?
    #endif
    
    init() {
        // 先设置默认数据，避免初始化时序问题
        let initialDataPoints: [Double] = [10, 25, 15, 40, 30, 50, 35, 60, 45, 70]
        let lastValue = initialDataPoints.last ?? 0
        let previousValue = initialDataPoints.count > 1 ? initialDataPoints[initialDataPoints.count - 2] : lastValue
        
        var trend = "stable"
        if lastValue > previousValue {
            trend = "up"
        } else if lastValue < previousValue {
            trend = "down"
        }
        
        // 直接设置currentData，避免在init中调用updateData
        currentData = ChartData(
            dataPoints: initialDataPoints,
            title: "实时股价趋势",
            currentValue: lastValue,
            trend: trend,
            lastUpdated: Date()
        )
        
        // 延迟检查现有活动，避免初始化冲突
        Task { @MainActor in
            checkExistingActivities()
        }
    }
    
    // 检查现有活动
    private func checkExistingActivities() {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            let existingActivities = Activity<LineChartAttributes>.activities
            if let activity = existingActivities.first {
                currentActivity = activity
                isActivityActive = true
                print("✅ 发现现有Live Activity: \(activity.id)")
            }
        }
        #endif
    }
    
    // 检查Live Activities权限
    func checkActivityPermission() -> Bool {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            let authInfo = ActivityAuthorizationInfo()
            return authInfo.areActivitiesEnabled
        }
        #endif
        return false
    }
    
    // 启动实时活动
    func startLiveActivity() {
        guard !isActivityActive else { 
            print("⚠️ Live Activity已经在运行")
            return 
        }
        
        #if canImport(ActivityKit)
        // 真实的ActivityKit实现
        if #available(iOS 16.1, *) {
            startRealLiveActivity()
        } else {
            startSimulatedActivity()
        }
        #else
        // 模拟实现
        startSimulatedActivity()
        #endif
    }
    
    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private func startRealLiveActivity() {
        // 检查权限
        guard checkActivityPermission() else {
            activityError = "Live Activities权限未开启，请在设置→通知中开启"
            print("❌ Live Activities未启用")
            return
        }
        
        do {
            let attributes = LineChartAttributes(chartName: "股价趋势")
            let contentState = LineChartAttributes.ContentState(
                dataPoints: currentData.dataPoints,
                title: currentData.title,
                currentValue: currentData.currentValue,
                trend: currentData.trend,
                lastUpdated: currentData.lastUpdated
            )
            
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil),
                pushType: nil
            )
            
            currentActivity = activity
            isActivityActive = true
            activityError = nil
            print("🎉 Live Activity启动成功 - ID: \(activity.id)")
            
        } catch {
            activityError = "启动Live Activity失败: \(error.localizedDescription)"
            print("❌ 启动Live Activity失败: \(error)")
        }
    }
    #endif
    
    private func startSimulatedActivity() {
        #if !canImport(ActivityKit)
        simulatedActivityId = UUID().uuidString
        #endif
        isActivityActive = true
        activityError = nil
        print("🔄 模拟Live Activity已启动")
        print("💡 要启用真实功能，请按照README.md中的配置步骤操作")
    }
    
    // 更新实时活动
    func updateLiveActivity() {
        guard isActivityActive else { 
            print("⚠️ 没有活跃的Live Activity可以更新")
            return 
        }
        
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *), let activity = currentActivity {
            updateRealLiveActivity(activity: activity)
        } else {
            updateSimulatedActivity()
        }
        #else
        updateSimulatedActivity()
        #endif
    }
    
    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private func updateRealLiveActivity(activity: Activity<LineChartAttributes>) {
        Task {
            let contentState = LineChartAttributes.ContentState(
                dataPoints: currentData.dataPoints,
                title: currentData.title,
                currentValue: currentData.currentValue,
                trend: currentData.trend,
                lastUpdated: currentData.lastUpdated
            )
            
            let updatedContent = ActivityContent(state: contentState, staleDate: nil)
            
            do {
                await activity.update(updatedContent)
                print("✅ Live Activity更新成功 - 当前值: \(currentData.currentValue)")
            } catch {
                print("❌ 更新Live Activity失败: \(error)")
                await MainActor.run {
                    self.activityError = "更新失败: \(error.localizedDescription)"
                }
            }
        }
    }
    #endif
    
    private func updateSimulatedActivity() {
        print("🔄 模拟Live Activity已更新 - 当前值: \(currentData.currentValue)")
    }
    
    // 停止实时活动
    func stopLiveActivity() {
        guard isActivityActive else { 
            print("⚠️ 没有活跃的Live Activity可以停止")
            return 
        }
        
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *), let activity = currentActivity {
            stopRealLiveActivity(activity: activity)
        } else {
            stopSimulatedActivity()
        }
        #else
        stopSimulatedActivity()
        #endif
    }
    
    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private func stopRealLiveActivity(activity: Activity<LineChartAttributes>) {
        Task {
            let finalContent = ActivityContent(
                state: activity.content.state, 
                staleDate: Date()
            )
            
            do {
                await activity.end(finalContent, dismissalPolicy: .immediate)
                
                await MainActor.run {
                    self.currentActivity = nil
                    self.isActivityActive = false
                    self.activityError = nil
                }
                
                print("🛑 Live Activity已停止")
            } catch {
                print("❌ 停止Live Activity失败: \(error)")
                await MainActor.run {
                    self.activityError = "停止失败: \(error.localizedDescription)"
                }
            }
        }
    }
    #endif
    
    private func stopSimulatedActivity() {
        #if !canImport(ActivityKit)
        simulatedActivityId = nil
        #endif
        isActivityActive = false
        activityError = nil
        print("🛑 模拟Live Activity已停止")
    }
    
    // 更新数据
    func updateData(dataPoints: [Double]) {
        let lastValue = dataPoints.last ?? 0
        let previousValue = dataPoints.count > 1 ? dataPoints[dataPoints.count - 2] : lastValue
        
        var trend = "stable"
        if lastValue > previousValue {
            trend = "up"
        } else if lastValue < previousValue {
            trend = "down"
        }
        
        currentData = ChartData(
            dataPoints: dataPoints,
            title: "实时股价趋势",
            currentValue: lastValue,
            trend: trend,
            lastUpdated: Date()
        )
        
        // 如果活动已启动，自动更新
        if isActivityActive {
            updateLiveActivity()
        }
    }
    
    // 模拟数据更新（用于演示）
    func simulateDataUpdate() {
        var newDataPoints = currentData.dataPoints
        let randomChange = Double.random(in: -10...10)
        let newValue = max(0, (newDataPoints.last ?? 50) + randomChange)
        
        newDataPoints.append(newValue)
        
        // 保持最近20个数据点
        if newDataPoints.count > 20 {
            newDataPoints.removeFirst()
        }
        
        updateData(dataPoints: newDataPoints)
    }
    
    // 获取所有活动状态（调试用）
    func getActivityInfo() -> String {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            let activities = Activity<LineChartAttributes>.activities
            let authInfo = ActivityAuthorizationInfo()
            
            return """
            🔍 Live Activities状态检查:
            ✅ ActivityKit可用: 是
            🔐 权限状态: \(authInfo.areActivitiesEnabled ? "已开启" : "未开启")
            📊 活跃活动数: \(activities.count)
            🆔 当前活动ID: \(currentActivity?.id ?? "无")
            🟢 活动状态: \(isActivityActive ? "运行中" : "未激活")
            """
        }
        #endif
        
        return """
        🔍 Live Activities状态检查:
        ❌ ActivityKit可用: 否（需要Xcode配置）
        🔄 模拟模式: 已启用
        🟡 活动状态: \(isActivityActive ? "模拟运行中" : "未激活")
        
        💡 要启用真实功能，请查看README.md配置说明
        """
    }
    
    // 检查当前环境是否支持Live Activities
    func isLiveActivitySupported() -> Bool {
        #if canImport(ActivityKit)
        if #available(iOS 16.1, *) {
            return true
        }
        #endif
        return false
    }
}

// MARK: - 📖 完整配置指南
/*
🎯 为什么使用条件编译？

1. **兼容性**: 在没有配置ActivityKit的环境中也能正常编译运行
2. **渐进式**: 可以先测试基础功能，再逐步启用Live Activities
3. **调试友好**: 提供详细的状态信息和错误提示

🚀 启用真实Live Activities的完整步骤：

1. **Xcode项目配置**:
   - Target → Signing & Capabilities → 添加 "Push Notifications"
   - Info.plist 添加: 
     ```xml
     <key>NSSupportsLiveActivities</key>
     <true/>
     ```

2. **创建Widget Extension**:
   - File → New → Target → Widget Extension
   - ✅ 勾选 "Include Live Activity"
   - Bundle ID: com.yourcompany.line.LineChartWidget

3. **Widget Extension配置**:
   创建 LineChartWidgetBundle.swift:
   ```swift
   import WidgetKit
   import SwiftUI

   @main
   struct LineChartWidgetBundle: WidgetBundle {
       var body: some Widget {
           LineChartLiveActivity()
       }
   }
   ```

4. **测试环境要求**:
   - 📱 iOS 16.1+ 真机（模拟器不支持）
   - 🏝️ iPhone 14 Pro/Pro Max （灵动岛功能）
   - ⚙️ 设置 → 通知 → Live Activities 已开启

5. **验证步骤**:
   - 使用 getActivityInfo() 检查状态
   - 查看Xcode控制台日志
   - 确认设备Live Activities权限已开启

📊 当前状态说明:
- ✅ 折线图组件: 完全可用
- ✅ 数据管理: 完全可用  
- ✅ UI界面: 完全可用
- 🔄 Live Activities: 模拟模式（需配置后启用真实功能）

💡 提示: 即使在模拟模式下，所有核心功能都是完全可用的！
*/ 