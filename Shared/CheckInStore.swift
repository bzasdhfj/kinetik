import Foundation

// MARK: - Date Helper for 3 AM cutoff
extension Date {
    static var logicalNow: Date {
        // Shift time back by 3 hours. 
        // 00:00 - 02:59 will be treated as the previous day.
        return Date().addingTimeInterval(-3 * 3600)
    }
}

// MARK: - 数据模型


enum TaskFrequency: Codable, Equatable, Hashable {
    case everyday
    case weekdays
    case weekends
    case specificWeekdays([Int]) // 1=Sun, 2=Mon...
    case specificDates([String]) // "yyyy-MM-dd"
}

enum TaskPriority: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct TaskTemplate: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var isRequired: Bool
    var sortOrder: Int
    var frequency: TaskFrequency = .everyday
    var priority: TaskPriority = .medium
    
    enum CodingKeys: String, CodingKey {
        case id, name, isRequired, sortOrder, frequency, priority
    }
    
    init(id: UUID = UUID(), name: String, isRequired: Bool, sortOrder: Int, frequency: TaskFrequency = .everyday, priority: TaskPriority = .medium) {
        self.id = id
        self.name = name
        self.isRequired = isRequired
        self.sortOrder = sortOrder
        self.frequency = frequency
        self.priority = priority
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        name = try container.decode(String.self, forKey: .name)
        isRequired = try container.decode(Bool.self, forKey: .isRequired)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        frequency = try container.decodeIfPresent(TaskFrequency.self, forKey: .frequency) ?? .everyday
        priority = try container.decodeIfPresent(TaskPriority.self, forKey: .priority) ?? .medium
    }
    
    func matches(date: Date) -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        let dateString = formatter.string(from: date)
        
        switch frequency {
        case .everyday: return true
        case .weekdays: return weekday >= 2 && weekday <= 6
        case .weekends: return weekday == 1 || weekday == 7
        case .specificWeekdays(let days): return days.contains(weekday)
        case .specificDates(let dates): return dates.contains(dateString)
        }
    }
}

struct DailyTask: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let templateId: UUID
    var name: String
    var isRequired: Bool
    var isCompleted: Bool
    var priority: TaskPriority = .medium
    
    enum CodingKeys: String, CodingKey {
        case id, templateId, name, isRequired, isCompleted, priority
    }
    
    init(id: UUID = UUID(), templateId: UUID, name: String, isRequired: Bool, isCompleted: Bool, priority: TaskPriority = .medium) {
        self.id = id
        self.templateId = templateId
        self.name = name
        self.isRequired = isRequired
        self.isCompleted = isCompleted
        self.priority = priority
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        templateId = try container.decode(UUID.self, forKey: .templateId)
        name = try container.decode(String.self, forKey: .name)
        isRequired = try container.decode(Bool.self, forKey: .isRequired)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        priority = try container.decodeIfPresent(TaskPriority.self, forKey: .priority) ?? .medium
    }
}

enum CompletionStatus: String, Codable, Equatable {
    case none       // 没做
    case partial    // 部分必须
    case full       // 所有必须
    case bonus      // 所有必须+附加
    case exempt     // 豁免（今天没有任何必做任务）
}

struct DailyRecord: Codable, Equatable {
    var tasks: [DailyTask]
    
    var completionStatus: CompletionStatus {
        if tasks.isEmpty { return .exempt }
        
        let requiredTasks = tasks.filter { $0.isRequired }
        let bonusTasks = tasks.filter { !$0.isRequired }
        
        let requiredCompleted = requiredTasks.filter { $0.isCompleted }.count
        let bonusCompleted = bonusTasks.filter { $0.isCompleted }.count
        
        if requiredCompleted == 0 && bonusCompleted == 0 {
            return requiredTasks.isEmpty ? .exempt : .none
        }
        
        if requiredTasks.isEmpty {
            if bonusCompleted > 0 {
                return bonusCompleted == bonusTasks.count ? .bonus : .partial
            } else {
                return .exempt
            }
        }
        
        if requiredCompleted < requiredTasks.count {
            return .partial
        }
        
        if bonusTasks.isEmpty || bonusCompleted < bonusTasks.count {
            return .full
        }
        
        return .bonus
    }
}

struct CheckInData: Codable {
    var calendarName: String = "每日打卡"
    var templates: [TaskTemplate] = []
    var records: [String: DailyRecord] = [:]
}

// MARK: - 打卡数据存储管理器
final class CheckInStore {

    static let shared = CheckInStore()

