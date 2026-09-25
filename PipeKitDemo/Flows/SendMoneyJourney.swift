//
//  SendMoneyJourney.swift
//  PipeKitDemo
//
//  A journey the dashboard can arrange: the three screens are compiled into
//  the app, and the dashboard picks which of them `send-money` shows and in
//  what order. The fallback is amount → confirm; publishing
//  amount → otp → confirm puts the one-time-code step in front of confirm.
//
//  Created by AlmoutasemNabil on 2026.
//  Copyright © 2026 AlmoutasemNabil. All rights reserved.
//

import SwiftUI
import PipeKitSDK

// MARK: - Screens

@FlowEntry
enum SendMoneyScreens {
    // Required: Confirm needs the amount, so no published order may drop it.
    @PipeScreen("amount", name: "Amount", required: true)
    static func amount() -> some View { AmountScreen() }

    @PipeScreen("otp", name: "One-time code")
    static func otp() -> some View { OneTimeCodeScreen() }

    @PipeScreen("confirm", name: "Confirm", required: true)
    static func confirm() -> some View { ConfirmScreen() }
}

// MARK: - Launcher

/// Row in the Flows tab that opens the journey in a sheet.
struct SendMoneyLauncher: View {
    @State private var isSending = false
    @State private var lastResult: String?

    var body: some View {
        Button {
            isSending = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(.indigo)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Send money").font(.headline)
                    Text(lastResult ?? orderSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityIdentifier("journey.send-money.open")
        .sheet(isPresented: $isSending) {
            PipeJourney("send-money", fallback: ["amount", "confirm"])
                .onJourneyComplete { context in
                    let amount = context.get("amount", as: Double.self) ?? 0
                    lastResult = "Sent \(amount.formatted(.currency(code: "USD")))"
                    isSending = false
                }
                .onJourneyCancel { _ in
                    lastResult = "Cancelled"
                    isSending = false
                }
        }
    }

    /// The order the next run will show.
    private var orderSummary: String {
        PipeKit.resolveJourney("send-money", fallback: ["amount", "confirm"])
            .screenIds.joined(separator: " → ")
    }
}

// MARK: - Amount

private struct AmountScreen: View {
    @Environment(\.pipeJourney) private var journey
    @State private var amount: Double = 250

    var body: some View {
        Form {
            Section {
                Text(amount, format: .currency(code: "USD"))
                    .font(.system(size: 44, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("journey.amount.value")
                Stepper("Amount", value: $amount, in: 10...5000, step: 10)
            } footer: {
                Text("To Sara Haddad · Arab Bank ••42")
            }
        }
        .navigationTitle("Amount")
        .journeyCancelButton()
        .safeAreaInset(edge: .bottom) {
            JourneyButton("Continue", id: "journey.amount.continue") {
                journey?.context.set("amount", value: amount)
                journey?.next()
            }
        }
    }
}

// MARK: - One-time code

private struct OneTimeCodeScreen: View {
    @Environment(\.pipeJourney) private var journey
    @State private var code = ""

    var body: some View {
        Form {
            Section {
                TextField("6-digit code", text: $code)
                    .keyboardType(.numberPad)
                    .font(.system(.title2, design: .monospaced))
                    .accessibilityIdentifier("journey.otp.code")
            } footer: {
                Text("We sent a code to •••• 0192. Any 6 digits work in the demo.")
            }
        }
        .navigationTitle("Verify")
        .journeyCancelButton()
        .safeAreaInset(edge: .bottom) {
            JourneyButton("Verify", id: "journey.otp.verify") {
                journey?.context.set("otpVerified", value: true)
                journey?.next()
            }
            .disabled(code.count != 6)
        }
    }
}

// MARK: - Confirm

private struct ConfirmScreen: View {
    @Environment(\.pipeJourney) private var journey

    var body: some View {
        Form {
            Section("Transfer") {
                LabeledContent("To", value: "Sara Haddad")
                LabeledContent("Amount", value: amount, format: .currency(code: "USD"))
                LabeledContent("Verified", value: verified ? "One-time code" : "—")
            }
            Section("This run") {
                LabeledContent("Order", value: journey?.navigator.screenIds.joined(separator: " → ") ?? "—")
                LabeledContent("Source", value: journey?.navigator.resolution.source.rawValue ?? "—")
            }
        }
        .navigationTitle("Confirm")
        .journeyCancelButton()
        .safeAreaInset(edge: .bottom) {
            JourneyButton("Send", id: "journey.confirm.send") {
                journey?.next()
            }
        }
    }

    private var amount: Double {
        journey?.context.get("amount", as: Double.self) ?? 0
    }

    private var verified: Bool {
        journey?.context.get("otpVerified", as: Bool.self) ?? false
    }
}

// MARK: - Shared

private extension View {
    /// The dashboard decides which screen comes first, so every screen
    /// offers a way out, not just the one that is first in code.
    func journeyCancelButton() -> some View {
        modifier(JourneyCancelButton())
    }
}

private struct JourneyCancelButton: ViewModifier {
    @Environment(\.pipeJourney) private var journey

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { journey?.cancel() }
            }
        }
    }
}

private struct JourneyButton: View {
    let title: String
    let id: String
    let action: () -> Void

    init(_ title: String, id: String, action: @escaping () -> Void) {
        self.title = title
        self.id = id
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .padding()
        .background(.bar)
        .accessibilityIdentifier(id)
    }
}
