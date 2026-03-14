//
//  SyncedPlayerView.swift
//  PipeKitDemo
//
//  Synchronized video player with activity timeline.
//
//  Created by AlmoutasemNabil on 2026.
//  Copyright © 2026 AlmoutasemNabil. All rights reserved.
//

import SwiftUI
import PipeKitSDK
import AVKit

struct SyncedPlayerView: View {
    let session: SessionReplayData
    @Binding var player: AVPlayer?
    @Binding var currentVideoTimeMs: TimeInterval
    @Binding var videoDurationMs: TimeInterval
    @Binding var isPlaying: Bool

    var allActivity: [ActivityEntry] {
        var entries: [ActivityEntry] = []
        let filteredLogs = session.logs.filter { log in
            !log.message.contains("[PipeKit] Touch")
        }
        entries.append(contentsOf: filteredLogs.map { .log($0) })
        entries.append(contentsOf: session.networkRequests.map { .network($0) })
        return entries.sorted { $0.timestamp < $1.timestamp }
    }

    var sessionDurationMs: TimeInterval {
        let maxLogTime = session.logs.map(\.timestamp).max() ?? 0
        let maxNetworkTime = session.networkRequests.map(\.timestamp).max() ?? 0
        let maxActivityTime = max(maxLogTime, maxNetworkTime)
        return max(session.durationMs, maxActivityTime)
    }

    var timeScaleRatio: Double {
        guard sessionDurationMs > 0, videoDurationMs > 0 else { return 1.0 }
        return videoDurationMs / sessionDurationMs
    }

    func sessionToVideoTime(_ sessionTimeMs: TimeInterval) -> TimeInterval {
        return sessionTimeMs * timeScaleRatio
    }

    func videoToSessionTime(_ videoTimeMs: TimeInterval) -> TimeInterval {
        guard timeScaleRatio > 0 else { return videoTimeMs }
        return videoTimeMs / timeScaleRatio
    }

    var currentSessionTimeMs: TimeInterval {
        return videoToSessionTime(currentVideoTimeMs)
    }

    var currentActivityIndex: Int? {
        guard !allActivity.isEmpty else { return nil }
        var lastIndex: Int? = nil
        for (index, entry) in allActivity.enumerated() {
            if entry.timestamp <= currentSessionTimeMs {
                lastIndex = index
            } else {
                break
            }
        }
        return lastIndex
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            if isLandscape {
                HStack(spacing: 0) {
                    videoPlayerSection
                        .frame(width: geometry.size.width * 0.5)
                    Divider()
                    activityTimelineSection
                        .frame(width: geometry.size.width * 0.5)
                }
            } else {
                VStack(spacing: 0) {
                    videoPlayerSection
                        .frame(height: geometry.size.height * 0.4)
                    Divider()
                    activityTimelineSection
                }
            }
        }
    }

    private var videoPlayerSection: some View {
        VStack(spacing: 8) {
            if let p = player {
                VideoPlayer(player: p)
                    .cornerRadius(12)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.1))
                    .overlay(
                        VStack {
                            Image(systemName: "video.slash")
                                .font(.largeTitle)
                            Text("No video")
                                .foregroundColor(.secondary)
                        }
                    )
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
            }

            HStack(spacing: 20) {
                Text(formatTime(currentVideoTimeMs))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: { seek(by: -5) }) {
                    Image(systemName: "gobackward.5")
                        .font(.title3)
                }

                Button(action: togglePlayback) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.title2)
                }
                .frame(width: 44, height: 44)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())

                Button(action: { seek(by: 5) }) {
                    Image(systemName: "goforward.5")
                        .font(.title3)
                }

                Spacer()

                Text(formatTime(videoDurationMs))
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            if videoDurationMs > 0 && abs(videoDurationMs - sessionDurationMs) > 1000 {
                Text("Video: \(formatTime(videoDurationMs)) | Session: \(formatTime(sessionDurationMs)) | Scale: \(String(format: "%.2fx", timeScaleRatio))")
                    .font(.caption2)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
            }
        }
    }

    private var activityTimelineSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Activity Timeline")
                    .font(.headline)
                Spacer()
                Text("\(allActivity.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))

            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Session time: \(formatTime(currentSessionTimeMs))")
                    .font(.caption2)
                Spacer()
            }
            .foregroundColor(.blue)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(allActivity.enumerated()), id: \.element.id) { index, entry in
                            SyncedActivityRow(
                                entry: entry,
                                isActive: index == currentActivityIndex,
                                isPast: currentActivityIndex != nil && index < currentActivityIndex!,
                                mappedVideoTime: sessionToVideoTime(entry.timestamp)
                            )
                            .id(entry.id)
                            .onTapGesture {
                                seekToActivity(entry)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                .onChange(of: currentActivityIndex) { newIndex in
                    if let index = newIndex, index < allActivity.count {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(allActivity[index].id, anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func togglePlayback() {
        if isPlaying { player?.pause() } else { player?.play() }
        isPlaying.toggle()
    }

    private func seek(by seconds: Double) {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: seconds, preferredTimescale: 1))
        player.seek(to: newTime)
    }

    private func seekToActivity(_ entry: ActivityEntry) {
        guard let player = player else { return }
        let videoTimeMs = sessionToVideoTime(entry.timestamp)
        let seconds = videoTimeMs / 1000
        player.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000))
    }

    private func formatTime(_ ms: TimeInterval) -> String {
        let totalSeconds = Int(ms / 1000)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
