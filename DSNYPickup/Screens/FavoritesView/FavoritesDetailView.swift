//
//  FavoritesDetailView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 2/2/23.
//

import SwiftUI
import Collections

struct FavoritesDetailView: View {
    @Environment(\.managedObjectContext) var viewContext
    @StateObject var stateModel: FavoritesDetailViewStateModel
    @StateObject var notificationManager = NotificationManager()
    
    @State var isLoading = false
    
    var body: some View {
        ScrollView {
            Text(stateModel.garbageCollection.formattedAddress ?? "")
                .font(.title)
            GarbageCollectionGridView(garbageCollection: stateModel.garbageCollection)
            Spacer()
            if notificationManager.authorizationStatus == .denied {
                Text("Please go into your setting and enable Notification to use daily notification reminders")
            } else {
                Toggle("Daily notification reminder", isOn: $stateModel.isNotificationOn)
                    .onChange(of: stateModel.isNotificationOn) { value in
                        if !value { notificationManager.removeNotificationWith(id: stateModel.id.uuidString) }
                    }
                if stateModel.isNotificationOn {
                    DatePicker("Time", selection: $stateModel.date, displayedComponents: [.hourAndMinute])
                }
                Button {
                    Task { @MainActor in
                        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: stateModel.date)
                        let days = EnumDays.dayToNumber(stateModel.dates)
                        guard let hour = dateComponents.hour, let minute = dateComponents.minute else { return }
                        await notificationManager.createLocalNotification(id: stateModel.id.uuidString, days: days, hour: hour, minute: minute)
//                        let savedPrescription = Prescriptions(context: moc)
//                        stateModel.savePrescription(savedPrescription)
//                        try? moc.save()
//                        isShowingDetail = false
                    }
                } label: {
                    Text("save")
                }
            }
        }.padding()
            .navigationTitle("Collection Details")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.accentColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                stateModel.sortData()
                notificationManager.reloadAuthorizationStatus()
            }
    }
}

//struct FavoritesDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        FavoritesDetailView(garbageCollection: .init())
//    }
//}

class FavoritesDetailViewStateModel: ObservableObject {
    @Published var id = UUID()
    @Published var date = Date()
    @Published var dates = [String]()
    @Published var isNotificationOn = false
    @Published var garbageCollection: GarbageCollection
    
    @State var garbage: OrderedDictionary = WeekDay.week
    @State var largeItems: OrderedDictionary = WeekDay.week
    @State var recycling: OrderedDictionary = WeekDay.week
    @State var composting: OrderedDictionary = WeekDay.week
    
    init(garbageCollection: GarbageCollection) {
        self.garbageCollection = garbageCollection
    }
    
    func sortData() {
        resetArrayData()
        
        let garbage = organizeCollection(from: garbageCollection.regularCollectionSchedule ?? "")
        let largeItems = organizeCollection(from: garbageCollection.bulkPickupCollectionSchedule ?? "")
        let recycling = organizeCollection(from: garbageCollection.recyclingCollectionSchedule ?? "")
        let composting = organizeCollection(from: garbageCollection.organicsCollectionSchedule ?? "")
//        self.dates = [garbage]
      
        self.dates = garbage + largeItems + recycling + composting 
    }

    func organizeCollection(from schedule: String) -> [String] {
        return schedule.components(separatedBy: ",")
    }

    func resetArrayData() {
       garbage.forEach({ (key, value) -> Void in
           garbage[key] = false
       })
       largeItems.forEach({ (key, value) -> Void in
           largeItems[key] = false
       })
       recycling.forEach({ (key, value) -> Void in
           recycling[key] = false
       })
       composting.forEach({ (key, value) -> Void in
           composting[key] = false
       })
   }
}
