//
//  GoalViewController.swift
//  Raptr
//
//  Created by Andrew Kim on 1/1/21.
//

import UIKit

class GoalViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var powerGoalInput: UITextField!
    
    var powerInput: String = "0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        powerGoalInput.delegate = self
        powerGoalInput.text = powerInput
        powerGoalInput.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        powerGoalInput.endEditing(true)
        
        powerInput = textField.text ?? "0"
        
        if let vc = presentingViewController as? SledViewController {
            self.dismiss(animated: true, completion: {
                vc.powerGoal = Float(self.powerInput)
            })
        }
        
        return true
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
