# PipeKit Demo

> A fully-featured demo app showcasing the [PipeKit iOS SDK](https://pipekit.tech) — session replay, remote feature flags, and server-driven flow composition in a single integration.

![Platform](https://img.shields.io/badge/platform-iOS%2016%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SDK](https://img.shields.io/badge/PipeKit%20SDK-0.4.0-indigo)
![License](https://img.shields.io/badge/license-MIT-green)

---

## What's Inside

This demo app simulates a **university management system** to demonstrate every major PipeKit capability in a real-world context:

| Tab | What It Shows |
|-----|--------------|
| **Record** | Start/stop session recording, trigger test events (network, logs, errors, crashes), view frame & touch stats in real time |
| **Sessions** | Browse saved session replays with synchronized video playback + activity timeline (logs, network requests) |
| **Flows** | Compose and execute server-driven pipelines — enroll students, generate transcripts, check prerequisites — all wired at runtime |
| **Data** | Browse students and courses, generate transcripts via flow execution, view enrollment capacity |
| **Settings** | SDK diagnostics, live feature flag values, registered `@Rewire` nodes, session stats |

---

## SDK Features Demonstrated

### Session Replay
Record everything happening in your app — screen video, touch events, network traffic, and console logs — then play it back with a synchronized timeline.

```swift
PipeKit.startSession()
PipeKit.stopSession()
PipeKit.identifyUser(userId: "user-123")
```

**View modifiers:**
```swift
.trackScreen("HomeScreen")    // Track screen views
.sensitiveContent()            // Redact sensitive UI from recordings
```

### Remote Feature Flags (`@PipeFlag`)
Declare feature flags as Swift properties. Values sync from the PipeKit dashboard — no app update required.

```swift
@PipeFlag var showOnboarding: Bool = true
@PipeFlag var enableBetaFeatures: Bool = false
@PipeFlag var maxRetries: Int = 3
```

### Dynamic Flow Composition (`@Rewire` + `Pipe`)
Register Swift functions as composable nodes. Chain them into server-driven pipelines that can be rewired remotely without shipping a new build.

**Register a node:**
```swift
@Rewire("Enroll Student")
static func enrollStudent(studentId: String, courseId: String) async throws -> [String: Any] {
    // enrollment logic
}
```

**Compose and run a flow:**
```swift
let result = try await FlowEngine.shared.execute(
    Flow("Course Enrollment") {
        Pipe("Lookup Student")
        Pipe("Lookup Course")
        Pipe("Check Prerequisites")
        Pipe("Enroll Student")
        Pipe("Send Notification")
    },
    context: context
)
```

### Auto-Discovery (`@FlowEntry`)
Mark any SwiftUI view with `@FlowEntry` — the SDK discovers and catalogs it at launch. No manual registration.

```swift
@FlowEntry
struct ContentView: View { ... }
```

---

## Getting Started

### Prerequisites
- Xcode 15+
- iOS 16+ simulator or device
- macOS 14+

### Setup

1. **Clone the repo:**
   ```bash
   git clone https://github.com/nicenabil/PipeKitDemo.git
   cd PipeKitDemo
   ```

2. **Copy the macro binary:**
   The demo uses Swift macros (`@Rewire`, `@FlowEntry`, `@PipeFlag`). You need the pre-built macro plugin:
   ```bash
   mkdir -p Macros
   # Copy PipeKitMacros binary from PipeKitSDK dist
   cp /path/to/PipeKitSDK/dist/Macros/PipeKitMacros Macros/
   ```

3. **Open in Xcode:**
   ```bash
   open PipeKitDemo.xcodeproj
   ```

4. **Select an iOS simulator** and hit **Run** (Cmd+R).

> **Note:** This is an iOS SDK. Run on an iPhone/iPad simulator or device — not a native macOS target.

### Configuration

The demo is pre-configured in `PipeKitDemoApp.swift`:

```swift
PipeKit.configure(
    apiKey: "your-api-key",
    baseURL: "https://pipekit.tech",
    config: PipeKitConfig(
        enableSessionReplay: true,
        enableFlows: true,
        captureNetwork: true,
        captureConsoleLogs: true
    )
)
```

Get your API key at [pipekit.tech](https://pipekit.tech).

---

## Project Structure

```
PipeKitDemo/
├── PipeKitDemoApp.swift          # App entry point + SDK configuration
├── ContentView.swift             # Root TabView + shared data models
├── Views/
│   ├── RecordingTab.swift        # Session recording controls + test actions
│   ├── UnifiedSessionsView.swift # Session browser + video playback
│   ├── SyncedPlayerView.swift    # Video player with synced activity timeline
│   ├── FlowRunnerView.swift      # Flow composition runner
│   ├── DataBrowserView.swift     # Student & course data browser
│   ├── SettingsView.swift        # SDK diagnostics + feature flags
│   └── Components.swift          # Shared UI components
├── Flows/
│   └── DemoFlows.swift           # @Rewire node definitions (university domain)
├── Package.swift                 # SPM dependency on PipeKitSDK
└── PipeKitDemo.xcodeproj/        # Xcode project
```

---

## Registered Flow Nodes

The demo registers 10 `@Rewire` nodes simulating a university system:

| Node | Signature |
|------|-----------|
| Lookup Student | `(studentId: String) -> [String: Any]` |
| Lookup Professor | `(professorId: String) -> [String: Any]` |
| Lookup Course | `(courseId: String) -> [String: Any]` |
| Check Prerequisites | `(studentId: String, courseId: String) -> Bool` |
| Enroll Student | `(studentId: String, courseId: String) -> [String: Any]` |
| Calculate GPA | `(studentId: String) -> Double` |
| Send Notification | `(email: String, message: String) -> String` |
| Generate Transcript | `(studentId: String) -> [String: Any]` |
| Generate Transcript (String) | `(studentId: String) -> String` |
| Present Alert | `(titlex: String, message: String) -> [String: Any]` |

---

## Pre-Built Flows

| Flow | Pipeline | Description |
|------|----------|-------------|
| **Course Enrollment** | Lookup Student → Lookup Course → Check Prerequisites → Enroll Student → Send Notification | Full enrollment with validation |
| **Transcript Request** | Lookup Student → Calculate GPA → Generate Transcript → Send Notification | GPA calculation + transcript delivery |
| **Student Profile** | Lookup Student → Calculate GPA | Quick student overview |
| **Course Info Check** | Lookup Course → Lookup Professor | Course details with professor info |

---

## Tech Stack

- **Swift 5.9** with Swift Macros (swift-syntax 509+)
- **SwiftUI** — declarative UI with NavigationStack, TabView, sheets
- **AVKit** — session replay video playback
- **Combine** — reactive state management
- **PipeKit SDK 0.4.0** — session replay, feature flags, flow engine

---

## Learn More

- [PipeKit Website](https://pipekit.tech)
- [PipeKit SDK Documentation](https://pipekit.tech/docs)

---

**Built with [PipeKit](https://pipekit.tech)**
