//
//  View+Ext.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 2/1/23.
//

import SwiftUI

extension View {
  func dismissKeyboardOnTap() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
  }
}
