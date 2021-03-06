//
//  CovidWidget.swift
//  CovidWidget
//
//  Created by Miguel de Icaza on 10/5/20.
//

import WidgetKit
import SwiftUI
import Intents
import Charts
import Shapes
import Combine

struct LocationView: View {
    var stat: Stats
    var body: some View {
        ZStack {
            //Color (.blue)
            VStack {
                HStack {
                    Text(stat.caption)
                        .bold()
                        .font (.body)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer ()
                }
                if let sub = stat.subCaption {
                    HStack {
                        Text (sub)
                            .font (.footnote)
                            .fontWeight(.light)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer ()
                    }
                }
            }
        }
    }
}

struct CovidChartView: View {
    @Environment(\.redactionReasons) private var reasons
    //var c: Color = Color ("BackgroundColor").colorMultiply(.accentColor)
    var stat: [Int]
    var smooth: [Int] = []
    var count = 20
    
    var body: some View {
        ZStack {
            //Color (.red)
            HStack {
                VStack {
                    ZStack {
                        Chart(data: reasons.isEmpty ? convertStats (stat, count: count) :  [])
                            .chartStyle(
                                MyColumnChartStyle(column: Capsule().foregroundColor(Color ("BackgroundColor")).blendMode(.screen), spacing: 0.5))


                        Chart(data: reasons.isEmpty ? convertStats (smooth, count: count) :  [])
                            .chartStyle(
                               LineChartStyle(.quadCurve, lineColor: Color ("MainTextColor"), lineWidth: 2))

                            .background(
                                GridPattern(horizontalLines: 8, verticalLines: 12)
                                   .inset(by: 1)
                                .stroke(Color.white.opacity(0.1), style: .init(lineWidth: 1, lineCap: .round)))

                    }
                    .frame(minHeight: 40, maxHeight: .infinity)
               }
               //.layoutPriority(1)
            }
        }
    }
}

// Scenarios:
//   countryRegion == "US" && admin = nil, this is a state in "provinceState"
//   countryRegion == "US", state is provinceState, county is "admin"
//   otherwise Country == specified, provinceRegion is the subregioin

struct GeographyStatView: View {
    @State var updatableStat: UpdatableStat
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color ("BackgroundColor")
            VStack (alignment: .leading, spacing: 2.0){
                if let stat = updatableStat.stat {
                    LocationView(stat: stat)
                    switch family {
                    case .systemSmall:
                        CovidChartView (stat: stat.casesDelta, smooth: stat.casesDeltaSmooth)
                    default:
                        HStack (spacing: 20){
                            CovidChartView (stat: stat.casesDelta, smooth: stat.casesDeltaSmooth)
                            CovidChartView (stat: stat.deathsDelta, smooth: stat.deathsDeltaSmooth)
                            //CovidChartView (stat: stat.deathsDelta, smooth: stat.casesDelta, count: 200)
                        }
                    }
                    //
                    Spacer ().frame(minHeight: 0)
                    VStack  {
                        HStack {
                            Text (fmtDelta (stat.deltaCases, compress: family == .systemSmall))
                                .font (.title3)
                                .lineLimit(1)
                                

                                Spacer (minLength: 12)
                                Text (fmtDelta (stat.deltaDeaths, compress: family == .systemSmall))
                                    .font (.title3)
                                    .lineLimit(1)
                                    

                        }.minimumScaleFactor(0.7)
                        HStack {
                            Text (family == .systemSmall ? fmtLarge (stat.totalCases) : fmtDigit (stat.totalCases))
                                .font(.footnote)
                                .foregroundColor(Color ("SubTextColor"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8  )
                            Spacer (minLength: 12)
                            Text (fmtLarge (stat.totalDeaths))
                                .font(.footnote)
                                .foregroundColor(Color ("SubTextColor"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8  )
                        }
                    }
                } else {
                    Text ("Loading")
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
        // Entries, the first one is the current time
        var entries: [SimpleEntry] = [SimpleEntry (date: Date (), configuration: configuration)]

        
        // The database around 5:45, and I leave some time for any late additions, so make it 6am
        let current = Date()
        if let est = TimeZone (abbreviation: "EST") {
            var components = Calendar.current.dateComponents(in: est, from: current)
            
            // The cron job updates at 6am EST
            components.hour = 6
            components.minute = 10
            if let morning = components.date {
                var target = morning >= current ? morning : Calendar.current.date(byAdding: .day, value: 1, to: morning)
                entries.append (SimpleEntry(date: morning, configuration: configuration))
            }
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

var widgets: [UpdatableStat] = []
var cancel: [AnyCancellable] = []

struct CovidWidgetEntryView : View {
    var entry: Provider.Entry

    func startStat () -> UpdatableStat
    {
        let s = UpdatableStat(code: "Massachusetts", sync: true)
        return s
    }
    
    var body: some View {
        //GeographyStatView(stat: fetch(code: "Massachusetts"))
        //GeographyStatView(stat: fetch(code: "13209.0"))
        GeographyStatView(updatableStat: startStat ())
    }
}

@main
struct CovidWidget: Widget {
    let kind: String = "CovidWidget"
    
    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            CovidWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Covid Widget")
        .description("Display statistics Covid Statistics.")
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
                .redacted(reason: .placeholder)

            CovidWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemMedium))

            CovidWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemLarge))

            CovidWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.sizeCategory, .extraExtraExtraLarge)


        }
    }
}

