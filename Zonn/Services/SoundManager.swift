import AppKit

/// Manages sound playback for the app, particularly completion sounds
/// Uses NSSound for simple, lightweight system sound integration
final class SoundManager {

    // MARK: - Singleton

    static let shared = SoundManager()

    // MARK: - Properties

    /// Whether sound effects are enabled (persisted to UserDefaults)
    var isSoundEnabled: Bool {
        get {
            // Default to true if not set
            if UserDefaults.standard.object(forKey: Keys.soundEnabled) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: Keys.soundEnabled)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Keys.soundEnabled)
        }
    }

    // MARK: - Constants

    private enum Keys {
        static let soundEnabled = "com.zonn.soundEnabled"
    }

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Plays a pleasant completion sound when a focus session completes
    /// Uses the system "Glass" sound which is subtle and pleasant
    func playCompletionSound() {
        guard isSoundEnabled else { return }

        // Try playing the system "Glass" sound first (pleasant and subtle)
        if let sound = NSSound(named: "Glass") {
            sound.play()
            return
        }

        // Fallback to Hero sound if Glass is unavailable
        if let sound = NSSound(named: "Hero") {
            sound.play()
            return
        }

        // Final fallback to Ping
        if let sound = NSSound(named: "Ping") {
            sound.play()
        }
    }
}
