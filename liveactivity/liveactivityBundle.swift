//
//  liveactivityBundle.swift
//  liveactivity
//
//  Created by CoderStar on 2025/7/28.
//

import WidgetKit
import SwiftUI

@main
struct liveactivityBundle: WidgetBundle {
    var body: some Widget {
        // 我们的折线图Live Activity
        LineChartWidget()
        
        // 保留原有的组件（可选）
        liveactivity()
        liveactivityControl()
        liveactivityLiveActivity()
    }
}