    private var inMemoryData: CheckInData

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        return f
    }()
    
    private var sharedFileURL: URL {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        
        // 判断当前是在沙盒内（Widget）还是沙盒外（Main App）
        let isSandboxed = home.path.contains("Containers")
        
        let targetDir: URL
        if isSandboxed {
            // Widget 在沙盒内，直接用 Documents
            targetDir = home.appendingPathComponent("Documents")
        } else {
            // 主 App 不在沙盒内，强制写入到 Widget 的沙盒
            targetDir = home.appendingPathComponent("Library/Containers/com.checkin.calendar.widget/Data/Documents")
        }
        
        if !fileManager.fileExists(atPath: targetDir.path) {
            try? fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
        }
        
        return targetDir.appendingPathComponent("checkin_data.json")
    }

    private init() {
        self.inMemoryData = CheckInData()
        loadData()
        
        if self.inMemoryData.templates.isEmpty {
            self.inMemoryData.templates = [
                TaskTemplate(name: "喝杯水", isRequired: true, sortOrder: 0),
                TaskTemplate(name: "运动30分钟", isRequired: true, sortOrder: 1),
                TaskTemplate(name: "阅读10页书", isRequired: false, sortOrder: 2)
            ]
            saveData()
        }
    }
    
    private func loadData() {
        if let data = try? Data(contentsOf: sharedFileURL),
           let decoded = try? JSONDecoder().decode(CheckInData.self, from: data) {
            self.inMemoryData = decoded
        }
    }
    
    private func saveData() {
        if let encoded = try? JSONEncoder().encode(inMemoryData) {
            try? encoded.write(to: sharedFileURL, options: .atomic)
        }
    }

    // MARK: - 日历名称
    
    var calendarName: String {
        get {
            loadData() // 获取最新
            return inMemoryData.calendarName
        }
        set {
            inMemoryData.calendarName = newValue
            saveData()
        }
    }

    // MARK: - 模板管理
    
    var templates: [TaskTemplate] {
        get {
            loadData()
            return inMemoryData.templates.sorted { $0.sortOrder < $1.sortOrder }
        }
        set {
            inMemoryData.templates = newValue
            saveData()
        }
    }
    
    // MARK: - 每日记录管理
    
    func getRecord(for date: Date) -> DailyRecord {
        loadData()
        let key = formatter.string(from: date)
        
        var record: DailyRecord
        if let existingRecord = inMemoryData.records[key] {
            record = existingRecord
        } else {
            record = DailyRecord(tasks: [])
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.logicalNow)
        let targetDate = calendar.startOfDay(for: date)
        
        // 对于今天和未来的日子，始终与最新的模板同步
        if targetDate >= today {
            let currentTemplates = templates
            var syncedTasks: [DailyTask] = []
            
            for template in currentTemplates {
                if template.matches(date: targetDate) {
                    if let existingTask = record.tasks.first(where: { $0.templateId == template.id }) {
                        var updatedTask = existingTask
                        updatedTask.name = template.name
                        updatedTask.isRequired = template.isRequired
                        updatedTask.priority = template.priority // Sync priority
                        syncedTasks.append(updatedTask)
                    } else {
                        syncedTasks.append(DailyTask(templateId: template.id, name: template.name, isRequired: template.isRequired, isCompleted: false, priority: template.priority))
                    }
                }
            }
            
            record.tasks = syncedTasks
            inMemoryData.records[key] = record
            saveData()
        } else {
            // 对于过去的日子，如果原本没有记录，就用当前的模板生成（全未完成）
            if inMemoryData.records[key] == nil {
                let currentTemplates = templates
                record.tasks = currentTemplates.filter { $0.matches(date: targetDate) }.map { t in
                    DailyTask(templateId: t.id, name: t.name, isRequired: t.isRequired, isCompleted: false, priority: t.priority)
                }
                inMemoryData.records[key] = record
                saveData()
            }
        }
        
        return record
    }

    func saveRecord(_ record: DailyRecord, for date: Date) {
        let key = formatter.string(from: date)
        inMemoryData.records[key] = record
        saveData()
    }
    
    func toggleTask(taskId: UUID, for date: Date) {
        var record = getRecord(for: date)
        if let index = record.tasks.firstIndex(where: { $0.id == taskId }) {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date.logicalNow)
            let taskDate = calendar.startOfDay(for: date)
            let task = record.tasks[index]
            
            // 补签规则：过去的必做任务不允许修改
            if taskDate < today && task.isRequired {
                return
            }
            
            record.tasks[index].isCompleted.toggle()
            saveRecord(record, for: date)
        }
    }
    
    // MARK: - 状态查询

    func status(for date: Date) -> CompletionStatus {
        let key = formatter.string(from: date)
        if let record = inMemoryData.records[key] {
            return record.completionStatus
        }
        let requiredTemplates = templates.filter { $0.isRequired && $0.matches(date: date) }
        return requiredTemplates.isEmpty ? .exempt : .none
    }

    func isTodayCheckedIn() -> Bool {
        let st = status(for: Date.logicalNow)
        return st == .full || st == .bonus || st == .exempt
    }

    // MARK: - 连续打卡天数计算

    func consecutiveDays() -> Int {
        loadData()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.logicalNow)

        let startDate: Date
        let todayStatus = status(for: today)
        
        if todayStatus == .full || todayStatus == .bonus || todayStatus == .exempt {
            startDate = today
        } else {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else {
                return 0
            }
            startDate = yesterday
        }

        var streak = 0
        var currentDate = startDate

        while true {
            let st = status(for: currentDate)
            if st == .full || st == .bonus {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else if st == .exempt {
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else {
                break
            }
        }

        return streak
    }
    
    // MARK: - 统计分析 (Analytics)
    
    func longestStreak() -> Int {
        loadData()
        let calendar = Calendar.current
        guard let firstDateStr = inMemoryData.records.keys.min(),
              let firstDate = formatter.date(from: firstDateStr) else { return 0 }
              
        let today = calendar.startOfDay(for: Date.logicalNow)
        var maxStreak = 0
        var currentStreak = 0
        var currentDate = firstDate
        
        while currentDate <= today {
            let st = status(for: currentDate)
            
            if st == .full || st == .bonus {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else if st == .exempt {
                // Pause streak, do not break
            } else {
                currentStreak = 0
            }
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }
        return maxStreak
    }
    
    func totalCheckInDays() -> Int {
        loadData()
        let dates = inMemoryData.records.keys.compactMap { formatter.date(from: $0) }
        var count = 0
        for date in dates {
            let st = status(for: date)
            if st == .full || st == .bonus {
                count += 1
            }
        }
        return count
    }
    
    func totalRequiredTasksCompleted() -> Int {
        loadData()
        return inMemoryData.records.values.reduce(0) { total, record in
            total + record.tasks.filter { $0.isRequired && $0.isCompleted }.count
        }
    }
    
    func totalRequiredTasksScheduled() -> Int {
        loadData()
        return inMemoryData.records.values.reduce(0) { total, record in
            total + record.tasks.filter { $0.isRequired }.count
        }
    }
    
    func totalBonusTasksCompleted() -> Int {
        loadData()
        return inMemoryData.records.values.reduce(0) { total, record in
            total + record.tasks.filter { !$0.isRequired && $0.isCompleted }.count
        }
    }
    
    func completionTrend(days: Int = 14) -> [(date: Date, count: Int)] {
        loadData()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date.logicalNow)
        var trend: [(date: Date, count: Int)] = []
        
        for i in (0..<days).reversed() {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let key = formatter.string(from: date)
                var count = 0
                if let record = inMemoryData.records[key] {
                    count = record.tasks.filter { $0.isCompleted }.count
                }
                trend.append((date: date, count: count))
            }
        }
        return trend
    }
    
    // MARK: - Widget 帮助方法
    
    func getStatuses(around date: Date) -> [String: CompletionStatus] {
        loadData()
        let calendar = Calendar.current
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date)),
              let startOfPrevMonth = calendar.date(byAdding: .month, value: -1, to: startOfMonth),
              let endOfNextMonth = calendar.date(byAdding: .month, value: 2, to: startOfMonth) else {
            return [:]
        }
        
        var statuses: [String: CompletionStatus] = [:]
        var current = startOfPrevMonth
        
        while current < endOfNextMonth {
            let key = formatter.string(from: current)
            if let record = inMemoryData.records[key] {
                if record.completionStatus != .none {
                    statuses[key] = record.completionStatus
                }
            }
            current = calendar.date(byAdding: .day, value: 1, to: current)!
        }
        return statuses
    }
    
    // MARK: - 重置数据
    
    func resetAllData() {
        inMemoryData.records.removeAll()
        inMemoryData.templates = [
            TaskTemplate(name: "喝杯水", isRequired: true, sortOrder: 0),
            TaskTemplate(name: "运动30分钟", isRequired: true, sortOrder: 1),
            TaskTemplate(name: "阅读10页书", isRequired: false, sortOrder: 2)
        ]
        inMemoryData.calendarName = "每日打卡"
        saveData()
    }
}
