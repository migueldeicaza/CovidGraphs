//
//  CovidData.swift
//  SharedCode
//
//  Created by Miguel de Icaza on 10/7/20.
//

import Foundation
import Combine

let formatVersion = 1

/// Imported from the Json file
public struct TrackedLocation: Codable, Equatable, Hashable {
    public var title: String!
    public var admin: String!
    public var proviceState: String!
    public var countryRegion: String!
    public var lat, long: String!
    
    public func getCaptions () -> (caption: String, subcaption: String?)
    {
        var caption: String
        var subcaption: String? = nil
        
        if countryRegion == "US" {
            if admin == nil {
                caption = proviceState
            } else {
                caption = admin
                subcaption = proviceState
            }
        } else {
            if proviceState == "" {
                caption = countryRegion
            } else {
                caption = proviceState
                subcaption = countryRegion
            }
        }
        return (caption, subcaption)
    }

}

// Imported from the JSON file, tends to have the last N samples (20 or so)
// the last element is the current status, the delta is the difference
// between the last two elements
public struct Snapshot: Codable {
    public var lastDeaths: [Int]!
    public var lastConfirmed: [Int]!
}

/// All of the locations we are tracking
public struct GlobalData: Codable {
    public var time: Date = Date()
    public var version: Int = formatVersion
    public var globals: [String:TrackedLocation] = [:]
}

public struct IndividualSnapshot: Codable {
    public var time: Date = Date()
    public var version: Int = formatVersion
    public var snapshot: Snapshot
}

public struct SnapshotData: Codable {
    public var time: Date = Date()
    public var version: Int = formatVersion
    public var snapshots: [String:Snapshot] = [:]
}

/// Contains the data for a given location
public struct Stats: Hashable {
    public var updateTime: Date
    
    /// Caption for the location
    public var caption: String
    /// Subcation to show for the location
    public var subCaption: String?
    /// Total number of cases for that location
    public var totalCases: Int
    /// Number of new cases in the last day for that location
    public var deltaCases: Int
    /// Array of total cases since the beginning
    public var cases: [Int]
    /// Array of change of cases per day
    public var casesDelta: [Int]
    /// Smoothed Array of change of cases per day
    public var casesDeltaSmooth: [Int]
    /// Total number of deaths in that location
    public var totalDeaths: Int
    /// Total of new deaths in the last day for that location
    public var deltaDeaths: Int
    /// Array of total deaths since the beginning
    public var deaths: [Int]
    /// Array of changes in deaths since the beginning
    public var deathsDelta: [Int]
    
    /// Smoothed Array of changes in deaths since the beginning
    public var deathsDeltaSmooth: [Int]
    public var lat, long: String!
}

/// Returns a configured decoder for our data files
func makeDecoder () -> JSONDecoder {
    let d = JSONDecoder()
    d.dateDecodingStrategy = .iso8601
    return d
}

/// Returns the URL for the specific region code
func cacheFileForRegion (code: String) -> URL? {
    if let cacheDir = try? FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
        return cacheDir.appendingPathComponent(code)
    }
    return nil
}
///
/// An observable `Stats` object that can start as nil (no data available), and can be updated over time (when we load from the
/// cache, or fetch new data from the network)
///
public class UpdatableStat: ObservableObject, Hashable, Equatable {
    /// This is the property that gets updated with new content
    @Published public var stat: Stats? = nil
    @Published public var diagnostics: String? = nil
    public var code: String
    var tl: TrackedLocation!
    var lock: NSLock? = nil
    
    /// Creates an UpdatableStat with a `code` that reprensents one of the known locations that we have statistics for
    public init (code: String, sync: Bool = false)
    {
        self.code = code
        self.tl = globalData.globals [code]
        
        if let existing = IndividualSnapshot.tryLoadCache(name: code) {
//            var current = Calendar.current
//            var components = current.dateComponents(in: current.timeZone, from: Date ())
            
            // If it is fresh enough, no need to download
            if existing.time + TimeInterval(24*60*60) > Date () {
                self.stat = makeStat(trackedLocation: self.tl, snapshot: existing.snapshot, date: existing.time)
                return
            }
        }
        if sync {
            lock = NSLock()
        }
        fetchNewSnapshot()
        if sync {
            lock?.lock ()
        }
    }
    
    // This hash function set the uniqueness based on the address
    public func hash(into: inout Hasher)
    {
        into.combine(ObjectIdentifier(self).hashValue)
    }
    
    public static func == (lhs: UpdatableStat, rhs: UpdatableStat) -> Bool {
        return lhs.stat == rhs.stat &&
            lhs.code == rhs.code &&
            lhs.tl == rhs.tl
    }

    public func receivedData (data: Data?, response: URLResponse?, error: Error?)
    {
        guard error == nil else {
            diagnostics = error.debugDescription
            print ("error: \(error!)")
            return
        }
        
        guard let content = data else {
            print("No data")
            diagnostics = "No data"
            return
        }
        if let cacheFile = cacheFileForRegion(code: self.code) {
            //print ("Saving to \(cacheFile)")
            try! content.write(to: cacheFile)
        }
        let decoder = makeDecoder()
        if let isnap = try? decoder.decode(IndividualSnapshot.self, from: content) {
            if let l = lock {
                self.stat = makeStat(trackedLocation: self.tl, snapshot: isnap.snapshot, date: isnap.time)
                l.unlock()
            } else {
                DispatchQueue.main.async {
                    
                    self.stat = makeStat(trackedLocation: self.tl, snapshot: isnap.snapshot, date: isnap.time)
                    print ("Data loaded")
                }
            }
        }
    }
    
