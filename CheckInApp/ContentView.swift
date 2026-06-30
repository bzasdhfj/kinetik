import SwiftUI
import WidgetKit
import Charts
import AppKit

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var streak: Int = CheckInStore.shared.consecutiveDays()
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            SidebarView(selectedTab: $selectedTab, streak: $streak)
                .frame(width: 200)
            
            // Divider
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Main View Area
            ZStack(alignment: .top) {
                switch selectedTab {
                case 0:
                    TasksView(date: Date.logicalNow, streak: $streak, isReadOnlyPast: false)
                case 1:
                    CalendarTab(streak: $streak)
                case 2:
                    StatisticsTab()
                case 3:
                    SettingsTab()
                default:
                    EmptyView()
                }
            }
            .padding(.top, 48) // Push content layer below title bar
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(GlassBackground())
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedTab)
        }
        .frame(minWidth: 880, minHeight: 620)
        .onAppear {
            refreshStreak()
        }
    }
    
    private func refreshStreak() {
        streak = CheckInStore.shared.consecutiveDays()
    }
}

// MARK: - 通用渐变背景
struct GlassBackground: View {
    var body: some View {
        ZStack {
            Image("AppBackground")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
            
            Color(nsColor: .windowBackgroundColor)
                .opacity(0.25)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
        }
    }
}

// MARK: - 侧边栏 View
struct SidebarView: View {
    @Binding var selectedTab: Int
    @Binding var streak: Int
    @State private var isHoveringTab: [Int: Bool] = [:]
    
    let tabs = [
        ("Today", "checklist"),
        ("Calendar", "calendar"),
        ("Analytics", "chart.xyaxis.line"),
        ("Settings", "gearshape")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // App Logo and Title
            HStack(spacing: 10) {
                if let iconImage = NSImage(named: NSImage.applicationIconName) {
                    Image(nsImage: iconImage)
                        .resizable()
                        .frame(width: 32, height: 32)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else {
                    Image(systemName: "leaf.fill")
                        .font(.title3)
                        .foregroundStyle(Color.teal)
                }
                
                Text("Kinetik")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.white, .secondary], startPoint: .top, endPoint: .bottom))
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
            
            // Navigation Links
            VStack(spacing: 4) {
                ForEach(0..<tabs.count, id: \.self) { idx in
                    Button(action: {
                        selectedTab = idx
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: tabs[idx].1)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(selectedTab == idx ? .white : .secondary)
                                .frame(width: 18, height: 18)
                            Text(tabs[idx].0)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .contentShape(Rectangle())
                        .foregroundStyle(selectedTab == idx ? Color.white : Color.primary.opacity(0.8))
                        .background(
                            ZStack {
                                if selectedTab == idx {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(LinearGradient(colors: [Color.teal.opacity(0.75), Color.blue.opacity(0.75)], startPoint: .leading, endPoint: .trailing))
                                } else if isHoveringTab[idx] ?? false {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.06))
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        withAnimation(.easeOut(duration: 0.15)) {
                            isHoveringTab[idx] = hovering
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            
            Spacer()
            
            // Streak Widget at bottom of Sidebar
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("🔥")
                        .font(.system(size: 16))
                    Text("\(streak)-day streak")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                Text("Consistency is key")
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 12)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
    }
}

// MARK: - 任务 Tab
struct TasksTab: View {
    @Binding var streak: Int
    var body: some View {
        TasksView(date: Date.logicalNow, streak: $streak, isReadOnlyPast: false)
    }
}

struct TasksView: View {
    let date: Date
    @Binding var streak: Int
    let isReadOnlyPast: Bool
    
    @Environment(\.dismiss) private var dismiss
    @State private var record: DailyRecord
    
    init(date: Date, streak: Binding<Int>, isReadOnlyPast: Bool) {
        self.date = date
        self._streak = streak
        self.isReadOnlyPast = isReadOnlyPast
        self._record = State(initialValue: CheckInStore.shared.getRecord(for: date))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            
            ScrollView {
                VStack(spacing: 20) {
                    let requiredTasks = record.tasks.filter { $0.isRequired }
                    if !requiredTasks.isEmpty {
                        TaskSectionView(
                            title: "Required Tasks",
                            icon: "star.fill",
                            tasks: requiredTasks,
                            isLocked: isReadOnlyPast
                        ) { taskId in
                            toggleTask(taskId)
                        }
                    }
                    
                    let bonusTasks = record.tasks.filter { !$0.isRequired }
                    if !bonusTasks.isEmpty {
                        TaskSectionView(
                            title: "Bonus Tasks (Optional)",
                            icon: "sparkles",
                            tasks: bonusTasks,
                            isLocked: false
                        ) { taskId in
                            toggleTask(taskId)
                        }
                    }
                    
                    if record.tasks.isEmpty {
                        EmptyStateView()
                    }
                }
                .frame(maxWidth: 600)
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
        .background(Color.clear)
        .onAppear {
            record = CheckInStore.shared.getRecord(for: date)
        }
    }
    
    private var headerView: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Calendar.current.isDateInToday(date) ? "Today's Tasks" : "\(date.formatted(.dateTime.month().day())) Tasks")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                if isReadOnlyPast {
                    Text("⚠️ Required tasks expired. Only bonus tasks can be checked in retroactively.")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                } else {
                    let reqTotal = record.tasks.filter { $0.isRequired }.count
                    let reqDone = record.tasks.filter { $0.isRequired && $0.isCompleted }.count
                    let optTotal = record.tasks.filter { !$0.isRequired }.count
                    let optDone = record.tasks.filter { !$0.isRequired && $0.isCompleted }.count
                    
                    Text("Required \(reqDone)/\(reqTotal)  •  Bonus \(optDone)/\(optTotal)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if isReadOnlyPast {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary.opacity(0.8))
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
                .hoverScale()
            }
        }
        .frame(maxWidth: 600)
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity)
    }
    
    private func toggleTask(_ taskId: UUID) {
        CheckInStore.shared.toggleTask(taskId: taskId, for: date)
        record = CheckInStore.shared.getRecord(for: date)
        streak = CheckInStore.shared.consecutiveDays()
        WidgetCenter.shared.reloadTimelines(ofKind: "CheckInCalendarWidget")
    }
}

struct TaskSectionView: View {
    let title: String
    let icon: String
    let tasks: [DailyTask]
    let isLocked: Bool
    let onToggle: (UUID) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                ForEach(tasks) { task in
                    TaskRowView(task: task, isLocked: isLocked) {
                        if !isLocked {
                            onToggle(task.id)
                        }
                    }
                    if task.id != tasks.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.06))
                            .padding(.leading, 48)
                    }
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 12, x: 0, y: 6)
        }
    }
}

