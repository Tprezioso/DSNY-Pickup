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
            Text(entry.garbageCollection.formattedAddress ?? "85-12 Jamaica Ave, Queens, NY 11421, USA")
                .font(.caption2)
            HStack {
                Spacer()
                Image(systemName: "trash")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.green)
                    
                Spacer()
                Image(systemName: "sofa")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.green)
                Spacer()
            }
            Spacer()
            HStack {
                Spacer()
                Image(systemName: "arrow.3.trianglepath")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.cyan)
                Spacer()
                Image(systemName: "leaf.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .foregroundColor(.orange)
                Spacer()
            }
            
            Spacer()
        }
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

struct DSNYPickupWidget_Previews: PreviewProvider {
    static var previews: some View {
        let context = DataManager.shared.container.viewContext

        DSNYPickupWidgetEntryView(entry: GarbageCollectionEntry(date: Date(), garbageCollection:  GarbageCollection(context: context)))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
