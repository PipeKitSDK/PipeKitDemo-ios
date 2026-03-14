//
//  RecordingTab.swift
//  PipeKitDemo
//
//  Session replay recording controls.
//
//  Created by AlmoutasemNabil on 2026.
//  Copyright © 2026 AlmoutasemNabil. All rights reserved.
//

import SwiftUI
import PipeKitSDK

struct RecordingTab: View {
    @State private var isRecording = false
    @State private var frameCount = 0
    @State private var touchCount = 0
    @State private var statusMessage = ""

    private let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    recordingStatusCard
                    recordingControls
                    quickActionsSection
                    logTestSection

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                    Spacer(minLength: 50)
                }
                .padding()
            }
            .navigationTitle("Session Replay")
            .onReceive(timer) { _ in updateStats() }
        }
        .trackScreen("RecordingTab")
    }

    private var recordingStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(isRecording ? Color.red : Color.gray)
                    .frame(width: 16, height: 16)
                Text(isRecording ? "Recording" : "Not Recording")
                    .font(.title2).fontWeight(.semibold)
            }

            if isRecording {
                HStack(spacing: 24) {
                    StatView(value: frameCount, label: "Frames", icon: "photo")
                    Divider().frame(height: 40)
                    StatView(value: touchCount, label: "Touches", icon: "hand.tap")
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 16).fill(isRecording ? Color.red.opacity(0.1) : Color.gray.opacity(0.1)))
        .sensitiveContent()
    }

    private var recordingControls: some View {
        HStack(spacing: 16) {
            Button(action: startRecording) {
                Label("Start", systemImage: "record.circle").frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent).tint(.green).disabled(isRecording)

            Button(action: stopRecording) {
                Label("Stop", systemImage: "stop.circle").frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent).tint(.red).disabled(!isRecording)
        }
        .sensitiveContent()
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Actions").font(.headline)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ActionButton(title: "Test Network", icon: "network", color: .blue) { testNetworkRequest() }
                ActionButton(title: "Simulate Error", icon: "exclamationmark.triangle", color: .orange) { simulateError() }
                ActionButton(title: "Crash App", icon: "xmark.octagon", color: .red) { triggerCrash() }
                NavigationLink { SecondScreen() } label: { ActionButtonContent(title: "Second Screen", icon: "rectangle.on.rectangle", color: .indigo) }
                NavigationLink { InteractiveScreen() } label: { ActionButtonContent(title: "Interactive", icon: "hand.draw", color: .purple) }
            }
        }
    }

    private var logTestSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Logging").font(.headline)
            HStack(spacing: 8) {
                LogButton(level: "Debug", color: .gray) { PipeKit.debug("Debug message"); statusMessage = "Logged debug" }
                LogButton(level: "Info", color: .blue) { PipeKit.log("Info message"); statusMessage = "Logged info" }
                LogButton(level: "Warn", color: .orange) { PipeKit.warning("Warning message"); statusMessage = "Logged warning" }
                LogButton(level: "Error", color: .red) { PipeKit.error("Error message"); statusMessage = "Logged error" }
            }
        }
    }

    private func startRecording() {
        PipeKit.startSession()
        isRecording = true
        statusMessage = "Recording started"
    }

    private func stopRecording() {
        PipeKit.stopSession()
        isRecording = false
        statusMessage = "Recording stopped and saved"
    }

    private func updateStats() {
        isRecording = PipeKit.isRecording
        if let session = PipeKit.currentSession {
            frameCount = session.frameCount ?? 0
            touchCount = session.touchEvents?.count ?? 0
        }
    }

    private func testNetworkRequest() {
        statusMessage = "Making request..."
        URLSession.shared.dataTask(with: URL(string: "https://httpbin.org/get")!) { _, response, error in
            DispatchQueue.main.async {
                if let error = error { statusMessage = "Error: \(error.localizedDescription)" }
                else if let r = response as? HTTPURLResponse { statusMessage = "Response: \(r.statusCode)" }
            }
        }.resume()
    }

    private func simulateError() {
        PipeKit.error("Simulated error!")
        statusMessage = "Error logged"
    }

    private func triggerCrash() {
        // Log some test data
        PipeKit.error("CRASH TEST: About to trigger fatal error")
        PipeKit.log("CRASH TEST: Last log before crash")

        // Give the logger + crash recovery timer a moment to flush
        // (the timer saves a checkpoint every 5s, let it fire at least once)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // This raises SIGILL — our signal handler will re-raise it,
            // and the process dies. On next launch, configure() will
            // finalize the recovered session from the last timer checkpoint.
            fatalError("Intentional crash triggered by user")
        }
    }
}