struct TaskRowView: View {
    let task: DailyTask
    let isLocked: Bool
    let onToggle: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: {
                if !isLocked {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        onToggle()
                    }
                }
            }) {
                ZStack {
                    Circle()
                        .strokeBorder(isLocked ? Color.gray.opacity(0.3) : (task.isCompleted ? (task.isRequired ? Color.teal : Color.orange) : Color.gray.opacity(0.4)), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if task.isCompleted {
                        Circle()
                            .fill(isLocked ? Color.gray.opacity(0.3) : (task.isRequired ? Color.teal : Color.orange))
                            .frame(width: 22, height: 22)
                            .transition(.scale.combined(with: .opacity))
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(isLocked ? Color.gray : .white)
                    }
                }
            }
            .buttonStyle(.plain)
            .disabled(isLocked)
            
            Text(task.name)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(task.isCompleted ? .secondary : (isLocked ? .tertiary : .primary))
                .strikethrough(task.isCompleted, color: .secondary)
            
            Spacer()
            
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isHovered && !isLocked ? Color.teal.opacity(0.06) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isHovered && !isLocked ? Color.teal.opacity(0.15) : Color.clear, lineWidth: 1)
                )
        )
        .scaleEffect(isHovered && !isLocked ? 1.015 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isHovered)
        .onHover { hovered in
            isHovered = hovered
        }
        .onTapGesture {
            if !isLocked {
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    onToggle()
                }
            }
        }
    }
}

// MARK: - 日历 Tab
struct CalendarTab: View {
    @Binding var streak: Int
    @State private var displayedMonth: Date = Date.logicalNow
    @State private var refreshTrigger = 0
    @State private var selectedPastDate: Date? = nil
    
