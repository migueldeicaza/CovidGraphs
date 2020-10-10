//
//  ContentView.swift
//  CovidGraphs
//
//  Created by Miguel de Icaza on 10/5/20.
//

import SwiftUI
import SharedCode

struct OneStat: View {
    var caption, major, minor: String
    
    var body: some View {
        VStack (alignment: .leading) {
            Text (caption)
                .font(.footnote)
            Text (major)
                .font(.title)
            Text (minor)
                .font (.footnote)
                .foregroundColor(Color.gray)
        }
    }
}

struct Stats {
    var caption: String
    var totalCases, deltaCases: String
    var recoveredCases, deltaRecovered: String
    var deaths, deltaDeaths: String
}

struct GeographyStatView: View {
    var stat: Stats
    
    var body: some View {
        VStack (alignment: .leading){
            HStack {
                Text(stat.caption).bold().font (.title2)
                Spacer ()
            }
            
            HStack (alignment: .top, spacing: 10) {
                    OneStat (caption: "Total cases", major: stat.totalCases, minor: stat.deltaCases)
                    OneStat (caption: "Recovered", major: stat.recoveredCases, minor: stat.deltaRecovered)
                    OneStat (caption: "Deaths", major: stat.deaths, minor: stat.deltaDeaths)

            }
        }.padding ()
        .border(Color.gray, width: /*@START_MENU_TOKEN@*/1/*@END_MENU_TOKEN@*/)
        .padding ()
    }
}
struct ContentView: View {
    var us_ma_Stat = Stats (caption: "Massachussets", totalCases: "135k", deltaCases: "+644", recoveredCases: "", deltaRecovered: "", deaths: "9,530", deltaDeaths: "+3")
    var us_Stat = Stats (caption: "United States", totalCases: "7.48M", deltaCases: "+34,491", recoveredCases: "", deltaRecovered: "", deaths: "210k", deltaDeaths: "+332")
    var world_Stat = Stats (caption: "Worldwide", totalCases: "35.4M", deltaCases: "", recoveredCases: "", deltaRecovered: "", deaths: "1.04M", deltaDeaths: "")
    var x = fetch (code:"California")
    var body: some View {
        VStack (alignment: .leading){
            GeographyStatView(stat: us_ma_Stat)
            VStack (alignment: .leading){
                HStack {
                    Text ("Massachusetts")
                        .bold().font (.title2)
                    Spacer ()
                    Text ("644")
                        .bold().font (.title2)
                }
                HStack {
                    Text ("Hello")
                    Spacer ()
                    Text ("3")
                }
                
                
            }.padding ()
            .foregroundColor(Color.white)
            .background(Color.black)

            GeographyStatView(stat: us_Stat)
            GeographyStatView(stat: world_Stat)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
