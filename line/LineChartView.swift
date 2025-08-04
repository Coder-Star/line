import SwiftUI

struct LineChartView: View {
    let dataPoints: [CGFloat]
    let lineColor: Color
    let lineWidth: CGFloat
    let showDots: Bool
    let animated: Bool
    let showGrid: Bool
    let showValues: Bool
    let showReferenceLine: Bool
    let referenceValue: CGFloat
    let minYValue: CGFloat?
    let maxYValue: CGFloat?
    let smoothness: CGFloat // 0.0 = 直线, 1.0 = 最平滑
    
    @State private var animationProgress: CGFloat = 0
    
    init(dataPoints: [CGFloat], 
         lineColor: Color = .blue, 
         lineWidth: CGFloat = 2, 
         showDots: Bool = true,
         animated: Bool = true,
         showGrid: Bool = true,
         showValues: Bool = true,
         showReferenceLine: Bool = true,
         referenceValue: CGFloat = 30,
         minYValue: CGFloat? = nil,
         maxYValue: CGFloat? = nil,
         smoothness: CGFloat = 0.6) {
        self.dataPoints = dataPoints
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.showDots = showDots
        self.animated = animated
        self.showGrid = showGrid
        self.showValues = showValues
        self.showReferenceLine = showReferenceLine
        self.referenceValue = referenceValue
        self.minYValue = minYValue
        self.maxYValue = maxYValue
        self.smoothness = smoothness
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            ZStack {
                // 绘制网格线
                if showGrid {
                    GridLinesView(
                        width: width, 
                        height: height, 
                        minValue: minYValue ?? (dataPoints.min() ?? 0),
                        maxValue: maxYValue ?? (dataPoints.max() ?? 1)
                    )
                }
                
                // 绘制参考线（初始值30）
                if showReferenceLine {
                    ReferenceLineView(
                        width: width, 
                        height: height, 
                        referenceValue: referenceValue, 
                        minValue: minYValue ?? (dataPoints.min() ?? 0),
                        maxValue: maxYValue ?? (dataPoints.max() ?? 1)
                    )
                }
                
                // 绘制数值标签
                if showValues {
                    ValueLabelsView(
                        width: width, 
                        height: height, 
                        minValue: minYValue ?? (dataPoints.min() ?? 0),
                        maxValue: maxYValue ?? (dataPoints.max() ?? 1)
                    )
                }
                
                if dataPoints.count > 1 {
                    // 绘制平滑折线
                    Path { path in
                        let points = calculatePoints(in: CGSize(width: width, height: height))
                        
                        if !points.isEmpty {
                            path.move(to: points[0])
                            
                            if points.count > 2 {
                                // 使用平滑贝塞尔曲线连接所有点
                                for i in 1..<points.count {
                                    let currentPoint = points[i]
                                    let previousPoint = points[i-1]
                                    
                                    // 计算控制点以创建平滑曲线
                                    let controlPoint1: CGPoint
                                    let controlPoint2: CGPoint
                                    
                                    if i == 1 {
                                        // 第一段曲线
                                        controlPoint1 = CGPoint(
                                            x: previousPoint.x + (currentPoint.x - previousPoint.x) * (0.25 * smoothness),
                                            y: previousPoint.y
                                        )
                                    } else {
                                        // 使用前一个点来计算平滑的控制点
                                        let prevPrevPoint = points[i-2]
                                        let factor = 0.15 * smoothness
                                        controlPoint1 = CGPoint(
                                            x: previousPoint.x + (currentPoint.x - prevPrevPoint.x) * factor,
                                            y: previousPoint.y + (currentPoint.y - prevPrevPoint.y) * factor
                                        )
                                    }
                                    
                                    if i == points.count - 1 {
                                        // 最后一段曲线
                                        controlPoint2 = CGPoint(
                                            x: currentPoint.x - (currentPoint.x - previousPoint.x) * (0.25 * smoothness),
                                            y: currentPoint.y
                                        )
                                    } else {
                                        // 使用下一个点来计算平滑的控制点
                                        let nextPoint = points[i+1]
                                        let factor = 0.15 * smoothness
                                        controlPoint2 = CGPoint(
                                            x: currentPoint.x - (nextPoint.x - previousPoint.x) * factor,
                                            y: currentPoint.y - (nextPoint.y - previousPoint.y) * factor
                                        )
                                    }
                                    
                                    path.addCurve(to: currentPoint, control1: controlPoint1, control2: controlPoint2)
                                }
                            } else if points.count == 2 {
                                // 只有两个点，使用直线
                                path.addLine(to: points[1])
                            }
                        }
                    }
                    .trim(from: 0, to: animated ? animationProgress : 1)
                    .stroke(lineColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    
                    // 绘制数据点
                    if showDots {
                        ForEach(Array(calculatePoints(in: CGSize(width: width, height: height)).enumerated()), id: \.offset) { index, point in
                            Circle()
                                .fill(lineColor)
                                .frame(width: 8, height: 8)
                                .position(point)
                                .opacity(animated ? (animationProgress >= CGFloat(index) / CGFloat(dataPoints.count - 1) ? 1 : 0) : 1)
                                .shadow(color: lineColor.opacity(0.3), radius: 2)
                        }
                    }
                } else if dataPoints.count == 1 {
                    // 单个数据点显示
                    Circle()
                        .fill(lineColor)
                        .frame(width: 12, height: 12)
                        .position(x: width / 2, y: height / 2)
                        .shadow(color: lineColor.opacity(0.3), radius: 2)
                }
            }
        }
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 1.5)) {
                    animationProgress = 1
                }
            }
        }
    }
    
    private func calculatePoints(in size: CGSize) -> [CGPoint] {
        guard dataPoints.count > 1 else { return [] }
        
        // 使用固定范围或数据范围
        let minValue = minYValue ?? (dataPoints.min() ?? 0)
        let maxValue = maxYValue ?? (dataPoints.max() ?? 1)
        let range = maxValue - minValue
        
        // 避免除零错误
        let normalizedRange = range == 0 ? 1 : range
        
        return dataPoints.enumerated().map { index, value in
            let x = CGFloat(index) / CGFloat(dataPoints.count - 1) * size.width
            let normalizedValue = (value - minValue) / normalizedRange
            let y = size.height - (normalizedValue * size.height)
            return CGPoint(x: x, y: y)
        }
    }
    
    // 计算数值范围（供其他组件使用）
    private func getValueRange() -> (min: CGFloat, max: CGFloat) {
        let minValue = dataPoints.min() ?? 0
        let maxValue = dataPoints.max() ?? 1
        return (minValue, maxValue)
    }
}

