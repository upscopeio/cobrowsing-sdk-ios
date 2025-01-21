//
//  FrameStorage.swift
//
//
//  Created by Upscope on 16.12.2024.
//

import UIKit

actor FrameStorage {
    var frames: [UIImage]
    
    init() {
        self.frames = []
    }
    
    func addFrameIfNeeded(_ frame: UIImage) -> Bool {
        if frames.isEmpty {
            frames.append(frame)
            return true
        }
        
        if let lastFrame = frames.last,
           let differentFrame = compare(previous: lastFrame, new: frame) {
            frames.removeFirst()
            frames.append(differentFrame)
            return true
        } else {
            return false
        }
    }
    
    func clearFrames() {
        frames.removeAll()
    }
    
    func compare(previous: UIImage, new: UIImage) -> UIImage? {
        let previousImageData = previous.getPixelData()
        let newImageData = new.getPixelData()
        if previousImageData != newImageData {
            return new
        }
        return nil
    }
}
