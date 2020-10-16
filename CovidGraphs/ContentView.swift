//
//  ContentView.swift
//  CovidGraphs
//
//  Created by Miguel de Icaza on 10/5/20.
//

import SwiftUI
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
                    .shadow(color: Color.black.opacity(0.3),
                            radius: 2,
                            x: 1,
                            y: 1)

                    .background(
                        GridPattern(horizontalLines: 8, verticalLines: 12)
                           .inset(by: 1)
                            .stroke(Color (.secondaryLabel).opacity(0.2), style: .init(lineWidth: 1, lineCap: .round)))
                    .padding ([.leading])
                

            }.padding([.bottom, .top], 8)
        }
        .frame(minHeight: 60, maxHeight: 100)
        //.padding([.leading, .trailing], 8)
        .padding ([.bottom, .top], 6)
    }
}

class TapTracker: ObservableObject {
    var stat: Stats?
    var showSearch = false
}


struct ContentView: View {
    @ObservedObject var locations: UpdatableLocations
    @State private var editMode = EditMode.inactive
    @State var showingSheet = false
    var tapTracker = TapTracker ()
    
    public init (locations: [UpdatableStat])
    {
        self.locations = UpdatableLocations (statArray: locations)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack (alignment: .leading) {
                    
                    List {
                        ForEach(locations.stats, id: \.self) { loc in
                            SummaryLocationView (loc: .constant (loc))
                                .onTapGesture {
                                    if let s = loc.stat {
                                        tapTracker.stat = s
                                        showDetail ()
                                    }
                                }
                        }
                        .onDelete(perform: onDelete)
                        .onMove(perform: onMove)
                        
                    }.listStyle(PlainListStyle())
                    .navigationBarItems(leading: HeaderView(), trailing: EditButton ())
                    .environment(\.editMode, $editMode)
                    Spacer ()
                }
                VStack {
                    Spacer ()
                    HStack {
                        Spacer ()
                        Button (action: onAdd, label: {
                            Image (systemName: "plus")
                                //.font(.system(.title2))
                                .foregroundColor(.accentColor)
                                
                        }).padding (10)
                        .background(Color.white)
                        .cornerRadius(38.5)
                        .padding()
                        .shadow(color: Color.black.opacity(0.2),
                                radius: 7,
                                x: 3,
                                y: 3)
                    }
                }
            }
        }
        .sheet(isPresented: $showingSheet) {
            if tapTracker.showSearch {
                PresentSearchAsSheet (showSearch: $showingSheet)
            } else {
                PresentLocationAsSheet (stat: tapTracker.stat!, showingDetail: $showingSheet)
            }
        }
    }
    
    func showDetail ()
    {
        tapTracker.showSearch = false
        showingSheet = true
    }
    
    func onAdd () {
        tapTracker.showSearch = true
        showingSheet = true
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
            ContentView(locations: [
                UpdatableStat(code: "Spain"),
                UpdatableStat(code: "Massachusetts"),
                UpdatableStat(code: "46005.0"),
                UpdatableStat(code:"California")
            ])
            .environment(\.colorScheme, .dark)
            ContentView(locations: [
                UpdatableStat(code: "Spain"),
                UpdatableStat(code: "Massachusetts"),
                UpdatableStat(code: "46005.0"),
                UpdatableStat(code:"California")
            ])
            .environment(\.colorScheme, .dark)
            .environment(\.sizeCategory, .extraExtraExtraLarge)

        }
    }
}
