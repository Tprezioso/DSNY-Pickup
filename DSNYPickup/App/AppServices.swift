import DSNYKit
import SwiftUI

extension DisposalGuideService {
    /// Shared so the in-memory page cache survives navigation.
    static let shared = DisposalGuideService()
}

extension ReminderScheduler {
    static let shared = ReminderScheduler()
}

extension EnvironmentValues {
    @Entry var scheduleService = ScheduleService()
    @Entry var dropOffService = DropOffService()
    @Entry var disposalGuide: DisposalGuideService = .shared
}
