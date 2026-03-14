//
//  DataBrowserView.swift
//  PipeKitDemo
//
//  Combined Students + Courses browser.
//
//  Created by AlmoutasemNabil on 2026.
//  Copyright © 2026 AlmoutasemNabil. All rights reserved.
//

import SwiftUI
import PipeKitSDK

// MARK: - Data Browser (Students + Courses)

struct DataBrowserView: View {
    @State private var selectedSegment = 0

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View", selection: $selectedSegment) {
                    Text("Students").tag(0)
                    Text("Courses").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                if selectedSegment == 0 {
                    StudentListView()
                } else {
                    CourseListView()
                }
            }
            .navigationTitle("University Data")
        }
    }
}

// MARK: - Student List View

struct StudentListView: View {
    @State private var selectedStudent: StudentItem?

    var body: some View {
        List {
            ForEach(UniversityData.students) { student in
                Button {
                    selectedStudent = student
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.indigo.opacity(0.15))
                                .frame(width: 44, height: 44)
                            Text(String(student.name.prefix(1)))
                                .font(.headline)
                                .foregroundColor(.indigo)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(student.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                            Text("\(student.id) — \(student.major)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            HStack(spacing: 4) {
                                ForEach(student.courses, id: \.self) { course in
                                    Text(course)
                                        .font(.system(size: 9, weight: .medium))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(3)
                                }
                            }
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "%.2f", student.gpa))
                                .font(.subheadline.weight(.bold).monospaced())
                                .foregroundColor(student.gpa >= 3.7 ? .green : student.gpa >= 3.0 ? .orange : .red)
                            Text("GPA")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .sheet(item: $selectedStudent) { student in
            StudentDetailSheet(student: student)
        }
    }
}

// MARK: - Student Detail Sheet

struct StudentDetailSheet: View {
    let student: StudentItem
    @Environment(\.dismiss) private var dismiss
    @State private var isRunning = false
    @State private var transcript: [String: Any]?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.indigo.opacity(0.15))
                                .frame(width: 56, height: 56)
                            Text(String(student.name.prefix(1)))
                                .font(.title2.weight(.semibold))
                                .foregroundColor(.indigo)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(student.name).font(.headline)
                            Text(student.email).font(.caption).foregroundColor(.secondary)
                            Text("\(student.major) — GPA: \(String(format: "%.2f", student.gpa))")
                                .font(.caption).foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Enrolled Courses") {
                    ForEach(student.courses, id: \.self) { courseId in
                        if let course = UniversityData.courses.first(where: { $0.id == courseId }) {
                            HStack {
                                Image(systemName: "books.vertical")
                                    .foregroundColor(.indigo)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(course.id) — \(course.title)")
                                        .font(.subheadline)
                                    Text("\(course.credits) credits — \(course.department)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text(courseId).font(.subheadline)
                        }
                    }
                }

                Section {
                    Button {
                        Task { await generateTranscript() }
                    } label: {
                        HStack {
                            Spacer()
                            if isRunning {
                                ProgressView().padding(.trailing, 8)
                            }
                            Text(isRunning ? "Generating..." : "Generate Transcript")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                        }
                    }
                    .disabled(isRunning)
                }

                if let t = transcript {
                    Section("Transcript") {
                        if let tid = t["transcriptId"] as? String {
                            HStack {
                                Text("ID").font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Text(tid).font(.caption.monospaced())
                            }
                        }
                        if let gpa = t["gpa"] as? Double {
                            HStack {
                                Text("GPA").font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.2f", gpa)).font(.caption.weight(.bold))
                            }
                        }
                        if let courses = t["courses"] as? [[String: Any]] {
                            ForEach(Array(courses.enumerated()), id: \.offset) { _, record in
                                HStack {
                                    Text("\(record["courseId"] as? String ?? "") — \(record["title"] as? String ?? "")")
                                        .font(.caption)
                                    Spacer()
                                    Text(record["grade"] as? String ?? "")
                                        .font(.caption.weight(.bold))
                                        .foregroundColor(.indigo)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(student.id)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func generateTranscript() async {
        isRunning = true
        let flow = Flow("Quick Transcript") {
            Pipe("lookupStudent")
            Pipe("generateTranscript")
        }
        let context = FlowContext()
        context.set("studentId", value: student.id)

        let engine = FlowEngine(configuration: .debug)
        do {
            _ = try await engine.run(flow, with: context)
            if let output = context.get("_output_generateTranscript", as: [String: Any].self) {
                transcript = output
            }
        } catch {
            print("Transcript error: \(error)")
        }
        isRunning = false
    }
}

// MARK: - Course List View

struct CourseListView: View {
    var body: some View {
        List {
            let departments = Set(UniversityData.courses.map(\.department))
            ForEach(departments.sorted(), id: \.self) { dept in
                Section(dept) {
                    ForEach(UniversityData.courses.filter({ $0.department == dept })) { course in
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                HStack {
                                    Text(course.id)
                                        .font(.subheadline.weight(.bold).monospaced())
                                        .foregroundColor(.indigo)
                                    Text(course.title)
                                        .font(.subheadline)
                                }
                                HStack(spacing: 12) {
                                    Label("\(course.credits) cr", systemImage: "clock")
                                    Label("\(course.enrolled)/\(course.capacity)", systemImage: "person.2")

                                    if let prof = UniversityData.professors.first(where: { $0.id == course.professorId }) {
                                        Label(prof.name, systemImage: "person.crop.circle")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }

                            Spacer()

                            let pct = Double(course.enrolled) / Double(course.capacity)
                            CircularProgress(value: pct)
                                .frame(width: 32, height: 32)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
}

// MARK: - Circular Progress Indicator

struct CircularProgress: View {
    let value: Double

    var color: Color {
        value > 0.9 ? .red : value > 0.7 ? .orange : .green
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 3)
            Circle()
                .trim(from: 0, to: value)
                .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(value * 100))")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(color)
        }
    }
}
