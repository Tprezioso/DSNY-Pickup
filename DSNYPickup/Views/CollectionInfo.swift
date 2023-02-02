//
//  CollectionInfo.swift
//  DSNYPickup
//
//  Created by Thomas Prezioso Jr on 1/20/23.
//

import SwiftUI

struct CollectionInfo: View {
    var body: some View {
        ScrollView {
            VStack {
                Text("""
    • Before Collection: Set items curbside after 4pm the night before your scheduled collection.
        
    • After Collection: Remove emptied containers by 9pm on collection day (or by 9am the next morning if your collection is after 4pm).
        
    • Collection service may be disrupted during snow operations as DSNY teams prepare for winter weather and plow streets to keep them safe.
        
    • Monitor this app's notifications.
        
    • Place items for collection at the curb after 4pm the night before your scheduled collection day.
       
    The Department recognizes these days as holidays:
        • New Year's Day
        • Martin Luther King, Jr.Day
        • Lincoln's Birthday
        • Presidents' Day
        • Memorial Day
        • Juneteenth
        • Independence Day
        • Labor Day
        • Columbus Day
        • Election Day
        • Veterans Day
        • Thanksgiving DayBefore Collection: Set items curbside after 4pm the night before your scheduled collection.
        • After Collection: Remove emptied containers by 9pm on collection day (or by 9am the next morning if your collection is after 4pm).
        • Collection service may be disrupted during snow operations as DSNY teams prepare for winter weather and plow streets to keep them safe.
        • Monitor this app's notifications.
        • Place items for collection at the curb after 4pm the night before your scheduled collection day.
        
        The Department recognizes these days as holidavs:
            • New Year's Day
            • Martin Luther King, Jr.Day
            • Lincoln's Birthday
            • Presidents' Day
            • Memorial Day
            • Juneteenth
            • Independence Day
            • Labor Day
            • Columbus Day
            • Election Day
            • Veterans Day
            • Thanksgiving Day

    If your collection day falls on a holiday, please check our social media accounts (Twitter, Facebook, or Instagram), our press release page, or 311 for updated direction.
    """)
                .multilineTextAlignment(.leading)
            .padding()
            }
        }.navigationTitle("Collection Information")
    }
}

struct CollectionInfo_Previews: PreviewProvider {
    static var previews: some View {
        CollectionInfo()
    }
}
