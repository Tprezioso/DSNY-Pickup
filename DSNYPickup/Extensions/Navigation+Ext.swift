//
//  Navigation+Ext.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 2/1/23.
//

import SwiftUI

extension UINavigationController {
  open override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    navigationBar.topItem?.backButtonDisplayMode = .minimal
  }
}