    private let calendar = Calendar.current
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                calendarCard
            }
            .frame(maxWidth: 600)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color.clear)
        .onAppear { refreshTrigger += 1 }
        .sheet(item: $selectedPastDate) { date in
            TasksView(date: date, streak: $streak, isReadOnlyPast: true)
                .frame(width: 400, height: 500)
        }
    }
    
    private var calendarCard: some View {
        VStack(spacing: 18) {
            monthNavigationBar
            weekdayHeaders
            dayGrid
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 25, x: 0, y: 12)
    }
    
    private var monthNavigationBar: some View {
        HStack {
            Button { withAnimation { shiftMonth(by: -1) } } label: { Image(systemName: "chevron.left.circle.fill").font(.title3).foregroundStyle(.teal) }.buttonStyle(.plain)
            Spacer()
            
            HStack(spacing: 12) {
                Text(monthYearString(for: displayedMonth))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                
                DatePicker("Jump to date", selection: $displayedMonth, displayedComponents: [.date])
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .environment(\.locale, Locale(identifier: "en_US"))
                    .frame(width: 105)
            }
            
            Spacer()
            Button { withAnimation { shiftMonth(by: 1) } } label: { Image(systemName: "chevron.right.circle.fill").font(.title3).foregroundStyle(.teal) }.buttonStyle(.plain)
        }
    }
    
    private var weekdayHeaders: some View {
        let symbols = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return HStack(spacing: 0) {
            ForEach(symbols, id: \.self) { symbol in
                Text(symbol).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(.secondary).frame(maxWidth: .infinity)
            }
        }
    }
    
    private var dayGrid: some View {
        let days = daysInMonth(for: displayedMonth)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
        
        return LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days, id: \.self) { day in
                if let day {
                    dayCell(for: day)
                        .onTapGesture {
                            handleDayTap(date: day)
                        }
                } else {
                    Color.clear.frame(height: 42)
                }
            }
        }
        .id(refreshTrigger)
    }
    
    @ViewBuilder
    private func dayCell(for date: Date) -> some View {
        let isToday = calendar.isDate(date, inSameDayAs: Date.logicalNow)
        let dayNumber = calendar.component(.day, from: date)
        let isFuture = calendar.startOfDay(for: date) > calendar.startOfDay(for: Date.logicalNow)
        let status = isFuture ? .none : CheckInStore.shared.status(for: date)
        
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(cellBackgroundColor(status: status, isToday: isToday))
                .opacity(isFuture ? 0.3 : 1.0)
            
            if isToday {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.teal, lineWidth: 1.5)
            }
            
            if status == .bonus {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.yellow)
                    .offset(x: 12, y: -12)
            }
            
            Text("\(dayNumber)")
                .font(.system(size: 14, weight: isToday ? .heavy : .medium, design: .rounded))
                .foregroundStyle(cellForegroundColor(status: status, isToday: isToday, isFuture: isFuture))
        }
        .frame(height: 42)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .hoverScale(disabled: isFuture)
    }
    
    private func cellBackgroundColor(status: CompletionStatus, isToday: Bool) -> some ShapeStyle {
        switch status {
        case .none:
            return AnyShapeStyle(Color.gray.opacity(0.1))
        case .partial:
            return AnyShapeStyle(Color.green.opacity(0.25))
        case .full:
            return AnyShapeStyle(Color.teal.opacity(0.75))
        case .bonus:
            return AnyShapeStyle(LinearGradient(colors: [.teal, .blue], startPoint: .topLeading, endPoint: .bottomTrailing))
        case .exempt:
            return AnyShapeStyle(Color.gray.opacity(0.04))
        }
    }
    
    private func cellForegroundColor(status: CompletionStatus, isToday: Bool, isFuture: Bool) -> some ShapeStyle {
        if status == .full || status == .bonus {
            return AnyShapeStyle(Color.white)
        } else if isFuture {
            return AnyShapeStyle(Color.gray.opacity(0.3))
        } else if status == .partial {
            return AnyShapeStyle(Color.primary)
        } else {
            return AnyShapeStyle(Color.secondary)
        }
    }
    
    private func handleDayTap(date: Date) {
        let today = calendar.startOfDay(for: Date.logicalNow)
        let target = calendar.startOfDay(for: date)
        if target < today {
            selectedPastDate = target
        }
    }
    
    private func shiftMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: displayedMonth) {
            displayedMonth = newMonth
        }
    }
    
    private func monthYearString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func daysInMonth(for date: Date) -> [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else { return [] }
        
        let weekdayOfFirst = calendar.component(.weekday, from: firstOfMonth) - 1
        var cells: [Date?] = Array(repeating: nil, count: weekdayOfFirst)
        for day in range {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth) {
                cells.append(dayDate)
            }
        }
        return cells
    }
}

extension Date: @retroactive Identifiable {
    public var id: Date { self }
}

