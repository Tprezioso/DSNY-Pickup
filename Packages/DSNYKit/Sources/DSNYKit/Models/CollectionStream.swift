import SwiftUI

/// A kind of curbside collection DSNY schedules separately.
public enum CollectionStream: String, CaseIterable, Codable, Sendable, Identifiable {
    case trash
    case recycling
    case compost
    case bulk

    public var id: String { rawValue }

    public var title: LocalizedStringResource {
        switch self {
        case .trash: "Trash"
        case .recycling: "Recycling"
        case .compost: "Compost"
        case .bulk: "Bulk Items"
        }
    }

    public var subtitle: LocalizedStringResource {
        switch self {
        case .trash: "Bagged household trash"
        case .recycling: "Paper, metal, glass, plastic & cartons"
        case .compost: "Food scraps & yard waste"
        case .bulk: "Furniture & large items"
        }
    }

    public var systemImage: String {
        switch self {
        case .trash: "trash.fill"
        case .recycling: "arrow.3.trianglepath"
        case .compost: "leaf.fill"
        case .bulk: "sofa.fill"
        }
    }

    public var color: Color {
        switch self {
        case .trash: .gray
        case .recycling: .blue
        case .compost: .brown
        case .bulk: .orange
        }
    }
}
