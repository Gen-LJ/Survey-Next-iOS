import Foundation
import OSLog

/// Sends an `Endpoint` and unwraps the `{ success, message, data }` envelope.
///
/// Does the jobs of Retrofit + `AuthInterceptor` + `safeApiCall` on Android:
/// attaches the bearer token, ends the session on a 401, and turns every
/// failure into an `APIError` with a readable message.
final class APIClient {
    private let session: SessionStore
    private let urlSession: URLSession
    private let logger = Logger(subsystem: "com.lucilab.surveynext", category: "API")

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase // countryId -> country_id
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase // pending_points -> pendingPoints
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = BackendDate.parse(string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not an RFC 3339 date: \(string)")
            }
            return date
        }
        return decoder
    }()

    init(session: SessionStore) {
        self.session = session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.requestTimeout
        self.urlSession = URLSession(configuration: config)
    }

    /// Returns the `data` field of a successful response.
    func send<T: Decodable>(_ endpoint: Endpoint, as type: T.Type = T.self) async throws -> T {
        let envelope: APIResponse<T> = try await envelope(for: endpoint)
        guard let payload = envelope.data else {
            throw APIError.server(envelope.message ?? "Something went wrong")
        }
        return payload
    }

    /// For endpoints that answer with a message and no data. Returns the message.
    @discardableResult
    func perform(_ endpoint: Endpoint) async throws -> String? {
        let envelope: APIResponse<EmptyData> = try await envelope(for: endpoint)
        return envelope.message
    }

    private func envelope<T: Decodable>(for endpoint: Endpoint) async throws -> APIResponse<T> {
        let request = try makeRequest(for: endpoint)
        log("→ \(endpoint.method.rawValue) \(request.url?.absoluteString ?? "")")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw APIError.network
        }

        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        log("← \(status) \(String(data: data, encoding: .utf8) ?? "")")

        guard (200..<300).contains(status) else {
            if status == 401 && endpoint.requiresAuth {
                session.clear()
                throw APIError.unauthorized
            }
            let body = try? decoder.decode(APIErrorBody.self, from: data)
            throw APIError.server(body?.message ?? body?.error ?? "Request failed (\(status))")
        }

        let envelope: APIResponse<T>
        do {
            envelope = try decoder.decode(APIResponse<T>.self, from: data)
        } catch {
            log("Decoding \(T.self) failed: \(error)")
            throw APIError.decoding
        }

        guard envelope.success else {
            throw APIError.server(envelope.message ?? "Something went wrong")
        }
        return envelope
    }

    private func makeRequest(for endpoint: Endpoint) throws -> URLRequest {
        var components = URLComponents(
            url: AppConfig.baseURL.appending(path: endpoint.path),
            resolvingAgainstBaseURL: false
        )!
        if !endpoint.query.isEmpty {
            components.queryItems = endpoint.query
        }

        var request = URLRequest(url: components.url!)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = endpoint.body {
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        if endpoint.requiresAuth, let token = session.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    /// Debug-only request log, like OkHttp's HttpLoggingInterceptor.
    /// Shows up in Xcode's console (⌘⇧Y), filtered by "API".
    private func log(_ message: String) {
        #if DEBUG
        logger.debug("\(message, privacy: .public)")
        #endif
    }
}
