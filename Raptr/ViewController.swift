//
//  ViewController.swift
//  Raptr
//
//  Created by Andrew Kim on 12/26/20.
//

import UIKit
import CoreBluetooth
import Foundation

class ViewController: UIViewController, CBPeripheralDelegate, CBCentralManagerDelegate {
    
    
    @IBOutlet weak var distValue: UILabel!
    @IBOutlet weak var powerValue: UILabel!
    @IBOutlet weak var offButton: UIButton!
    @IBOutlet weak var leftMotorButton: UIButton!
    @IBOutlet weak var rightMotorButton: UIButton!
    @IBOutlet weak var latVarButton: UIButton!
    @IBOutlet weak var linear1Button: UIButton!
    @IBOutlet weak var linear2Button: UIButton!
    @IBOutlet weak var linear3Button: UIButton!
    @IBOutlet weak var linear4Button: UIButton!
    
    // Properties
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    
    private var rxChar: CBCharacteristic?

    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
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
            print("Connected to RAPTR sled")
            // Discover both Nordic and Legacy services
            peripheral.discoverServices([RaptrPeripheral.sledServiceUUID, RaptrPeripheral.legacyServiceUUID])
        }
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
            let filtered = String(str.filter {!"\r\n".contains($0) })
            let dataPoints = filtered.components(separatedBy: ",")

            if dataPoints.count == 5 {
                distValue.text = String(dataPoints[2])
                powerValue.text = String(dataPoints[4])
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
    
    // Writes an input value to the specificed characteristic
    private func writeModeToChar(withCharacteristic characteristic: CBCharacteristic, withValue value: Data) {
        if characteristic.properties.contains(.write) && peripheral != nil {
            // write the sled mode value to the specified characteristic
            peripheral.writeValue(value, for: characteristic, type: .withResponse)
        }
    }
    
    // PWM Motor Control Button Callbacks
    @IBAction func offButtonPressed(_ sender: UIButton) {
        writeModeToChar(withCharacteristic: rxChar!, withValue: Data("!B81".utf8))
    }
    @IBAction func leftMotorButtonPressed(_ sender: UIButton) {
        writeModeToChar(withCharacteristic: rxChar!, withValue: Data("!B71".utf8))
    }
    @IBAction func rightMotorButtonPressed(_ sender: UIButton) {
        writeModeToChar(withCharacteristic: rxChar!, withValue: Data("!B61".utf8))
    }
    @IBAction func latVarButtonPressed(_ sender: UIButton) {
        writeModeToChar(withCharacteristic: rxChar!, withValue: Data("!B51".utf8))
    }
    // Linear Motor Control Button Callbacks
    @IBAction func linear1ButtonPressed(_ sender: UIButton) {
        writeModeToChar(withCharacteristic: rxChar!, withValue: Data("!B11".utf8))
    }
    @IBAction func linear2ButtonPressed(_ sender: UIButton) {
        writeModeToChar(withCharacteristic: rxChar!, withValue: Data("!B21".utf8))
    }
    @IBAction func linear3ButtonPressed(_ sender: UIButton) {
        writeModeToChar(withCharacteristic: rxChar!, withValue: Data("!B31".utf8))
    }
    @IBAction func linear4ButtonPressed(_ sender: UIButton) {
        writeModeToChar(withCharacteristic: rxChar!, withValue: Data("!B41".utf8))
    }
}

