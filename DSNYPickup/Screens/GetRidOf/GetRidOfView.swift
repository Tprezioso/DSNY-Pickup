import DSNYKit
import SwiftUI

/// "How do I get rid of …?" search over DSNY's own index. Works offline from the cached or bundled copy.
struct GetRidOfView: View {
    @Environment(\.disposalGuide) private var guide

    @State private var topics: [DisposalTopic] = []
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                if query.trimmingCharacters(in: .whitespaces).isEmpty {
                    categoryList
                } else {
                    searchResults
                }
            }
            .navigationTitle("Get Rid Of")
            .searchable(text: $query, prompt: "Mattress, batteries, paint…")
            .navigationDestination(for: DisposalTopic.self) { topic in
                DisposalDetailView(topic: topic)
            }
            .navigationDestination(for: Category.self) { category in
                CategoryView(category: category)
            }
            .task {
                topics = await guide.localTopics()
                if let fresh = try? await guide.refreshTopics() {
                    topics = fresh
                }
            }
        }
    }

    // MARK: Lists

    @ViewBuilder
    private var searchResults: some View {
        let matches = Self.rankedMatches(in: topics, for: query)
        if matches.isEmpty {
            ContentUnavailableView.search(text: query)
        } else {
            ForEach(matches) { topic in
                NavigationLink(value: topic) {
                    VStack(alignment: .leading) {
                        Text(topic.term)
                        Text(topic.category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var categoryList: some View {
        Section {
            ForEach(categories) { category in
                NavigationLink(value: category) {
                    Label(category.name, systemImage: category.systemImage)
                }
            }
        } header: {
            Text("Browse")
        } footer: {
            Text("From DSNY's \"How to Get Rid Of\" guide on nyc.gov.")
        }
    }

    /// Topics matching `query`, best matches first, then alphabetical.
    private static func rankedMatches(in topics: [DisposalTopic], for query: String) -> [DisposalTopic] {
        var ranked: [(topic: DisposalTopic, rank: Int)] = []
        for topic in topics {
            if let rank = topic.matchRank(query) {
                ranked.append((topic, rank))
            }
        }
        ranked.sort { lhs, rhs in
            if lhs.rank != rhs.rank { return lhs.rank < rhs.rank }
            return lhs.topic.term.localizedStandardCompare(rhs.topic.term) == .orderedAscending
        }
        return ranked.map(\.topic)
    }

    /// One category per DSNY "Get Rid Of" page, with its topics.
    private var categories: [Category] {
        Dictionary(grouping: topics.filter { $0.pageURL.path().contains("/get-rid-of/") }, by: \.category)
            .map { Category(name: $0.key, topics: $0.value) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
}

struct Category: Hashable, Identifiable {
    let name: String
    let topics: [DisposalTopic]

    var id: String { name }

    /// A symbol for the category, falling back to a generic box.
    var systemImage: String {
        let lowered = name.lowercased()
        let symbols: [(String, String)] = [
            ("animal", "pawprint"), ("appliance", "refrigerator"), ("automotive", "car"), ("batter", "battery.50percent"),
            ("clothing", "tshirt"), ("construction", "hammer"), ("electronic", "desktopcomputer"), ("furniture", "sofa"),
            ("gas", "flame"), ("harmful", "exclamationmark.triangle"), ("ink", "printer"), ("large", "shippingbox"),
            ("light", "lightbulb"), ("medical", "cross.case"), ("metal", "arrow.3.trianglepath"), ("paper", "newspaper"),
            ("oil", "drop"), ("plant", "leaf"), ("spurs", "basketball")
        ]
        return symbols.first { lowered.contains($0.0) }?.1 ?? "shippingbox"
    }
}

private struct CategoryView: View {
    let category: Category

    var body: some View {
        List(category.topics) { topic in
            NavigationLink(topic.term, value: topic)
        }
        .navigationTitle(category.name)
    }
}

#Preview {
    GetRidOfView()
}
