#if canImport(ActivityKit)
import ActivityKit
#endif
import Foundation

#if canImport(ActivityKit)
@available(iOS 16.1, *)
struct LineChartAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // 折线图数据点
        var dataPoints: [Double]
        // 图表标题
        var title: String
        // 当前值
        var currentValue: Double
        // 趋势（上升、下降、平稳）
        var trend: String
        // 更新时间
        var lastUpdated: Date
        
        init(dataPoints: [Double] = [], 
             title: String = "数据趋势", 
             currentValue: Double = 0,
             trend: String = "stable",
             lastUpdated: Date = Date()) {
            self.dataPoints = dataPoints
            self.title = title
            self.currentValue = currentValue
            self.trend = trend
            self.lastUpdated = lastUpdated
        }
    }
    
    // 固定属性（活动创建时设置，不会更改）
    var chartName: String
    var chartType: String
    
    init(chartName: String = "折线图", chartType: String = "line") {
        self.chartName = chartName
        self.chartType = chartType
    }
}
#else
// ActivityKit不可用时的备用定义
struct LineChartAttributes {
    struct ContentState: Codable, Hashable {
        var dataPoints: [Double]
        var title: String
        var currentValue: Double
        var trend: String
        var lastUpdated: Date
        
        init(dataPoints: [Double] = [], 
             title: String = "数据趋势", 
             currentValue: Double = 0,
             trend: String = "stable",
             lastUpdated: Date = Date()) {
            self.dataPoints = dataPoints
            self.title = title
            self.currentValue = currentValue
            self.trend = trend
            self.lastUpdated = lastUpdated
        }
    }
    
    var chartName: String
    var chartType: String
    
    init(chartName: String = "折线图", chartType: String = "line") {
        self.chartName = chartName
        self.chartType = chartType
    }
}
#endif 