// MARK: - 统计分析 Tab
struct StatisticsTab: View {
    @State private var totalDays = 0
    @State private var longestStreak = 0
    @State private var reqTasksDone = 0
    @State private var reqTasksTotal = 0
    @State private var bonusTasksDone = 0
    @State private var trendData: [(date: Date, count: Int)] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                statsGrid
                chartCard
            }
            .frame(maxWidth: 800)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color.clear)
        .onAppear {
            refreshData()
        }
    }
    
    private var header: some View {
        Text("Analytics & Trends")
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .foregroundStyle(LinearGradient(colors: [.white, .secondary], startPoint: .leading, endPoint: .trailing))
            .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var statsGrid: some View {
        let rate = reqTasksTotal > 0 ? Int((Double(reqTasksDone) / Double(reqTasksTotal)) * 100) : 0
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            statCard(title: "Completion Rate", value: "\(rate)%", icon: "percent", color: .green)
            statCard(title: "Total Days", value: "\(totalDays)", icon: "calendar.badge.checkmark", color: .blue)
            statCard(title: "Longest Streak", value: "\(longestStreak)", icon: "flame.fill", color: .orange)
            statCard(title: "Required Tasks", value: "\(reqTasksDone)/\(reqTasksTotal)", icon: "star.fill", color: .teal)
            statCard(title: "Bonus Rewards", value: "\(bonusTasksDone)", icon: "sparkles", color: .purple)
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
    }
    
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last 14 Days Trend")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            
            Chart {
                ForEach(trendData, id: \.date) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Tasks", item.count)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.teal)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Date", item.date),
                        y: .value("Tasks", item.count)
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(LinearGradient(colors: [Color.teal.opacity(0.25), Color.clear], startPoint: .top, endPoint: .bottom))
                    
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Tasks", item.count)
                    )
                    .foregroundStyle(Color.orange)
                    .symbolSize(40)
                }
            }
            .frame(height: 220)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 2)) { _ in
                    AxisValueLabel(format: .dateTime.month().day())
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 8)
    }
    
    private func refreshData() {
        totalDays = CheckInStore.shared.totalCheckInDays()
        longestStreak = CheckInStore.shared.longestStreak()
        reqTasksDone = CheckInStore.shared.totalRequiredTasksCompleted()
        reqTasksTotal = CheckInStore.shared.totalRequiredTasksScheduled()
        bonusTasksDone = CheckInStore.shared.totalBonusTasksCompleted()
        trendData = CheckInStore.shared.completionTrend(days: 14)
    }
}

