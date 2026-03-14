//
//  FlowRunnerView.swift
//  PipeKitDemo
//
//  Flow composition runner with step-by-step execution log.
//
//  Created by AlmoutasemNabil on 2026.
//  Copyright © 2026 AlmoutasemNabil. All rights reserved.
//

import SwiftUI
import PipeKitSDK

struct FlowRunnerView: View {
    @State private var selectedStudent: StudentItem?
    @State private var selectedCourse: CourseItem?
    @State private var runningFlowId: String?
    @State private var executionLog: [ExecutionStep] = []
    @State private var flowResult: FlowRunSummary?
    @State private var showResult = false

    struct ExecutionStep: Identifiable {
        let id = UUID()
        let nodeName: String
        let status: StepStatus
        let detail: String
        let timestamp: Date

        enum StepStatus {
            case running, success, failed
        }
    }

    struct FlowRunSummary {
        let flowName: String
        let success: Bool
        let duration: TimeInterval
        let steps: [ExecutionStep]
    }

    var body: some View {
        NavigationStack {
            List {
                // Param selectors
                Section {
                    Picker("Student", selection: $selectedStudent) {
                        Text("Select Student").tag(nil as StudentItem?)
                        ForEach(UniversityData.students) { s in
                            Text("\(s.name) (\(s.id))").tag(s as StudentItem?)
                        }
                    }

                    Picker("Course", selection: $selectedCourse) {
                        Text("Select Course").tag(nil as CourseItem?)
                        ForEach(UniversityData.courses) { c in
                            Text("\(c.id) — \(c.title)").tag(c as CourseItem?)
                        }
                    }
                } header: {
                    Text("Select Parameters")
                } footer: {
                    Text("Pick a student and/or course, then run a flow below. PipeKit auto-wires outputs between steps.")
                }

                // Flows
                Section("University Flows") {
                    flowButton(
                        name: "Course Enrollment",
                        icon: "pencil.and.list.clipboard",
                        description: "Lookup -> Check Prerequisites -> Enroll -> Notify",
                        nodes: ["lookupStudent", "lookupCourse", "checkPrerequisites", "enrollStudent", "sendNotification"],
                        requiredParams: [("studentId", selectedStudent?.id), ("courseId", selectedCourse?.id), ("message", "You have been enrolled!")]
                    )

                    flowButton(
                        name: "Transcript Request",
                        icon: "building.columns",
                        description: "Lookup -> Calculate GPA -> Generate -> Notify",
                        nodes: ["lookupStudent", "calculateGPA", "generateTranscript", "sendNotification"],
                        requiredParams: [("studentId", selectedStudent?.id), ("message", "Your transcript is ready.")]
                    )

                    flowButton(
                        name: "Student Profile",
                        icon: "graduationcap",
                        description: "Lookup Student -> Calculate GPA",
                        nodes: ["lookupStudent", "calculateGPA"],
                        requiredParams: [("studentId", selectedStudent?.id)]
                    )

                    flowButton(
                        name: "Course Info Check",
                        icon: "books.vertical",
                        description: "Lookup Course -> Lookup Professor",
                        nodes: ["lookupCourse", "lookupProfessor"],
                        requiredParams: [("courseId", selectedCourse?.id)]
                    )
                }

                // Execution log
                if !executionLog.isEmpty {
                    Section("Execution Log") {
                        ForEach(executionLog) { step in
                            HStack(spacing: 10) {
                                stepIcon(step.status)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(step.nodeName)
                                        .font(.subheadline.weight(.semibold))
                                    Text(step.detail)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(2)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .navigationTitle("PipeKit Flows")
            .sheet(isPresented: $showResult) {
                if let result = flowResult {
                    FlowResultSheet(result: result)
                }
            }
        }
    }

    @ViewBuilder
    private func stepIcon(_ status: ExecutionStep.StepStatus) -> some View {
        switch status {
        case .running:
            ProgressView()
                .scaleEffect(0.7)
                .frame(width: 20, height: 20)
        case .success:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .frame(width: 20, height: 20)
        case .failed:
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
                .frame(width: 20, height: 20)
        }
    }

    private func flowButton(name: String, icon: String, description: String, nodes: [String], requiredParams: [(String, String?)]) -> some View {
        let missingParams = requiredParams.filter { $0.1 == nil }.map { $0.0 }
        let disabled = !missingParams.isEmpty || runningFlowId != nil

        return Button {
            Task { await runFlow(name: name, nodes: nodes, params: requiredParams) }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(.indigo)
                    Text(name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                    Spacer()
                    if runningFlowId == name {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundColor(disabled ? .gray : .indigo)
                    }
                }
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)

                // Step pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(Array(nodes.enumerated()), id: \.offset) { idx, node in
                            if idx > 0 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 7))
                                    .foregroundColor(.secondary)
                            }
                            Text(FlowRegistry.shared.node(forId: node)?.displayName ?? node)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.indigo.opacity(0.1))
                                .foregroundColor(.indigo)
                                .cornerRadius(4)
                        }
                    }
                }

                if !missingParams.isEmpty {
                    Text("Needs: \(missingParams.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.orange)
                }
            }
            .padding(.vertical, 4)
        }
        .disabled(disabled)
    }

    private func runFlow(name: String, nodes: [String], params: [(String, String?)]) async {
        runningFlowId = name
        executionLog = []

        let flow = Flow(name)
        for nodeId in nodes {
            flow.pipe(nodeId)
        }

        let context = FlowContext()
        for (key, value) in params {
            if let v = value {
                context.set(key, value: v)
            }
        }

        let engine = FlowEngine(configuration: .debug)
        let startTime = Date()

        // Show each step as "running"
        for nodeId in nodes {
            let nodeName = FlowRegistry.shared.node(forId: nodeId)?.displayName ?? nodeId
            let step = ExecutionStep(nodeName: nodeName, status: .running, detail: "Executing...", timestamp: Date())
            executionLog.append(step)
        }

        do {
            let result = try await engine.run(flow, with: context)
            let duration = Date().timeIntervalSince(startTime)

            executionLog = result.completedNodes.enumerated().map { idx, nodeId in
                let nodeName = FlowRegistry.shared.node(forId: nodeId)?.displayName ?? nodeId
                let logEntry = idx < context.log.count ? context.log[idx].description : "Done"
                return ExecutionStep(nodeName: nodeName, status: .success, detail: logEntry, timestamp: Date())
            }

            for (nodeId, error) in result.failedNodes {
                let nodeName = FlowRegistry.shared.node(forId: nodeId)?.displayName ?? nodeId
                executionLog.append(ExecutionStep(nodeName: nodeName, status: .failed, detail: error, timestamp: Date()))
            }

            flowResult = FlowRunSummary(flowName: name, success: result.isSuccess, duration: duration, steps: executionLog)
            showResult = true
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            if let lastIdx = executionLog.lastIndex(where: { $0.status == .running }) {
                executionLog[lastIdx] = ExecutionStep(
                    nodeName: executionLog[lastIdx].nodeName,
                    status: .failed,
                    detail: error.localizedDescription,
                    timestamp: Date()
                )
            }
            flowResult = FlowRunSummary(flowName: name, success: false, duration: duration, steps: executionLog)
            showResult = true
        }

        runningFlowId = nil
    }
}

// MARK: - Flow Result Sheet

struct FlowResultSheet: View {
    let result: FlowRunnerView.FlowRunSummary
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: result.success ? "checkmark.seal.fill" : "xmark.seal.fill")
                            .font(.largeTitle)
                            .foregroundColor(result.success ? .green : .red)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.flowName)
                                .font(.headline)
                            Text(result.success ? "Completed successfully" : "Failed")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2fs", result.duration))
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Step-by-Step Execution") {
                    ForEach(Array(result.steps.enumerated()), id: \.offset) { idx, step in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(step.status == .success ? Color.green.opacity(0.15) : Color.red.opacity(0.15))
                                    .frame(width: 28, height: 28)
                                Text("\(idx + 1)")
                                    .font(.caption2.weight(.bold))
                                    .foregroundColor(step.status == .success ? .green : .red)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(step.nodeName)
                                    .font(.subheadline.weight(.semibold))
                                Text(step.detail)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }

                            Spacer()

                            Image(systemName: step.status == .success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(step.status == .success ? .green : .red)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("Execution Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
