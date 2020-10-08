//
//  CovidData.swift
//  SharedCode
//
//  Created by Miguel de Icaza on 10/7/20.
//

import Foundation

public struct Stats {
    public var caption: String
    public var totalCases, deltaCases: String
    public var recoveredCases, deltaRecovered: String
    public var deaths, deltaDeaths: String
}

public var us_ma_Stat = Stats (caption: "Massachussets", totalCases: "135k", deltaCases: "+644", recoveredCases: "", deltaRecovered: "", deaths: "9,530", deltaDeaths: "+3")
public var us_Stat = Stats (caption: "United States", totalCases: "7.48M", deltaCases: "+34,491", recoveredCases: "", deltaRecovered: "", deaths: "210k", deltaDeaths: "+332")
public var world_Stat = Stats (caption: "Worldwide", totalCases: "35.4M", deltaCases: "", recoveredCases: "", deltaRecovered: "", deaths: "1.04M", deltaDeaths: "")



