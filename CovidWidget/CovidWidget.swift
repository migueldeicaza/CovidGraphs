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
import Charts
import Shapes

struct CovidChartView: View {
    @Environment(\.redactionReasons) private var reasons

    var stat: [Int]
    
    // Maps from integers to 0..1
    func convertStats (_ v: [Int]) -> [CGFloat]
    {
        if !reasons.isEmpty {
            return []
        }
        if let min = v.min () {
            if let max = v.max () {
                let d = CGFloat (max-min)
                var result: [CGFloat] = []
        
                for x in v {
                    result.append(CGFloat (x-min) / d)
                }
                print ("\(result)")
                return result
            }
        }
        return [0.0]
    }
    
    var body: some View {
        ZStack {
            //Color (.red)
            HStack {
                
                VStack {
                    Chart(data: convertStats (stat))
                        .chartStyle(
                           LineChartStyle(.quadCurve, lineColor: Color ("MainTextColor"), lineWidth: 2))

                        .background(
                            GridPattern(horizontalLines: 8, verticalLines: 12)
                               .inset(by: 1)
                            .stroke(Color.white.opacity(0.1), style: .init(lineWidth: 1, lineCap: .round)))

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

struct LocationView: View {
    @Binding var stat: Stats
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

struct GeographyStatView: View {
    @State var stat: Stats
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            Color ("BackgroundColor")
            VStack (alignment: .leading, spacing: 2.0){
                
                LocationView(stat: $stat)
                switch family {
                case .systemSmall:
                    CovidChartView (stat: stat.casesDelta)
                default:
                    HStack (spacing: 20){
                        CovidChartView (stat: stat.casesDelta)
                        CovidChartView (stat: stat.deathsDelta)
                    }
                }
                //
                Spacer ().frame(minHeight: 0)
                VStack  {
                    HStack {
                        Text (fmtDelta (stat.deltaCases))
                            .font (.title3)
                            .lineLimit(1)
                            

                            Spacer (minLength: 12)
                            Text (fmtDelta (stat.deltaDeaths))
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
        //GeographyStatView(stat: fetch(code: "Massachusetts"))
        //GeographyStatView(stat: fetch(code: "13209.0"))
        GeographyStatView(stat: fetch(code: "Spain"))
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
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .environment(\.sizeCategory, .extraExtraExtraLarge)


        }
    }
}

