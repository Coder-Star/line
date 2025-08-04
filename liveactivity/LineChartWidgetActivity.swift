import ActivityKit
import WidgetKit
import SwiftUI
import Foundation

// 确保 LineChartAttributes 在 Live Activity extension 中可用
// 重新定义以确保在扩展中正确工作
@available(iOS 16.1, *)
struct LineChartAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 选择的情感名称
        var selectedFeeling: String
        // 当前情感数值
        var currentValue: Double
        // 最近的增量变化
        var deltaValue: Double
        // 折线图数据点
        var dataPoints: [Double]
        // 历史数据
        var oneHourBefore: Double?
        var sixHoursBefore: Double?
        var oneDayBefore: Double?
        var oneWeekBefore: Double?
        // 更新时间
        var lastUpdated: Date
        
        init(selectedFeeling: String = "Calm",
             currentValue: Double = 30,
             deltaValue: Double = 0,
             dataPoints: [Double] = [],
             oneHourBefore: Double? = nil,
             sixHoursBefore: Double? = nil,
             oneDayBefore: Double? = nil,
             oneWeekBefore: Double? = nil,
             lastUpdated: Date = Date()) {
            self.selectedFeeling = selectedFeeling
            self.currentValue = currentValue
            self.deltaValue = deltaValue
            self.dataPoints = dataPoints
            self.oneHourBefore = oneHourBefore
            self.sixHoursBefore = sixHoursBefore
            self.oneDayBefore = oneDayBefore
            self.oneWeekBefore = oneWeekBefore
            self.lastUpdated = lastUpdated
        }
    }
    
    // 固定属性（活动创建时设置，不会更改）
    var appName: String
    
    init(appName: String = "Mood Tracker") {
        self.appName = appName
    }
}

struct LineChartWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LineChartAttributes.self) { context in
            // 锁屏界面
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            // 灵动岛界面
            DynamicIsland {
                // 展开状态
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(context.state.selectedFeeling)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("\(Int(context.state.currentValue))")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(context.state.deltaValue >= 0 ? "+\(Int(context.state.deltaValue))" : "\(Int(context.state.deltaValue))")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(context.state.deltaValue >= 0 ? .green : .red)
                        Text(timeAgo(from: context.state.lastUpdated))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 8) {
                        // 迷你折线图
                        MiniLineChartView(dataPoints: context.state.dataPoints.map { CGFloat($0) })
                            .frame(height: 35)
                        
                        // 四个历史数据
                        HStack(spacing: 0) {
                            HistoryValueView(title: "1 Week", value: context.state.oneWeekBefore)
                            Spacer()
                            HistoryValueView(title: "1 Day", value: context.state.oneDayBefore)
                            Spacer()
                            HistoryValueView(title: "12 Hours", value: context.state.sixHoursBefore)
                            Spacer()
                            HistoryValueView(title: "1 Hour", value: context.state.oneHourBefore)
                        }
                        .font(.caption2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            } compactLeading: {
                // 紧凑状态左侧 - 心情类型
                Text(context.state.selectedFeeling)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .lineLimit(1)
            } compactTrailing: {
                // 紧凑状态右侧 - 当前值
                Text("\(Int(context.state.currentValue))")
                    .font(.caption2)
                    .fontWeight(.semibold)
            } minimal: {
                // 最小状态
                Text("\(Int(context.state.currentValue))")
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
        }
    }
}

// 锁屏实时活动视图
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<LineChartAttributes>
    
    var body: some View {
        VStack(spacing: 8) {
            // 顶部信息
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.selectedFeeling)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    Text("\(Int(context.state.currentValue))")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(context.state.deltaValue >= 0 ? "+\(Int(context.state.deltaValue))" : "\(Int(context.state.deltaValue))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(context.state.deltaValue >= 0 ? .green : .red)
                    
                    Text("Updated \(timeAgo(from: context.state.lastUpdated))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // 折线图区域
            VStack(spacing: 6) {
                // 总是显示折线图，即使数据很少
                MiniLineChartView(dataPoints: context.state.dataPoints.isEmpty ? [CGFloat(context.state.currentValue)] : context.state.dataPoints.map { CGFloat($0) })
                    .frame(height: 40)
                
                // 历史数据时间轴
                HStack(spacing: 8) {
                    HistoryValueView(title: "1 Week", value: context.state.oneWeekBefore)
                    Spacer()
                    HistoryValueView(title: "1 Day", value: context.state.oneDayBefore)
                    Spacer()
                    HistoryValueView(title: "12 Hours", value: context.state.sixHoursBefore)
                    Spacer()
                    HistoryValueView(title: "1 Hour", value: context.state.oneHourBefore)
                }
            }
        }
        .padding(12)
    }
}

// 迷你折线图视图（用于实时活动）
struct MiniLineChartView: View {
    let dataPoints: [CGFloat]
    
    var body: some View {
        GeometryReader { geometry in
            if dataPoints.count > 1 {
                // 多点平滑折线图
                Path { path in
                    let points = calculatePoints(in: CGSize(width: geometry.size.width, height: geometry.size.height))
                    
                    if points.count >= 2 {
                        // 绘制平滑贝塞尔曲线
                        path.move(to: points[0])
                        
                        if points.count == 2 {
                            // 两个点直接连线
                            path.addLine(to: points[1])
                        } else {
                            // 多个点使用平滑曲线
                            for i in 1..<points.count {
                                let currentPoint = points[i]
                                let previousPoint = points[i-1]
                                
                                // 计算控制点实现平滑效果
                                let smoothness: CGFloat = 0.3
                                let deltaX = currentPoint.x - previousPoint.x
                                
                                let controlPoint1 = CGPoint(
                                    x: previousPoint.x + deltaX * smoothness,
                                    y: previousPoint.y
                                )
                                let controlPoint2 = CGPoint(
                                    x: currentPoint.x - deltaX * smoothness,
                                    y: currentPoint.y
                                )
                                
                                path.addCurve(to: currentPoint, control1: controlPoint1, control2: controlPoint2)
                            }
                        }
                    }
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            } else if dataPoints.count == 1 {
                // 单点显示为水平线
                Path { path in
                    let y = geometry.size.height / 2
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                
                // 在中心添加一个点
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
    
    private func calculatePoints(in size: CGSize) -> [CGPoint] {
        guard dataPoints.count > 1 else { return [] }
        
        let minValue = dataPoints.min() ?? 0
        let maxValue = dataPoints.max() ?? 1
        let range = maxValue - minValue
        let normalizedRange = range == 0 ? 1 : range
        
        return dataPoints.enumerated().map { index, value in
            let x = CGFloat(index) / CGFloat(dataPoints.count - 1) * size.width
            let normalizedValue = (value - minValue) / normalizedRange
            let y = size.height - (normalizedValue * size.height)
            return CGPoint(x: x, y: y)
        }
    }
}

// 历史数值显示组件
struct HistoryValueView: View {
    let title: String
    let value: Double?
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            if let value = value {
                Text(value >= 0 ? "+\(Int(value))" : "\(Int(value))")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(value >= 0 ? .green : .red)
            } else {
                Text("--")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// 时间格式化辅助函数
private func timeAgo(from date: Date) -> String {
    let timeInterval = Date().timeIntervalSince(date)
    let minutes = Int(timeInterval / 60)
    
    if minutes < 1 {
        return "just now"
    } else if minutes < 60 {
        return "\(minutes)min ago"
    } else {
        let hours = minutes / 60
        return "\(hours)hr ago"
    }
}

// 日期格式化器扩展
extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
} 
