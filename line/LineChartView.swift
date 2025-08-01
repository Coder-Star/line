import SwiftUI

struct LineChartView: View {
    let dataPoints: [CGFloat]
    let lineColor: Color
    let lineWidth: CGFloat
    let showDots: Bool
    let animated: Bool
    
    @State private var animationProgress: CGFloat = 0
    
    init(dataPoints: [CGFloat], 
         lineColor: Color = .blue, 
         lineWidth: CGFloat = 2, 
         showDots: Bool = true,
         animated: Bool = true) {
        self.dataPoints = dataPoints
        self.lineColor = lineColor
        self.lineWidth = lineWidth
        self.showDots = showDots
        self.animated = animated
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            if dataPoints.count > 1 {
                ZStack {
                    // 绘制折线
                    Path { path in
                        let points = calculatePoints(in: CGSize(width: width, height: height))
                        
                        if !points.isEmpty {
                            path.move(to: points[0])
                            for point in points.dropFirst() {
                                path.addLine(to: point)
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
                                .frame(width: 6, height: 6)
                                .position(point)
                                .opacity(animated ? (animationProgress >= CGFloat(index) / CGFloat(dataPoints.count - 1) ? 1 : 0) : 1)
                        }
                    }
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
        
        let minValue = dataPoints.min() ?? 0
        let maxValue = dataPoints.max() ?? 1
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
}

 