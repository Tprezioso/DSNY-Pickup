import DSNYKit
import SwiftUI

extension DisposalGuideService {
    /// Shared so the in-memory page cache survives navigation.
    static let shared = DisposalGuideService()
}

extension ReminderScheduler {
    static let shared = ReminderScheduler()
}

extension ServiceCalendarService {
    /// Configured from `NYC311APIKey` in Info.plist (set via Config/Secrets.xcconfig).
    /// `nil` when no key is set, which turns service change features off.
    static let fromBundle: ServiceCalendarService? = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "NYC311APIKey") as? String,
              !key.isEmpty, !key.hasPrefix("$(") else { return nil }
        return ServiceCalendarService(apiKey: key)
    }()
}

extension EnvironmentValues {
    @Entry var scheduleService = ScheduleService()
    @Entry var dropOffService = DropOffService()
    @Entry var disposalGuide: DisposalGuideService = .shared
}
