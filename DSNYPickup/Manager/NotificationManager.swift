//
//  NotificationManager.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 2/2/23.
//

import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    @Published var notification: [UNNotificationRequest] = []
    @Published var authorizationStatus: UNAuthorizationStatus?
    
    func reloadAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.authorizationStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { isGranted, _ in
            DispatchQueue.main.async {
                self.authorizationStatus = isGranted ? .authorized : .denied
            }
        }
    }
    
    func reloadLocalNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { notifications in
            DispatchQueue.main.async {
                self.notification = notifications
            }
        }
    }
    
    func createLocalNotification(id: String, days: [EnumDays?], hour: Int, minute: Int) async {
        let safeDays = days.compactMap { $0 }.removeDuplicates()
        
        for day in safeDays {
            var dateComponents = DateComponents()
            dateComponents.calendar = Calendar.current
            dateComponents.weekday = day.number
            dateComponents.hour = hour
            dateComponents.minute = minute
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            let notificationContent = UNMutableNotificationContent()
            notificationContent.title = "Don't forget to take out the Trash!"
            notificationContent.sound = .default
            
            let request = UNNotificationRequest(identifier: id, content: notificationContent, trigger: trigger)
            do {
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print(error)
            }
        }
        

    }
    
    func removeNotificationWith(id: String) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            for request in requests {
                if request.identifier == id {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
                }
            }
        }
    }
    
    func updateLocalNotification(id: String, days: [EnumDays], hour: Int, minute: Int) async {
        let notifications = await UNUserNotificationCenter.current().pendingNotificationRequests()
        if notifications.isEmpty {
            await self.createLocalNotification(id: id, days: days, hour: hour, minute: minute)
        } else {
            for request in notifications {
                if request.identifier == id {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [request.identifier])
                    await self.createLocalNotification(id: id, days: days
                                                       , hour: hour, minute: minute)
                }
            }
        }
    }
}

extension Array where Element:Equatable {
    func removeDuplicates() -> [Element] {
        var result = [Element]()

        for value in self {
            if result.contains(value) == false {
                result.append(value)
            }
        }

        return result
    }
}
