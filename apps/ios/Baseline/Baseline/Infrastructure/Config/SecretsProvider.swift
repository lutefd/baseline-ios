import Foundation
import Security

struct SecretsProvider {
    private enum Keys {
        static let baseURL = "baseline.sync.baseURL"
        static let apiToken = "baseline.sync.apiToken"
    }

    private enum LocalSecrets {
        static let fileName = "LocalSecrets"
        static let fileExtension = "plist"
        static let baseURLKey = "API_BASE_URL"
        static let apiTokenKey = "API_TOKEN"
    }

    enum SecretError: Error {
        case missingBaseURL
        case missingToken
        case invalidBaseURL
    }

    func loadBaseURL() throws -> URL {
        try seedFromLocalSecretsIfNeeded()
        guard let baseURLString = readString(for: Keys.baseURL), !baseURLString.isEmpty else {
            throw SecretError.missingBaseURL
        }
        guard let url = URL(string: baseURLString) else {
            throw SecretError.invalidBaseURL
        }
        return url
    }

    func loadAPIToken() throws -> String {
        try seedFromLocalSecretsIfNeeded()
        guard let token = readString(for: Keys.apiToken), !token.isEmpty else {
            throw SecretError.missingToken
        }
        return token
    }

    private func seedFromLocalSecretsIfNeeded() throws {
        let hasBaseURL = !(readString(for: Keys.baseURL) ?? "").isEmpty
        let hasToken = !(readString(for: Keys.apiToken) ?? "").isEmpty
        guard !hasBaseURL || !hasToken else { return }

        guard let url = Bundle.main.url(forResource: LocalSecrets.fileName, withExtension: LocalSecrets.fileExtension),
              let data = try? Data(contentsOf: url),
              let raw = try? PropertyListSerialization.propertyList(from: data, format: nil),
              let plist = raw as? [String: Any]
        else {
            return
        }

        if !hasBaseURL,
           let baseURL = plist[LocalSecrets.baseURLKey] as? String,
           !baseURL.isEmpty {
            _ = saveString(baseURL, for: Keys.baseURL)
        }

        if !hasToken,
           let token = plist[LocalSecrets.apiTokenKey] as? String,
           !token.isEmpty {
            _ = saveString(token, for: Keys.apiToken)
        }
    }

    private func readString(for key: String) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: Bundle.main.bundleIdentifier ?? "Baseline",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data,
              let string = String(data: data, encoding: .utf8)
        else {
            return nil
        }
        return string
    }

    @discardableResult
    private func saveString(_ value: String, for key: String) -> Bool {
        let data = Data(value.utf8)
        let service = Bundle.main.bundleIdentifier ?? "Baseline"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: service
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if updateStatus == errSecSuccess {
            return true
        }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        return addStatus == errSecSuccess
    }
}
