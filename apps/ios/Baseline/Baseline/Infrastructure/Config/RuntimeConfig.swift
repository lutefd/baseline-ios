import Foundation

struct RuntimeConfig {
    let baseURL: URL
    let apiToken: String

    enum ConfigError: Error {
        case missingConfiguration
    }

    static func load(secretsProvider: SecretsProvider = SecretsProvider()) throws -> RuntimeConfig {
        do {
            let baseURL = try secretsProvider.loadBaseURL()
            let token = try secretsProvider.loadAPIToken()
            return RuntimeConfig(baseURL: baseURL, apiToken: token)
        } catch {
            throw ConfigError.missingConfiguration
        }
    }
}
