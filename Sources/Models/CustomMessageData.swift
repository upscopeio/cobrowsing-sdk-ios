//
//  CustomMessageData.swift
//  upscopeio-sdk
//
//  Created by Upscope on 19.11.2024.
//

import Foundation

struct Visitor: Codable {
    let visitor: String // uniqueId or shortId
}

struct CustomMessageData: Codable {
    let visitor: Visitor
    let message: String
}
