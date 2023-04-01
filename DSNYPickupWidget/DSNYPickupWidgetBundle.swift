//
//  DSNYPickupWidgetBundle.swift
//  DSNYPickupWidget
//
//  Created by Thomas Prezioso Jr on 3/28/23.
//

import WidgetKit
import SwiftUI

@main
struct DSNYPickupWidgetBundle: WidgetBundle {
    @StateObject private var manager: DataManager = DataManager()
    var body: some Widget {
        DSNYPickupWidget()
    }
}
