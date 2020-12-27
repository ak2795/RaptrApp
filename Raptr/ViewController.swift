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
    
    // Properties
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!

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
                    peripheral.discoverCharacteristics([RaptrPeripheral.legacyDataUUID], for: service)
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
                if characteristic.uuid == RaptrPeripheral.legacyDataUUID {
                    print("Legacy Data Characteristic found")
                    peripheral.setNotifyValue(true, for: characteristic)
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
        else if characteristic.uuid == RaptrPeripheral.legacyDataUUID {
            let data = characteristic.value!
            let str = String(decoding: data, as: UTF8.self)
            let filtered = String(str.filter {!"\r\n".contains($0) })
            let dataPoints = filtered.components(separatedBy: ",")
            print(str)
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

}

