//
//  ViewController.swift
//  Raptr
//
//  Created by Andrew Kim on 12/26/20.
//

import UIKit
import CoreBluetooth
import Foundation
import Charts

class SledViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {
    
//    @IBOutlet weak var graphView: LineChartView!
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distValue: UILabel!
    @IBOutlet weak var powerValue: UILabel!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var connectionButton: UIButton!
    
    // Properties
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var rxChar: CBCharacteristic?
    
    private var sessionMetrics = SessionMetrics()
    var selectedModeTitle: String?
    var powerGoal: Float!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 140, weight: .bold, scale: .large)
        let largeRecordSymbol = UIImage(systemName: "record.circle", withConfiguration: largeConfig)
        recordButton.setImage(largeRecordSymbol, for: .normal)
        timeLabel.text = String(sessionMetrics.counter)
        
//        graphView.backgroundColor = .systemGray6
//        graphView.rightAxis.enabled = false
//        graphView.xAxis.labelPosition = XAxis.LabelPosition.bottom
//        graphView.legend.enabled = false
//        graphView.leftAxis.axisMinimum = 0.0
    }
    
    // If powered on, start scanning
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if (central.state != .poweredOn) {
            print("Central is not powered on")
        } else {
            // Scan for Legacy and Nordic services
            print("Central is scanning for services")
            central.scanForPeripherals(withServices: [RaptrPeripheral.sledServiceUUID, RaptrPeripheral.legacyServiceUUID], options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        }
    }
    
    // Handles the result of the scan
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Found device so stop the scan
        self.centralManager.stopScan()
        
        // Copy the peripheral instance
        self.peripheral = peripheral
        self.peripheral.delegate = self
        
        // Connect
        self.centralManager.connect(self.peripheral, options: nil)
    }
    
    // The handler if connect is successful
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if peripheral == self.peripheral {
            statusLabel.text = "Connected"
            statusLabel.backgroundColor = .systemGreen
            connectionButton.setTitle("Disconnect", for: .normal)
            // Discover both Nordic and Legacy services
            peripheral.discoverServices([RaptrPeripheral.sledServiceUUID, RaptrPeripheral.legacyServiceUUID])
        }
    }
    
    // Handles when BLE device disconnects
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        statusLabel.text = "Disconnected"
        statusLabel.backgroundColor = .systemRed
        connectionButton.setTitle("Connect", for: .normal)
        central.cancelPeripheralConnection(peripheral)
    }

    // Handles discovery event
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services {
            for service in services {
                if service.uuid == RaptrPeripheral.sledServiceUUID {
                    print ("Sled Service found")
                    // kick off the discovery of characteristics
                    peripheral.discoverCharacteristics([RaptrPeripheral.distPowerUUID], for: service)
                    return
                }
                if service.uuid == RaptrPeripheral.legacyServiceUUID {
                    print ("Legacy service found")
                    // kick off the discovery of characteristics
                    peripheral.discoverCharacteristics([RaptrPeripheral.legacyTxUUID], for: service)
                    peripheral.discoverCharacteristics([RaptrPeripheral.legacyRxUUID], for: service)
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                if characteristic.uuid == RaptrPeripheral.distPowerUUID {
                    print("Power Distance Characteristic found")
                    peripheral.setNotifyValue(true, for:characteristic)
                }
                if characteristic.uuid == RaptrPeripheral.legacyTxUUID {
                    print("Legacy TX Characteristic found")
                    peripheral.setNotifyValue(true, for: characteristic)
                }
                if characteristic.uuid == RaptrPeripheral.legacyRxUUID {
                    print("Legacy RX Characteristic found")
                    peripheral.setNotifyValue(true, for: characteristic)
                    rxChar = characteristic
                }
            }
        }
    }
    
    // Callback for updating the Bluetooth data
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == RaptrPeripheral.distPowerUUID {
            let data = characteristic.value!
            let decodedVector = decode(data: data)
            let transformedVector = transform(ints: decodedVector)
            distValue.text = String(transformedVector.dist)
            powerValue.text = String(transformedVector.power)
            
        }
        else if characteristic.uuid == RaptrPeripheral.legacyTxUUID {
            let data = characteristic.value!
            let str = String(decoding: data, as: UTF8.self)
            let dataPoints = str.components(separatedBy: ",")

            if dataPoints.count == 2 && data.count > 10 {
                // DEBUG Statement
                print(dataPoints)
d                powerValue.text = String(dataPoints[1])
                // Check the power value to change the label to respective color
                if let powerFloat = Float(dataPoints[1]) {
                    checkPower(powerFloat)
                } else {
                    print("ERROR: No power value available")
                }
                
                sessionMetrics.setMetrics(dist: dataPoints[0], power: dataPoints[1])
                if sessionMetrics.isPlaying {
                    updateLineGraph()
                }
            }
        }
    }
    
    // Decodes data into two UInt32 values
    func decode(data: Data) -> (dist: UInt32, power: UInt32) {
        let values = data.withUnsafeBytes { bufferPointer in
                bufferPointer
                    .bindMemory(to: UInt32.self)
                    .map { rawBitPattern in
                        return UInt32(littleEndian: rawBitPattern)
                    }
            }

        assert(values.count == 2)
        return (dist: values[0], power: values[1])
    }
    
    // Transforms the UInt32 values into Floats
    func transform(ints: (dist: UInt32, power: UInt32))
        -> (dist: Float, power: Float) {
        let transform: (UInt32) -> Float = { Float($0) / 1000000000 } // define whatever transformation you need
        return (transform(ints.dist), transform(ints.power))
    }
    
    // Function to check if power is increasing or decreasing and change the color of the UILabel
    func checkPower(_ power: Float) {
        if power > sessionMetrics.currentPower {
            powerValue.backgroundColor = .systemGreen
        } else if power < sessionMetrics.currentPower {
            powerValue.backgroundColor = .systemRed
        } else {
            powerValue.backgroundColor = .systemGray6
        }
    }
    
    // Update the line graph with power and distance values over time
    func updateLineGraph() {
        // Create new data entries for line graph
        let powerVsDist = ChartDataEntry(x: Double(sessionMetrics.currentDist), y: Double(sessionMetrics.currentPower))
        let powerGoalLine = ChartDataEntry(x: Double(sessionMetrics.currentDist), y: Double(powerGoal ?? 0.0))
                
        // Add new entry to their respective data sets
        sessionMetrics.powerVsDistSet.append(powerVsDist)
        sessionMetrics.goalSet.append(powerGoalLine)

        // Settings for Power vs Distance Line
        sessionMetrics.powerVsDistSet.drawCirclesEnabled = false
        sessionMetrics.powerVsDistSet.drawValuesEnabled = false
        sessionMetrics.powerVsDistSet.setColor(.systemGreen)
        sessionMetrics.powerVsDistSet.fill = Fill(color: .systemGreen)
        sessionMetrics.powerVsDistSet.fillAlpha = 0.8
        sessionMetrics.powerVsDistSet.drawFilledEnabled = true
        
        // Settings for Power Goal Line
        sessionMetrics.goalSet.drawCirclesEnabled = false
        sessionMetrics.goalSet.drawValuesEnabled = false
        sessionMetrics.goalSet.setColor(.systemRed)
        sessionMetrics.goalSet.lineWidth = 2.5
        
//        let data = LineChartData(dataSets: [sessionMetrics.powerVsDistSet, sessionMetrics.goalSet])
//        self.graphView.data = data
//        self.graphView.data?.notifyDataChanged()
    }
    
    // Increment the stopwatch timer
    @objc func updateTimer() {
        sessionMetrics.counter += 1
        timeLabel.text = String(format: "%.1f", sessionMetrics.counter / 10)
    }
    
    @IBAction func changeModePressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "goToModes", sender: self)
    }
    
    @IBAction func changeGoalPressed(_ sender: UIButton) {
        self.performSegue(withIdentifier: "changeGoal", sender: self)
    }
    
    @IBAction func recordButtonPressed(_ sender: Any) {
        if sessionMetrics.isPlaying {
            // Clear the timer
            sessionMetrics.timer.invalidate()
            sessionMetrics.isPlaying = false
            sessionMetrics.counter = 0.0
            let largeConfig = UIImage.SymbolConfiguration(pointSize: 140, weight: .bold, scale: .large)
            let largeRecordSymbol = UIImage(systemName: "record.circle", withConfiguration: largeConfig)
            recordButton.setImage(largeRecordSymbol, for: .normal)
        } else {
            // Save to CSV
//            sessionMetrics.createCsv(from: sessionMetrics.distPwrArray)
            
            // Clear the old graph data
//            self.graphView.clearValues()
            sessionMetrics.clearMetrics()
            
            // Create a new timer for stopwatch
            sessionMetrics.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            sessionMetrics.isPlaying = true
            let largeConfig = UIImage.SymbolConfiguration(pointSize: 140, weight: .bold, scale: .large)
            let largeStopSymbol = UIImage(systemName: "stop.fill", withConfiguration: largeConfig)
            recordButton.setImage(largeStopSymbol, for: .normal)
        }
    }
    
    @IBAction func connectionButtonPressed(_ sender: UIButton) {
        if centralManager == nil {
            // Connect to the BLE device
            statusLabel.text = "Connecting"
            statusLabel.backgroundColor = .systemOrange
            centralManager = CBCentralManager(delegate: self, queue: nil)
        } else {
            // Disconnect from BLE device
            centralManager.cancelPeripheralConnection(peripheral)
            centralManager = nil
            rxChar = nil
            
            statusLabel.text = "Disconnected"
            statusLabel.backgroundColor = .systemRed
            connectionButton.setTitle("Connect", for: .normal)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToModes" {
            let destinationVC = segue.destination as! MotorModeViewController
            destinationVC.peripheral = peripheral
            destinationVC.rxChar = rxChar
            destinationVC.modeTitle = selectedModeTitle ?? "OFF"
        } else if segue.identifier == "changeGoal" {
            let destinationVC = segue.destination as! GoalViewController
            if powerGoal == nil {
                destinationVC.powerInput = ""
            } else {
                destinationVC.powerInput = String(powerGoal)
            }
        }
    }
}
