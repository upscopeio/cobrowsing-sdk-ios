//
//  ErrorData.swift
//  upscopeio-sdk
//
//  Created by Upscope on 06.11.2024.
//

// TODO: - verificate the json version

struct ErrorData: Codable {
    enum ErrorType: String, Codable {
        case error, warn
    }
    
    let errorType: ErrorType
    let description: String
}
