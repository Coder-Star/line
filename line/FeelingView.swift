//
//  FeelingView.swift
//  line
//
//  Created by CoderStar on 2025/7/28.
//

import SwiftUI

struct FeelingView: View {
    @Binding var selectedFeeling: String
    let onFeelingSelected: (String) -> Void
    
    // 8个情感状态 - 使用图片资源
    let feelingData = [
        ("Calm", "Calm"),
        ("Connected", "Connected"),
        ("Motivated", "Motivated"),
        ("Stimulated", "Stimulated"),
        ("Focused", "Focused"),
        ("Light-Hearted", "Light_Hearted"), // 注意assets中的名称有空格
        ("Inspired", "Inspired"),
        ("Curious", "Curious")
    ]
    
         // 动态计算按钮位置
     func calculateButtonPositions(in geometry: GeometryProxy) -> [FeelingItem] {
         let screenWidth = geometry.size.width
         let screenHeight = geometry.size.height
         
         // 进一步减少标题区域高度，让按钮更靠上
         let titleAreaHeight: CGFloat = 160 
         
                  // 可用于按钮的高度 - 保持底部空白
         let availableHeight = screenHeight - titleAreaHeight - geometry.safeAreaInsets.top - geometry.safeAreaInsets.bottom - 80 // 增加到80px底部边距
         
         // 固定间距
         let fixedVerticalSpacing: CGFloat = 20
         
         // 动态计算按钮尺寸：(可用高度 - 3个间距) / 4个按钮
         let calculatedButtonSize = (availableHeight - fixedVerticalSpacing * 3) / 4
         let buttonSize = max(min(calculatedButtonSize, 160), 120) // 增加到120-160px，让按钮稍微大一点
        
                          var feelings: [FeelingItem] = []
        
                 // 按钮布局 - 确保在标题区域下方
         let centerX = screenWidth / 2
         
         // 左右列的X坐标 - 增加横向间距
         let leftColumnX = centerX - buttonSize * 0.8
         let rightColumnX = centerX + buttonSize * 0.8
         
         // 起始Y坐标：直接从标题区域下方开始，不居中
         let buttonsStartY = titleAreaHeight + geometry.safeAreaInsets.top + fixedVerticalSpacing
         
         // 左列按钮位置 (Calm, Motivated, Focused, Inspired)
         let leftColumnButtons = [0, 2, 4, 6]
         for (index, dataIndex) in leftColumnButtons.enumerated() {
             let data = feelingData[dataIndex]
             let yPosition = buttonsStartY + CGFloat(index) * (buttonSize + fixedVerticalSpacing)
             
             feelings.append(FeelingItem(
                 name: data.0,
                 imageName: data.1,
                 position: CGPoint(x: leftColumnX, y: yPosition),
                 size: CGSize(width: buttonSize, height: buttonSize)
             ))
         }
         
         // 右列按钮位置 (Connected, Stimulated, Light-Hearted, Curious) - 稍微错位
         let rightColumnButtons = [1, 3, 5, 7]
         for (index, dataIndex) in rightColumnButtons.enumerated() {
             let data = feelingData[dataIndex]
             // 右列向下偏移更多，形成更明显的错位效果
             let yPosition = buttonsStartY + CGFloat(index) * (buttonSize + fixedVerticalSpacing) + fixedVerticalSpacing * 1.3
             
             feelings.append(FeelingItem(
                 name: data.0,
                 imageName: data.1,
                 position: CGPoint(x: rightColumnX, y: yPosition),
                 size: CGSize(width: buttonSize, height: buttonSize)
             ))
         }
        
        return feelings
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 底层：common_bg背景 - 铺满整个屏幕 (与LoginView保持一致)
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
                
                VStack(alignment: .leading, spacing: 20) {
                    // 标题区域 - 根据Figma设计精确布局
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("How would you")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                                Text("like to feel today?")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                        }
                        .padding(.leading, 40)
                        .padding(.top, 30)
                        
                        Text("Pick one mood for the app to gently nudge your feed toward. You can change this anytime.")
                            .font(.system(size: 14, weight: .light))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .lineLimit(nil)
                            .padding(.horizontal, 40)
                            .padding(.top, 8)
                    }
                    
                    Spacer()
                }
                
                // 情感按钮区域 - 动态计算位置
                let dynamicFeelings = calculateButtonPositions(in: geometry)
                ForEach(dynamicFeelings, id: \.name) { feeling in
                    FeelingButton(
                        feeling: feeling,
                        isSelected: selectedFeeling == feeling.name
                    ) {
                        print("🎯 用户选择了情感: \(feeling.name)")
                        selectedFeeling = feeling.name
                        print("🔄 更新selectedFeeling为: \(selectedFeeling)")
                        onFeelingSelected(feeling.name)
                        print("✅ 调用onFeelingSelected回调完成")
                    }
                }
            }
        }
    }
}

// 情感项目数据结构
struct FeelingItem {
    let name: String
    let imageName: String
    let position: CGPoint // 绝对位置
    let size: CGSize
}

// 情感按钮组件
struct FeelingButton: View {
    let feeling: FeelingItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(feeling.imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: feeling.size.width, height: feeling.size.height)
                .scaleEffect(isSelected ? 1.15 : 1.0)
                .shadow(
                    color: isSelected ? Color.white.opacity(0.4) : Color.clear, 
                    radius: isSelected ? 15 : 0
                )
        }
        .position(feeling.position)
        .animation(.easeInOut(duration: 0.3), value: isSelected)
    }
}

 
 
