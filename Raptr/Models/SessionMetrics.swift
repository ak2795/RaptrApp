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
    
    // Data storage for CSV
    var recordCount = 0
    var distPwrArray:[Dictionary<String, Float>] = Array()
    
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
            var dct = Dictionary<String, Float>()
            dct.updateValue(currentDist, forKey: "Distance")
            dct.updateValue(currentPower, forKey: "Power")
            distPwrArray.append(dct)
        }
    }
    
    func clearMetrics() {
        distPwrArray.removeAll()
        currentDist = 0.0
        currentPower = 0.0
        goalSet.removeAll()
        goalSet = LineChartDataSet(entries: [ChartDataEntry](), label: "Power Goal")
        powerVsDistSet.removeAll()
        powerVsDistSet = LineChartDataSet(entries: [ChartDataEntry](), label: "Power vs. Distance")
    }
    
    func createCsv(from recArray:[Dictionary<String, Float>]) {
        var csvString = "\("Distance"),\("Power")\n\n"
        for dct in recArray {
            csvString = csvString.appending("\(String(describing: dct["Distance"]!)) ,\(String(describing: dct["Power"]!))\n")
        }
        
        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("Recording\(recordCount).csv")
            try csvString.write(to: fileURL, atomically: true, encoding: .utf8)
            recordCount += 1
        } catch {
            print("error creating file")
        }
    }
}