// MARK: - 网格线组件
struct GridLinesView: View {
    let width: CGFloat
    let height: CGFloat
    let minValue: CGFloat
    let maxValue: CGFloat
    
    var body: some View {
        let range = maxValue - minValue
        let normalizedRange = range == 0 ? 1 : range
        
        ZStack {
            // 横向网格线
            ForEach(0..<5, id: \.self) { index in
                let y = CGFloat(index) / 4.0 * height
                Path { path in
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: width, y: y))
                }
                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            }
            
            // 纵向网格线
            ForEach(0..<6, id: \.self) { index in
                let x = CGFloat(index) / 5.0 * width
                Path { path in
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
            }
        }
    }
}

// MARK: - 参考线组件
struct ReferenceLineView: View {
    let width: CGFloat
    let height: CGFloat
    let referenceValue: CGFloat
    let minValue: CGFloat
    let maxValue: CGFloat
    
    var body: some View {
        let range = maxValue - minValue
        let normalizedRange = range == 0 ? 1 : range
        
        // 计算参考线的Y位置
        let normalizedRef = (referenceValue - minValue) / normalizedRange
        let refY = height - (normalizedRef * height)
        
        // 只有当参考线在图表范围内时才显示
        if referenceValue >= minValue && referenceValue <= maxValue {
            ZStack {
                // 参考线
                Path { path in
                    path.move(to: CGPoint(x: 0, y: refY))
                    path.addLine(to: CGPoint(x: width, y: refY))
                }
                .stroke(Color.yellow.opacity(0.6), style: StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                
                // 参考线标签
                HStack {
                    Text("初始值: \(Int(referenceValue))")
                        .font(.caption2)
                        .foregroundColor(.yellow.opacity(0.8))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(4)
                    Spacer()
                }
                .position(x: width / 2, y: refY - 12)
            }
        }
    }
}

// MARK: - 数值标签组件
struct ValueLabelsView: View {
    let width: CGFloat
    let height: CGFloat
    let minValue: CGFloat
    let maxValue: CGFloat
    
    var body: some View {
        
        VStack {
            HStack {
                Text("\(Int(maxValue))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Text("\(Int((maxValue + minValue) / 2))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Text("\(Int(minValue))")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
            }
        }
        .frame(width: width, height: height)
    }
}

 