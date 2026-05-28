import Foundation

public enum DictionaryMode: String, Codable, CaseIterable, Sendable {
    case engeng = "engeng"
    case engviet = "engviet"

    public var displayName: String {
        switch self {
        case .engeng: return "English - English"
        case .engviet: return "English - Vietnamese"
        }
    }
}

public final class PreferencesManager: Sendable {
    public static let shared = PreferencesManager()
    nonisolated(unsafe) private let defaults = UserDefaults.standard
    private let modeKey = "dictionaryMode"

    private init() {}

    public var dictionaryMode: DictionaryMode {
        get {
            if let raw = defaults.string(forKey: modeKey),
               let mode = DictionaryMode(rawValue: raw) {
                return mode
            }
            return .engviet
        }
        set {
            defaults.set(newValue.rawValue, forKey: modeKey)
        }
    }
}
