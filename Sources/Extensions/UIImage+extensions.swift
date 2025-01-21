//
//  UIImage+extensions.swift
//  upscopeio-sdk
//
//  Created by Upscope on 18.10.2024.
//

import SwiftUI

extension UIImage {
    func getPixelData() -> CFData? {
        if let cgImage = self.cgImage {
            let provider = cgImage.dataProvider
            return provider?.data
        }
        return nil
    }
    
    var base64: String? {
        self.jpegData(compressionQuality: 0.5)?.base64EncodedString()
    }
}
