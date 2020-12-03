//
//  LocationDetailView.swift
//  CovidGraphs
//
//  Created by Miguel de Icaza on 10/11/20.
//

import SwiftUI
import Charts
import Shapes
import MapKit
import CoreLocation

struct MainTitle: View {
    @Binding var stat: Stats
    
    var body: some View {
        VStack {
            HStack {
                Text(stat.caption)
                    .font (.title)
                    .bold()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer ()
            }
            if let sub = stat.subCaption {
                HStack {
                    Text (sub)
                        .font (.body)
                        .bold()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .foregroundColor(.secondary)

                    Spacer ()
                }
            }
        }
    }
}

struct LocationDetailSummaryView: View {
    @Binding var stat: Stats
    var body: some View {
        HStack {
            VStack (alignment: .leading){
                HStack(spacing: 8.0) {
                    Text ("\(fmtDigit (stat.totalCases))")
                        .bold ()
                    Text ("+\(fmtDigit (stat.deltaCases))")
                        .foregroundColor(Color.accentColor)
                }
                Text ("Confirmed cases")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.secondary)
            }
            Divider ()
            VStack (alignment: .leading) {
                HStack(spacing: 8.0) {
                    Text ("\(fmtDigit (stat.totalDeaths))")
                        .bold ()
                        
                    Text ("+\(fmtDigit (stat.deltaDeaths))")
                        .foregroundColor(Color.accentColor)
                }
                Text ("Deaths")
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.secondary)
            }
            Spacer ()
        }
    }
}

struct TimeSelectorView: View {
    @Binding var days: Int
    var body: some View {
        HStack {
            Button (action: { days = 7 })   { Text ("1W").font (.footnote).bold ().frame (maxWidth: .infinity) }
            Button (action: { days = 14 })  { Text ("2W").font (.footnote).bold ().frame (maxWidth: .infinity) }
            Button (action: { days = 21 })  { Text ("3W").font (.footnote).bold ().frame (maxWidth: .infinity) }
            Button (action: { days = 30 })  { Text ("1M").font (.footnote).bold ().frame (maxWidth: .infinity) }
            Button (action: { days = 91 })  { Text ("3M").font (.footnote).bold ().frame (maxWidth: .infinity) }
            Button (action: { days = 182 }) { Text ("6M").font (.footnote).bold ().frame (maxWidth: .infinity) }
            Button (action: { days = -1 })  { Text ("All").font (.footnote).bold ().frame (maxWidth: .infinity) }
        }.padding ([.trailing, .leading])
    }
}

struct LabeledChart: View {
    @Binding var data: [Int]
    @Binding var days: Int
    @State var overlay: String
    let slots = 4
    
    // yeah, this is terrible, and I should compute min/max based on data/days, but
    // have to figure out how to do that with Bindings and updating state
    func getValueAt (_ n: Int) -> Int
    {
        let (min, max) = getBounds (data, count: days)
        let ss = (max-min)/slots
        
        return min + n * ss
    }
    