    public func fetchNewSnapshot (session: URLSession? = nil){
        let url = URL(string: "https://tirania.org/covid-data/\(code)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = (session ?? URLSession.shared).dataTask(with: request, completionHandler: receivedData(data:response:error:))
        
        task.resume()
    }
}

/// An array of UpdatableStat objects that can be observed for changes
public class UpdatableLocations: ObservableObject {
    @Published
    public var stats: [UpdatableStat]
    var cancellables = [AnyCancellable]()

    public init (statArray: [UpdatableStat])
    {
        self.stats = statArray
        
        self.stats.forEach({
            let c = $0.objectWillChange.sink(receiveValue: { self.objectWillChange.send() })
            
            // Important: You have to keep the returned value allocated,
            // otherwise the sink subscription gets cancelled
            self.cancellables.append(c)
        })
    }    
}

extension IndividualSnapshot {
    static public func tryLoadCache (name: String) -> IndividualSnapshot?
    {
        if let file = cacheFileForRegion(code: name) {
            //print ("Loading from \(file)")
            if let data = try? Data (contentsOf: file) {
                let decoder = makeDecoder()
                if let snapshot = try? decoder.decode(IndividualSnapshot.self, from: data) {
                    return snapshot
                }
            }
        }
        return nil
    }
}

func load () -> SnapshotData
{
    let idata = try! Data (contentsOf: URL (fileURLWithPath: "/tmp/individual"))
    let d = makeDecoder()
    do {
        let k = try d.decode(SnapshotData.self, from: idata)
        return k
    } catch {
        print ("error")
    }
    abort ()
}

public var globalData: GlobalData = {
    let filePath = Bundle.main.url(forResource: "global", withExtension: "")
    if let gd = try? Data(contentsOf: filePath!) {
        let d = makeDecoder()
        return try! d.decode(GlobalData.self, from: gd)
    }
    abort ()
}()

var _sortedData: [Pretty] = []

func sortBySubcaption (first: TrackedLocation, second: TrackedLocation) -> Bool {
    return ("\(first.countryRegion ?? ""), \(first.proviceState ?? ""), \(first.admin ?? "")") <
    ("\(second.countryRegion ?? ""), \(second.proviceState ?? ""), \(second.admin ?? "")")
}

// Contains the user visible code and the code to look this value up
public struct Pretty: Hashable {
    var visible: String
    var code: String
}

public var prettifiedLocations: [Pretty] = {
    if _sortedData.count != 0 {
        return _sortedData
    }
    let sorted = globalData.globals.sorted(by: { x, y in sortBySubcaption(first: x.value, second: y.value) })
    
    for slot in sorted {
        let v = slot.value
        var visible: String
        if (v.admin ?? "") == "" {
            if (v.proviceState ?? "") == "" {
                visible = v.countryRegion ?? ""
            } else {
                visible = "\(v.proviceState ?? ""), \(v.countryRegion ?? "")"
            }
        } else {
            visible = "\(v.admin ?? ""), \(v.proviceState ?? ""), \(v.countryRegion ?? "")"
        }
        _sortedData.append (Pretty (visible: visible, code: slot.key))
    }
    return _sortedData
}()
    
var sd: SnapshotData!

public var emptyStat = Stats(updateTime: Date(), caption: "", subCaption: nil,
                      totalCases: 0, deltaCases: 0,
                      cases: [], casesDelta: [], casesDeltaSmooth: [],
                      totalDeaths: 0, deltaDeaths: 0,
                      deaths: [], deathsDelta: [], deathsDeltaSmooth: [])

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

public func makeStat (trackedLocation: TrackedLocation, snapshot: Snapshot, date: Date = Date()) -> Stats
{
    let last2Deaths = Array (snapshot.lastDeaths.suffix(2))
    let totalDeaths = last2Deaths[1]
    let deltaDeaths = last2Deaths[1]-last2Deaths[0]
    let last2Cases = Array(snapshot.lastConfirmed.suffix(2))
    let totalCases = last2Cases [1]
    let deltaCases = last2Cases[1]-last2Cases[0]

    let (caption, subcaption) = trackedLocation.getCaptions ()
    
    return Stats (updateTime: date,
                  caption: caption,
                  subCaption: subcaption,
                  totalCases: totalCases,
                  deltaCases: deltaCases,
                  cases: snapshot.lastConfirmed,
                  casesDelta: makeDelta (snapshot.lastConfirmed),
                  casesDeltaSmooth: makeDelta (snapshot.lastConfirmed.smoothed()),
                  totalDeaths: totalDeaths,
                  deltaDeaths: deltaDeaths,
                  deaths: snapshot.lastDeaths,
                  deathsDelta: makeDelta (snapshot.lastDeaths),
                  deathsDeltaSmooth: makeDelta(snapshot.lastDeaths.smoothed()),
                  lat: trackedLocation.lat,
                  long: trackedLocation.long)
}


public func fetch (code: String) -> Stats
{
    let idata = try! Data (contentsOf: URL (fileURLWithPath: "/tmp/ind/\(code)"))
    let d = makeDecoder()

    guard let k = try? d.decode(IndividualSnapshot.self, from: idata) else {
        emptyStat.caption = "INDFILE"
        return emptyStat
    }

    let snapshot = k.snapshot
    guard let tl = globalData.globals [code] else {
        emptyStat.caption = "GLOBAL"
        return emptyStat
    }
        
    return makeStat (trackedLocation: tl, snapshot: snapshot)
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

// If compress is true, it attempts to compress the text, otherwise it does not
public func fmtDelta (_ n: Int, compress: Bool = true) -> String
{
    switch compress ? n : 0 {
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

