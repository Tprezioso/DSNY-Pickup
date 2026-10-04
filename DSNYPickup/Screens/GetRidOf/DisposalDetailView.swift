import DSNYKit
import SwiftUI

/// Shows the DSNY guidance for one item, parsed from the matching section of nyc.gov.
struct DisposalDetailView: View {
    let topic: DisposalTopic

    @Environment(\.disposalGuide) private var guide
    @State private var state: LoadState = .loading

    enum LoadState {
        case loading
        case loaded(DisposalSection)
        case failed(DSNYError)
    }

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded(let section):
                SectionContent(topic: topic, section: section)
            case .failed(let error):
                ContentUnavailableView {
                    Label(error.errorDescription ?? "", systemImage: error.systemImage)
                } description: {
                    Text("You can still read DSNY's guidance on nyc.gov.")
                } actions: {
                    Button("Try Again") { Task { await load() } }
                        .buttonStyle(.glass)
                    Link("Open on nyc.gov", destination: topic.url)
                        .buttonStyle(.glassProminent)
                }
            }
        }
        .navigationTitle(topic.term)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Link(destination: topic.url) {
                    Label("Open on nyc.gov", systemImage: "safari")
                }
            }
        }
        .task(id: topic) { await load() }
    }

    private func load() async {
        state = .loading
        do {
            state = .loaded(try await guide.section(for: topic))
        } catch is CancellationError {
            // View went away.
        } catch {
            state = .failed(error.asDSNYError)
        }
    }
}

private struct SectionContent: View {
    let topic: DisposalTopic
    let section: DisposalSection

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(section.title)
                    .font(.title2.bold())

                if !topic.relatedTerms.isEmpty {
                    Text("Also covers \(topic.relatedTerms.prefix(6).joined(separator: ", "))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                    BlockView(block: block)
                }

                Link(destination: section.sourceURL) {
                    Label("Source: nyc.gov/dsny", systemImage: "link")
                        .font(.footnote)
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
    }
}

private struct BlockView: View {
    let block: DisposalSection.Block

    var body: some View {
        switch block {
        case .heading(let text):
            Text(text)
                .font(.headline)
                .padding(.top, 6)
        case .paragraph(let markdown):
            Text(Self.attributed(markdown))
        case .bullets(let items):
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•")
                        Text(Self.attributed(item))
                    }
                }
            }
        }
    }

    static func attributed(_ markdown: String) -> AttributedString {
        (try? AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(markdown)
    }
}
