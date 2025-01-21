//
//  YouAreData.swift
//  upscopeio-sdk
//
//  Created by Upscope on 25.09.2024.
//

struct YouAreData: Codable {
    let shortId: String
    let uniqueConnectionId: String
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        guard container.count == 2 else {
            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Expected 2 elements in YouAreData array")
        }
        shortId = try container.decode(String.self)
        uniqueConnectionId = try container.decode(String.self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(shortId)
        try container.encode(uniqueConnectionId)
    }
}
