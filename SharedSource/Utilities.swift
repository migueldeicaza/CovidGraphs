//
//  Utilities.swift
//  CovidGraphs
//
//  Created by Miguel de Icaza on 10/11/20.
//

import Foundation
import SwiftUI
import Combine

/**
 * Given an array of numbers, takes the last `count` numbers (or all, if the value -1 is passed)
 * and then returns an float array that has the values in the range 0..1 which is what the
 * Chart library expects
 *
 * - Parameter n: array of integers
 * - Parameter count: number of elements to fetch, or -1 if it should map all the elements, defaults to all the elements
 * - Returns: An array of up to `n` values where all the values have been scaled where the smallest value is 0,
 *   and the largest is 1, and every other value is in between
 */
func convertStats (_ v: [Int], count: Int = -1) -> [CGFloat]
{
    let n = count == -1 ? v.count : count
    let subset = v.suffix(n)
    if let min = subset.min () {
        if let max = subset.max () {
            let d = CGFloat (max-min)
            var result: [CGFloat] = []
    
            for x in subset {
                result.append(CGFloat (x-min) / d)
            }
            return result
        }
    }
    return [0.0]
}

func getBounds (_ v: [Int], count: Int = -1) -> (min: Int, max: Int)
{
    let n = count == -1 ? v.count : count
    let subset = v.suffix(n)
    if let min = subset.min () {
        if let max = subset.max () {
            return (min, max)
        }
    }
    return (0, 1)
}

