import Foundation
import WidgetKit

enum SharedDataService {
    private static let suiteName = "group.app.rork.6vtblymiqi8mn2qxg1jtu.shared"

    static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    static func saveLatestNote(_ content: String, from sender: String) {
        let defaults = sharedDefaults
        defaults?.set(content, forKey: "latestNoteContent")
        defaults?.set(sender, forKey: "latestNoteSender")
        defaults?.set(Date().timeIntervalSince1970, forKey: "latestNoteTimestamp")
        WidgetCenter.shared.reloadAllTimelines()
    }

    static func getLatestNote() -> (content: String, sender: String, timestamp: Date)? {
        guard let defaults = sharedDefaults,
              let content = defaults.string(forKey: "latestNoteContent"),
              let sender = defaults.string(forKey: "latestNoteSender") else {
            return nil
        }
        let timestamp = defaults.double(forKey: "latestNoteTimestamp")
        return (content, sender, Date(timeIntervalSince1970: timestamp))
    }

    static func clearData() {
        let defaults = sharedDefaults
        defaults?.removeObject(forKey: "latestNoteContent")
        defaults?.removeObject(forKey: "latestNoteSender")
        defaults?.removeObject(forKey: "latestNoteTimestamp")
        WidgetCenter.shared.reloadAllTimelines()
    }
}
