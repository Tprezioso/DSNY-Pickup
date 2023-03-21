//
//  FavoritesDetailView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 2/2/23.
//

import SwiftUI
import Collections

struct FavoritesDetailView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var stateModel: FavoritesDetailViewStateModel
    
    var body: some View {
        ZStack {
            ScrollView {
                Text(stateModel.garbageCollection.formattedAddress ?? "")
                    .font(.title)
                GarbageCollectionGridView(garbageCollection: stateModel.garbageCollection)
                Spacer()
                if stateModel.notificationManager.authorizationStatus == .denied {
                    Text("Please go into your setting and enable Notification to use daily notification reminders")
                } else {
                    Button("Set Notification Reminder") {
                        stateModel.isShowingEditNotification.toggle()
                    }.buttonStyle(RoundedRectangleButtonStyle())
                }
            }.padding()
            .sheet(isPresented: $stateModel.isShowingEditNotification) {
                FavoritesNotificationSheetView(stateModel: stateModel)
                    .presentationDetents([.medium])
            }
            .navigationTitle("Collection Details")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.accentColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .onAppear {
                stateModel.sortData()
                stateModel.notificationManager.reloadAuthorizationStatus()
            }
            if stateModel.savedNotificationTapped {
                LottieView(name: "Check", loopMode: .playOnce, isShowing: $stateModel.savedNotificationTapped)
                    .frame(width: 250, height: 250)
                
            }
        }
    }
}

struct FavoritesDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesDetailView(stateModel: FavoritesDetailViewStateModel(garbageCollection: GarbageCollection(), notificationManager: NotificationManager()))
    }
}

class FavoritesDetailViewStateModel: ObservableObject {
    @Published var date = Date()
    @Published var dates = [String]()
    @Published var isNotificationOn = false
    @Published var savedNotificationTapped = false
    @Published var garbageCollection: GarbageCollection
    @Published var isShowingEditNotification = false
    @Published var notificationManager: NotificationManager
    
    var isSaveButtonEnabled: Bool {
        garbageCollection.savedDate == date && notificationManager.notification.filter { $0.identifier == garbageCollection.id?.uuidString
        }.isEmpty
    }
    
    var daysFor: String {
        if dates.removeDuplicates().filter({ $0 != ""}).count > 1 {
           return dates.removeDuplicates().joined(separator: ", ")
        } else {
            return dates.removeDuplicates().filter({ $0 != ""}).first!
        }
    }
    
    @State var garbage: OrderedDictionary = WeekDay.week
    @State var largeItems: OrderedDictionary = WeekDay.week
    @State var recycling: OrderedDictionary = WeekDay.week
    @State var composting: OrderedDictionary = WeekDay.week
    
    init(garbageCollection: GarbageCollection, notificationManager: NotificationManager) {
        self.garbageCollection = garbageCollection
        self.notificationManager = notificationManager
        self.isNotificationOn = garbageCollection.isNotificationsOn
        self.date = garbageCollection.savedDate ?? Date()
    }
    
    func sortData() {
        resetArrayData()
        
        let garbage = organizeCollection(from: garbageCollection.regularCollectionSchedule ?? "")
        let largeItems = organizeCollection(from: garbageCollection.bulkPickupCollectionSchedule ?? "")
        let recycling = organizeCollection(from: garbageCollection.recyclingCollectionSchedule ?? "")
        let composting = organizeCollection(from: garbageCollection.organicsCollectionSchedule ?? "")
      
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
    
    func saveGarbageCollection(_ garbageCollection: GarbageCollection) {
         garbageCollection.isNotificationsOn = isNotificationOn
    }
    
    func saveNotification(selected: DayOf) async {
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: date)
        var days = selected == DayOf.dayOf ? EnumDays.dayToNumber(dates) : EnumDays.dayBefore(dates)
        let safeDays = days.compactMap { $0 }.removeDuplicates()
        guard let hour = dateComponents.hour, let minute = dateComponents.minute else { return }
        var arrayOfIDs = [""]
        for safeDay in safeDays {
            let id = UUID()
            arrayOfIDs.append(id.uuidString)
            await notificationManager.createLocalNotification(id: id.uuidString, day: safeDay, hour: hour, minute: minute)
        }
        garbageCollection.notificationIDs = arrayOfIDs
        garbageCollection.isNotificationsOn = isNotificationOn
        garbageCollection.savedDate = date
        garbageCollection.frequencyOfDays = selected.description
        savedNotificationTapped = true
        isShowingEditNotification = false

    }
}
