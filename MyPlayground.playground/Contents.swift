import Cocoa
import Foundation

let current = Date()
let est = TimeZone (abbreviation: "EST")!
    var components = Calendar.current.dateComponents(in: est, from: current)
    
    // Update time
    components.hour = 5
    components.minute = 55
    if let morning = components.date {
        print (morning)
        
        let x = morning >= current
        var target = morning >= current ? morning : Calendar.current.date(byAdding: .day, value: 1, to: morning)
        
        print (target)
    }
