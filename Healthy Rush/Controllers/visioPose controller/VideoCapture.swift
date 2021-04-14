//
//  VideoCapture.swift
//  VisionPose
//
//  Created by Mario on 03/04/2021.
//


import AVFoundation
import CoreVideo
import UIKit
import VideoToolbox



protocol VideoCaptureDelegate: AnyObject {
    func videoCapture(_ videoCapture: VideoCapture, didCaptureFrame image: CGImage?)
}

//Defines some error during video capture
enum VideoCaptureError: Error {
    case invalidInput
    case invalidOutput
    case unknown
}

class VideoCapture: NSObject {
    
    weak var captureDelegate: VideoCaptureDelegate?

    let captureSession = AVCaptureSession()

    let videoOutput = AVCaptureVideoDataOutput()

    //Set the internal camera as the default initial capture device
    private var cameraPstn = AVCaptureDevice.Position.front

    
    private let sessionQueue = DispatchQueue(
        label: "poseEstimateSessionQueue")
    
    
    /**
     Switches front to rear camera and viceversa.
     */
    public func flipCamera(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            do {
                self.cameraPstn = self.cameraPstn == .back ? .front : .back

                self.captureSession.beginConfiguration()

                try self.setCaptureSessionInput()
                try self.setCaptureSessionOutput()

                self.captureSession.commitConfiguration()

                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    //this part of the function tries to setup the capture calling the private istance
    public func setupCapture(completion: @escaping (Error?) -> Void) {
        sessionQueue.async {
            do {
                try self.setupCapture()
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }
    }
    /**
     This is the part of the function internal to the class and unaccessible from outside.
     It checks if a session is already running and terminates its execution, then starts a new capture session.
     */
    private func setupCapture() throws {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }

        captureSession.beginConfiguration()

        // A 1080p video capture is preferred but if camera cannot provide it then
        //fall back to maximum possible quality
        if(captureSession.canSetSessionPreset(.hd1920x1080)){
            captureSession.sessionPreset = .hd1920x1080
        }
        else{
            captureSession.sessionPreset = .high
        }
        

        try setCaptureSessionInput()

        try setCaptureSessionOutput()

        //commit the current configuration to capture device
        captureSession.commitConfiguration()
    }

    private func setCaptureSessionInput() throws {

        guard let captureDevice = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: AVMediaType.video,
            position: cameraPstn) else {
                throw VideoCaptureError.invalidInput
        }

        captureSession.inputs.forEach { input in
            captureSession.removeInput(input)
        }

        
        guard let videoInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            throw VideoCaptureError.invalidInput
        }

        guard captureSession.canAddInput(videoInput) else {
            throw VideoCaptureError.invalidInput
        }

        captureSession.addInput(videoInput)
    }

    private func setCaptureSessionOutput() throws {
        captureSession.outputs.forEach { output in
            captureSession.removeOutput(output)
        }

        // Discard newer frames that arrive while the dispatch queue is already busy with
        // an older frame.
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        //Set a new buffer to handle data stream
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)

        guard captureSession.canAddOutput(videoOutput) else {
            throw VideoCaptureError.invalidOutput
        }

        captureSession.addOutput(videoOutput)

        // Update the video orientation
        if let connection = videoOutput.connection(with: .video),
            connection.isVideoOrientationSupported {
            connection.videoOrientation =
                AVCaptureVideoOrientation(deviceOrientation: UIDevice.current.orientation)
            connection.isVideoMirrored = cameraPstn == .front

            // Inverse the landscape orientation to force the image in the upward
            // orientation.
            if connection.videoOrientation == .landscapeLeft {
                connection.videoOrientation = .landscapeRight
            } else if connection.videoOrientation == .landscapeRight {
                connection.videoOrientation = .landscapeLeft
            }
        }
    }


    public func startCapturing(completion completionHandler: (() -> Void)? = nil) {
        sessionQueue.async {
            if !self.captureSession.isRunning {
                // Invoke the startRunning method of the captureSession to start the
                // flow of data from the inputs to the outputs.
                self.captureSession.startRunning()
            }

            if let completionHandler = completionHandler {
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
    }

    public func stopCapturing(completion completionHandler: (() -> Void)? = nil) {
        sessionQueue.async {
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }

            if let completionHandler = completionHandler {
                DispatchQueue.main.async {
                    completionHandler()
                }
            }
        }
    }
}


extension VideoCapture: AVCaptureVideoDataOutputSampleBufferDelegate {

    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard let captureDelegate = captureDelegate else { return }

    
        if #available(iOS 13.0, *) {
            if let pixelBuffer = sampleBuffer.imageBuffer {
                //starts by locking the buffer to obtain privileges 
                guard CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly) == kCVReturnSuccess
                else {
                    return
                }
                
                var image: CGImage?
                
                //creates a new bitmap image from the passed pixelbuffer
                VTCreateCGImageFromCVPixelBuffer(pixelBuffer, options: nil, imageOut: &image)
                //unlock the buffer to release resources
                CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
                
                DispatchQueue.main.sync {
                    captureDelegate.videoCapture(self, didCaptureFrame: image)
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
