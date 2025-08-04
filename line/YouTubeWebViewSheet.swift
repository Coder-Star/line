//
//  YouTubeWebViewSheet.swift
//  line
//
//  Created by CoderStar on 2025/7/28.
//

import SwiftUI
import WebKit

// YouTube WebView Sheet
struct YouTubeWebViewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var cookies: [String: String]
    let onCookiesUpdated: ([String: String]) -> Void
    let onLoginSuccess: () -> Void
    @State private var isLoading = true
    @State private var webView: WKWebView?
    @State private var showSuccessMessage = false
    @State private var isClosing = false
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading YouTube...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                }
                
                YouTubeWebViewContainer(
                    webView: $webView,
                    isLoading: $isLoading,
                    onCookiesExtracted: { extractedCookies in
                        self.cookies = extractedCookies
                        self.onCookiesUpdated(extractedCookies)
                        
                        print("🎉 准备显示成功消息")
                        // 显示成功消息，等待用户手动确认
                        DispatchQueue.main.async {
                            showSuccessMessage = true
                            print("✅ 成功消息状态已设置为true")
                        }
                    }
                )
                    }
        .navigationTitle("YouTube Login")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .alert("Login Successful!", isPresented: $showSuccessMessage) {
            Button("Continue") {
                print("👆 用户点击了Continue按钮")
                
                // 先关闭YouTube页面
                dismiss()
                
                // 等YouTube页面完全收起来后再触发跳转
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    print("🔄 YouTube页面已关闭，开始跳转到FeelingView")
                    onLoginSuccess()
                }
            }
        } message: {
            Text("You have successfully logged in to YouTube. Welcome!")
        }
        }
    }
}

// YouTube WebView Container
struct YouTubeWebViewContainer: UIViewRepresentable {
    @Binding var webView: WKWebView?
    @Binding var isLoading: Bool
    let onCookiesExtracted: ([String: String]) -> Void
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = WKWebsiteDataStore.default()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        // 直接加载Google账户登录页面
        if let url = URL(string: "https://accounts.google.com/signin/v2/identifier?service=youtube&continue=https://www.youtube.com&hl=en") {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        
        // 保存webView引用
        DispatchQueue.main.async {
            self.webView = webView
        }
        
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 不需要更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: YouTubeWebViewContainer
        
        init(_ parent: YouTubeWebViewContainer) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
            
            // 页面加载完成后检查cookie
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.checkForTargetCookies(webView: webView)
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }
        
        private func checkForTargetCookies(webView: WKWebView) {
            let cookieStore = webView.configuration.websiteDataStore.httpCookieStore
            cookieStore.getAllCookies { allCookies in
                let targetCookies = ["SID", "HSID", "SSID", "APISID", "SAPISID"]
                var extractedCookies: [String: String] = [:]
                
                for cookie in allCookies {
                    if cookie.domain.contains("youtube.com") || cookie.domain.contains("google.com") {
                        if targetCookies.contains(cookie.name) {
                            extractedCookies[cookie.name] = cookie.value
                        }
                    }
                }
                
                // 必须获取到所有5个Cookie才返回
                if extractedCookies.count == targetCookies.count && 
                   targetCookies.allSatisfy({ extractedCookies.keys.contains($0) }) {
                    DispatchQueue.main.async {
                        self.parent.onCookiesExtracted(extractedCookies)
                    }
                } else {
                    print("🔍 Cookie检查：需要获取全部5个Cookie，当前已获取：\(extractedCookies.keys.sorted())")
                }
            }
        }
    }
}

 
