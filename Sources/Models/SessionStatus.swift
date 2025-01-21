//
//  SessionStatusData.swift
//  upscopeio-sdk
//
//  Created by Upscope on 13.11.2024.
//

enum SessionStatus: String, Codable {
    case active
    case pending = "pendingRequest"
}
