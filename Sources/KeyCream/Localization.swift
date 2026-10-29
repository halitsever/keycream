import Foundation

/** Menu strings in the language chosen from the menu, or the first supported system language. */
enum Localization {
    static let languages: [(code: String, name: String)] = [
        ("tr", "Türkçe"), ("en", "English"), ("de", "Deutsch"), ("fr", "Français"),
        ("es", "Español"), ("pt", "Português"), ("ru", "Русский"), ("ja", "日本語"),
        ("ko", "한국어"), ("zh-Hans", "简体中文"), ("ar", "العربية"), ("hi", "हिन्दी"),
    ]
    private static let fallback = "tr"
    /** Same key System Settings writes for a per-app language, so both stay in sync. */
    private static let appleLanguagesKey = "AppleLanguages"

    /** nil means follow the system. */
    static var override: String? {
        get {
            guard let domain = Bundle.main.bundleIdentifier,
                  let preferred = UserDefaults.standard.persistentDomain(forName: domain)?[appleLanguagesKey] as? [String] else {
                return nil
            }
            return preferred.lazy.compactMap(supportedCode(for:)).first
        }
        set {
            if let newValue {
                UserDefaults.standard.set([newValue], forKey: appleLanguagesKey)
            } else {
                UserDefaults.standard.removeObject(forKey: appleLanguagesKey)
            }
            cachedBundle = nil
        }
    }

    static func string(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    private static var cachedBundle: Bundle?

    private static var bundle: Bundle {
        if let cachedBundle { return cachedBundle }
        let code = override ?? systemLanguage
        let resolved = Bundle.main.path(forResource: code, ofType: "lproj").flatMap(Bundle.init(path:)) ?? Bundle.main
        cachedBundle = resolved
        return resolved
    }

    /** Read from global preferences because the app domain may still hold an override set earlier in this run. */
    private static var systemLanguage: String {
        let global = CFPreferencesCopyValue(
            appleLanguagesKey as CFString, kCFPreferencesAnyApplication, kCFPreferencesCurrentUser, kCFPreferencesAnyHost
        ) as? [String] ?? Locale.preferredLanguages
        return global.lazy.compactMap(supportedCode(for:)).first ?? fallback
    }

    private static func supportedCode(for identifier: String) -> String? {
        let language = Locale.Language(identifier: identifier)
        guard let code = language.languageCode?.identifier else { return nil }
        if code == "zh" {
            return language.script?.identifier == "Hans" || ["CN", "SG"].contains(language.region?.identifier) ? "zh-Hans" : nil
        }
        return languages.contains { $0.code == code } ? code : nil
    }
}
