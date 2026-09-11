import Foundation

protocol PreferencesStoring {
    func load() -> LauncherPreferences
    func save(_ preferences: LauncherPreferences)
}

/// Persists `LauncherPreferences` as JSON inside `UserDefaults`.
final class PreferencesStore: PreferencesStoring {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "com.startmenu.launcher.preferences") {
        self.defaults = defaults
        self.key = key
    }

    func load() -> LauncherPreferences {
        guard let data = defaults.data(forKey: key) else {
            return LauncherPreferences()
        }
        do {
            return try JSONDecoder().decode(LauncherPreferences.self, from: data)
        } catch {
            return LauncherPreferences()
        }
    }

    func save(_ preferences: LauncherPreferences) {
        do {
            let data = try JSONEncoder().encode(preferences)
            defaults.set(data, forKey: key)
        } catch {
            // Persisting preferences is best effort; a failed save must never
            // prevent the launcher from opening.
        }
    }
}
