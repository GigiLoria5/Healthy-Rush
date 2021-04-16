//
//  ViewController.swift
//  VisionPose
//
//  Created by Mario on 03/04/2021.
//

import UIKit
import Vision

class VisioPoseController: UIViewController {

    //Initial image dimension (set to zero)
    var imageSize = CGSize.zero
    
    private let videoCapture = VideoCapture()
    
    private var currentFrame: CGImage?
    
    private var minConfidenceAllowed: Float = 0.3
    
    
    //creates a new body processor
    private let bodyProcessor = BodyPoseProcessor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //initialize and start capturing video frames
        setupVideoFrms()
    }
    
    
    private func setupVideoFrms() {
        videoCapture.setupCapture { error in
            if let error = error {
                print("Impossibile inizializzare la camera: \(error)")
                return
            }
            self.videoCapture.captureDelegate = self
            
            self.videoCapture.startCapturing()
        }
    }
        
    //terminates the capturing if view closes
    override func viewWillDisappear(_ animated: Bool) {
        videoCapture.stopCapturing {
            super.viewWillDisappear(animated)
            
            //reset the body Processor
            self.bodyProcessor.reset()
            
        }
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        //Reinitialize camera to handle the orientation change
        setupVideoFrms()
    }
    
    //function linked to the changing camera button
    //flip internal camera with external if pressed
    @IBAction func onCameraButtonTapped(_ sender: Any) {
        videoCapture.flipCamera { error in
            if let error = error {
                print("Cambio della camera non riuscito: \(error)")
            }
            
            //reset the body processor when camera is flipped
            self.bodyProcessor.reset()
        }
    }
    
    /**
     The function requests to process the image passed as parameter
     to Vision framework
     */
    @available(iOS 14.0, *)
    func estimation(_ cgImage:CGImage) {
        imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        
        //create the requestHandler
        let requestHandler = VNImageRequestHandler(cgImage: cgImage)

        // Create a request to recognize a human body pose
        let request = VNDetectHumanBodyPoseRequest(completionHandler: bodyPoseHandler)

        do {
            // Execute iteratively the body pose-detection request.
            try requestHandler.perform([request])
        } catch {
            print("Richiesta pose-detection fallita: \(error).")
        }
    }
    
    /**
     Processes observations and generate the preview on screen of
     recognized human body pose
     */
    @available(iOS 14.0, *)
    func bodyPoseHandler(request: VNRequest, error: Error?) {
        guard let observations =
                request.results as? [VNHumanBodyPoseObservation] else { return }
        
        // Process each observation
        if observations.count == 0 {
//            poseLabel.text = "no body detected"
            guard self.currentFrame != nil else {
                return
            }
            //a new image is created after processing body points in current frame
//            let image = UIImage(cgImage: currentFrame)
            //open a thread that shows the preview image
            DispatchQueue.main.async {
//                self.previewImageView.image = image
            }
        } else {
            //creates a list of points according to the observation
            _ = observations.map { (observation) -> [CGPoint] in
                let ps = processObservation(observation)
                
                let joints = getBodyJointsFor(observation: observation)
            
//              process the current body pose
                bodyProcessor.processPose(joints)
                
//              print on device screen the current body state, which pose is now assuming
                
//                poseLabel.text = bodyProcessor.printBodyState()
                
//              debugPrint(bodyProcessor.returnBodyState())
                
                return ps ?? []
            }
            //converts the list to a monodimensional array
//            let flatten = points.flatMap{$0}

//            let image = currentFrame?.drawPoints(points: flatten)
//            DispatchQueue.main.async {
//                self.previewImageView.image = image
//            }
        }
        
    }
    
    /**
     Execute the retrieval of all points from the Vision Body observation.
     All recognized points are saved and converted into a list if the confidence
     is at least equal to a certain threshold value, as the weak recognitions should
     be avoided. Finally the points are projected from normalized coordinate space into
     image space
     */
    
    @available(iOS 14.0, *)
    func processObservation(_ observation: VNHumanBodyPoseObservation) -> [CGPoint]? {
        
        // Retrieve all body points.
        
        guard let recognizedPoints =
                try? observation.recognizedPoints(forGroupKey: .all) else {
            return []
        }
        
        
        let imagePoints: [CGPoint] = recognizedPoints.values.compactMap {
            guard $0.confidence > minConfidenceAllowed else { return nil }
            
            let imgS = CGPoint(x: imageSize.width, y: imageSize.height)

            return normalizedToImagePoints(point: $0.location, w: Int(imgS.x), h: Int(imgS.y))
        }
        
        return imagePoints
    }
    
    /**
     Returns a list of positions associated with the points recognized by the pose observation from Vision.
     The points are the relative position in the image
     */
    
    @available(iOS 14.0, *)
    func getBodyJointsFor(observation: VNHumanBodyPoseObservation) -> ([VNHumanBodyPoseObservation.JointName: CGPoint]) {
        
        var joints = [VNHumanBodyPoseObservation.JointName : CGPoint]()
        
        guard let identifiedPoints = try? observation.recognizedPoints(.all) else {
            return joints
        }
        
        let imgS = CGPoint(x: imageSize.width, y: imageSize.height)
        
        for (key, point) in identifiedPoints {
            guard point.confidence > 0.1 else { continue }
//        select only joints in the jointsOfInterest list and saves the relative positions
            if jointsOfInterest.contains(key) {
                joints[key] = normalizedToImagePoints(point: point.location, w: Int(imgS.x), h: Int(imgS.y))
            }
        }
        return joints
    }

}



// MARK: - VideoCaptureDelegate

extension VisioPoseController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame capturedImage: CGImage?) {

        guard let image = capturedImage else {
            fatalError("Immagine catturata è NULL")
        }

        currentFrame = image
        
        if #available(iOS 14.0, *) {
            estimation(image)
        } else {
            // Fallback on earlier versions
        }
    }
}
