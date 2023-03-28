//
//  Array+Ext.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 3/27/23.
//

import Foundation

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
