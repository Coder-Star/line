import ActivityKit
import WidgetKit
import SwiftUI

struct LineChartLiveActivity: Widget {
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
                            Text(context.attributes.chartName)
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("\(String(format: "%.1f", context.state.currentValue))")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TrendIndicator(trend: context.state.trend)
                        .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    MiniLineChartView(dataPoints: context.state.dataPoints.map { CGFloat($0) })
                        .frame(height: 40)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }
            } compactLeading: {
                // 紧凑状态左侧
                TrendIndicator(trend: context.state.trend)
            } compactTrailing: {
                // 紧凑状态右侧
                Text("\(String(format: "%.0f", context.state.currentValue))")
                    .font(.caption2)
                    .fontWeight(.semibold)
            } minimal: {
                // 最小状态
                TrendIndicator(trend: context.state.trend)
            }
        }
    }
}

// 锁屏实时活动视图
struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<LineChartAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(context.attributes.chartName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text(context.state.title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        TrendIndicator(trend: context.state.trend)
                        Text("\(String(format: "%.1f", context.state.currentValue))")
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                    
                    Text("当前值")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 折线图
            if !context.state.dataPoints.isEmpty {
                MiniLineChartView(dataPoints: context.state.dataPoints.map { CGFloat($0) })
                    .frame(height: 60)
            }
            
            HStack {
                Text("更新时间: \(DateFormatter.shortTime.string(from: context.state.lastUpdated))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(16)
    }
}

// 迷你折线图视图（用于实时活动）
struct MiniLineChartView: View {
    let dataPoints: [CGFloat]
    
    var body: some View {
        GeometryReader { geometry in
            if dataPoints.count > 1 {
                Path { path in
                    let points = calculatePoints(in: CGSize(width: geometry.size.width, height: geometry.size.height))
                    
                    if !points.isEmpty {
                        path.move(to: points[0])
                        for point in points.dropFirst() {
                            path.addLine(to: point)
                        }
                    }
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
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

// 趋势指示器
struct TrendIndicator: View {
    let trend: String
    
    var body: some View {
        Group {
            switch trend {
            case "up":
                Image(systemName: "arrow.up.right")
                    .foregroundColor(.green)
            case "down":
                Image(systemName: "arrow.down.right")
                    .foregroundColor(.red)
            default:
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
            }
        }
        .font(.caption)
        .fontWeight(.semibold)
    }
}


