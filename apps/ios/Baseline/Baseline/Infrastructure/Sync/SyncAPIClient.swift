import Foundation

struct SyncAPIClient {
    enum APIError: Error {
        case invalidResponse
        case httpError(Int)
    }

    private let config: RuntimeConfig
    private let session: URLSession

    init(config: RuntimeConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func push(_ payload: SyncPushRequestDTO) async throws -> SyncPushResponseDTO {
        let url = config.baseURL.appending(path: "v1/sync/push")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try SyncDateCoding.makeEncoder().encode(payload)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        return try SyncDateCoding.makeDecoder().decode(SyncPushResponseDTO.self, from: data)
    }

    func pull(updatedAfter: Date) async throws -> SyncPullResponseDTO {
        var components = URLComponents(url: config.baseURL.appending(path: "v1/sync/pull"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "updatedAfter", value: SyncDateCoding.makeEncoderDateString(updatedAfter))
        ]
        let url = components?.url ?? config.baseURL.appending(path: "v1/sync/pull")

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        return try SyncDateCoding.makeDecoder().decode(SyncPullResponseDTO.self, from: data)
    }
}

private extension SyncDateCoding {
    static func makeEncoderDateString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
    }
}
