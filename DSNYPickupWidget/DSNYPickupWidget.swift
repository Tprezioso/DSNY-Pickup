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

    func getSnapshot(for configuration: DSNYPickupLocationIntent, in context: Context, completion: @escaping (GarbageCollectionEntry) -> ()) {
        do {
            let data = try getData()
            let entry = GarbageCollectionEntry(date: Date(), garbageCollection: data.first!)
            completion(entry)
        } catch {
            print(error)
        }
    }

    func getTimeline(for configuration: DSNYPickupLocationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        do {
            let items = try getData()
            let matchingDay = items.first { $0.formattedAddress == configuration.pickupLocation }!
            let entry = GarbageCollectionEntry(date: Date(), garbageCollection: matchingDay)
            let timeline = Timeline(entries: [entry], policy: .atEnd)
            completion (timeline)
        } catch {
            print(error)
        }
    }
    
    private func getData() throws -> [GarbageCollection] {
        let context = DataManager.shared.container.viewContext
        let request = GarbageCollection.fetchRequest()
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
        VStack {
            Spacer()
            Text(entry.garbageCollection.formattedAddress ?? "1234 Main st, Queens, NY 12345, USA")
                .font(.caption2)
            HStack {
                Spacer()
                Image(systemName: "trash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(!(entry.garbageCollection.regularCollectionSchedule?.isEmpty ?? true) && entry.garbageCollection.savedDate?.dayNumberOfWeek() == entry.date.dayNumberOfWeek() ? .green : .secondary)
                
                Spacer()
                Image(systemName: "sofa")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(!(entry.garbageCollection.bulkPickupCollectionSchedule?.isEmpty ?? true) && entry.garbageCollection.savedDate?.dayNumberOfWeek() == entry.date.dayNumberOfWeek() ? .green : .secondary)
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "arrow.3.trianglepath")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(!(entry.garbageCollection.recyclingCollectionSchedule?.isEmpty ?? true) && entry.garbageCollection.savedDate?.dayNumberOfWeek() == entry.date.dayNumberOfWeek() ? .cyan : .secondary)
                Spacer()
                Image(systemName: "leaf.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(!(entry.garbageCollection.organicsCollectionSchedule?.isEmpty ?? true) && entry.garbageCollection.savedDate?.dayNumberOfWeek() == entry.date.dayNumberOfWeek() ? .orange : .secondary)
                Spacer()
            }
            
            Spacer()
        }
    }
}

struct DSNYPickupWidget: Widget {
    let kind: String = "DSNYPickupWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: DSNYPickupLocationIntent.self, provider: Provider()) { entry in
            DSNYPickupWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("DSNYPickup Widget")
        .description("Know when NYC garbage is picked up")
    }
}

struct DSNYPickupWidget_Previews: PreviewProvider {
    static var previews: some View {
        let context = DataManager.shared.container.viewContext

        DSNYPickupWidgetEntryView(entry: GarbageCollectionEntry(date: Date(), garbageCollection:  GarbageCollection(context: context)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

extension Date {
    func dayNumberOfWeek() -> Int? {
        return Calendar.current.dateComponents([.weekday], from: self).weekday
    }
}
