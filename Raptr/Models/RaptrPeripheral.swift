//
//  RaptrPeripheral.swift
//  Raptr
//
//  Created by Andrew Kim on 12/26/20.
//

import UIKit
import CoreBluetooth

import Foundation

class RaptrPeripheral: NSObject {
    // Nordic Chip
    public static let sledServiceUUID = CBUUID.init(string: "823C1400-0FCF-4F7F-A226-14480F5D6B1C")
    public static let distPowerUUID = CBUUID.init(string:"823C1401-0FCF-4F7F-A226-14480F5D6B1C")
    public static let pwmUUID = CBUUID.init(string:"823C1402-0FCF-4F7F-A226-14480F5D6B1C")
    
    // Adafruit Legacy
    public static let legacyServiceUUID = CBUUID.init(string:"6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    public static let legacyTxUUID = CBUUID.init(string:"6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
    public static let legacyRxUUID = CBUUID.init(string:"6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
}
