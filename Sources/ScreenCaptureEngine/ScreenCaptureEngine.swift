//
//  1.swift
//  upscopeio-sdk
//
//  Created by Upscope on 19.09.2024.
//

import UIKit
import Photos
import AVFoundation
import ReplayKit

enum RecordType {
    case video
    case frames
}

protocol RecordingProtocol {
    func startRecordingAction(_ type: RecordType) async
    func stopRecordingAction() async
}

class ScreenCaptureEngine: NSObject, RPScreenRecorderDelegate {
    private let recorder = RPScreenRecorder.shared()
    private let frameHandler: (UIImage) -> Void
    
    init(frameHandler: @escaping (UIImage) -> Void) {
        self.frameHandler = frameHandler
        super.init()
        recorder.delegate = self
    }
    
    func startCapture() {
        recorder.isMicrophoneEnabled = false
        recorder.startCapture { (cmSampleBuffer, rpSampleBufferType, error) in
            if let error = error {
                print("Error during capture: \(error.localizedDescription)")
                return
            }
            
            guard rpSampleBufferType == .video else { return }
            
            guard let imageBuffer = CMSampleBufferGetImageBuffer(cmSampleBuffer) else { return }
            
            let ciImage = CIImage(cvPixelBuffer: imageBuffer)
            let context = CIContext()
            guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
            
            let image = UIImage(cgImage: cgImage)
            self.frameHandler(image)
        } completionHandler: { error in
            if let error = error {
                print("Capture stopped with error: \(error.localizedDescription)")
            }
        }
    }
    
    func stopCapture() {
        recorder.stopCapture { error in
            if let error = error {
                print("Error stopping capture: \(error.localizedDescription)")
            }
        }
    }
}
