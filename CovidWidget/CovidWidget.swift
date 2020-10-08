//
//  CovidWidget.swift
//  CovidWidget
//
//  Created by Miguel de Icaza on 10/5/20.
//

import WidgetKit
import SwiftUI
import Intents
import SharedCode

struct OneStat: View {
    var caption, total, delta: String
    
    var body: some View {
        VStack (alignment: .trailing) {
            //Text (caption).font(.footnote)
            Text (delta)
                .font (.title3)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text (total)
                .font(.footnote)
                .foregroundColor(Color ("SubTextColor"))
                .lineLimit(1)
                .minimumScaleFactor(0.8  )


        }
    }
}
struct GeographyStatView: View {
    var stat: Stats
    
    var body: some View {
        ZStack {
            Color ("BackgroundColor")
            VStack (alignment: .leading){
                HStack {
                    Text(stat.caption)
                        .bold()
                        .font (.body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        
                    Spacer ()
                }
                Spacer ()
                HStack (alignment: .top, spacing: 5) {
                        OneStat (caption: "Total", total: stat.totalCases, delta: stat.deltaCases)
                    Spacer ()
                        //OneStat (caption: "Recovered", major: stat.recoveredCases, minor: stat.deltaRecovered)
                        OneStat (caption: "Deaths", total: stat.deaths, delta: stat.deltaDeaths)

                }
                
            }
            .foregroundColor(Color ("MainTextColor"))
            .padding()
        }
    }
}

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct CovidWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        GeographyStatView(stat: us_ma_Stat)
    }
}

@main
struct CovidWidget: Widget {
    let kind: String = "CovidWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            CovidWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemSmall])

    }
}

struct CovidWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CovidWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            CovidWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.colorScheme, .dark)
            
            CovidWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.sizeCategory, .extraExtraExtraLarge)
            
            CovidWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .redacted(reason: .placeholder)

        }
    }
}
