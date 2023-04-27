//
//  Date+Ext.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 4/24/23.
//

import Foundation

extension Date {
    func dayNumberOfWeek() -> Int? {
        return Calendar.current.dateComponents([.weekday], from: self).weekday
    }
}
