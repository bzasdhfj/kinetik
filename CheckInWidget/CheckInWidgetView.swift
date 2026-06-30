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
                HeatmapWidgetLayout(entry: entry, columns: 16)
            case .systemLarge:
                VStack(spacing: 12) {
                    HeatmapWidgetLayout(entry: entry, columns: 16)
                    
                    Divider().padding(.vertical, 4)
                    
                    // Large widget can also show the month grid
                    Text("Recent Activity")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    MonthOverviewGrid(entry: entry)
                }
            default:
                HeatmapWidgetLayout(entry: entry, columns: 16)
            }
        }
        .containerBackground(for: .widget) {
            ZStack {
                Image("WidgetBackgroundImage")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                
                Color(nsColor: .windowBackgroundColor)
                    .opacity(0.3)
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
                
                // Streak
                HStack(spacing: 2) {
                    Text("🔥").font(.system(size: 12))
                    Text("\(entry.consecutiveDays) days")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(Color.orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.12), in: Capsule())
            }
            
            // Heatmap Grid
            HStack(spacing: 3) {
                // Y-Axis labels (Weekdays)
                VStack(spacing: 3) {
                    Text("S").font(.system(size: 7)).foregroundStyle(.tertiary).frame(height: 10)
                    Text("").font(.system(size: 7)).frame(height: 10)
                    Text("T").font(.system(size: 7)).foregroundStyle(.tertiary).frame(height: 10)
                    Text("").font(.system(size: 7)).frame(height: 10)
                    Text("T").font(.system(size: 7)).foregroundStyle(.tertiary).frame(height: 10)
                    Text("").font(.system(size: 7)).frame(height: 10)
                    Text("S").font(.system(size: 7)).foregroundStyle(.tertiary).frame(height: 10)
                }
                
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
                            .foregroundStyle(.green)
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
                            .fill(Color.green.opacity(0.12))
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

// MARK: - 大号挂件的月份预览
struct MonthOverviewGrid: View {
    let entry: CheckInEntry
    private let calendar = Calendar.current
    
    var body: some View {
        let days = CalendarHelper.allDaysInMonth(date: entry.date)
        let firstWeekday = CalendarHelper.firstWeekdayOfMonth(date: entry.date)
        let leadingEmptyDays = firstWeekday - 1
        let totalCells = leadingEmptyDays + days.count
        let rows = (totalCells + 6) / 7
        
        VStack(spacing: 4) {
            // Weekday Header
            HStack(spacing: 0) {
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .bold))
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
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(cellColor(for: status))
                                    .opacity(date > Date.logicalNow ? 0.1 : 1.0)
                                    .padding(2)
                                
                                if isToday {
                                    RoundedRectangle(cornerRadius: 6)
                                        .strokeBorder(Color.teal, lineWidth: 1.5)
                                        .padding(2)
                                }
                                
                                Text("\(dayNumber)")
                                    .font(.system(size: 12, weight: isToday ? .heavy : .medium))
                                    .foregroundStyle(status == .full || status == .bonus ? Color.white : .primary)
                            }
                            .frame(height: 24)
                            .frame(maxWidth: .infinity)
                            
                        } else {
                            Color.clear
                                .frame(height: 24)
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
        formatter.timeZone = .current
        let key = formatter.string(from: date)
        return entry.statuses[key] ?? .none
    }
    
    private func cellColor(for status: CompletionStatus) -> Color {
        switch status {
        case .none: return Color.gray.opacity(0.1)
        case .partial: return Color.green.opacity(0.3)
        case .full: return Color.teal.opacity(0.8)
        case .bonus: return Color.blue.opacity(0.8)
        case .exempt: return Color.gray.opacity(0.05)
        }
    }
}
