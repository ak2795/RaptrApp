//
//  MotorModeViewController.swift
//  Raptr
//
//  Created by Andrew Kim on 12/31/20.
//

import UIKit
import CoreBluetooth

class MotorModeViewController: UIViewController {
    var peripheral: CBPeripheral!
    var rxChar: CBCharacteristic!
    var selectedMode: UIButton! = nil
    var modeTitle: String! = "OFF"
    
    // buttion dictionary
    var modeButtons : [String? : UIButton]?
    
    @IBOutlet weak var offButton: UIButton!
    @IBOutlet weak var linear1Button: UIButton!
    @IBOutlet weak var linear2Button: UIButton!
    @IBOutlet weak var linear3Button: UIButton!
    @IBOutlet weak var latVarButton: UIButton!
    @IBOutlet weak var rollingHillsButton: UIButton!
    @IBOutlet weak var leftMotorButton: UIButton!
    @IBOutlet weak var rightMotorButton: UIButton!
        
    override func viewDidLoad() {
        modeButtons = [offButton.currentTitle : offButton,
                        linear1Button.currentTitle : linear1Button,
                        linear2Button.currentTitle : linear2Button,
                        linear3Button.currentTitle : linear3Button,
                        latVarButton.currentTitle : latVarButton,
                        rollingHillsButton.currentTitle: rollingHillsButton,
                        leftMotorButton.currentTitle : leftMotorButton,
                        rightMotorButton.currentTitle : rightMotorButton]
        
        super.viewDidLoad()
        setButtonState(offButton)
        setButtonState(linear1Button)
        setButtonState(linear2Button)
        setButtonState(linear3Button)
        setButtonState(latVarButton)
        setButtonState(rollingHillsButton)
        setButtonState(leftMotorButton)
        setButtonState(rightMotorButton)
        
        // Initialize with the offButton selected
        if selectedMode == nil {
            selectedMode = offButton
        }
        selectedMode = modeButtons?[modeTitle]
        selectedMode.backgroundColor = .systemBlue
        selectedMode.isEnabled = false
    }
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        if let vc = presentingViewController as? SledViewController {
            self.dismiss(animated: true, completion: {
                vc.selectedModeTitle = self.selectedMode.currentTitle
            })
        }
    }
    
    // Function to set the state of the buttons
    func setButtonState(_ button: UIButton) {
        button.isEnabled = peripheral != nil
        if button.isEnabled {
            if button.currentTitle == "OFF" {
                button.backgroundColor = .systemRed
            } else {
                button.backgroundColor = .label
            }
        }
        else {
            button.backgroundColor = .systemGray
        }
    }
    
    // Writes an input value to the specificed characteristic
    private func writeModeToChar(withCharacteristic characteristic: CBCharacteristic, withValue value: Data) {
        if characteristic.properties.contains(.write) && peripheral != nil {
            // write the sled mode value to the specified characteristic
            peripheral.writeValue(value, for: characteristic, type: .withResponse)
        }
    }
    
    @IBAction func motorControlPressed(_ sender: UIButton) {
        // Determine which button is pressed to and write the correct command to the characteristic
        let buttonPressed = sender.currentTitle
        switch buttonPressed {
//        case "OFF":
//            writeModeToChar(withCharacteristic: rxChar!, withValue: Data([0x00]))
//        case "Left Motor":
//            writeModeToChar(withCharacteristic: rxChar!, withValue: Data([0x00]))
//        case "Right Motor":
//            writeModeToChar(withCharacteristic: rxChar!, withValue: Data([0x00]))
//        case "Lateral Variation":
//            writeModeToChar(withCharacteristic: rxChar!, withValue: Data([0x00]))
        case "Linear 1":
            writeModeToChar(withCharacteristic: rxChar!, withValue: Data([0x01]))
        case "Linear 2":
            writeModeToChar(withCharacteristic: rxChar!, withValue: Data([0x02]))
        case "Linear 3":
            writeModeToChar(withCharacteristic: rxChar!, withValue: Data([0x03]))
        case "Rolling Hills":
            writeModeToChar(withCharacteristic: rxChar!, withValue: Data([0x06]))
        default:
            break
        }
        // Change the color of the selected mode and set the new selected mode
        setButtonState(selectedMode)
        selectedMode.isEnabled = true
        sender.backgroundColor = .systemBlue
        sender.isEnabled = false
        selectedMode = sender
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
