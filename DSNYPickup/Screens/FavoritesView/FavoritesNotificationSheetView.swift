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
    
    var isSaveButtonEnabled: Bool {
        stateModel.garbageCollection.savedDate == stateModel.date && stateModel.notificationManager.notification.filter { $0.identifier == stateModel.garbageCollection.id?.uuidString
        }.isEmpty
    }
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
                        Text("For Days: \(stateModel.dates.removeDuplicates().joined(separator: ", "))")
                        DatePicker("Time",
                                   selection: $stateModel.date,
                                   displayedComponents: [.hourAndMinute]
                        )
                    }
                    Button {
                        Task { @MainActor in

                            let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: stateModel.date)
                            let days = EnumDays.dayToNumber(stateModel.dates)
                            guard let hour = dateComponents.hour, let minute = dateComponents.minute else { return }
                            await stateModel.notificationManager.createLocalNotification(id: stateModel.garbageCollection.id?.uuidString ?? "0", days: days, hour: hour, minute: minute)
                            stateModel.garbageCollection.isNotificationsOn = stateModel.isNotificationOn
                            stateModel.garbageCollection.savedDate = stateModel.date
                            try? viewContext.save()
                            stateModel.savedNotificationTapped = true
                            stateModel.isShowingEditNotification.toggle()
                        }
                    } label: {
                        Text("Save")
                    }.buttonStyle(RoundedRectangleButtonStyle())
                    .disabled(isSaveButtonEnabled)
                }
                Spacer()
            }.padding()
            .navigationTitle("Notification Reminder")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        stateModel.isShowingEditNotification.toggle()
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
