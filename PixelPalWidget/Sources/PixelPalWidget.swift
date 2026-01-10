import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), state: .low, gender: .male, phase: 1)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let state = SharedData.loadState()
        let gender = SharedData.loadGender() ?? .male
        let phase = SharedData.loadPhase()
        let entry = SimpleEntry(date: Date(), state: state, gender: gender, phase: phase)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        let currentDate = Date()
        let state = SharedData.loadState()
        let gender = SharedData.loadGender() ?? .male
        let phase = SharedData.loadPhase()

        // Create entries for the next hour (refresh every 15 minutes)
        var entries: [SimpleEntry] = []
        for minuteOffset in stride(from: 0, to: 60, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, state: state, gender: gender, phase: phase)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct SimpleEntry: TimelineEntry {
    let date: Date
    let state: AvatarState
    let gender: Gender
    let phase: Int
}

// MARK: - Widget View

/// Widget view per v1.1 spec: Character + phase icon only, NO numbers.
struct PixelPalWidgetEntryView: View {
    var entry: Provider.Entry

    /// Frame selection based on minute (static snapshot, changes on refresh)
    private var frameNumber: Int {
        let minute = Calendar.current.component(.minute, from: entry.date)
        return (minute % 2) + 1
    }

    private var phaseColor: Color {
        switch entry.phase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }

    private var phaseIcon: String {
        switch entry.phase {
        case 1: return "circle"
        case 2: return "circle.fill"
        case 3: return "star.fill"
        case 4: return "sparkles"
        default: return "circle"
        }
    }

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            gender: entry.gender,
            state: entry.state,
            frame: frameNumber
        )

        VStack(spacing: 8) {
            // Character
            Image(spriteName)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)

            // Phase indicator (icon only per v1.1 spec - no numbers, no text)
            HStack(spacing: 4) {
                Image(systemName: phaseIcon)
                    .font(.caption)
                    .foregroundColor(phaseColor)
                Text("Phase \(entry.phase)")
                    .font(.caption2)
                    .foregroundColor(phaseColor.opacity(0.8))
            }
        }
    }
}

// MARK: - Accessory Widget Views (Lock Screen)

/// Lock Screen circular widget per v1.1 spec: character only, no numbers
@available(iOS 16.0, *)
struct PixelPalAccessoryCircularView: View {
    var entry: Provider.Entry

    private var frameNumber: Int {
        let minute = Calendar.current.component(.minute, from: entry.date)
        return (minute % 2) + 1
    }

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            gender: entry.gender,
            state: entry.state,
            frame: frameNumber
        )

        ZStack {
            AccessoryWidgetBackground()
            Image(spriteName)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .padding(4)
        }
    }
}

/// Lock Screen rectangular widget per v1.1 spec: character + phase icon only
@available(iOS 16.0, *)
struct PixelPalAccessoryRectangularView: View {
    var entry: Provider.Entry

    private var frameNumber: Int {
        let minute = Calendar.current.component(.minute, from: entry.date)
        return (minute % 2) + 1
    }

    private var phaseColor: Color {
        switch entry.phase {
        case 1: return .gray
        case 2: return .blue
        case 3: return .purple
        case 4: return .orange
        default: return .gray
        }
    }

    private var phaseIcon: String {
        switch entry.phase {
        case 1: return "circle"
        case 2: return "circle.fill"
        case 3: return "star.fill"
        case 4: return "sparkles"
        default: return "circle"
        }
    }

    var body: some View {
        let spriteName = SpriteAssets.spriteName(
            gender: entry.gender,
            state: entry.state,
            frame: frameNumber
        )

        HStack(spacing: 8) {
            Image(spriteName)
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)

            // Phase indicator only (no numbers per spec)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: phaseIcon)
                        .font(.caption2)
                        .foregroundColor(phaseColor)
                    Text("Phase \(entry.phase)")
                        .font(.caption2)
                        .fontWeight(.medium)
                }
            }

            Spacer()
        }
    }
}

/// Lock Screen inline widget per v1.1 spec: phase icon only
@available(iOS 16.0, *)
struct PixelPalAccessoryInlineView: View {
    var entry: Provider.Entry

    private var phaseIcon: String {
        switch entry.phase {
        case 1: return "circle"
        case 2: return "circle.fill"
        case 3: return "star.fill"
        case 4: return "sparkles"
        default: return "circle"
        }
    }

    var body: some View {
        // Inline: Just phase indicator, no numbers per v1.1 spec
        Label("PixelPal Phase \(entry.phase)", systemImage: phaseIcon)
    }
}

// MARK: - Home Screen Widget

struct PixelPalHomeWidget: Widget {
    let kind: String = "PixelPalWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                PixelPalWidgetEntryView(entry: entry)
                    .containerBackground(.black, for: .widget)
            } else {
                PixelPalWidgetEntryView(entry: entry)
                    .padding()
                    .background(Color.black)
            }
        }
        .configurationDisplayName("Pixel Pal")
        .description("Your ambient walking companion.")
        .supportedFamilies([.systemSmall])
    }
}

// MARK: - Lock Screen Widgets

@available(iOS 16.0, *)
struct PixelPalLockScreenWidget: Widget {
    let kind: String = "PixelPalLockScreenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                PixelPalLockScreenView(entry: entry)
                    .containerBackground(.clear, for: .widget)
            } else {
                PixelPalLockScreenView(entry: entry)
            }
        }
        .configurationDisplayName("Pixel Pal")
        .description("Your PixelPal on the Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

@available(iOS 16.0, *)
struct PixelPalLockScreenView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    var body: some View {
        switch widgetFamily {
        case .accessoryCircular:
            PixelPalAccessoryCircularView(entry: entry)
        case .accessoryRectangular:
            PixelPalAccessoryRectangularView(entry: entry)
        case .accessoryInline:
            PixelPalAccessoryInlineView(entry: entry)
        default:
            PixelPalWidgetEntryView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle

@main
struct PixelPalWidgetBundle: WidgetBundle {
    var body: some Widget {
        PixelPalHomeWidget()
        if #available(iOS 16.0, *) {
            PixelPalLockScreenWidget()
        }
        PixelPalLiveActivity()
    }
}
