//
//  AVCaptureVideoOrientation+Extension.swift
//  VisionPose
//
//  Created by Mario on 03/04/2021.
//

import AVFoundation
import UIKit


//utility extension to define the device orientation

extension AVCaptureVideoOrientation {
    init(deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .landscapeLeft:
            self = .landscapeLeft
        case .landscapeRight:
            self = .landscapeRight
        case .portrait:
            self = .portrait
        case .portraitUpsideDown:
            self = .portraitUpsideDown
        default:
            self = .portrait
        }
    }
}
