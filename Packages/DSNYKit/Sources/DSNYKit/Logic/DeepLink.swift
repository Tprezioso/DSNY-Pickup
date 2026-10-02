import Foundation

/// `dsnypickup://` URLs that widgets use to open the app on a specific screen.
public enum DeepLink: Equatable, Sendable {
    case address(UUID)
    case home

    public static let scheme = "dsnypickup"

    public var url: URL {
        switch self {
        case .address(let id): URL(string: "\(Self.scheme)://address/\(id.uuidString)")!
        case .home: URL(string: "\(Self.scheme)://home")!
        }
    }

    public init?(url: URL) {
        guard url.scheme == Self.scheme else { return nil }
        switch url.host() {
        case "address":
            guard let id = url.pathComponents.dropFirst().first.flatMap(UUID.init(uuidString:)) else { return nil }
            self = .address(id)
        case "home":
            self = .home
        default:
            return nil
        }
    }
}
