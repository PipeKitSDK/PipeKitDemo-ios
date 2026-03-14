//
//  SettingsView.swift
//  PipeKitDemo
//
//  Created by AlmoutasemNabil on 2026.
//  Copyright © 2026 AlmoutasemNabil. All rights reserved.
//

import SwiftUI
import PipeKitSDK

struct SettingsView: View {
    @PipeFlag var showOnboarding: Bool = true
    @PipeFlag var enableBetaFeatures: Bool = false
    @PipeFlag var maxRetries: Int = 3

    var body: some View {
        NavigationStack {
            List {
                Section("PipeKit SDK") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(PipeKit.version)
                            .foregroundColor(.secondary)
                    }
                }

                Section("Feature Flags (@PipeFlag)") {
                    HStack {
                        Text("showOnboarding")
                            .font(.subheadline.monospaced())
                        Spacer()
                        Image(systemName: showOnboarding ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(showOnboarding ? .green : .red)
                    }
                    HStack {
                        Text("enableBetaFeatures")
                            .font(.subheadline.monospaced())
                        Spacer()
                        Image(systemName: enableBetaFeatures ? "checkmark.circle.fill" : "xmark.circle")
                            .foregroundColor(enableBetaFeatures ? .green : .red)
                    }
                    HStack {
                        Text("maxRetries")
                            .font(.subheadline.monospaced())
                        Spacer()
                        Text("\(maxRetries)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Flow Engine") {
                    HStack {
                        Text("Registered Nodes")
                        Spacer()
                        Text("\(FlowRegistry.shared.count)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Registered @Rewire Functions") {
                    ForEach(FlowRegistry.shared.availableNodes, id: \.id) { node in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "puzzlepiece.extension")
                                    .foregroundColor(.indigo)
                                Text(node.displayName)
                                    .font(.subheadline.weight(.semibold))
                            }
                            Text("(\(node.parameters.isEmpty ? "void" : node.parameters)) \u{2192} \(node.returnType)")
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }

                Section("Session Replay") {
                    HStack {
                        Text("Recording")
                        Spacer()
                        Text(PipeKit.isRecording ? "Active" : "Stopped")
                            .foregroundColor(PipeKit.isRecording ? .green : .secondary)
                    }
                    HStack {
                        Text("Saved Sessions")
                        Spacer()
                        Text("\(PipeKit.getSavedSessions().count)")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Device") {
                    HStack {
                        Text("Device ID")
                        Spacer()
                        Text(PipeKitRemote.getOrCreateDeviceId().prefix(8) + "...")
                            .foregroundColor(.secondary).font(.caption.monospaced())
                    }
                }

                Section("Storage") {
                    Button("Clear All Sessions", role: .destructive) {
                        PipeKit.getSavedSessions().forEach { PipeKit.deleteSession($0) }
                    }
                }

                Section("About") {
                    Text("PipeKit Demo")
                        .font(.headline)
                    Text("The iOS SDK for session replay, remote feature flags, and server-driven logic — all in one line of code.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Link("pipekit.tech", destination: URL(string: "https://pipekit.tech")!)
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
        }
        .trackScreen("SettingsTab")
    }
}
