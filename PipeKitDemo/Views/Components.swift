//
//  Components.swift
//  PipeKitDemo
//
//  Shared UI components: ActionButton, LogButton, StatView, InfoRow, etc.
//
//  Created by AlmoutasemNabil on 2026.
//  Copyright © 2026 AlmoutasemNabil. All rights reserved.
//

import SwiftUI
import PipeKitSDK

// MARK: - ActionButton

struct ActionButton: View {
    let title: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            ActionButtonContent(title: title, icon: icon, color: color)
        }
        .redacted(reason: .privacy)
    }
}

// MARK: - ActionButtonContent

struct ActionButtonContent: View {
    let title: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon).font(.title2)
            Text(title).font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.15))
        .foregroundColor(color)
        .cornerRadius(12)
    }
}

// MARK: - LogButton

struct LogButton: View {
    let level: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(level).font(.caption).fontWeight(.medium).frame(maxWidth: .infinity)
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(color.opacity(0.15)).foregroundColor(color).cornerRadius(8)
        }
    }
}

// MARK: - StatView

struct StatView: View {
    let value: Int; let label: String; let icon: String
    var body: some View {
        VStack {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption)
                Text("\(value)").font(.title2).bold().monospacedDigit()
            }
            Text(label).font(.caption).foregroundColor(.secondary)
        }
    }
}

// MARK: - InfoRow

struct InfoRow: View {
    let label: String; let value: String
    var body: some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(value).fontWeight(.medium)
        }
        .font(.subheadline)
    }
}

// MARK: - SessionListItem

struct SessionListItem: View {
    let session: SessionReplayData
    let isSelected: Bool
    let isUploading: Bool
    let onUpload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.startTime.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    Text(String(format: "%.1fs", session.durationMs / 1000))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isUploading {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }

            HStack(spacing: 12) {
                Label("\(session.logs.count)", systemImage: "doc.text")
                Label("\(session.networkRequests.count)", systemImage: "network")
                Label("\(session.frameCount)", systemImage: "photo")
            }
            .font(.caption2)
            .foregroundColor(.secondary)

            Button(action: onUpload) {
                Label("Upload", systemImage: "icloud.and.arrow.up")
                    .font(.caption2)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .disabled(isUploading)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ActivityRowView

struct ActivityRowView: View {
    let entry: ActivityEntry

    var body: some View {
        switch entry {
        case .log(let log):
            HStack(alignment: .top, spacing: 8) {
                Text(logLevelIcon(log.level))
                    .font(.caption)
                VStack(alignment: .leading, spacing: 2) {
                    Text(log.message)
                        .font(.caption2)
                        .lineLimit(2)
                        .foregroundColor(logLevelColor(log.level))
                    Text(formatTimestamp(log.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 4)

        case .network(let req):
            HStack(alignment: .top, spacing: 8) {
                Text("🌐")
                    .font(.caption)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(req.method)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        if let status = req.statusCode {
                            Text("[\(status)]")
                                .font(.caption2)
                                .foregroundColor(status < 400 ? .green : .red)
                        }
                    }
                    Text(req.url)
                        .font(.caption2)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                    if let duration = req.duration {
                        Text("\(formatTimestamp(req.timestamp)) - \(String(format: "%.0fms", duration))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    private func formatTimestamp(_ ms: TimeInterval) -> String {
        String(format: "+%.2fs", ms / 1000)
    }

    private func logLevelIcon(_ level: LogLevel) -> String {
        switch level {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }

    private func logLevelColor(_ level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .primary
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - SyncedActivityRow

struct SyncedActivityRow: View {
    let entry: ActivityEntry
    let isActive: Bool
    let isPast: Bool
    var mappedVideoTime: TimeInterval? = nil

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack {
                Circle()
                    .fill(isActive ? Color.blue : (isPast ? Color.gray : Color.gray.opacity(0.3)))
                    .frame(width: 10, height: 10)
                if !isActive {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if let videoTime = mappedVideoTime {
                        Text(formatVideoTime(videoTime))
                            .font(.caption2)
                            .fontWeight(isActive ? .bold : .regular)
                            .foregroundColor(isActive ? .blue : .secondary)
                        Text("·")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Text(formatTimestamp(entry.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.7))
                }

                switch entry {
                case .log(let log):
                    HStack(spacing: 6) {
                        Text(logLevelIcon(log.level))
                            .font(.caption)
                        Text(log.message)
                            .font(.callout)
                            .lineLimit(isActive ? nil : 2)
                            .foregroundColor(isActive ? logLevelColor(log.level) : (isPast ? .secondary : .primary))
                    }

                case .network(let req):
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("🌐").font(.caption)
                            Text(req.method)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            if let status = req.statusCode {
                                Text("[\(status)]")
                                    .font(.caption)
                                    .foregroundColor(status < 400 ? .green : .red)
                            }
                            if let duration = req.duration {
                                Text(String(format: "%.0fms", duration))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text(req.url)
                            .font(.caption)
                            .lineLimit(isActive ? nil : 1)
                            .foregroundColor(isPast ? .secondary : .primary)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isActive ? Color.blue.opacity(0.1) : Color.clear)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }

    private func formatTimestamp(_ ms: TimeInterval) -> String {
        let totalSeconds = Int(ms / 1000)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        let millis = Int(ms) % 1000
        return String(format: "(%d:%02d.%03d)", minutes, seconds, millis)
    }

    private func formatVideoTime(_ ms: TimeInterval) -> String {
        let totalSeconds = Int(ms / 1000)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func logLevelIcon(_ level: LogLevel) -> String {
        switch level {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }

    private func logLevelColor(_ level: LogLevel) -> Color {
        switch level {
        case .debug: return .gray
        case .info: return .primary
        case .warning: return .orange
        case .error: return .red
        }
    }
}

// MARK: - SecondScreen

struct SecondScreen: View {
    @State private var counter = 0

    var body: some View {
        VStack(spacing: 24) {
            Text("Second Screen").font(.largeTitle).bold()
            Text("\(counter)").font(.system(size: 64, weight: .bold, design: .rounded))
            HStack(spacing: 16) {
                Button("-") { counter -= 1 }.buttonStyle(.bordered).font(.title)
                Button("+") { counter += 1 }.buttonStyle(.bordered).font(.title)
            }
        }
        .navigationTitle("Second Screen")
        .trackScreen("SecondScreen")
    }
}

// MARK: - InteractiveScreen

struct InteractiveScreen: View {
    @State private var sliderValue = 0.5
    @State private var toggleOn = false

    var body: some View {
        Form {
            Section("Slider") {
                Slider(value: $sliderValue)
                Text("Value: \(sliderValue, specifier: "%.2f")")
            }
            Section("Toggle") { Toggle("Feature", isOn: $toggleOn) }
            Section("Buttons") {
                Button("Action") { print("Tapped") }
                Button("Destructive", role: .destructive) { print("Destructive") }
            }
        }
        .navigationTitle("Interactive")
        .trackScreen("InteractiveScreen")
    }
}
