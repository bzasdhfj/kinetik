// CheckInWidget.swift
// 打卡日历小组件 - 入口文件
// 定义小组件配置 Intent、Widget 声明和 WidgetBundle

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 小组件定义

/// 打卡日历小组件 —— 使用 AppIntentConfiguration 支持用户自定义配置
struct CheckInCalendarWidget: Widget {
    /// 小组件的唯一标识符，用于系统识别和刷新
    let kind: String = "CheckInCalendarWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CheckInWidgetConfigIntent.self,
            provider: CheckInTimelineProvider()
        ) { entry in
            CheckInWidgetView(entry: entry)
        }
        .configurationDisplayName("Kinetik")
        .description("Track your daily check-in records")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - 小组件入口

/// WidgetBundle 作为小组件扩展的 @main 入口点
/// 如需添加更多小组件，在此 body 中追加即可
@main
struct CheckInWidgetBundle: WidgetBundle {
    var body: some Widget {
        CheckInCalendarWidget()
    }
}

// MARK: - 预览

#Preview("打卡日历 - 大", as: .systemLarge) {
    CheckInCalendarWidget()
} timeline: {
    CheckInEntry(
        date: .now,
        calendarName: "Daily Check-In",
        statuses: ["2026-06-18": .full, "2026-06-19": .full, "2026-06-20": .bonus, "2026-06-21": .bonus],
        consecutiveDays: 4,
        totalDays: 16,
        isTodayCheckedIn: true
    )
    CheckInEntry(
        date: .now,
        calendarName: "Daily Check-In",
        statuses: ["2026-06-18": .full, "2026-06-19": .full, "2026-06-20": .bonus],
        consecutiveDays: 3,
        totalDays: 12,
        isTodayCheckedIn: false
    )
}

#Preview("打卡日历 - 中", as: .systemMedium) {
    CheckInCalendarWidget()
} timeline: {
    CheckInEntry(
        date: .now,
        calendarName: "Daily Check-In",
        statuses: ["2026-06-18": .full, "2026-06-19": .full, "2026-06-20": .bonus, "2026-06-21": .bonus],
        consecutiveDays: 4,
        totalDays: 16,
        isTodayCheckedIn: true
    )
}
