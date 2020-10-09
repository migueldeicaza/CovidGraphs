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
    public var totalCases, deltaCases: String
    public var cases: [Int]
    public var totalDeaths, deltaDeaths: String
    public var deaths: [Int]
}

//public var us_ma_Stat = Stats (caption: "Massachussets", totalCases: "135k", deltaCases: "+644", deaths: "9,530", deltaDeaths: "+3")
//public var us_Stat = Stats (caption: "United States", totalCases: "7.48M", deltaCases: "+34,491", deaths: "210k", deltaDeaths: "+332")
//public var world_Stat = Stats (caption: "Worldwide", totalCases: "35.4M", deltaCases: "", deaths: "1.04M", deltaDeaths: "")


func loadGlobalData (data: Data) -> GlobalData?
{
    let d = JSONDecoder()
    d.dateDecodingStrategy = .iso8601
    do {
        return try d.decode(GlobalData.self, from: data)
    } catch let DecodingError.dataCorrupted(context) {
        print(context)
    } catch let DecodingError.keyNotFound(key, context) {
        print("Key '\(key)' not found:", context.debugDescription)
        print("codingPath:", context.codingPath)
    } catch let DecodingError.valueNotFound(value, context) {
        print("Value '\(value)' not found:", context.debugDescription)
        print("codingPath:", context.codingPath)
    } catch let DecodingError.typeMismatch(type, context)  {
        print("Type '\(type)' mismatch:", context.debugDescription)
        print("codingPath:", context.codingPath)
    } catch {
        print("error: ", error)
    }
    return nil
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

var emptyStat = Stats(caption: "Taxachussets", totalCases: "1234", deltaCases: "+11", cases: [], totalDeaths: "897", deltaDeaths: "+2", deaths: [])
var fmt: NumberFormatter!

func fmtLarge (_ n: Int) -> String
{
    
    switch n {
    case let x where x < 0:
        return "0."     // "0." as a flag to determine something went wrong
        
    case 0..<99999:
        return fmt.string(from: NSNumber (value: n)) ?? "?"
        
    case 100000..<999999:
        return fmt.string(from: NSNumber (value: Float (n)/1000.0)) ?? "?" + "k"
        
    default:
        return fmt.string(from: NSNumber (value: Float (n)/1000000.0)) ?? "?" + "M"
    }
}

func fmtDelta (_ n: Int) -> String
{
    
    switch n {
    case let x where x < 0:
        return "-0"     // "-0" as a flag to determine something went wrong
        
    case 0..<999:
        return "+" + (fmt.string(from: NSNumber (value: n)) ?? "?")
        
    case 1000..<999999:
        return "+" + (fmt.string(from: NSNumber (value: Float (n)/1000.0)) ?? "?") + "k"
        
    default:
        return "+" + (fmt.string(from: NSNumber (value: Float (n)/1000000.0)) ?? "?") + "M"
    }
}

func initDataTools ()
{
    fmt = NumberFormatter()
    fmt.numberStyle = .decimal
}

public func fetch (code: String) -> Stats
{
    print ("code: \(code)")
    if gd == nil || sd == nil {
        initDataTools ()
        if let (a, b) = load () {
            gd = a
            sd = b
        } else {
            emptyStat.caption = "Failure"
            return emptyStat
        }
    }
    //let tl = gd.globals [code]
    guard let snapshot = sd.snapshots [code] else {
        return emptyStat
    }
    
    let last2Deaths = Array (snapshot.lastDeaths.suffix(2))
    let totalDeaths = last2Deaths[1]
    let deltaDeaths = last2Deaths[1]-last2Deaths[0]
    let last2Cases = Array(snapshot.lastConfirmed.suffix(2))
    let totalCases = last2Cases [1]
    let deltaCases = last2Cases[1]-last2Cases[0]
    return Stats (caption: code,
                  totalCases: fmtLarge (totalCases),
                  deltaCases: fmtDelta (deltaCases),
                  cases: snapshot.lastDeaths,
                  totalDeaths: fmtLarge (totalDeaths),
                  deltaDeaths: fmtDelta (deltaDeaths),
                  deaths: snapshot.lastDeaths)
}


