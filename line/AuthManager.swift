//
//  AuthManager.swift
//  line
//
//  Created by CoderStar on 2025/7/28.
//

import SwiftUI
import Foundation
import CryptoKit

class AuthManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var cookies: [String: String] = [:]
    
    private let userDefaults = UserDefaults.standard
    private let isLoggedInKey = "isLoggedIn"
    private let cookiesKey = "youtubeCookies"
    
    init() {
        loadAuthState()
    }
    
    // MARK: - 加载认证状态
    private func loadAuthState() {
        isLoggedIn = userDefaults.bool(forKey: isLoggedInKey)
        
        if let data = userDefaults.data(forKey: cookiesKey),
           let savedCookies = try? JSONDecoder().decode([String: String].self, from: data) {
            cookies = savedCookies
        }
        
        // 验证cookies是否完整
        if isLoggedIn && !isValidCookies(cookies) {
            logout() // 如果cookies不完整，清除登录状态
        }
    }
    
    // MARK: - 保存登录状态
    func saveAuthState(cookies: [String: String]) {
        guard isValidCookies(cookies) else {
            print("❌ Cookie不完整，无法保存登录状态")
            return
        }
        
        // 先保存cookies，但不立即设置isLoggedIn
        self.cookies = cookies
        
        if let data = try? JSONEncoder().encode(cookies) {
            userDefaults.set(data, forKey: cookiesKey)
        }
        
        print("✅ 登录数据已保存，等待用户确认")
        
        // 异步上传YouTube Session到后端
        Task {
            await uploadYouTubeSession()
        }
    }
    
    // MARK: - 确认登录状态（用户点击Continue后调用）
    func confirmLogin() {
        self.isLoggedIn = true
        userDefaults.set(true, forKey: isLoggedInKey)
        print("✅ 登录状态已确认")
    }
    
    // MARK: - 注销
    func logout() {
        isLoggedIn = false
        cookies.removeAll()
        
        userDefaults.removeObject(forKey: isLoggedInKey)
        userDefaults.removeObject(forKey: cookiesKey)
        
        print("🔓 已注销，登录状态已清除")
    }
    
    // MARK: - 验证Cookie完整性
    private func isValidCookies(_ cookies: [String: String]) -> Bool {
        let requiredCookies = ["SID", "HSID", "SSID", "APISID", "SAPISID"]
        return requiredCookies.allSatisfy { cookies.keys.contains($0) }
    }
    
    // MARK: - 获取Cookie字符串（用于API调用）
    func getCookieString() -> String {
        return cookies.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
    }
    
    // MARK: - 检查登录状态是否有效
    func validateAuthState() -> Bool {
        return isLoggedIn && isValidCookies(cookies)
    }
    
    // MARK: - 生成SAPISID Hash
    private func generateSAPISIDHash() -> String? {
        guard let sapisid = cookies["SAPISID"] else {
            print("❌ 没有找到SAPISID Cookie")
            return nil
        }
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let origin = "https://www.youtube.com"
        let input = "\(timestamp) \(origin) \(sapisid)"
        
        // 计算SHA1哈希
        let inputData = Data(input.utf8)
        let hash = Insecure.SHA1.hash(data: inputData)
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        return "\(timestamp)_\(hashString)"
    }
    
    // MARK: - 上传YouTube Session到后端
    func uploadYouTubeSession() async {
        guard isValidCookies(cookies) else {
            print("❌ Cookie不完整，无法上传YouTube Session")
            return
        }
        
        let baseURL = "https://timeline-tuner-backend.soc1024.com:5003"
        let endpoint = "/youtube_session"
        
        guard let url = URL(string: baseURL + endpoint) else {
            print("❌ 无效的URL")
            return
        }
        
        // 生成SAPISID Hash
        guard let sapisidHash = generateSAPISIDHash() else {
            print("❌ 无法生成SAPISID Hash")
            return
        }
        
        // 准备请求体数据
        let requestBody: [String: Any] = [
            "user_agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
            "origin": "https://www.youtube.com",
            "cookies": cookies,
            "auth_user_index": 0,
            "sapisid_hash": sapisidHash,
            "raw_cookie_header": getCookieString()
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: requestBody, options: [])
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("_fAyMKD19I7PmBeTg8p_N9sbdEzJVVkqatWTNwbW26w", forHTTPHeaderField: "X-API-Key")
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    if let responseData = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let success = responseData["success"] as? Bool,
                       let message = responseData["message"] as? String,
                       success {
                        print("✅ YouTube Session上传成功: \(message)")
                    } else {
                        print("❌ YouTube Session上传失败: 服务器返回错误")
                    }
                } else {
                    print("❌ YouTube Session上传失败: HTTP \(httpResponse.statusCode)")
                    if let errorData = String(data: data, encoding: .utf8) {
                        print("错误详情: \(errorData)")
                    }
                }
            }
        } catch {
            print("❌ YouTube Session上传失败: \(error.localizedDescription)")
        }
    }
} 