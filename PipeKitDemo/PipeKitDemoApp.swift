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
            apiKey: "pk_live_LH7N18khutYbG7w7-MDPrZJZ66NiWsjHUm5carpaLIM",
            baseURL: "https://pipekit.tech",
            // appId omitted — falls back to the real bundle id (com.pipekit.demo),
            // which is what the backend app row and session uploads are keyed on.
            config: PipeKitConfig(
                enableSessionReplay: true,
                enableFlows: true,
                captureNetwork: true,
                captureConsoleLogs: true,
                // MQTT is the default since 1.0.0 and needs no configuration: the
                // broker host comes from baseURL and the connection is TLS on 8883.
                // Stated explicitly here because this app is the reference example.
                transport: .mqtt
            )
        )

        // Local stack (docker compose): the API on :8080 and a plaintext broker
        // on :1883. Swap the block above for this when testing against it —
        // never commit it, the plaintext broker would send the API key in clear.
        //
        // PipeKit.configure(
        //     apiKey: "<your local pk_live key>",
        //     baseURL: "http://192.168.1.14:8080",
        //     config: PipeKitConfig(
        //         transport: .mqtt,
        //         mqttHost: "192.168.1.14",
        //         mqttPort: 1883,
        //         mqttUseTLS: false
        //     )
        // )

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
