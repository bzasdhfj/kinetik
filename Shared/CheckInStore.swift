import Foundation

// MARK: - 数据模型

struct TaskTemplate: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    var isRequired: Bool
    var sortOrder: Int
}

struct DailyTask: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    let templateId: UUID
    var name: String
    var isRequired: Bool
    var isCompleted: Bool
}

enum CompletionStatus: String, Codable, Equatable {
    case none       // 没做
    case partial    // 部分必须
    case full       // 所有必须
    case bonus      // 所有必须+附加
}

struct DailyRecord: Codable, Equatable {
    var tasks: [DailyTask]
    
    var completionStatus: CompletionStatus {
        if tasks.isEmpty { return .none }
        
        let requiredTasks = tasks.filter { $0.isRequired }
        let bonusTasks = tasks.filter { !$0.isRequired }
        
        let requiredCompleted = requiredTasks.filter { $0.isCompleted }.count
        let bonusCompleted = bonusTasks.filter { $0.isCompleted }.count
        
        if requiredCompleted == 0 && bonusCompleted == 0 {
            return .none
        }
        
        if requiredTasks.isEmpty {
            return bonusCompleted == bonusTasks.count ? .bonus : .partial
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
        let today = calendar.startOfDay(for: Date())
        let targetDate = calendar.startOfDay(for: date)
        
        // 对于今天和未来的日子，始终与最新的模板同步
        if targetDate >= today {
            let currentTemplates = templates
            var syncedTasks: [DailyTask] = []
            
            for template in currentTemplates {
                if let existingTask = record.tasks.first(where: { $0.templateId == template.id }) {
                    // 保留完成状态，但更新名称和是否必做的属性
                    var updatedTask = existingTask
                    updatedTask.name = template.name
                    updatedTask.isRequired = template.isRequired
                    syncedTasks.append(updatedTask)
                } else {
                    // 这是在设置里新加的任务
                    syncedTasks.append(DailyTask(templateId: template.id, name: template.name, isRequired: template.isRequired, isCompleted: false))
                }
            }
            
            record.tasks = syncedTasks
            inMemoryData.records[key] = record
            saveData()
        } else {
            // 对于过去的日子，如果原本没有记录，就用当前的模板生成（全未完成）
            if inMemoryData.records[key] == nil {
                let currentTemplates = templates
                record.tasks = currentTemplates.map { t in
                    DailyTask(templateId: t.id, name: t.name, isRequired: t.isRequired, isCompleted: false)
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
            let today = calendar.startOfDay(for: Date())
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
        return .none
    }

    func isTodayCheckedIn() -> Bool {
        let st = status(for: Date())
        return st == .full || st == .bonus
    }

    // MARK: - 连续打卡天数计算

    func consecutiveDays() -> Int {
        loadData()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let startDate: Date
        let todayStatus = status(for: today)
        
        if todayStatus == .full || todayStatus == .bonus {
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
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else {
                    break
                }
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
        var maxStreak = 0
        var currentStreak = 0
        
        // 我们需要找出所有打卡的日期并排序
        let dates = inMemoryData.records.keys.compactMap { formatter.date(from: $0) }.sorted()
        
        for i in 0..<dates.count {
            let st = status(for: dates[i])
            if st == .full || st == .bonus {
                if currentStreak == 0 {
                    currentStreak = 1
                } else if i > 0 {
                    let prevDate = dates[i-1]
                    if calendar.isDate(dates[i], inSameDayAs: calendar.date(byAdding: .day, value: 1, to: prevDate)!) {
                        currentStreak += 1
                    } else if st == .full || st == .bonus { // 中断了，重新开始
                        currentStreak = 1
                    }
                }
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 0
            }
        }
        return maxStreak
    }
    
    func totalRequiredTasksCompleted() -> Int {
        loadData()
        return inMemoryData.records.values.reduce(0) { total, record in
            total + record.tasks.filter { $0.isRequired && $0.isCompleted }.count
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
        let today = calendar.startOfDay(for: Date())
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
}
