//
//  ContentView.swift
//  PipeKitDemo
//
//  Created by AlmoutasemNabil on 2026.
//  Copyright © 2026 AlmoutasemNabil. All rights reserved.
//

import SwiftUI
import AVKit
import PipeKitSDK

// MARK: - Shared Data

struct StudentItem: Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
    let gpa: Double
    let major: String
    let courses: [String]
}

struct CourseItem: Identifiable, Hashable {
    let id: String
    let title: String
    let department: String
    let credits: Int
    let capacity: Int
    let enrolled: Int
    let professorId: String
}

struct ProfessorItem: Identifiable, Hashable {
    let id: String
    let name: String
    let email: String
    let department: String
    let courses: [String]
}

// Mirror the mock data from DemoFlows so the UI can display it
enum UniversityData {
    static let students: [StudentItem] = [
        StudentItem(id: "STU001", name: "Emma Johnson", email: "emma.johnson@university.edu", gpa: 3.85, major: "Computer Science", courses: ["CS101", "MATH201", "CS202"]),
        StudentItem(id: "STU002", name: "Michael Chen", email: "michael.chen@university.edu", gpa: 3.62, major: "Mathematics", courses: ["MATH201", "MATH301", "PHYS150"]),
        StudentItem(id: "STU003", name: "Sarah Williams", email: "sarah.williams@university.edu", gpa: 3.92, major: "Computer Science", courses: ["CS101", "CS202", "CS301"]),
        StudentItem(id: "STU004", name: "David Martinez", email: "david.martinez@university.edu", gpa: 3.45, major: "Physics", courses: ["PHYS150", "PHYS250"]),
        StudentItem(id: "STU005", name: "Jessica Lee", email: "jessica.lee@university.edu", gpa: 3.78, major: "Computer Science", courses: ["CS101", "CS202"]),
    ]

    static let courses: [CourseItem] = [
        CourseItem(id: "CS101", title: "Intro to Programming", department: "Computer Science", credits: 3, capacity: 40, enrolled: 38, professorId: "PROF001"),
        CourseItem(id: "CS202", title: "Data Structures", department: "Computer Science", credits: 3, capacity: 35, enrolled: 32, professorId: "PROF001"),
        CourseItem(id: "CS301", title: "Algorithms", department: "Computer Science", credits: 4, capacity: 30, enrolled: 28, professorId: "PROF001"),
        CourseItem(id: "MATH201", title: "Linear Algebra", department: "Mathematics", credits: 4, capacity: 45, enrolled: 42, professorId: "PROF002"),
        CourseItem(id: "MATH301", title: "Calculus III", department: "Mathematics", credits: 4, capacity: 40, enrolled: 35, professorId: "PROF002"),
        CourseItem(id: "PHYS150", title: "Physics I", department: "Physics", credits: 4, capacity: 50, enrolled: 48, professorId: "PROF003"),
        CourseItem(id: "PHYS250", title: "Physics II", department: "Physics", credits: 4, capacity: 35, enrolled: 22, professorId: "PROF003"),
    ]

    static let professors: [ProfessorItem] = [
        ProfessorItem(id: "PROF001", name: "Dr. Robert Anderson", email: "r.anderson@university.edu", department: "Computer Science", courses: ["CS101", "CS202", "CS301"]),
        ProfessorItem(id: "PROF002", name: "Dr. Patricia Moore", email: "p.moore@university.edu", department: "Mathematics", courses: ["MATH201", "MATH301"]),
        ProfessorItem(id: "PROF003", name: "Dr. James White", email: "j.white@university.edu", department: "Physics", courses: ["PHYS150", "PHYS250"]),
    ]
}

// MARK: - Activity Entry (shared between session replay views)

enum ActivityEntry: Identifiable {
    case log(LogEntry)
    case network(NetworkEntry)

    var id: String {
        switch self {
        case .log(let entry): return "log-\(entry.timestamp)"
        case .network(let entry): return "net-\(entry.id)"
        }
    }

    var timestamp: TimeInterval {
        switch self {
        case .log(let entry): return entry.timestamp
        case .network(let entry): return entry.timestamp
        }
    }
}

// MARK: - Root View

@FlowEntry
struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var alertPresenter = AlertPresenter.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            // Session Replay tabs
            RecordingTab()
                .tabItem {
                    Label("Record", systemImage: "record.circle")
                }
                .tag(0)

            UnifiedSessionsView()
                .tabItem {
                    Label("Sessions", systemImage: "play.rectangle.on.rectangle")
                }
                .tag(1)

            // Flow Composition tabs
            FlowRunnerView()
                .tabItem {
                    Label("Flows", systemImage: "arrow.triangle.branch")
                }
                .tag(2)

            DataBrowserView()
                .tabItem {
                    Label("Data", systemImage: "person.3.fill")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
        .tint(.indigo)
        .alert(alertPresenter.title, isPresented: $alertPresenter.isPresented) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertPresenter.message)
        }
    }

    @Rewire("Present Alert")
    static func presentAlert(title: String, message: String) async throws -> [String: Any] {
        await MainActor.run {
            AlertPresenter.shared.show(title: title, message: message)
            PipeKit.log("presented an alert")
        }
        return [
            "title": title,
            "message": message,
            "presented": true
        ]
    }
}

#Preview { ContentView() }
