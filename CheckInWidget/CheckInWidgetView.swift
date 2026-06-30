import SwiftUI
import WidgetKit
import AppIntents

struct CheckInWidgetView: View {
    let entry: CheckInEntry

    @Environment(\.widgetFamily) var widgetFamily

    var body: some View {
        Group {
            switch widgetFamily {
            case .systemMedium:
                MediumWidgetLayout(entry: entry)
            case .systemLarge:
                VStack(spacing: 12) {
                    HeatmapWidgetLayout(entry: entry, columns: 16)
                    
                    Divider().padding(.vertical, 4)
                    
                    Text("Recent Activity")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    MonthOverviewGrid(entry: entry, cellSize: 22, spacing: 4, fontSize: 11)
                }
            default:
                MediumWidgetLayout(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                // Peach-Pink-Purple gradient matching the main App
                LinearGradient(
                    colors: [
                        Color(red: 254/255, green: 225/255, blue: 165/255), // Soft peach
                        Color(red: 253/255, green: 180/255, blue: 200/255), // Soft pink
                        Color(red: 215/255, green: 185/255, blue: 235/255)  // Soft purple
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Frosted glass effect
                Color.white.opacity(0.12)
                    .background(.ultraThinMaterial)
            }
        }
    }
}

struct HeatmapWidgetLayout: View {
    let entry: CheckInEntry
    let columns: Int
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.calendarName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    Text("Check-in Heatmap")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                
                // Streak & Total
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Text("🔥").font(.system(size: 10))
                        Text("\(entry.consecutiveDays)d")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.orange)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.orange.opacity(0.12), in: Capsule())
                    
                    HStack(spacing: 2) {
                        Text("📊").font(.system(size: 10))
                        Text("\(entry.totalDays)d")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color.teal)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.teal.opacity(0.12), in: Capsule())
                }
            }
            
            // Heatmap Grid
            HStack(spacing: 3) {
                // Y-Axis labels (Weekdays)
                VStack(spacing: 3) {
                    Text("Sun").font(.system(size: 7, weight: .bold)).foregroundStyle(.secondary).frame(height: 10)
                    Text("Mon").font(.system(size: 7, weight: .bold)).foregroundStyle(.secondary).frame(height: 10)
                    Text("Tue").font(.system(size: 7, weight: .bold)).foregroundStyle(.secondary).frame(height: 10)
                    Text("Wed").font(.system(size: 7, weight: .bold)).foregroundStyle(.secondary).frame(height: 10)
                    Text("Thur").font(.system(size: 7, weight: .bold)).foregroundStyle(.secondary).frame(height: 10)
                    Text("Fri").font(.system(size: 7, weight: .bold)).foregroundStyle(.secondary).frame(height: 10)
                    Text("Sat").font(.system(size: 7, weight: .bold)).foregroundStyle(.secondary).frame(height: 10)
                }
                .frame(width: 22, alignment: .trailing)
                
                let gridData = generateHeatmapData(columns: columns)
                
                ForEach(0..<columns, id: \.self) { colIndex in
                    VStack(spacing: 3) {
                        ForEach(0..<7, id: \.self) { rowIndex in
                            let date = gridData[colIndex][rowIndex]
                            if let date = date {
                                let status = getStatus(for: date)
                                let isFuture = Calendar.current.startOfDay(for: date) > Calendar.current.startOfDay(for: Date.logicalNow)
                                let isToday = Calendar.current.isDate(date, inSameDayAs: Date.logicalNow)
                                
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(cellColor(for: status))
                                    .opacity(isFuture ? 0.05 : 1.0)
                                    .overlay(
                                        isToday ? RoundedRectangle(cornerRadius: 2).stroke(Color.teal, lineWidth: 1) : nil
                                    )
                                    .frame(width: 10, height: 10)
                            } else {
                                Color.clear.frame(width: 10, height: 10)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            
            // Check-in Button Row
            Button(intent: CheckInIntent()) {
                HStack(spacing: 4) {
                    if entry.isTodayCheckedIn {
                        Text("✅ Checked In")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.black.opacity(0.7))
                    } else {
                        Text("📝 Check In Now")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background {
                    if entry.isTodayCheckedIn {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                    } else {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(LinearGradient(colors: [.teal, .blue], startPoint: .leading, endPoint: .trailing))
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(4)
    }
    
    private func getStatus(for date: Date) -> CompletionStatus {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        let key = formatter.string(from: date)
        return entry.statuses[key] ?? .none
    }
    
    private func cellColor(for status: CompletionStatus) -> Color {
        switch status {
        case .none: return Color.gray.opacity(0.15)
        case .partial: return Color.green.opacity(0.35)
        case .full: return Color.teal
        case .bonus: return Color.blue
        case .exempt: return Color.gray.opacity(0.05)
        }
    }
    
    // 生成从今天往前推 N 周的数据（以周日为开头）
    private func generateHeatmapData(columns: Int) -> [[Date?]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.logicalNow)
        let weekday = calendar.component(.weekday, from: today) // 1=Sun, 7=Sat
        
        let daysToSaturday = 7 - weekday
        let endOfThisWeek = calendar.date(byAdding: .day, value: daysToSaturday, to: today)!
        
        var grid: [[Date?]] = []
        
        for col in 0..<columns {
            let daysOffset = (columns - 1 - col) * 7
            let colEndDay = calendar.date(byAdding: .day, value: -daysOffset, to: endOfThisWeek)!
            
            var columnDates: [Date?] = []
            for row in 0..<7 {
                let rowDate = calendar.date(byAdding: .day, value: -(6 - row), to: colEndDay)!
                columnDates.append(rowDate)
            }
            grid.append(columnDates)
        }
        
        return grid
    }
}

// MARK: - 大号挂件的月份预览 (参数化)
struct MonthOverviewGrid: View {
    let entry: CheckInEntry
    var cellSize: CGFloat = 22
    var spacing: CGFloat = 4
    var fontSize: CGFloat = 11
    
    private let calendar = Calendar.current
    
    var body: some View {
        let days = CalendarHelper.allDaysInMonth(date: entry.date)
        let firstWeekday = CalendarHelper.firstWeekdayOfMonth(date: entry.date)
        let leadingEmptyDays = firstWeekday - 1
        let totalCells = leadingEmptyDays + days.count
        let rows = (totalCells + 6) / 7
        
        VStack(spacing: spacing) {
            // Weekday Header
            HStack(spacing: 0) {
                ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: fontSize - 3, weight: .bold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        let index = row * 7 + col - leadingEmptyDays
                        if index >= 0 && index < days.count {
                            let date = days[index]
                            let dayNumber = calendar.component(.day, from: date)
                            let isToday = calendar.isDate(date, inSameDayAs: Date.logicalNow)
                            let status = getStatus(for: date)
                            
                            ZStack {
                                RoundedRectangle(cornerRadius: cellSize * 0.25)
                                    .fill(cellColor(for: status))
                                    .opacity(date > Date.logicalNow ? 0.1 : 1.0)
                                    .padding(cellSize * 0.08)
                                
                                if isToday {
                                    RoundedRectangle(cornerRadius: cellSize * 0.25)
                                        .strokeBorder(Color.black.opacity(0.6), lineWidth: 1)
                                        .padding(cellSize * 0.08)
                                }
                                
                                Text("\(dayNumber)")
                                    .font(.system(size: fontSize, weight: isToday ? .heavy : .medium))
                                    .foregroundStyle(status == .full || status == .bonus ? Color.white : Color.black.opacity(0.8))
                            }
                            .frame(height: cellSize)
                            .frame(maxWidth: .infinity)
                            
                        } else {
                            Color.clear
                                .frame(height: cellSize)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }
    
    private func getStatus(for date: Date) -> CompletionStatus {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        let key = formatter.string(from: date)
        return entry.statuses[key] ?? .none
    }
    
    private func cellColor(for status: CompletionStatus) -> Color {
        switch status {
        case .none: return Color.black.opacity(0.04)
        case .partial: return Color.orange.opacity(0.35)
        case .full: return Color.red.opacity(0.65)
        case .bonus: return Color.purple.opacity(0.65)
        case .exempt: return Color.black.opacity(0.02)
        }
    }
}

// MARK: - 中号挂件：分栏 Dashboard 布局 (左侧操作/连胜，右侧月份日历)
struct MediumWidgetLayout: View {
    let entry: CheckInEntry
    
    var body: some View {
        HStack(spacing: 12) {
            // 左侧：打卡信息与按钮
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.calendarName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.85))
                
                // 连胜与累计合并型玻璃胶囊 (暗色半透明以适配亮色背景)
                HStack(spacing: 8) {
                    HStack(spacing: 2) {
                        Text("🔥").font(.system(size: 9))
                        Text("\(entry.consecutiveDays)d")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 220/255, green: 100/255, blue: 0))
                    }
                    
                    Divider()
                        .frame(width: 1, height: 10)
                        .background(Color.black.opacity(0.15))
                    
                    HStack(spacing: 2) {
                        Text("📊").font(.system(size: 9))
                        Text("\(entry.totalDays)d")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(red: 0, green: 130/255, blue: 130/255))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.black.opacity(0.08), lineWidth: 1)
                )
                .padding(.vertical, 2)
                
                Spacer()
                
                // 打卡按钮 (适配软件暖粉橘色调的渐变按钮)
                Button(intent: CheckInIntent()) {
                    HStack(spacing: 4) {
                        if entry.isTodayCheckedIn {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(red: 0, green: 150/255, blue: 80/255))
                            Text("Checked In")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(Color(red: 0, green: 150/255, blue: 80/255))
                        } else {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Check In Now")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background {
                        if entry.isTodayCheckedIn {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.green.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Color.green.opacity(0.15), lineWidth: 1)
                                )
                        } else {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(LinearGradient(colors: [Color(red: 255/255, green: 110/255, blue: 110/255), Color(red: 255/255, green: 150/255, blue: 90/255)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: Color.red.opacity(0.15), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // 右侧：紧凑型月份日历 (暗色半透明边框区块)
            VStack(spacing: 4) {
                Text(monthYearString(for: entry.date))
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                
                MonthOverviewGrid(entry: entry, cellSize: 12, spacing: 2, fontSize: 8)
            }
            .padding(8)
            .background(Color.black.opacity(0.02))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.black.opacity(0.05), lineWidth: 1)
            )
            .frame(width: 122)
        }
        .padding(.vertical, 2)
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }
}
