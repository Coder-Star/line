//
//  lineApp.swift
//  line
//
//  Created by CoderStar on 2025/7/28.
//

import SwiftUI
#if canImport(ActivityKit)
import ActivityKit
#endif

@main
struct lineApp: App {
    var body: some Scene {
        WindowGroup {
            MainNavigationView()
        }
    }
    
    init() {
        // Live Activities初始化设置
        setupLiveActivities()
    }
    
    private func setupLiveActivities() {
        #if canImport(ActivityKit)
        // 真实的ActivityKit环境
        if #available(iOS 16.1, *) {
            setupRealLiveActivities()
        } else {
            setupSimulatedEnvironment()
        }
        #else
        // 模拟环境
        setupSimulatedEnvironment()
        #endif
    }
    
    #if canImport(ActivityKit)
    @available(iOS 16.1, *)
    private func setupRealLiveActivities() {
        // 检查Live Activities是否可用
        let authInfo = ActivityAuthorizationInfo()
        
        if authInfo.areActivitiesEnabled {
            print("✅ Live Activities已启用")
        } else {
            print("❌ Live Activities未启用 - 请在设置→通知中开启")
        }
        
        // 打印当前活动状态（调试用）
        let activities = Activity<LineChartAttributes>.activities
        print("📊 当前活跃的Live Activities数量: \(activities.count)")
        
        // 监听活动状态变化
        Task {
            for await activity in Activity<LineChartAttributes>.activityUpdates {
                print("🔄 Live Activity状态更新: \(activity.id)")
            }
        }
        
        // 清理过期活动（可选）
        cleanupExpiredActivities()
    }
    
    @available(iOS 16.1, *)
    private func cleanupExpiredActivities() {
        Task {
            let activities = Activity<LineChartAttributes>.activities
            let expiredActivities = activities.filter { activity in
                // 检查活动是否已过期（例如：超过24小时）
                let timeInterval = Date().timeIntervalSince(activity.content.state.lastUpdated)
                return timeInterval > 24 * 60 * 60 // 24小时
            }
            
            // 结束过期活动
            for activity in expiredActivities {
                do {
                    await activity.end(nil, dismissalPolicy: .immediate)
                    print("🗑️ 清理过期Live Activity: \(activity.id)")
                } catch {
                    print("❌ 清理活动失败: \(error)")
                }
            }
        }
    }
    #endif
    
    private func setupSimulatedEnvironment() {
        print("🔄 Live Activities模拟环境已启动")
        print("💡 要启用真实功能，请查看README.md中的配置说明")
        
        #if !canImport(ActivityKit)
        print("⚠️ ActivityKit不可用 - 运行在模拟模式下")
        #else
        print("⚠️ iOS版本低于16.1 - 运行在模拟模式下")
        #endif
    }
}
