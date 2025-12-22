import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), state: .neutral)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let state = SharedData.loadState()
        let entry = SimpleEntry(date: Date(), state: state)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        let state = SharedData.loadState()
        
        // Refresh every 15 minutes
        for hourOffset in 0 ..< 4 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: hourOffset * 15, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, state: state)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let state: AvatarState
}

struct PixelPalWidgetEntryView : View {
    var entry: Provider.Entry
    
    // For the widget, we might want to show a specific frame or alternate based on time?
    // Widgets are static snapshots. We can't animate easily.
    // But we can use the date to pick a frame if we wanted to simulate slow breathing?
    // "Widgets cannot animate freely... Use 2-frame pixel shifts to imply breathing... Timeline entries should be conservative"
    // We can't really do 2-frame animation in a standard widget without frequent timeline updates which is bad for battery.
    // However, the user request says: "Alternate between Frame A / Frame B on refresh"
    // So we can just pick a random frame or based on minute?
    // Let's pick based on the minute to have some variation if it refreshes.
    
    var frameIndex: Int {
        let minute = Calendar.current.component(.minute, from: entry.date)
        return minute % 2
    }

    var body: some View {
        VStack {
            Image(uiImage: imageForState(entry.state, frame: frameIndex))
                .resizable()
                .interpolation(.none)
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
        }
    }
    
    func imageForState(_ state: AvatarState, frame: Int) -> UIImage {
        let name: String
        switch state {
        case .vital: name = "vital_\(frame + 1)"
        case .neutral: name = "neutral_\(frame + 1)"
        case .lowEnergy: name = "low_\(frame + 1)"
        }
        // Assuming assets are available in the Widget target bundle
        return UIImage(named: name) ?? UIImage()
    }
}

@main
struct PixelPalWidget: Widget {
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
