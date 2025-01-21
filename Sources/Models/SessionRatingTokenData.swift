//
//  SessionRatingTokenData.swift
//  upscopeio-sdk
//
//  Created by Upscope on 25.09.2024.
//

struct SessionRatingTokenData: Codable {
    let token: String
    let sessionId: String
    let requestingAgent: String
}
