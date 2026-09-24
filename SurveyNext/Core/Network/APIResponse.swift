import Foundation

/// The envelope every backend handler answers with: `{ success, message, data }`.
/// Equivalent of `StatusResponseModel<T>`.
struct APIResponse<T: Decodable>: Decodable {
    let success: Bool
    let message: String?
    let data: T?
}

/// For endpoints that answer `{ success, message }` with no data,
/// such as publish, pause and delete.
struct EmptyData: Decodable {}

/// Error bodies: handlers answer with "message", the role middleware with "error".
struct APIErrorBody: Decodable {
    let message: String?
    let error: String?
}

/// Go encodes `time.Time` as RFC 3339, with fractional seconds only when they
/// aren't zero, so both shapes have to parse.
nonisolated enum BackendDate {
    nonisolated(unsafe) private static let withFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    nonisolated(unsafe) private static let plain: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    static func parse(_ string: String) -> Date? {
        withFraction.date(from: string) ?? plain.date(from: string)
    }
}
