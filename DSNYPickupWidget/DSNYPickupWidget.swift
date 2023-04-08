//
//  DSNYPickupWidget.swift
//  DSNYPickupWidget
//
//  Created by Thomas Prezioso Jr on 3/28/23.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> GarbageCollectionEntry {
        let data = try? getData()
        return GarbageCollectionEntry(date: Date(), garbageCollection: (data?.first!)!)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (GarbageCollectionEntry) -> ()) {
        do {
            let data = try getData()
            let entry = GarbageCollectionEntry(date: Date(), garbageCollection: data.first!)
            completion(entry)
        } catch {
            print(error)
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        do {
            let items = try getData()
            let entry = GarbageCollectionEntry(date: Date(), garbageCollection: items.first!)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion (timeline)
        } catch {
            print(error)
        }
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = GarbageCollectionEntry(date: entryDate, garbageCollection: garbageCollectionItems.first ?? )
//            entries.append(entry)
//        }
//
//        let timeline = Timeline(entries: entries, policy: .atEnd)
//        completion(timeline)
    }
    
    private func getData() throws -> [GarbageCollection] {
        let context = DataManager.shared.container.viewContext //PersistenceController.shared.container.viewContext
        let request = GarbageCollection.fetchRequest ()
        let result = try context.fetch(request)
        return result
    }
}

struct GarbageCollectionEntry: TimelineEntry {
    let date: Date
    let garbageCollection: GarbageCollection
}

struct DSNYPickupWidgetEntryView : View {
    var entry: GarbageCollectionEntry

    var body: some View {
        Text(entry.garbageCollection.formattedAddress ?? "65-25 160th street")
    }
}

struct DSNYPickupWidget: Widget {
    let kind: String = "DSNYPickupWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            DSNYPickupWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

//struct DSNYPickupWidget_Previews: PreviewProvider {
//    static var previews: some View {
//        DSNYPickupWidgetEntryView(entry: GarbageCollectionEntry(date: Date(), garbageCollection: MockData.garbageCollection))
//            .previewContext(WidgetPreviewContext(family: .systemSmall))
//    }
//}
