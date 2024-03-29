//
//  FavoritesNotificationSheetView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 2/17/23.
//

import SwiftUI

struct FavoritesNotificationSheetView: View {
    @Environment(\.managedObjectContext) var viewContext
    @StateObject var stateModel: FavoritesDetailViewStateModel
    @State var selectedFrequency = DayOf.dayOf
    var array = DayOf.allCases
    
    var body: some View {
        NavigationStack {
            VStack {
                Toggle("Set Notification Reminder", isOn: $stateModel.isNotificationOn)
                    .toggleStyle(SymbolToggleStyle(systemImage: "iphone.gen3.radiowaves.left.and.right.circle.fill", activeColor: .accentColor))
                    .padding(.trailing, 2)
                    .onChange(of: stateModel.isNotificationOn) { value in
                        if value == false { stateModel.notificationManager.removeNotificationWith(id: stateModel.garbageCollection.id?.uuidString ?? "0") }
                    }
                if stateModel.isNotificationOn {
                    VStack(alignment: .leading) {
                        Text("For Days: \(stateModel.daysFor)")
                        DatePicker(
                            "Time",
                            selection: $stateModel.date,
                            displayedComponents: [.hourAndMinute]
                        )
                        Picker("Day Of", selection: $selectedFrequency) {
                            ForEach(DayOf.allCases, id: \.self) {
                                Text($0.description)
                            }
                        }.pickerStyle(.segmented)
                    }
                    Button {
                        Task { @MainActor in
                            stateModel.notificationManager.reloadLocalNotifications()
                            if let savedNotificationIDs = stateModel.garbageCollection.notificationIDs {
                                let filterArray = stateModel.notificationManager.notification.filter {
                                    savedNotificationIDs.contains($0.identifier)
                                }
                                if !filterArray.isEmpty {
                                    await stateModel.updateNotification(selected: selectedFrequency, notifications: filterArray)
                                } else {
                                    await stateModel.saveNotification(selected: selectedFrequency)
                                }
                            } else {
                                await stateModel.saveNotification(selected: selectedFrequency)
                            }
                            try? viewContext.save()
                        }
                    } label: {
                        Text("Save")
                    }.buttonStyle(RoundedRectangleButtonStyle())
                    .disabled(stateModel.isSaveButtonEnabled)
                }
                Spacer()
            }.padding()
            .onAppear {
                Task { @MainActor in
                    stateModel.notificationManager.reloadLocalNotifications()
                }
                if let savedDate = stateModel.garbageCollection.savedDate {
                    stateModel.date = savedDate
                }
                if let saveFrequency = stateModel.garbageCollection.frequencyOfDays {
                    if saveFrequency == DayOf.dayOf.description {
                        selectedFrequency = DayOf.dayOf
                    } else {
                        selectedFrequency = DayOf.dayBefore
                    }
                }
            }
            .navigationTitle("Notification Reminder")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        stateModel.isShowingEditNotification = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

struct FavoritesNotificationSheetView_Previews: PreviewProvider {
    static var previews: some View {
        FavoritesNotificationSheetView(stateModel: .init(garbageCollection: GarbageCollection(), notificationManager: NotificationManager()))
    }
}


enum DayOf: String, CaseIterable, CustomStringConvertible, Equatable {
    var description: String {
        switch self {
        case .dayBefore:
            return "Day Before"
        case .dayOf:
            return "Day Of"
        }
    }
    
    case dayBefore, dayOf    
}
