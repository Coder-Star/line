//
//  LoginView.swift
//  line
//
//  Created by CoderStar on 2025/7/28.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var authManager: AuthManager
    let onConnected: () -> Void
    
    @State private var showingYouTubeLogin = false
    @State private var agreeToService = false
    @State private var showAgreementAlert = false
    @State private var showLoginSuccessAlert = false
    
    var body: some View {
        ZStack {
            // 底层：common_bg背景 - 铺满整个屏幕
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
            
            // 上层：login_bg覆盖层 - 583高度，底部挨着Home Indicator上方
            GeometryReader { geometry in
                VStack {
                    Spacer()
                    Image("login_bg")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: 583)
                        .clipped()
                }
                .frame(maxWidth: .infinity, maxHeight: geometry.size.height - geometry.safeAreaInsets.bottom - 60)
            }
            
            VStack(spacing: 30) {
                Spacer()
                
                // 主标题区域 - 按设计稿调整
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Don't let your feed\npick your feelings.")
                            .font(.system(size: 36, weight: .bold, design: .default))
                            .foregroundColor(.white)
                    }
                    
                    Text("See how scrolling shifts your mood—and gently steer it.")
                        .font(.system(size: 14, weight: .light, design: .default))
                        .foregroundColor(.white)
                        .lineLimit(nil)
                        .frame(maxWidth: 250, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 30)
                .offset(y: -150)
                
                Spacer()
                
                // 底部按钮区域
                VStack(spacing: 16) {
                    // YouTube登录按钮 - 白色背景样式
                    Button(action: {
                        if agreeToService {
                            showingYouTubeLogin = true
                        } else {
                            showAgreementAlert = true
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.rectangle.fill")
                                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                                .font(.system(size: 16))
                            Text("Login with Youtube")
                                .font(.system(size: 18, weight: .medium, design: .default))
                                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.white)
                        .cornerRadius(40)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(authManager.isLoggedIn)
                    .opacity(authManager.isLoggedIn ? 0.5 : 1.0)
                    
                    // 服务条款勾选 - 按设计稿调整，居中显示
                    HStack(spacing: 8) {
                        Button(action: {
                            agreeToService.toggle()
                        }) {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.white, lineWidth: 1.5)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(Color.white.opacity(0.2))
                                )
                                .frame(width: 16, height: 16)
                                .overlay(
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.white)
                                        .font(.system(size: 10, weight: .bold))
                                        .opacity(agreeToService ? 1 : 0)
                                )
                        }
                        
                        HStack(spacing: 0) {
                            Text("I agree with the ")
                                .font(.custom("Playfair Display", size: 14))
                                .foregroundColor(.white)
                            Text("XXX Service")
                                .font(.custom("Playfair Display", size: 14))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text(".")
                                .font(.custom("Playfair Display", size: 14))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 47)
                .padding(.bottom, 50)
                
                // iOS Home Indicator
                HStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 100)
                        .fill(Color.white)
                        .frame(width: 134, height: 5)
                    Spacer()
                }
                .padding(.bottom, 8)
            }
        }
        .navigationBarHidden(true)
        .alert("Please Agree to Terms", isPresented: $showAgreementAlert) {
            Button("OK", role: .cancel) {
                // 可以选择自动勾选协议
                // agreeToService = true
            }
        } message: {
            Text("Please check \"I agree with the XXX Service.\" before logging in")
        }
        .alert("Login Successful!", isPresented: $showLoginSuccessAlert) {
            Button("Continue") {
                onConnected()
            }
        } message: {
            Text("You have successfully logged in to YouTube. Welcome!")
        }
        .sheet(isPresented: $showingYouTubeLogin) {
            YouTubeWebViewSheet(
                cookies: .constant([:]), 
                onCookiesUpdated: { extractedCookies in
                    print("🍪 提取到的cookies: \(extractedCookies.keys.sorted())")
                    
                    // 保存登录状态到AuthManager
                    authManager.saveAuthState(cookies: extractedCookies)
                    
                    // 登录状态已在sheet内部处理，不在这里显示alert
                },
                onLoginSuccess: {
                    // 用户点击Continue后的回调
                    print("🎉 用户确认登录成功")
                    authManager.confirmLogin()
                    onConnected()
                }
            )
        }
    }
}

 
