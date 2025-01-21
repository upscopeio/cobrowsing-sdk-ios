//
//  AppDelegate.swift
//  UpscopeIO
//
//  Created by Upscope on 01/21/2025.
//  Copyright (c) 2025 Upscope. All rights reserved.
//

import UIKit
import UpscopeIO

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var upscopeManager: UpscopeManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // Init your Upscope Manager with custom configurations and mandatory apiKey
        upscopeManager = .init(apiKey: "Your api here", uniqueId: .value("My uniqueId here"))
        
        return true
    }
}

