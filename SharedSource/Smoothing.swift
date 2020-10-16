//
//  Smoothing.swift
//  CovidGraphs
//
//  Created by Russ Shanahan on 10/16/20.
//

import Foundation


// MARK: Apply smoothing to the raw data

extension Array where Element == Int {
    /*
     Apply a seven-day simple moving average to the input data, and then apply exponential smoothing.
     
     The seven-day SMA is applied to knock out the typical day-of-week fluctuations of covid data.
     Reported data are typically higher/lower based on day of the week, and we want to remove that noise
     to improve graph readability.
     
     The exponential smoothing will smooth out the data a bit more by calculating
     the current exponential smoothing value as 30% of this element's value + 70% of yesterday's
     exponential smoothing value. 30% is a fairly high value for ES, and we're using a value that
     high because there's a tradeoff between how much smoothing you have and how much your data
     lags. We already have a lag since we're applying a 7-day SMA first, so we just want a light
     EMA application.
     
     More info on smoothing here:
     https://en.wikipedia.org/wiki/Exponential_smoothing
     */

    func smoothed() -> [Int] {
        return toDouble().smaSmoothing(days: 7).emaSmoothing(factor: 0.3).toInt()
    }
}

extension Array where Element == Double {
    
    /*
     Apply a simple moving average to the data.
     
     For example, for a 7-day SMA, the output element at position 14 will be
     the average of elements 8 through 14 in the input.
     */
    
    func smaSmoothing(days daysInPeriod: Int) -> [Double] {
        let smaSmoothed: [Double] = self.enumerated().compactMap { (offset: Int, element: Double) in
            guard offset >= (daysInPeriod - 1) else {
                // Too early in the data to apply smoothing
                return element
            }
            return self[(offset - (daysInPeriod - 1))...offset].reduce(0, +)/daysInPeriod
        }
        
        return smaSmoothed
    }

    /*
     Apply an exponential moving average to the data.
     
     For example, for a 10% exponential smoothing, the output element
     at position 14 will be 10% of the value of input element 14 plus
     90% of the calculated exponential smoothing value from the previous
     element's processing.
     */
    
    func emaSmoothing(factor weightFactor: Double) -> [Double] {
        var lastSmoothedValue: Double = 0.0
        let emaSmoothed: [Double] = self.compactMap { element in
            let thisValue = lastSmoothedValue * (1 - weightFactor) + element * weightFactor
            lastSmoothedValue = thisValue
            return thisValue
        }
        
        return emaSmoothed
    }
}

// MARK: Convenience extensions to transform array types

extension Array where Element == Int {
    func toDouble() -> [Double] {
        map { Double($0) }
    }
}

extension Array where Element == Double {
    func toInt() -> [Int] {
        map { Int(round($0)) }
    }
}
