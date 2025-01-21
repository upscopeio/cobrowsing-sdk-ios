//
//  BeginSessionData.swift
//  upscopeio-sdk
//
//  Created by Upscope on 25.09.2024.
//

struct BeginSessionData: Codable {
    let requestingAgent: String?
    let mode: Mode
    let desiredMode: Mode
}
