//
//  CovidGraphsApp.swift
//  CovidGraphs
//
//  Created by Miguel de Icaza on 10/5/20.
//

import SwiftUI

@main
struct CovidGraphsApp: App {
    @AppStorage ("locations")
    var locations: String = "Massachusetts,California,Mexico,25021.0,25025.0,Vermont"
    
    func makeLocations (input: String) -> [UpdatableStat]
    {
        var res: [UpdatableStat] = []
        
        for x in input.split(separator: ",") {
            res.append (UpdatableStat (code: String (x)))
        }
        return res
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(locations: makeLocations(input: locations))
        }
    }
}
