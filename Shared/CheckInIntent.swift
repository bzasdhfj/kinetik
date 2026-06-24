import AppIntents
import WidgetKit

// MARK: - 每日签到 AppIntent
/// 用于 Widget 按钮交互，切换今日打卡状态
struct CheckInIntent: AppIntent {

    /// Intent 标题（系统展示用）
    static var title: LocalizedStringResource = "每日签到"

    /// 执行打卡/取消打卡操作
    /// - 如果今天已打卡，则取消打卡
    /// - 如果今天未打卡，则标记为已打卡
    /// - 操作完成后刷新 Widget 时间线
    func perform() async throws -> some IntentResult {
        let store = CheckInStore.shared
        let today = Date()

        if store.isTodayCheckedIn() {
            var record = store.getRecord(for: today)
            for i in record.tasks.indices {
                record.tasks[i].isCompleted = false
            }
            store.saveRecord(record, for: today)
        } else {
            var record = store.getRecord(for: today)
            for i in record.tasks.indices where record.tasks[i].isRequired {
                record.tasks[i].isCompleted = true
            }
            store.saveRecord(record, for: today)
        }

        WidgetCenter.shared.reloadTimelines(ofKind: "CheckInCalendarWidget")

        return .result()
    }
}
