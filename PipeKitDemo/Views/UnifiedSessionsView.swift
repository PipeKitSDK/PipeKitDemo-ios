//
//  UnifiedSessionsView.swift
//  PipeKitDemo
//
//  Session browser with video playback and synchronized activity timeline.
//
//  Created by AlmoutasemNabil on 2026.
//  Copyright © 2026 AlmoutasemNabil. All rights reserved.
//

import SwiftUI
import PipeKitSDK
import AVKit

struct UnifiedSessionsView: View {
    @State private var sessions: [SessionReplayData] = []
    @State private var selectedSessionId: String?
    @State private var isUploading: [String: Bool] = [:]
    @State private var alertMessage = ""
    @State private var showingAlert = false

    // Player state
    @State private var player: AVPlayer?
    @State private var currentVideoTimeMs: TimeInterval = 0
    @State private var videoDurationMs: TimeInterval = 0
    @State private var isPlaying = false
    @State private var timeObserver: Any?
    @State private var durationObserver: NSKeyValueObservation?

    var selectedSession: SessionReplayData? {
        guard let id = selectedSessionId else { return nil }
        return sessions.first { $0.sessionId == id }
    }

    var body: some View {
        NavigationSplitView {
            Group {
                if sessions.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "video.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("No Sessions")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("Record from the Record tab")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    List(selection: $selectedSessionId) {
                        ForEach(sessions) { session in
                            SessionListItem(
                                session: session,
                                isSelected: selectedSessionId == session.sessionId,
                                isUploading: isUploading[session.sessionId] ?? false,
                                onUpload: { uploadSession(session) }
                            )
                            .tag(session.sessionId)
                        }
                        .onDelete(perform: deleteSessions)
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationTitle("Sessions")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadSessions) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear(perform: loadSessions)
            .alert("Upload", isPresented: $showingAlert) { Button("OK") {} } message: { Text(alertMessage) }

        } detail: {
            if let session = selectedSession {
                SyncedPlayerView(
                    session: session,
                    player: $player,
                    currentVideoTimeMs: $currentVideoTimeMs,
                    videoDurationMs: $videoDurationMs,
                    isPlaying: $isPlaying
                )
                .id(session.sessionId)
                .onAppear { setupPlayer(for: session) }
                .onDisappear { cleanupPlayer() }
                .onChange(of: selectedSessionId) { newId in
                    if let id = newId, let session = sessions.first(where: { $0.sessionId == id }) {
                        setupPlayer(for: session)
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "play.rectangle.on.rectangle")
                        .font(.system(size: 70))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Select a Session")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Choose a session from the sidebar to watch\nwith synchronized activity timeline")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    if !sessions.isEmpty {
                        Button(action: { selectedSessionId = sessions.first?.sessionId }) {
                            Label("Play Latest", systemImage: "play.fill")
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 10)
                    }
                }
                .padding()
            }
        }
        .trackScreen("UnifiedSessionsView")
    }

    // MARK: - Data Management

    private func loadSessions() {
        sessions = PipeKit.getSavedSessions()
        if let id = selectedSessionId, !sessions.contains(where: { $0.sessionId == id }) {
            selectedSessionId = nil
            cleanupPlayer()
        }
    }

    private func deleteSessions(at offsets: IndexSet) {
        for i in offsets {
            let session = sessions[i]
            if selectedSessionId == session.sessionId {
                selectedSessionId = nil
                cleanupPlayer()
            }
            PipeKit.deleteSession(session)
        }
        sessions.remove(atOffsets: offsets)
    }

    private func uploadSession(_ session: SessionReplayData) {
        guard SessionUploader.shared.isConfigured else {
            alertMessage = "Upload endpoint configured automatically via PipeKit.configure()"
            showingAlert = true
            return
        }
        isUploading[session.sessionId] = true
        PipeKit.uploadSession(sessionId: session.sessionId) { result in
            DispatchQueue.main.async {
                isUploading[session.sessionId] = false
                switch result {
                case .success(let response):
                    alertMessage = "Upload successful!\nSession: \(response.sessionId)"
                case .failure(let error):
                    alertMessage = "Upload failed: \(error.localizedDescription)"
                }
                showingAlert = true
            }
        }
    }

    // MARK: - Player Management

    private func setupPlayer(for session: SessionReplayData) {
        cleanupPlayer()
        guard session.frameCount > 0,
              let url = SessionReplayManager.shared.getVideoURL(for: session),
              FileManager.default.fileExists(atPath: url.path) else {
            // No video or 0 frames (e.g. logs-only session or crash before first frame)
            player = nil
            videoDurationMs = 0
            return
        }

        // Validate the video file has actual playable content
        let asset = AVURLAsset(url: url)
        let tracks = asset.tracks(withMediaType: .video)
        guard !tracks.isEmpty else {
            print("[PipeKit] Video file has no video tracks — likely corrupt: \(url.lastPathComponent)")
            player = nil
            videoDurationMs = 0
            return
        }

        let newPlayer = AVPlayer(url: url)
        player = newPlayer

        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = newPlayer.addPeriodicTimeObserver(forInterval: interval, queue: .main) { time in
            currentVideoTimeMs = time.seconds * 1000
        }

        durationObserver = newPlayer.currentItem?.observe(\.duration, options: [.new]) { item, _ in
            if item.duration.isNumeric {
                DispatchQueue.main.async {
                    videoDurationMs = item.duration.seconds * 1000
                }
            }
        }

        if let duration = newPlayer.currentItem?.asset.duration, duration.isNumeric {
            videoDurationMs = duration.seconds * 1000
        }

        // Also observe for errors (e.g. truncated fMP4 that partially loads)
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemFailedToPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { notification in
            if let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error {
                print("[PipeKit] Video playback error (may be a recovered crash session): \(error.localizedDescription)")
            }
            isPlaying = false
        }

        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            isPlaying = false
        }
    }

    private func cleanupPlayer() {
        if let observer = timeObserver, let p = player {
            p.removeTimeObserver(observer)
        }
        durationObserver?.invalidate()
        durationObserver = nil
        player?.pause()
        player = nil
        timeObserver = nil
        currentVideoTimeMs = 0
        videoDurationMs = 0
        isPlaying = false
    }
}
