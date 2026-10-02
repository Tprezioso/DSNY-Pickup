import DSNYKit
import SwiftUI

/// Full-screen error with a retry button, used for every network failure.
struct ErrorStateView: View {
    let error: DSNYError
    var retry: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(error.errorDescription ?? String(localized: "Something went wrong"), systemImage: error.systemImage)
        } description: {
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
            }
        } actions: {
            if let retry {
                Button("Try Again", action: retry)
                    .buttonStyle(.glassProminent)
            }
        }
    }
}

extension Error {
    /// Maps any error to the app's error type.
    var asDSNYError: DSNYError {
        self as? DSNYError ?? .invalidResponse
    }
}

#Preview {
    ErrorStateView(error: .offline) {}
}
