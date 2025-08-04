//
//  SettingView.swift
//  line
//
//  Created by CoderStar on 2025/7/28.
//

import SwiftUI

struct SettingView: View {
    @ObservedObject var authManager: AuthManager
    let onDisconnect: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var isDisconnecting = false
    
    // 获取应用版本信息
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    // 获取HSID显示名称
    private var userDisplayName: String {
        if let hsid = authManager.cookies["HSID"], !hsid.isEmpty {
            let displayHSID = String(hsid.prefix(8)) // 只显示前8位，避免过长
            return "@\(displayHSID)"
        }
        return "@your_Youtube"
    }
    
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // 账户信息区域
                VStack(spacing: 20) {
                    // YouTube账户显示
                    VStack(spacing: 12) {
                        Text(userDisplayName)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(authManager.isLoggedIn ? "Your account is authorised" : "Not connected")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // 断开连接按钮
                    Button(action: {
                        if authManager.isLoggedIn {
                            isDisconnecting = true
                            onDisconnect()
                            
                            // 短暂显示断开状态后重置
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                isDisconnecting = false
                            }
                        }
                    }) {
                        Text(isDisconnecting ? "Disconnected" : "Disconnect")
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(isDisconnecting ? Color.green : Color.white)
                            .foregroundColor(isDisconnecting ? .white : .black)
                            .cornerRadius(25)
                            .animation(.easeInOut(duration: 0.3), value: isDisconnecting)
                    }
                    .disabled(!authManager.isLoggedIn)
                    .opacity(authManager.isLoggedIn ? 1.0 : 0.6)
                }
                .padding(.horizontal, 30)
                
                // Cookie信息区域
                if authManager.isLoggedIn && !authManager.cookies.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Login Cookies:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(Array(authManager.cookies.keys.sorted()), id: \.self) { key in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(key):")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(authManager.cookies[key] ?? "")
                                        .font(.caption2)
                                        .foregroundColor(.green.opacity(0.8))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 30)
                }
                
                // 应用信息
                VStack(spacing: 12) {
                    Text("Mood Feed Controller")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("Take control of your emotions, don't let the feed control you.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                // 版本信息
                VStack(spacing: 4) {
                    Text(appVersion)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Built with ❤️ for mindful browsing")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }

    }
}

 