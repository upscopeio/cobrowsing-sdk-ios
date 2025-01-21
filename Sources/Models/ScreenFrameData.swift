//
//  ScreenFrameData.swift
//  upscopeio-sdk
//
//  Created by Upscope on 04.11.2024.
//

struct ImageSize: Codable {
    let w: Double
    let h: Double
}

enum ScreenFrameData: Codable {
    case base64String(String)
    case size(ImageSize)
    
    // Custom encoding logic
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .base64String(let base64String):
            try container.encode("data:image/png;base64,"+base64String)
        case .size(let size):
            try container.encode(size)
        }
    }
    
    // Custom decoding logic
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try decoding as a string
        if let base64String = try? container.decode(String.self) {
            self = .base64String(base64String)
            return
        }
        
        // Try decoding as an ImageSize
        if let size = try? container.decode(ImageSize.self) {
            self = .size(size)
            return
        }
        
        throw DecodingError.typeMismatch(
            ScreenFrameData.self,
            DecodingError.Context(
                codingPath: decoder.codingPath,
                debugDescription: "Expected a base64 string or ImageSize object"
            )
        )
    }
}