    func fmtDate (_ n: Int) -> String
    {
        let d = days == -1 ? data.count : days
        guard let date = Calendar.current.date(byAdding: .day, value: -(n*(d/slots)), to: Date()) else {
            return ""
        }
        switch d {
        case 0...120:
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM dd"
            return fmt.string(from: date)
            
        default:
            let fmt = DateFormatter()
            fmt.dateFormat = "MMM"
            return fmt.string(from: date)
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                ZStack {
                    Group {
                        if days > 0 && days < 60 {
                            Chart(data: convertStats (data, count: days))
                                .chartStyle(
                                    MyColumnChartStyle(column: Capsule().foregroundColor(Color ("BackgroundColor")).blendMode(.screen), spacing: 2))
                        } else {
                            Chart(data: convertStats (data, count: days))
                                .chartStyle(
                                    LineChartStyle(.quadCurve, lineColor: Color.accentColor, lineWidth: 2))

                        }
                    }
                    .background(
                        GridPattern(horizontalLines: slots + 1, verticalLines: slots + 1)
                           .inset(by: 1)
                            .stroke(Color (.secondaryLabel).opacity(0.2), style: .init(lineWidth: 1, lineCap: .round)))

                    HStack {
                        VStack {
                            Text (overlay)
                                .font (.title)
                                .opacity(0.3)
                                .padding ([.leading], 8)
                                .padding ([.top], 2)
                            Spacer ()
                        }
                        Spacer ()
                    }
                }.padding ([.leading])
                AxisLabels(.vertical, data: 0...3, id: \.self) { v in
                                 Text("\(getValueAt(3-v))")
                                    .font(.footnote).bold ()
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.3)
                                 }
                                 .frame(width: 30)
                
            }
            AxisLabels(.horizontal, data: 0...3, id: \.self) { v in
                             Text("\(fmtDate (3-v))")
                                .font(.footnote).bold ()
                             }
            .frame(height: 20)
        }
        .frame (maxHeight: 200)
    }
}

struct LocationDetailView: View {
    @State var stat: Stats
    @State var days = 120
    @State var coordinateRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
       span: MKCoordinateSpan(latitudeDelta: 0.2, longitudeDelta: 0.2))
    
    var body: some View {
        VStack {
            VStack {
                MainTitle (stat: $stat)
                Divider ()
                Map (coordinateRegion: $coordinateRegion)
                LocationDetailSummaryView (stat: $stat)
                    .frame(maxHeight: 60)
            }.padding ([.leading, .trailing], 20)
            Divider ()
            ScrollView {
                TimeSelectorView (days: $days)
                LabeledChart (data: $stat.casesDelta, days: $days, overlay: "Cases")
                    .frame (minHeight: 200)
                LabeledChart (data: $stat.deathsDelta, days: $days, overlay: "Deaths")
                    .frame (minHeight: 200)
            }
        }.onAppear {
            let lat = Double (stat.lat ?? "44.414") ?? 0
            let long = Double (stat.long ?? "-98.27") ?? 0

            // Start out hoping to cover the area
            coordinateRegion = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: lat,
                                               longitude: long),
                span: MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2))
            
            // Now zoom in
            let geocoder = CLGeocoder ()
            let address = stat.caption + (stat.subCaption == nil ? "" : (", " + stat.subCaption!))
            
            geocoder.geocodeAddressString(address) { place, err in
                guard err == nil else { return }
                guard let region = place?.first?.region as? CLCircularRegion else { return }
                
                coordinateRegion = MKCoordinateRegion (
                    center: coordinateRegion.center,
                    span: MKCoordinateSpan (latitudeDelta: region.radius/70000, longitudeDelta: region.radius/70000))
            }
        }
    }
}

///
/// Shows a LocationDetailView with a close button
///
struct PresentLocationAsSheet: View {
    var stat: Stats
    @Binding var showingDetail: Bool
    
    var body: some View {
        VStack {
            ZStack {
                LocationDetailView (stat: stat)
                VStack {
                    HStack {
                        Spacer ()
                        Button(action: { self.showingDetail = false}) {
                            Image(systemName: "multiply.circle.fill")
                                .font(.system(size: 24, weight: .regular))
                                .padding([.trailing], 10)
                        }
                    }
                    Spacer ()
                }
            }
        }.padding (.top, 10)
    }
}

struct LocationDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            //Text ("hi")
            LocationDetailView(stat: fetch(code: "Massachusetts"))
//            LocationDetailView(stat: fetch(code: "Massachusetts"))
//                .environment(\.colorScheme, .dark)
//            LocationDetailView(stat: fetch(code: "46005.0"))
//                .environment(\.sizeCategory, .extraExtraExtraLarge)
//            LocationDetailView(stat: fetch(code: "California"))
        }

    }
}
