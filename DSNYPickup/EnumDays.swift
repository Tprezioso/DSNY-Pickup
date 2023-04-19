//
//  EnumDays.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 4/17/23.
//

import Foundation
enum EnumDays: Int, CustomStringConvertible, CaseIterable {
    var description: String {
        switch self {
        case .MONDAY:
            return "Monday"
        case .TUESDAY:
            return "Tuesday"
        case .WEDNESDAY:
            return "Wednesday"
        case .THURSDAY:
            return "Thursday"
        case .FRIDAY:
            return "Friday"
        case .SATURDAY:
            return "Saturday"
        case .SUNDAY:
            return "Sunday"
        }
    }
    
    var number: Int {
        switch self {
        case .MONDAY:
            return 2
        case .TUESDAY:
            return 3
        case .WEDNESDAY:
            return 4
        case .THURSDAY:
            return 5
        case .FRIDAY:
            return 6
        case .SATURDAY:
            return 7
        case .SUNDAY:
            return 1
        }
    }
    
    static func dayToNumber(_ days: [String]) -> [EnumDays?] {
       return days.map { day in
           self.allCases.first {"\($0)" == day }
        }
    }
    
    static func dayBefore(_ days: [String]) -> [EnumDays?] {
        return days.map { day in
            self.allCases.first {"\($0)" == day }?.previous()
         }
     }
    
    case MONDAY,TUESDAY,WEDNESDAY,THURSDAY,FRIDAY,SATURDAY,SUNDAY
}

extension CaseIterable where Self: Equatable, AllCases: BidirectionalCollection {
    func previous() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        let previous = all.index(before: idx)
        return all[previous < all.startIndex ? all.index(before: all.endIndex) : previous]
    }

    func next() -> Self {
        let all = Self.allCases
        let idx = all.firstIndex(of: self)!
        let next = all.index(after: idx)
        return all[next == all.endIndex ? all.startIndex : next]
    }
}
