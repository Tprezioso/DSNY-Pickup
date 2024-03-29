//
//  CalendarHeaderView.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/14/23.
//

import SwiftUI

struct CalendarHeaderView: View {
    // Monday through Saturday week
    let daysOfWeek = ["M", "T", "W", "T", "F", "S"]
    var isWidget = false

    var body: some View {
            ForEach(daysOfWeek, id: \.self) { dayOfWeek in
                Text(dayOfWeek)
                    .font(isWidget ? .caption : .body)
                    .fontWeight(.black)
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity)
            
        }
    }
}

struct CalendarHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        CalendarHeaderView()
    }
}
