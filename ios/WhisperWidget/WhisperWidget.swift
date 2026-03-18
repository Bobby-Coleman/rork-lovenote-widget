import WidgetKit
import SwiftUI

nonisolated struct WhisperEntry: TimelineEntry {
    let date: Date
    let noteContent: String
    let senderName: String
    let hasNote: Bool
}

nonisolated struct WhisperProvider: TimelineProvider {
    private let suiteName = "group.app.rork.6vtblymiqi8mn2qxg1jtu.shared"

    func placeholder(in context: Context) -> WhisperEntry {
        WhisperEntry(date: .now, noteContent: "you're my favorite person", senderName: "someone", hasNote: true)
    }

    func getSnapshot(in context: Context, completion: @escaping (WhisperEntry) -> Void) {
        let entry = loadEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WhisperEntry>) -> Void) {
        let entry = loadEntry()
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date())!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadEntry() -> WhisperEntry {
        guard let defaults = UserDefaults(suiteName: suiteName),
              let content = defaults.string(forKey: "latestNoteContent"),
              let sender = defaults.string(forKey: "latestNoteSender") else {
            return WhisperEntry(date: .now, noteContent: "", senderName: "", hasNote: false)
        }
        return WhisperEntry(date: .now, noteContent: content, senderName: sender, hasNote: true)
    }
}

struct WhisperWidgetView: View {
    var entry: WhisperEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallWidget
            case .systemMedium:
                mediumWidget
            case .accessoryRectangular:
                lockScreenRectangular
            case .accessoryCircular:
                lockScreenCircular
            default:
                mediumWidget
            }
        }
    }

    private var smallWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.hasNote {
                Text(entry.noteContent)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundStyle(.black)
                    .lineLimit(4)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                Text("— \(entry.senderName)")
                    .font(.system(.caption2, design: .serif))
                    .foregroundStyle(.black.opacity(0.5))
            } else {
                Spacer()
                Image(systemName: "heart")
                    .font(.title2)
                    .foregroundStyle(.black.opacity(0.2))
                    .frame(maxWidth: .infinity)
                Spacer()
                Text("whisper")
                    .font(.system(.caption2, design: .serif))
                    .foregroundStyle(.black.opacity(0.4))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.white, for: .widget)
    }

    private var mediumWidget: some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.hasNote {
                Text(entry.noteContent)
                    .font(.system(.body, design: .serif))
                    .foregroundStyle(.black)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()

                HStack {
                    Text("— \(entry.senderName)")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.black.opacity(0.5))
                    Spacer()
                    Text("whisper")
                        .font(.system(.caption2, design: .serif))
                        .foregroundStyle(.black.opacity(0.3))
                }
            } else {
                Spacer()
                VStack(spacing: 6) {
                    Image(systemName: "heart")
                        .font(.title2)
                        .foregroundStyle(.black.opacity(0.2))
                    Text("no whispers yet")
                        .font(.system(.caption, design: .serif))
                        .foregroundStyle(.black.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.white, for: .widget)
    }

    private var lockScreenRectangular: some View {
        VStack(alignment: .leading, spacing: 2) {
            if entry.hasNote {
                Text(entry.noteContent)
                    .font(.system(.caption, design: .serif))
                    .lineLimit(2)
                Text("— \(entry.senderName)")
                    .font(.system(.caption2, design: .serif))
                    .foregroundStyle(.secondary)
            } else {
                Text("whisper")
                    .font(.system(.caption, design: .serif))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(.fill, for: .widget)
    }

    private var lockScreenCircular: some View {
        ZStack {
            if entry.hasNote {
                Image(systemName: "heart.fill")
                    .font(.title3)
            } else {
                Image(systemName: "heart")
                    .font(.title3)
            }
        }
        .containerBackground(.fill, for: .widget)
    }
}

struct WhisperWidget: Widget {
    let kind: String = "WhisperWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WhisperProvider()) { entry in
            WhisperWidgetView(entry: entry)
        }
        .configurationDisplayName("Whisper")
        .description("See your partner's latest love note.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryRectangular,
            .accessoryCircular,
        ])
        .containerBackgroundRemovable(false)
    }
}
