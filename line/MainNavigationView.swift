//
//  MainNavigationView.swift
//  line
//
//  Created by CoderStar on 2025/7/28.
//

import SwiftUI

struct MainNavigationView: View {
    @StateObject private var authManager = AuthManager()
    @State private var selectedFeeling = ""
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if authManager.isLoggedIn {
                    // 已登录：直接显示Feeling页面
                    FeelingView(
                        selectedFeeling: $selectedFeeling,
                        onFeelingSelected: { feeling in
                            print("📝 MainNavigationView收到情感选择: \(feeling)")
                            selectedFeeling = feeling
                            print("📝 MainNavigationView设置selectedFeeling为: \(selectedFeeling)")
                            navigationPath.append("chart_\(feeling)")
                            print("📝 MainNavigationView导航到chart页面，参数: \(feeling)")
                        }
                    )
                } else {
                    // 未登录：显示登录页面
                    LoginView(
                        authManager: authManager,
                        onConnected: {
                            // 登录成功后AuthManager会自动更新isLoggedIn状态
                            // 界面会自动切换到Feeling页面
                        }
                    )
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "feeling":
                    // 第二个页面：Feeling选择页面
                    FeelingView(
                        selectedFeeling: $selectedFeeling,
                        onFeelingSelected: { feeling in
                            print("📝 MainNavigationView(nav)收到情感选择: \(feeling)")
                            selectedFeeling = feeling
                            print("📝 MainNavigationView(nav)设置selectedFeeling为: \(selectedFeeling)")
                            // 选择情感后导航到Chart页面
                            navigationPath.append("chart_\(feeling)")
                            print("📝 MainNavigationView(nav)导航到chart页面，参数: \(feeling)")
                        }
                    )
                    
                case let str where str.hasPrefix("chart_"):
                    // 第三个页面：Chart显示页面 - 从导航参数中提取情感
                    let feeling = String(str.dropFirst("chart_".count))
//                    print("🔍 从导航参数解析出情感: '\(feeling)'")
                    ChartView(
                        selectedFeeling: feeling,
                        onBackToSelection: {
                            // 返回到Feeling页面
                            navigationPath.removeLast()
                        },
                        onGoToSettings: {
                            // 导航到Setting页面
                            navigationPath.append("settings")
                        }
                    )
                    
                case "settings":
                    // 第四个页面：Setting设置页面
                    SettingView(
                        authManager: authManager,
                        onDisconnect: {
                            // 注销登录
                            authManager.logout()
                            selectedFeeling = ""
                            navigationPath.removeLast(navigationPath.count)
                        }
                    )
                    
                default:
                    // 默认页面
                    if authManager.isLoggedIn {
                        FeelingView(
                            selectedFeeling: $selectedFeeling,
                            onFeelingSelected: { feeling in
                                print("📝 MainNavigationView(default)收到情感选择: \(feeling)")
                                selectedFeeling = feeling
                                print("📝 MainNavigationView(default)设置selectedFeeling为: \(selectedFeeling)")
                                navigationPath.append("chart_\(feeling)")
                                print("📝 MainNavigationView(default)导航到chart页面，参数: \(feeling)")
                            }
                        )
                    } else {
                        LoginView(
                            authManager: authManager,
                            onConnected: {}
                        )
                    }
                }
            }
        }
    }
}

 
