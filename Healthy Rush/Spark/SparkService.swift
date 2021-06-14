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
    // MARK: dismiss hud
    
    static func dismissHud(_ hud: JGProgressHUD, text: String, detailText: String, delay: TimeInterval) {
        DispatchQueue.main.async {
            hud.textLabel.text = text
            hud.detailTextLabel.text = detailText
            hud.dismiss(afterDelay: delay, animated: true)
        }
    }
}
