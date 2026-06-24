import Foundation

// MARK: - 日历辅助工具
/// 提供日历网格所需的日期计算与格式化方法
struct CalendarHelper {

    /// 共享的公历日历实例
    private static let calendar = Calendar.current

    /// 日期格式化器：yyyy-MM-dd
    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }()

    /// 月份格式化器：2026年6月
    private static let monthYearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy年M月"
        f.locale = Locale(identifier: "zh_CN")
        f.timeZone = .current
        return f
    }()

    // MARK: - 月份信息

    /// 获取指定日期所在月份的总天数
    static func daysInMonth(date: Date) -> Int {
        guard let range = calendar.range(of: .day, in: .month, for: date) else {
            return 30
        }
        return range.count
    }

    /// 获取指定日期所在月份第一天的星期（1 = 周日，2 = 周一，...，7 = 周六）
    static func firstWeekdayOfMonth(date: Date) -> Int {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDay = calendar.date(from: components) else {
            return 1
        }
        return calendar.component(.weekday, from: firstDay)
    }

    // MARK: - 日期格式化

    /// 格式化为 "2026年6月" 样式
    static func monthYearString(date: Date) -> String {
        monthYearFormatter.string(from: date)
    }

    /// 格式化为 "yyyy-MM-dd" 样式
    static func dateString(date: Date) -> String {
        dayFormatter.string(from: date)
    }

    // MARK: - 日期组件

    /// 获取日期中的「日」部分（1~31）
    static func dayComponent(date: Date) -> Int {
        calendar.component(.day, from: date)
    }

    /// 判断指定日期是否为今天
    static func isToday(date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    // MARK: - 月份内所有日期

    /// 返回指定日期所在月份的全部日期数组
    static func allDaysInMonth(date: Date) -> [Date] {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let firstDay = calendar.date(from: components) else {
            return []
        }

        let totalDays = daysInMonth(date: date)
        var days: [Date] = []
        days.reserveCapacity(totalDays)

        for offset in 0..<totalDays {
            if let day = calendar.date(byAdding: .day, value: offset, to: firstDay) {
                days.append(day)
            }
        }

        return days
    }

    // MARK: - 月份导航

    /// 获取上一个月的日期
    static func previousMonth(date: Date) -> Date {
        calendar.date(byAdding: .month, value: -1, to: date) ?? date
    }

    /// 获取下一个月的日期
    static func nextMonth(date: Date) -> Date {
        calendar.date(byAdding: .month, value: 1, to: date) ?? date
    }
}
