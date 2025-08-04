import Foundation
#if canImport(ActivityKit)
import ActivityKit
#endif

// 基础数据结构
struct LineChartContentState: Codable, Hashable {
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

#if canImport(ActivityKit)
@available(iOS 16.1, *)
struct LineChartAttributes: ActivityAttributes {
    public typealias ContentState = LineChartContentState
    
    // 固定属性（活动创建时设置，不会更改）
    var appName: String
    
    init(appName: String = "Mood Tracker") {
        self.appName = appName
    }
}
#else
// ActivityKit不可用时的备用定义
struct LineChartAttributes {
    typealias ContentState = LineChartContentState
    
    var appName: String
    
    init(appName: String = "Mood Tracker") {
        self.appName = appName
    }
}
#endif 