import DSNYKit
import StoreKit
import SwiftUI

/// What Pro includes, with the one-time purchase and Restore.
struct ProPaywallView: View {
    @Environment(PurchaseManager.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    VStack(alignment: .leading, spacing: 18) {
                        ForEach(ProFeature.allCases) { feature in
                            FeatureRow(feature: feature)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if purchases.isPro {
                        Label(
                            purchases.isGrandfathered ? "You've used DSNY Pickup since before Pro, so it's on us. Thank you!" : "Pro is unlocked. Thank you!",
                            systemImage: "checkmark.seal.fill"
                        )
                        .font(.headline)
                        .foregroundStyle(.green)
                        .multilineTextAlignment(.center)
                    } else {
                        ProductView(id: ProStatus.ProductID.pro) {
                            Image(systemName: "sparkles")
                                .font(.largeTitle)
                                .foregroundStyle(.tint)
                        }
                        .productViewStyle(.large)
                    }

                    Button(isRestoring ? "Restoring…" : "Restore Purchases") {
                        Task {
                            isRestoring = true
                            await purchases.restore()
                            isRestoring = false
                        }
                    }
                    .disabled(isRestoring)
                    .font(.footnote)

                    Text("One-time purchase. No subscription. Trash, recycling and compost schedules, the Next Pickup widget, Siri questions and holiday-aware reminders stay free.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            HStack(spacing: -10) {
                ForEach(CollectionStream.allCases) { StreamIcon($0, size: 48) }
            }
            .padding(.bottom, 4)
            Text("DSNY Pickup Pro")
                .font(.largeTitle.bold())
                .fontDesign(.rounded)
            Text("Never miss a pickup, even on holidays.")
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

private struct FeatureRow: View {
    let feature: ProFeature

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.systemImage)
                .font(.title3)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.headline)
                Text(feature.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    ProPaywallView()
        .environment(PurchaseManager())
}
