//
//  RemoteInstructionData.swift
//  upscopeio-sdk
//
//  Created by Upscope on 04.11.2024.
//

struct RemoteInstructionData: Codable {
    let action: String
    let agentName: String
    let observerId: String
    let shortId: String
    let uniqueConnectionId: String
    let lineData: LineData?
    let color: String?
    let x: Double?
    let y: Double?
    
    struct LineData: Codable {
        let path: String
        let color: String
    }
}
