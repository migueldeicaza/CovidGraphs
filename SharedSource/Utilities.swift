//
//  Utilities.swift
//  CovidGraphs
//
//  Created by Miguel de Icaza on 10/11/20.
//

import Foundation
import SwiftUI

// Maps from integers to 0..1
func convertStats (_ v: [Int]) -> [CGFloat]
{
    if let min = v.min () {
        if let max = v.max () {
            let d = CGFloat (max-min)
            var result: [CGFloat] = []
    
            for x in v {
                result.append(CGFloat (x-min) / d)
            }
            return result
        }
    }
    return [0.0]
}
