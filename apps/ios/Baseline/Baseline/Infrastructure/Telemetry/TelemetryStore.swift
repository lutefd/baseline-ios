import Foundation

final class TelemetryStore {
    private let defaults: UserDefaults

    private enum Keys {
        static let saveCount = "telemetry.saveCount"
        static let totalFormSeconds = "telemetry.totalFormSeconds"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func recordSave(formDurationSeconds: TimeInterval) {
        let currentSaves = defaults.integer(forKey: Keys.saveCount)
        defaults.set(currentSaves + 1, forKey: Keys.saveCount)

        let currentDuration = defaults.double(forKey: Keys.totalFormSeconds)
        defaults.set(currentDuration + formDurationSeconds, forKey: Keys.totalFormSeconds)
    }

    var saveCount: Int {
        defaults.integer(forKey: Keys.saveCount)
    }

    var averageFormDurationSeconds: Double {
        let count = max(saveCount, 1)
        let total = defaults.double(forKey: Keys.totalFormSeconds)
        return total / Double(count)
    }
}
