//
//  VisioController.swift
//  Healthy Rush
//
//  Created by mario on 17/04/21.
//

import UIKit
import Vision

class VisioController{
    
    //Initial image dimension (set to zero)
    var imageSize = CGSize.zero
    private let videoCapture = VideoCapture(quality: .low)
    //creates a new body processor
    private var scaleFactor: CGFloat!
    private var bodyProcessor : BodyPoseProcessor! = nil
    private var minConfidenceAllowed: Float = 0.3
    var bodyState : BodyPoseProcessor.BodyState!
    
    
    func startCapture() {
        
        switch videoCapture.preferredQuality! {
        case .high:
            scaleFactor = 1
        case .medium:
            scaleFactor = 1/3
        case .low:
            scaleFactor = 1/5
        default:
            scaleFactor = 1
        }
        
        bodyProcessor = BodyPoseProcessor(scaleFactor: scaleFactor)
        
        videoCapture.setupCapture { error in
            if let error = error {
                print("Impossibile inizializzare la camera: \(error)")
                return
            }
            self.videoCapture.captureDelegate = self
            if self.videoCapture.captureDelegate != nil{
                self.videoCapture.startCapturing()
            }else{
                print("inizializzazione cattura fallita")
            }
        }
    }
    
    func stopCapture(){
        
        self.videoCapture.stopCapturing(){
            
            self.bodyProcessor.reset()
        }
    }
    
    func flipCamera(){
        videoCapture.flipCamera { error in
            if let error = error {
                print("Cambio della camera non riuscito: \(error)")
            }
            
            //reset the body processor when camera is flipped
            self.bodyProcessor.reset()
        }
    }
    
    
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
            
        } else {
            //creates a list of points according to the observation
            _ = observations.map { (observation) -> [CGPoint] in
                let ps = processObservation(observation)
                
                let joints = getBodyJointsFor(observation: observation)
            
//              process the current body pose
                bodyProcessor.processPose(joints)
                print(bodyProcessor.printBodyState())
                bodyState = bodyProcessor.returnBodyState()
                
                return ps ?? []
            }
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

extension VisioController: VideoCaptureDelegate {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame capturedImage: CGImage?) {

        guard let image = capturedImage else {
            fatalError("Immagine catturata è NULL")
        }
        
        if #available(iOS 14.0, *) {
            estimation(image)
        } else {
            // Fallback on earlier versions
            print("Impossibile avviare stima immagine")
        }
    }
    
}
