//
//  CovidData.swift
//  SharedCode
//
//  Created by Miguel de Icaza on 10/7/20.
//

import Foundation

let formatVersion = 1

// Imported from the Json file
public struct TrackedLocation: Codable {
    public var title: String!
    public var admin: String!
    public var proviceState: String!
    public var countryRegion: String!
    public var lat, long: String!
}

// Imported from the JSON file, tends to have the last N samples (20 or so)
// the last element is the current status, the delta is the difference
// between the last two elements
public struct Snapshot: Codable {
    public var lastDeaths: [Int]!
    public var lastConfirmed: [Int]!
}

public struct GlobalData: Codable {
    public var time: Date = Date()
    public var version: Int = formatVersion
    public var globals: [String:TrackedLocation] = [:]
}

public struct SnapshotData: Codable {
    public var time: Date = Date()
    public var version: Int = formatVersion
    public var snapshots: [String:Snapshot] = [:]
}

public struct Stats {
    public var caption: String
    public var subCaption: String?
    public var totalCases, deltaCases: Int
    public var cases: [Int]
    public var casesDelta: [Int]
    public var totalDeaths, deltaDeaths: Int
    public var deaths: [Int]
    public var deathsDelta: [Int]
}

func loadGlobalData (data: Data) -> GlobalData?
{
    let d = JSONDecoder()
    d.dateDecodingStrategy = .iso8601
    return try? d.decode(GlobalData.self, from: data)
}

func loadSnapshotData (data: Data) -> SnapshotData?
{
    let d = JSONDecoder()
    d.dateDecodingStrategy = .iso8601
    return try? d.decode(SnapshotData.self, from: data)
}

func load () -> (GlobalData, SnapshotData)?
{
    if let gd = try? Data(contentsOf: URL (fileURLWithPath: "/tmp/global")) {
        if let id = try? Data (contentsOf: URL (fileURLWithPath: "/tmp/individual")){
            if let lgd = loadGlobalData(data: gd) {
                if let lsd = loadSnapshotData(data: id) {
                    return (lgd, lsd)
                }
            }
        }
    }
    return nil
}

var gd: GlobalData!
var sd: SnapshotData!

var emptyStat = Stats(caption: "Taxachussets", subCaption: nil, totalCases: 1234, deltaCases: +11, cases: [], casesDelta: [], totalDeaths: 897, deltaDeaths: +2, deaths: [], deathsDelta: [])

func makeDelta (_ v: [Int]) -> [Int]
{
    var result: [Int] = []
    var last = v [0]
    
    for i in 1..<v.count {
        result.append (v[i]-last)
        last = v [i]
    }
    return result
}

public func fetch (code: String) -> Stats
{
    if gd == nil || sd == nil {
        if let (a, b) = load () {
            gd = a
            sd = b
        } else {
            emptyStat.caption = "LOAD"
            return emptyStat
        }
    }
    
    guard let snapshot = sd.snapshots [code] else {
        emptyStat.caption = "CODE"
        return emptyStat
    }
    let tl = gd.globals [code]!
    
    let last2Deaths = Array (snapshot.lastDeaths.suffix(2))
    let totalDeaths = last2Deaths[1]
    let deltaDeaths = last2Deaths[1]-last2Deaths[0]
    let last2Cases = Array(snapshot.lastConfirmed.suffix(2))
    let totalCases = last2Cases [1]
    let deltaCases = last2Cases[1]-last2Cases[0]
    
    var caption: String
    var subcaption: String?
    
    if tl.countryRegion == "US" {
        if tl.admin == nil {
            caption = tl.proviceState
        } else {
            caption = tl.admin
            subcaption = tl.proviceState
        }
    } else {
        if tl.proviceState == "" {
            caption = tl.countryRegion
        } else {
            caption = tl.proviceState
            subcaption = tl.countryRegion
        }
    }
    return Stats (caption: caption,
                  subCaption: subcaption,
                  totalCases: totalCases,
                  deltaCases: deltaCases,
                  cases: snapshot.lastConfirmed,
                  casesDelta: makeDelta (snapshot.lastConfirmed),
                  totalDeaths: totalDeaths,
                  deltaDeaths: deltaDeaths,
                  deaths: snapshot.lastDeaths,
                  deathsDelta: makeDelta (snapshot.lastDeaths)
    )
}


var fmtDecimal: NumberFormatter = {
    var fmt = NumberFormatter()
    fmt.numberStyle = .decimal
    fmt.maximumFractionDigits = 2
    
    return fmt
} ()

var fmtDecimal1: NumberFormatter = {
    var fmt = NumberFormatter()
    fmt.numberStyle = .decimal
    fmt.maximumFractionDigits = 1
    
    return fmt
} ()

var fmtNoDecimal: NumberFormatter = {
    var fmt = NumberFormatter()
    fmt.numberStyle = .decimal
    fmt.maximumFractionDigits = 0
    return fmt
} ()


public func fmtLarge (_ n: Int) -> String
{
    switch n {
    case let x where x < 0:
        return "0."     // "0." as a flag to determine something went wrong
        
    case 0..<99999:
        return fmtDecimal.string(from: NSNumber (value: n)) ?? "?"
        
    case 100000..<999999:
        return (fmtNoDecimal.string(from: NSNumber (value: Float (n)/1000.0)) ?? "?") + "k"
        
    default:
        return fmtNoDecimal.string(from: NSNumber (value: Float (n)/1000000.0)) ?? "?" + "M"
    }
}

public func fmtDigit (_ n: Int) -> String {
    return fmtDecimal.string (from: NSNumber (value: n)) ?? "?"
}

public func fmtDelta (_ n: Int) -> String
{
    switch n {
    case let x where x < 0:
        return "-0"     // "-0" as a flag to determine something went wrong
        
    case 0..<9999:
        return "+" + (fmtDecimal.string(from: NSNumber (value: n)) ?? "?")
        
    case 10000..<999999:
        return "+" + (fmtDecimal1.string(from: NSNumber (value: Float (n)/1000.0)) ?? "?") + "k"
        
    default:
        return "+" + (fmtDecimal.string(from: NSNumber (value: Float (n)/1000000.0)) ?? "?") + "M"
    }
}

