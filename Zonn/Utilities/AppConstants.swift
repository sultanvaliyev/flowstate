import Foundation

enum AppConstants {
    enum BundleIdentifiers {
        static let spotify = "com.spotify.client"
    }

    enum UserDefaultsKeys {
        static let legacySessions = "com.zonn.sessions"
        static let migrationCompleted = "com.zonn.migrationCompleted"
        static let lastDuration = "com.zonn.lastDuration"
    }

    enum LoggerSubsystem {
        static let main = "app.zonn.Zonn"
    }

    enum Validation {
        static let maxSessionLabelLength = 50
    }
}
