//
//  lineApp.swift
//  line
//
//  Created by CoderStar on 2025/7/28.
//

import ActivityKit
import SwiftUI

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
        if #available(iOS 16.1, *) {
            setupRealLiveActivities()
        }
    }

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
                await activity.end(nil, dismissalPolicy: .immediate)
                print("🗑️ 清理过期Live Activity: \(activity.id)")
            }
        }
    }
}
