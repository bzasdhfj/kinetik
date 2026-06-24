import AppIntents
import WidgetKit

/// 用户可通过长按小组件进入编辑模式，自定义日历名称
struct CheckInWidgetConfigIntent: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Widget Configuration"
    static var description: IntentDescription = "Configure your tracking widget"

    /// 日历名称参数，用户可在小组件编辑界面修改
    @Parameter(title: "Tracker Name", default: "Daily Check-In")
    var calendarName: String

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
