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
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // 账户信息区域
                VStack(spacing: 20) {
                    // YouTube账户显示
                    VStack(spacing: 12) {
                        Text("@your_Youtube")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text(authManager.isLoggedIn ? "Your account is authorised" : "Not connected")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // 断开连接按钮
                    Button(action: {
                        if authManager.isLoggedIn {
                            onDisconnect()
                            alertMessage = "Successfully disconnected from YouTube"
                            showAlert = true
                        } else {
                            alertMessage = "No YouTube account connected"
                            showAlert = true
                        }
                    }) {
                        Text("Disconnect")
                            .font(.system(size: 18, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .foregroundColor(.black)
                            .cornerRadius(25)
                    }
                    .disabled(!authManager.isLoggedIn)
                    .opacity(authManager.isLoggedIn ? 1.0 : 0.6)
                }
                .padding(.horizontal, 30)
                
                // Cookie信息区域（调试用）
                if authManager.isLoggedIn && !authManager.cookies.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Connected Cookies:")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(authManager.cookies.keys.sorted()), id: \.self) { key in
                                    HStack {
                                        Text("\(key):")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white.opacity(0.8))
                                        
                                        Text("Connected ✓")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                        
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .frame(maxHeight: 120)
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
                    Text("Version 1.0.0")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text("Built with ❤️ for mindful browsing")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 50)
            }
        }
        .navigationBarHidden(true)
        .alert("Settings", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

 