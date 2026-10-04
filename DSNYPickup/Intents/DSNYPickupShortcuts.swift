import AppIntents
import DSNYKit

/// Makes the intents and entities in DSNYKit part of the app's App Intents metadata.
struct DSNYPickupAppIntents: AppIntentsPackage {
    static var includedPackages: [any AppIntentsPackage.Type] { [DSNYKitIntentsPackage.self] }
}

/// Phrases that work with Siri right after install, and tiles in the Shortcuts app and Spotlight.
struct DSNYPickupShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextPickupIntent(),
            phrases: [
                "When is my next pickup in \(.applicationName)",
                "When is garbage day in \(.applicationName)",
                "Check \(.applicationName)",
                "When is the next pickup at \(\.$address) in \(.applicationName)"
            ],
            shortTitle: "Next Pickup",
            systemImageName: "calendar"
        )
        AppShortcut(
            intent: StreamPickupIntent(),
            phrases: [
                "When is \(\.$stream) in \(.applicationName)",
                "When is \(\.$stream) pickup in \(.applicationName)",
                "When does \(\.$stream) get picked up in \(.applicationName)"
            ],
            shortTitle: "Pickup Day",
            systemImageName: "arrow.3.trianglepath",
            parameterPresentation: ParameterPresentation(
                for: \.$stream,
                summary: Summary("When is \(\.$stream)"),
                optionsCollections: {
                    OptionsCollection(CollectionStreamOptionsProvider(), title: "Collections", systemImageName: "trash")
                }
            )
        )
        AppShortcut(
            intent: TonightIntent(),
            phrases: [
                "What goes out tonight in \(.applicationName)",
                "Do I put the trash out tonight in \(.applicationName)",
                "What bins go out tonight with \(.applicationName)"
            ],
            shortTitle: "Tonight",
            systemImageName: "moon.stars"
        )
        AppShortcut(
            intent: DisposalLookupIntent(),
            phrases: [
                "How do I get rid of something in \(.applicationName)",
                "Ask \(.applicationName) how to throw something away"
            ],
            shortTitle: "Get Rid Of",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: SetRemindersIntent(),
            phrases: [
                "Turn on pickup reminders in \(.applicationName)",
                "Remind me about trash day with \(.applicationName)"
            ],
            shortTitle: "Reminders",
            systemImageName: "bell.badge"
        )
    }

    static let shortcutTileColor: ShortcutTileColor = .grayGreen
}

/// Lets the "Pickup Day" shortcut show one tile per collection in Spotlight and Shortcuts.
private struct CollectionStreamOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [CollectionStream] {
        CollectionStream.allCases
    }
}
