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
    @Environment(\.dismiss) var dismiss
    @StateObject var stateModel: FavoritesDetailViewStateModel
    @StateObject var notificationManager: NotificationManager
    
    @State var isLoading = false
    
    var body: some View {
        ZStack {
            ScrollView {
                Text(stateModel.garbageCollection.formattedAddress ?? "")
                    .font(.title)
                GarbageCollectionGridView(garbageCollection: stateModel.garbageCollection)
                Spacer()
                if notificationManager.authorizationStatus == .denied {
                    Text("Please go into your setting and enable Notification to use daily notification reminders")
                } else {
                    Button("Notification Reminder") {
                        // SF Symbol for animated toggle: iphone.gen3.radiowaves.left.and.right.circle.fill
                        stateModel.isShowingEditNotification.toggle()
                    }
                    
                }
            }.padding()
            .sheet(isPresented: $stateModel.isShowingEditNotification) {
                Toggle("Set Notification Reminder", isOn: $stateModel.isNotificationOn)
                    .toggleStyle(SymbolToggleStyle(systemImage: "iphone.gen3.radiowaves.left.and.right.circle.fill", activeColor: .accentColor))
                    .padding(.trailing, 2)
                    .onChange(of: stateModel.isNotificationOn) { value in
                        if !value { notificationManager.removeNotificationWith(id: stateModel.id.uuidString) }
                    }
                if stateModel.isNotificationOn {
                    VStack(alignment: .leading) {
                        Text("For Days: \(stateModel.dates.removeDuplicates().joined(separator: ", "))")
                        DatePicker("Time",
                                   selection: $stateModel.date,
                                   displayedComponents: [.hourAndMinute]
                        )
                    }
                    Button {
                        Task { @MainActor in
                            notificationManager.removeNotificationWith(id: stateModel.id.uuidString)
                            let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: stateModel.date)
                            let days = EnumDays.dayToNumber(stateModel.dates)
                            guard let hour = dateComponents.hour, let minute = dateComponents.minute else { return }
                            await notificationManager.createLocalNotification(id: stateModel.id.uuidString, days: days, hour: hour, minute: minute)
                            stateModel.garbageCollection.isNotificationsOn = stateModel.isNotificationOn
                            stateModel.garbageCollection.savedDate = stateModel.date
                            try? viewContext.save()
                            stateModel.savedNotificationTapped = true
                            stateModel.isShowingEditNotification.toggle()
                        }
                    } label: {
                        Text("Save")
                    }.buttonStyle(RoundedRectangleButtonStyle())
                    .disabled(stateModel.isSaveButtonEnabled)
                }
            }
            .navigationTitle("Collection Details")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.accentColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            
            .onAppear {
                stateModel.sortData()
                notificationManager.reloadAuthorizationStatus()
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
        FavoritesDetailView(stateModel: FavoritesDetailViewStateModel(garbageCollection: GarbageCollection()), notificationManager: NotificationManager())
    }
}

class FavoritesDetailViewStateModel: ObservableObject {
    @Published var id = UUID()
    @Published var date = Date()
    @Published var dates = [String]()
    @Published var isNotificationOn = false
    @Published var savedNotificationTapped = false
    @Published var garbageCollection: GarbageCollection
    @Published var isShowingEditNotification = false
    
    var isSaveButtonEnabled: Bool {
        garbageCollection.savedDate == self.date
    }
    
    @State var garbage: OrderedDictionary = WeekDay.week
    @State var largeItems: OrderedDictionary = WeekDay.week
    @State var recycling: OrderedDictionary = WeekDay.week
    @State var composting: OrderedDictionary = WeekDay.week
    
    init(garbageCollection: GarbageCollection) {
        self.garbageCollection = garbageCollection
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
}
