//
//  SparkService.swift
//  Healthy Rush
//
//  Created by Luigi Loria on 13/04/21.
//

import UIKit
import JGProgressHUD

class SparkService {
    
    // MARK: -
    // MARK: Show alert
    /*
    static func showAlert(style: UIAlertController.Style, title: String?, message: String?, actions: [UIAlertAction] = [UIAlertAction(title: "Ok", style: .cancel, handler: nil)], completion: (() -> Swift.Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        for action in actions {
            alert.addAction(action)
        }
        if let topVC = UIApplication.getTopMostViewController() {
            topVC.present(alert, animated: true, completion: completion)
        }
    }
    
    static func showAlert(style: UIAlertController.Style, title: String?, message: String?, textFields: [UITextField], completion: @escaping ([String]?) -> ()) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        
        for textField in textFields {
            alert.addTextField(configurationHandler: { (theTextField) in
                theTextField.placeholder = textField.placeholder
            })
        }
        
        let textFieldAction = UIAlertAction(title: "Submit", style: .cancel) { (action) in
            var textFieldsTexts: [String] = []
            if let alertTextFields = alert.textFields {
                for textField in alertTextFields {
                    if let textFieldText = textField.text {
                        textFieldsTexts.append(textFieldText)
                    }
                }
                completion(textFieldsTexts)
            }
        }
        alert.addAction(textFieldAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default) { (action) in
            completion(nil)
        }
        alert.addAction(cancelAction)
        
        if let topVC = UIApplication.getTopMostViewController() {
            topVC.present(alert, animated: true, completion: nil)
        }
        
    }
    */
    // MARK: -
    // MARK: dismiss hud
    
    static func dismissHud(_ hud: JGProgressHUD, text: String, detailText: String, delay: TimeInterval) {
        DispatchQueue.main.async {
            hud.textLabel.text = text
            hud.detailTextLabel.text = detailText
            hud.dismiss(afterDelay: delay, animated: true)
        }
    }
}
