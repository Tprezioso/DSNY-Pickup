import AppIntents

extension CollectionStream: AppEnum {
    public static let typeDisplayRepresentation: TypeDisplayRepresentation = "Collection"

    // Synonyms let Siri match "garbage", "compost bin", "big items" and so on.
    public static let caseDisplayRepresentations: [CollectionStream: DisplayRepresentation] = [
        .trash: DisplayRepresentation(title: "Trash", image: .init(systemName: "trash.fill"), synonyms: ["Garbage", "Refuse", "Trash Pickup"]),
        .recycling: DisplayRepresentation(title: "Recycling", image: .init(systemName: "arrow.3.trianglepath"), synonyms: ["Recyclables", "Paper", "Bottles and Cans"]),
        .compost: DisplayRepresentation(title: "Compost", image: .init(systemName: "leaf.fill"), synonyms: ["Organics", "Food Scraps", "Yard Waste", "Brown Bin"]),
        .bulk: DisplayRepresentation(title: "Bulk Items", image: .init(systemName: "sofa.fill"), synonyms: ["Bulk", "Furniture", "Large Items"])
    ]
}
