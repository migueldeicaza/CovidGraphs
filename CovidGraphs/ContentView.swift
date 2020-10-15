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

struct SummaryLocationView: View {
    @Binding var loc: UpdatableStat
    var body: some View {
        ZStack {
            HStack {
                VStack {
                    HStack {
                        Text(loc.stat?.caption ?? loc.code)
                            .font (.title2)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer ()
                    }
                    if let sub = loc.stat?.subCaption {
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
                    if let stat = loc.stat {
                        StatDisplay(stat: .constant (stat))
                    } else {
                        ZStack {
                            StatDisplay (stat: .constant (emptyStat)).redacted(reason: .placeholder)
                            ProgressView ()
                        }
                    }
                }
                Chart(data: convertStats (loc.stat?.casesDelta ?? [], count: 40))
                    .chartStyle(
                        LineChartStyle(.quadCurve, lineColor: Color.accentColor, lineWidth: 2))

                    .background(
                        GridPattern(horizontalLines: 8, verticalLines: 12)
                           .inset(by: 1)
                            .stroke(Color (.secondaryLabel).opacity(0.2), style: .init(lineWidth: 1, lineCap: .round)))
                    .padding ([.leading])

            }.padding(8)
        }
        .frame(minHeight: 60, maxHeight: 100)
        .padding([.leading, .trailing], 8)
        .padding ([.bottom], 6)
    }
}

class TapTracker: ObservableObject {
    var stat: Stats?
}


struct ContentView: View {
    @ObservedObject var locations: UpdatableLocations
    @State private var editMode = EditMode.inactive
    @State var showingDetail = false
    var tapTracker = TapTracker ()
    
    public init (locations: [UpdatableStat])
    {
        self.locations = UpdatableLocations (statArray: locations)
    }
    
    var body: some View {
            NavigationView {
                ZStack {
                    VStack {
                        List {
                            ForEach(locations.stats, id: \.self) { loc in
                                SummaryLocationView (loc: .constant (loc))
                                    .onTapGesture {
                                        if let s = loc.stat {
                                            tapTracker.stat = s
                                            showingDetail = true
                                        }
                                    }
                            }
                            .onDelete(perform: onDelete)
                            .onMove(perform: onMove)

                        }.listStyle(InsetListStyle())
                        .navigationBarItems(leading: HeaderView (), trailing: EditButton ())
                        .environment(\.editMode, $editMode)
                        Spacer ()
                    }
                    VStack {
                        Spacer ()
                        HStack {
                            Spacer ()
                            Button(action: onAdd) { Image(systemName: "plus") }
                                .padding ()
                        }
                    }
                }
            }.sheet(isPresented: $showingDetail) {
                
                PresentLocationAsSheet (stat: tapTracker.stat!, showingDetail: $showingDetail)
            }
    }
    
    func onAdd () {
        
    }
    
    func onDelete(offsets: IndexSet) {
        locations.stats.remove(atOffsets: offsets)
    }

    func onMove(source: IndexSet, destination: Int) {
        locations.stats.move(fromOffsets: source, toOffset: destination)
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
                UpdatableStat(code: "Spain"),
                UpdatableStat(code: "Massachusetts"),
                UpdatableStat(code: "46005.0"),
                UpdatableStat(code:"California")
            ])
//            ContentView(locations: [
//                fetch(code: "Spain"),
//                fetch(code: "Massachusetts"),
//                fetch(code: "46005.0"),
//                fetch (code:"California")
//            ])
//            .environment(\.colorScheme, .dark)
//            ContentView(locations: [
//                fetch(code: "Spain"),
//                fetch(code: "Massachusetts"),
//                fetch(code: "46005.0"),
//                fetch (code:"California")
//            ])
//            .environment(\.colorScheme, .dark)
//            .environment(\.sizeCategory, .extraExtraExtraLarge)

        }
    }
}
