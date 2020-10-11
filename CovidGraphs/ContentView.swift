//
//  ContentView.swift
//  CovidGraphs
//
//  Created by Miguel de Icaza on 10/5/20.
//

import SwiftUI
import SharedCode
import Charts
import Shapes

var spain = fetch(code: "Spain")
var ma = fetch(code: "Massachusetts")
var fr = fetch(code: "France")
var x = fetch (code:"California")

struct ResizableSingleLine: ViewModifier {
    func body(content: Content) -> some View {
            content
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
}
struct StatDisplay: View {
    @Binding var stat: Stats
    var body: some View {
        HStack {
            VStack (alignment: .leading) {
                Text ("Deaths: ")
                    .bold()
                    .modifier(ResizableSingleLine())
                Text ("Cases: ")
                    .bold()
                    .modifier(ResizableSingleLine())

            }
            .foregroundColor(.secondary)
            Spacer ()
            VStack (alignment: .trailing) {
                Text ("+\(fmtDigit(stat.deltaDeaths))")
                    .bold()
                    .modifier(ResizableSingleLine())
                Text ("+\(fmtDigit(stat.deltaCases))")
                    .bold()
                    .modifier(ResizableSingleLine())
                    
            }
    

            VStack (alignment: .trailing) {
                Text ("\(fmtDigit(stat.totalDeaths))")
                    .modifier(ResizableSingleLine())
                Text ("\(fmtDigit(stat.totalCases))")
                    .modifier(ResizableSingleLine())
            }
            .foregroundColor(.secondary)
            .font(.body)
        }
    }
}
struct LocationView: View {
    @Binding var stat: Stats
    var body: some View {
        ZStack {
            //Color ("BackgroundColor")
            VStack {
                HStack {
                    VStack {
                        HStack {
                            Text(stat.caption)
                                .font (.title2)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Spacer ()
                        }
                        if let sub = stat.subCaption {
                            HStack {
                                Text (sub)
                                    .font (.title3)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.7)
                                    .foregroundColor(.secondary)
                                Spacer ()
                            }
                        }
                        Spacer ()
                        StatDisplay(stat: $stat)
                        
                    }
                    Chart(data: convertStats (stat.casesDelta))
                        .chartStyle(
                           LineChartStyle(.quadCurve, lineColor: Color ("BackgroundColor"), lineWidth: 2))

                        .background(
                            GridPattern(horizontalLines: 8, verticalLines: 12)
                               .inset(by: 1)
                                .stroke(Color (.secondaryLabel).opacity(0.2), style: .init(lineWidth: 1, lineCap: .round)))
                        .padding ([.leading])

                }
            }.padding(8)
        }
        .frame(minHeight: 60, maxHeight: 100)
        .padding([.leading, .trailing], 8)
        .padding ([.bottom], 6)
    }
}

struct ContentView: View {
    @State var locations: [Stats]
    @State private var editMode = EditMode.inactive
    
    var body: some View {
            NavigationView {
                ZStack {
                    VStack {
                        ForEach(locations, id: \.caption) { loc in
                            LocationView (stat: .constant (loc))
                            Divider().background(Color (.secondaryLabel))
                                .padding([.trailing,.leading], 8)
                        }
                        .navigationBarItems(leading: HeaderView (), trailing: EditButton())

                        Spacer ()
                    }
                }

            }

    }
}

struct HeaderView: View {
    func formatDate () -> String
    {
        let dateFormatter = DateFormatter ()
        dateFormatter.dateFormat = "MMMM dd"
        return dateFormatter.string(from: Date ())
    }
    
    var body: some View {
        VStack {
            HStack {
                Text ("Covid Statisitics")
                    .font (.title)
                    .bold()
                Spacer ()
            }
            HStack {
                Text (formatDate())
                    .font (.title2)
                    .bold()
                    .foregroundColor(.secondary)
                Spacer ()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView(locations: [
                fetch(code: "Spain"),
                fetch(code: "Massachusetts"),
                fetch(code: "46005.0"),
                fetch (code:"California")
            ])
            ContentView(locations: [
                fetch(code: "Spain"),
                fetch(code: "Massachusetts"),
                fetch(code: "46005.0"),
                fetch (code:"California")
            ])
            .environment(\.colorScheme, .dark)
            ContentView(locations: [
                fetch(code: "Spain"),
                fetch(code: "Massachusetts"),
                fetch(code: "46005.0"),
                fetch (code:"California")
            ])
            .environment(\.colorScheme, .dark)
            .environment(\.sizeCategory, .extraExtraExtraLarge)

        }
    }
}
