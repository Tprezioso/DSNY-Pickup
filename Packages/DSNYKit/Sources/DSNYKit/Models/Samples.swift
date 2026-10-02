import Foundation

public extension CollectionSchedule {
    /// A realistic schedule for previews and widget placeholders (125 Worth St, Manhattan).
    static let sample = CollectionSchedule(
        formattedAddress: "125 Worth St, New York, NY 10013, USA",
        rawSchedules: [
            .trash: "Tuesday,Thursday,Saturday",
            .recycling: "Saturday",
            .compost: "Saturday",
            .bulk: "Tuesday,Thursday"
        ],
        residentialRoutingTime: "Daily: 8:00 AM - 9:00 AM and 6:00 PM - 7:00 PM",
        commercialRoutingTime: "Daily: 10:00 AM - 10:59 AM and 2:00 PM - 2:59 PM",
        mixedUseRoutingTime: "Call 311"
    )
}

public extension DropOffSite {
    static let sample = DropOffSite(
        id: "specialWaste-sample",
        kind: .specialWaste,
        name: "DSNY Special Waste Drop-Off Site",
        address: "74 Pike Slip, New York, 10002",
        borough: "Manhattan",
        latitude: 40.70990,
        longitude: -73.99232
    )
}
