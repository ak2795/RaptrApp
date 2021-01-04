//
//  SessionMetrics.swift
//  Raptr
//
//  Created by Andrew Kim on 12/31/20.
//

import Foundation
import Charts

class SessionMetrics {
    // Variables for timer
    var counter = 0.0
    var timer = Timer()
    var isPlaying = false
    
    // Data sets for line chart plotting
    var powerVsDistSet : LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "Power vs. Distance")
    var goalSet : LineChartDataSet = LineChartDataSet(entries: [ChartDataEntry](), label: "Power Goal")
    
    // Single most recent power and distance values
    var currentPower : Float = 0.0
    var currentDist : Float = 0.0
    var currentPowerGoal : Float = 0.0
    
    // Sets the current power and distance values and adds values to the session array
    func setMetrics(dist: String, power: String) {
        let distValue = Float(dist) ?? -1
        let powerValue = Float(power) ?? -1
        if (distValue > currentDist) {
            currentDist = distValue
            currentPower = powerValue
        }
    }
    
    func clearMetrics() {
        currentDist = 0.0
        currentPower = 0.0
        goalSet.removeAll()
        goalSet = LineChartDataSet(entries: [ChartDataEntry](), label: "Power Goal")
        powerVsDistSet.removeAll()
        powerVsDistSet = LineChartDataSet(entries: [ChartDataEntry](), label: "Power vs. Distance")
    }
}