// MARK: - 设置 Tab
struct SettingsTab: View {
    @State private var calendarName = CheckInStore.shared.calendarName
    @State private var templates = CheckInStore.shared.templates
    @State private var newTaskName = ""
    @State private var newTaskIsRequired = true
    @State private var newTaskFrequency: String = "everyday"
    @State private var newSpecificDates: [Date] = []
    @State private var dateToAdd = Date.logicalNow
    @State private var showResetAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Settings")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(LinearGradient(colors: [.white, .secondary], startPoint: .leading, endPoint: .trailing))
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Calendar Name
                VStack(alignment: .leading, spacing: 12) {
                    Text("Basic Config")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text("Calendar Title")
                            .font(.system(size: 13, design: .rounded))
                        Spacer()
                        TextField("daily", text: $calendarName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 180)
                            .onChange(of: calendarName) { _, newValue in
                                CheckInStore.shared.calendarName = newValue
                                WidgetCenter.shared.reloadTimelines(ofKind: "CheckInCalendarWidget")
                            }
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                
                // Add New Task Form
                VStack(alignment: .leading, spacing: 12) {
                    Text("Add Habit template")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        TextField("Habit name...", text: $newTaskName)
                            .textFieldStyle(.roundedBorder)
                        
                        Picker("Task Priority", selection: $newTaskIsRequired) {
                            Text("Core Habit").tag(true)
                            Text("Optional Bonus").tag(false)
                        }
                        .pickerStyle(.segmented)
                        
                        Picker("Frequency Schedule", selection: $newTaskFrequency) {
                            Text("Everyday").tag("everyday")
                            Text("Weekdays").tag("weekdays")
                            Text("Weekends").tag("weekends")
                            Text("Specific Dates").tag("specificDates")
                        }
                        
                        if newTaskFrequency == "specificDates" {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    DatePicker("", selection: $dateToAdd, displayedComponents: .date)
                                        .labelsHidden()
                                    Button("Add Date") {
                                        if !newSpecificDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: dateToAdd) }) {
                                            newSpecificDates.append(dateToAdd)
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                }
                                if !newSpecificDates.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(newSpecificDates, id: \.self) { date in
                                                HStack(spacing: 4) {
                                                    Text(date.formatted(.dateTime.month().day()))
                                                    Image(systemName: "xmark")
                                                        .font(.system(size: 8, weight: .bold))
                                                }
                                                .font(.system(size: 11, design: .rounded))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.teal.opacity(0.15), in: Capsule())
                                                .onTapGesture {
                                                    newSpecificDates.removeAll { $0 == date }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Button(action: {
                            guard !newTaskName.isEmpty else { return }
                            let frequency: TaskFrequency
                            switch newTaskFrequency {
                            case "everyday": frequency = .everyday
                            case "weekdays": frequency = .weekdays
                            case "weekends": frequency = .weekends
                            case "specificDates":
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd"
                                formatter.locale = Locale(identifier: "en_US_POSIX")
                                formatter.timeZone = .current
                                let strings = newSpecificDates.map { formatter.string(from: $0) }
                                frequency = .specificDates(strings)
                            default: frequency = .everyday
                            }
                            
                            let newT = TaskTemplate(name: newTaskName, isRequired: newTaskIsRequired, sortOrder: templates.count, frequency: frequency)
                            withAnimation {
                                templates.append(newT)
                                newTaskName = ""
                                newSpecificDates.removeAll()
                                newTaskFrequency = "everyday"
                            }
                            saveTemplates()
                        }) {
                            Text("Create Task Template")
                                .frame(maxWidth: .infinity)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .disabled(newTaskName.isEmpty || (newTaskFrequency == "specificDates" && newSpecificDates.isEmpty))
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(16)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                
                // Templates List
                VStack(alignment: .leading, spacing: 12) {
                    Text("Existing Habits")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                    
                    VStack(spacing: 0) {
                        ForEach($templates) { $template in
                            HStack(spacing: 12) {
                                TextField("Task Name", text: $template.name)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13, design: .rounded))
                                
                                Spacer()
                                
                                Text(frequencyString(for: template.frequency))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.white.opacity(0.08), in: Capsule())
                                
                                Picker("", selection: $template.isRequired) {
                                    Text("Req").tag(true)
                                    Text("Opt").tag(false)
                                }
                                .pickerStyle(.menu)
                                .frame(width: 55)
                                .font(.system(size: 11))
                                
                                Button(action: {
                                    if let idx = templates.firstIndex(where: { $0.id == template.id }) {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            templates.remove(at: idx)
                                        }
                                        saveTemplates()
                                    }
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red)
                                        .font(.subheadline)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            
                            if template.id != templates.last?.id {
                                Divider()
                                    .background(Color.white.opacity(0.06))
                            }
                        }
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                
                // Danger Zone
                VStack(alignment: .leading, spacing: 12) {
                    Text("Danger Zone")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.red.opacity(0.8))
                    
                    Button(role: .destructive) {
                        showResetAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Reset All Data")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(.red)
                        .background(Color.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.2), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: 600)
            .padding(24)
            .frame(maxWidth: .infinity)
        }
        .background(Color.clear)
        .alert("Reset All Data?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                withAnimation {
                    CheckInStore.shared.resetAllData()
                    calendarName = CheckInStore.shared.calendarName
                    templates = CheckInStore.shared.templates
                    WidgetCenter.shared.reloadTimelines(ofKind: "CheckInCalendarWidget")
                }
            }
        } message: {
            Text("This will permanently delete all your check-in records and reset your tasks to defaults. This action cannot be undone.")
        }
        .onChange(of: templates) { _, _ in
            saveTemplates()
        }
    }
    
    private func frequencyString(for freq: TaskFrequency) -> String {
        switch freq {
        case .everyday: return "Everyday"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .specificWeekdays(_): return "Custom"
        case .specificDates(let dates): return "\(dates.count) Dates"
        }
    }
    
    private func saveTemplates() {
        for i in templates.indices {
            templates[i].sortOrder = i
        }
        CheckInStore.shared.templates = templates
        WidgetCenter.shared.reloadTimelines(ofKind: "CheckInCalendarWidget")
    }
}

struct HoverScaleModifier: ViewModifier {
    let disabled: Bool
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered && !disabled ? 1.05 : 1.0)
            .shadow(color: isHovered && !disabled ? Color.teal.opacity(0.25) : .clear, radius: isHovered ? 6 : 0, x: 0, y: 3)
            .animation(.spring(response: 0.25, dampingFraction: 0.65), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func hoverScale(disabled: Bool = false) -> some View {
        modifier(HoverScaleModifier(disabled: disabled))
    }
}

struct EmptyStateView: View {
    @State private var isFloating = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.teal.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.teal)
                    .offset(y: isFloating ? -5 : 5)
                    .animation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isFloating)
            }
            .padding(.bottom, 8)
            
            Text("No tasks yet")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
            
            Text("Add your first task in Settings to start building habits.")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.top, 80)
        .onAppear {
            isFloating = true
        }
    }
}
