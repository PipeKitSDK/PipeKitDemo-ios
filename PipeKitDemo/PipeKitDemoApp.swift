//
//  PipeKitDemoApp.swift
//  PipeKitDemo
//
//  Created by AlmoutasemNabil on 2026.
//  Copyright © 2026 AlmoutasemNabil. All rights reserved.
//

import SwiftUI
import PipeKitSDK

@main
struct PipeKitDemoApp: App {

    init() {
        // All @FlowEntry types are auto-discovered — no manual registration needed.
        PipeKit.configure(
            apiKey: "pk_live_YOUR_KEY",
            baseURL: "https://pipekit.tech",
            config: PipeKitConfig(
                enableSessionReplay: true,
                enableFlows: true,
                captureNetwork: true,
                captureConsoleLogs: true
            )
        )

        PipeKit.identifyUser(userId: UUID().uuidString, email: "jon@snow.com", name: "demo user")

        // Show what's registered
        PipeKit.catalog()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
