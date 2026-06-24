// CheckInTimelineProvider.swift
// 打卡日历小组件 - 时间线提供器
// 负责为小组件提供数据快照和刷新策略

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - 时间线条目

/// 小组件的数据模型，包含日历展示所需的全部信息
struct CheckInEntry: TimelineEntry {
    /// 条目对应的日期
    let date: Date
    /// 日历名称（用户可通过配置自定义）
    let calendarName: String
    /// 当月及其前后的状态字典（格式: "yyyy-MM-dd" : CompletionStatus）
    let statuses: [String: CompletionStatus]
    /// 当前连续签到天数
    let consecutiveDays: Int
    /// 今日是否已签到
    let isTodayCheckedIn: Bool
}

// MARK: - 时间线提供器

/// 遵循 AppIntentTimelineProvider，支持用户通过 Intent 配置小组件
struct CheckInTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = CheckInEntry
    typealias Intent = CheckInWidgetConfigIntent

    /// 占位视图数据 —— 在小组件加载时展示骨架屏
    func placeholder(in context: Context) -> CheckInEntry {
        CheckInEntry(
            date: .now,
            calendarName: "每日打卡",
            statuses: ["2026-06-18": .full, "2026-06-19": .full, "2026-06-20": .bonus],
            consecutiveDays: 3,
            isTodayCheckedIn: true
        )
    }

    /// 快照数据 —— 在小组件库预览等场景使用，返回真实数据
    func snapshot(
        for configuration: CheckInWidgetConfigIntent,
        in context: Context
    ) async -> CheckInEntry {
        createEntry(for: configuration)
    }

    /// 时间线数据 —— 主要的数据提供方法
    /// 使用 `.after` 策略在次日零点自动刷新，确保日历日期切换正确
    func timeline(
        for configuration: CheckInWidgetConfigIntent,
        in context: Context
    ) async -> Timeline<CheckInEntry> {
        let entry = createEntry(for: configuration)

        // 计算次日零点作为刷新时间
        let nextMidnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        )

        return Timeline(entries: [entry], policy: .after(nextMidnight))
    }

    // MARK: - 私有方法

    /// 从 CheckInStore 读取当前数据，构建时间线条目
    private func createEntry(for configuration: CheckInWidgetConfigIntent) -> CheckInEntry {
        let store = CheckInStore.shared
        return CheckInEntry(
            date: .now,
            calendarName: configuration.calendarName,
            statuses: store.getStatuses(around: .now),
            consecutiveDays: store.consecutiveDays(),
            isTodayCheckedIn: store.isTodayCheckedIn()
        )
    }
}
