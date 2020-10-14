//
//  CovidGraphsApp.swift
//  CovidGraphs
//
//  Created by Miguel de Icaza on 10/5/20.
//

import SwiftUI
import SharedCode

@main
struct CovidGraphsApp: App {
    @AppStorage ("locations")
    var locations: String = "Massachusetts,California,Spain"
    
    func makeLocations (input: String) -> [Stats]
    {
        var res: [Stats] = []
        
        for x in input.split(separator: ",") {
            res.append (fetch (code: String (x)))
        }
        return res
    }
    var body: some Scene {
        WindowGroup {
            ContentView(locations: makeLocations(input: locations))
        }
    }
}
