//
//  DemoFlows.swift
//  PipeKitDemo
//
//  University Domain Example using PipeKit
//  Demonstrates a complete academic management system with student enrollment,
//  course management, and transcript generation.
//
//  Functions must be `static` because @Rewire registers them at type-load
//  time (before any instance exists). They're stateless pipeline nodes —
//  data flows through FlowContext, not through `self`.
//
//  Created by AlmoutasemNabil on 2026.
//  Copyright © 2026 AlmoutasemNabil. All rights reserved.
//

import Foundation
import PipeKitSDK

@FlowEntry
class DemoFlows {

    // MARK: - Mock Data Store

    private static let studentsDB: [String: [String: Any]] = [
        "STU001": [
            "id": "STU001",
            "name": "Emma Johnson",
            "email": "emma.johnson@university.edu",
            "gpa": 3.85,
            "major": "Computer Science",
            "enrolledCourses": ["CS101", "MATH201", "CS202"]
        ],
        "STU002": [
            "id": "STU002",
            "name": "Michael Chen",
            "email": "michael.chen@university.edu",
            "gpa": 3.62,
            "major": "Mathematics",
            "enrolledCourses": ["MATH201", "MATH301", "PHYS150"]
        ],
        "STU003": [
            "id": "STU003",
            "name": "Sarah Williams",
            "email": "sarah.williams@university.edu",
            "gpa": 3.92,
            "major": "Computer Science",
            "enrolledCourses": ["CS101", "CS202", "CS301"]
        ],
        "STU004": [
            "id": "STU004",
            "name": "David Martinez",
            "email": "david.martinez@university.edu",
            "gpa": 3.45,
            "major": "Physics",
            "enrolledCourses": ["PHYS150", "PHYS250"]
        ],
        "STU005": [
            "id": "STU005",
            "name": "Jessica Lee",
            "email": "jessica.lee@university.edu",
            "gpa": 3.78,
            "major": "Computer Science",
            "enrolledCourses": ["CS101", "CS202"]
        ]
    ]

    private static let professorsDB: [String: [String: Any]] = [
        "PROF001": [
            "id": "PROF001",
            "name": "Dr. Robert Anderson",
            "email": "r.anderson@university.edu",
            "department": "Computer Science",
            "courses": ["CS101", "CS202", "CS301"]
        ],
        "PROF002": [
            "id": "PROF002",
            "name": "Dr. Patricia Moore",
            "email": "p.moore@university.edu",
            "department": "Mathematics",
            "courses": ["MATH201", "MATH301"]
        ],
        "PROF003": [
            "id": "PROF003",
            "name": "Dr. James White",
            "email": "j.white@university.edu",
            "department": "Physics",
            "courses": ["PHYS150", "PHYS250"]
        ]
    ]

    private static let coursesDB: [String: [String: Any]] = [
        "CS101": [
            "id": "CS101",
            "title": "Intro to Programming",
            "department": "Computer Science",
            "credits": 3,
            "capacity": 40,
            "enrolled": 38,
            "professorId": "PROF001"
        ],
        "CS202": [
            "id": "CS202",
            "title": "Data Structures",
            "department": "Computer Science",
            "credits": 3,
            "capacity": 35,
            "enrolled": 32,
            "professorId": "PROF001"
        ],
        "CS301": [
            "id": "CS301",
            "title": "Algorithms",
            "department": "Computer Science",
            "credits": 4,
            "capacity": 30,
            "enrolled": 28,
            "professorId": "PROF001"
        ],
        "MATH201": [
            "id": "MATH201",
            "title": "Linear Algebra",
            "department": "Mathematics",
            "credits": 4,
            "capacity": 45,
            "enrolled": 42,
            "professorId": "PROF002"
        ],
        "MATH301": [
            "id": "MATH301",
            "title": "Calculus III",
            "department": "Mathematics",
            "credits": 4,
            "capacity": 40,
            "enrolled": 35,
            "professorId": "PROF002"
        ],
        "PHYS150": [
            "id": "PHYS150",
            "title": "Physics I",
            "department": "Physics",
            "credits": 4,
            "capacity": 50,
            "enrolled": 48,
            "professorId": "PROF003"
        ],
        "PHYS250": [
            "id": "PHYS250",
            "title": "Physics II",
            "department": "Physics",
            "credits": 4,
            "capacity": 35,
            "enrolled": 22,
            "professorId": "PROF003"
        ]
    ]

    // MARK: - University Operations

    @Rewire("Lookup Student")
    static func lookupStudent(studentId: String) async throws -> [String: Any] {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard let student = studentsDB[studentId] else {
            throw PipeKitError.custom("Student not found: \(studentId)")
        }
        return student
    }

    @Rewire("Lookup Professor")
    static func lookupProfessor(professorId: String) async throws -> [String: Any] {
        try await Task.sleep(nanoseconds: 250_000_000)
        guard let professor = professorsDB[professorId] else {
            throw PipeKitError.custom("Professor not found: \(professorId)")
        }
        return professor
    }

    @Rewire("Lookup Course")
    static func lookupCourse(courseId: String) async throws -> [String: Any] {
        try await Task.sleep(nanoseconds: 250_000_000)
        guard let course = coursesDB[courseId] else {
            throw PipeKitError.custom("Course not found: \(courseId)")
        }
        return course
    }

    @Rewire("Check Prerequisites")
    static func checkPrerequisites(studentId: String, courseId: String) async throws -> Bool {
        try await Task.sleep(nanoseconds: 200_000_000)
        guard let _ = studentsDB[studentId] else {
            throw PipeKitError.custom("Student not found: \(studentId)")
        }
        guard let _ = coursesDB[courseId] else {
            throw PipeKitError.custom("Course not found: \(courseId)")
        }
        if courseId == "CS301" {
            guard let student = studentsDB[studentId],
                  let enrolledCourses = student["enrolledCourses"] as? [String],
                  enrolledCourses.contains("CS202") else {
                return false
            }
        }
        if courseId == "MATH301" {
            guard let student = studentsDB[studentId],
                  let enrolledCourses = student["enrolledCourses"] as? [String],
                  enrolledCourses.contains("MATH201") else {
                return false
            }
        }
        return true
    }

    @Rewire("Enroll Student")
    static func enrollStudent(studentId: String, courseId: String) async throws -> [String: Any] {
        try await Task.sleep(nanoseconds: 400_000_000)
        guard let student = studentsDB[studentId] else {
            throw PipeKitError.custom("Student not found: \(studentId)")
        }
        guard let course = coursesDB[courseId] else {
            throw PipeKitError.custom("Course not found: \(courseId)")
        }
        if let enrolled = course["enrolled"] as? Int,
           let capacity = course["capacity"] as? Int,
           enrolled >= capacity {
            throw PipeKitError.custom("Course is at capacity")
        }
        if let enrolledCourses = student["enrolledCourses"] as? [String],
           enrolledCourses.contains(courseId) {
            throw PipeKitError.custom("Student already enrolled in this course")
        }
        let enrollmentId = "ENR-\(Int.random(in: 100000...999999))"
        let timestamp = ISO8601DateFormatter().string(from: Date())
        return [
            "enrollmentId": enrollmentId,
            "studentId": studentId,
            "courseId": courseId,
            "status": "enrolled",
            "timestamp": timestamp
        ]
    }

    @Rewire("Calculate GPA")
    static func calculateGPA(studentId: String) async throws -> Double {
        try await Task.sleep(nanoseconds: 350_000_000)
        guard let student = studentsDB[studentId] else {
            throw PipeKitError.custom("Student not found: \(studentId)")
        }
        guard let gpa = student["gpa"] as? Double else {
            throw PipeKitError.custom("GPA calculation failed")
        }
        return gpa
    }

    @Rewire("Send Notification")
    static func sendNotification(email: String, message: String) async throws -> String {
        try await Task.sleep(nanoseconds: 300_000_000)
        guard !email.isEmpty && email.contains("@") else {
            throw PipeKitError.custom("Invalid email address")
        }
        let notificationId = "NOT-\(Int.random(in: 100000...999999))"
        return "Notification sent to \(email): \(notificationId)"
    }

    @Rewire("Generate Transcript")
    static func generateTranscript(studentId: String) async throws -> [String: Any] {
        try await Task.sleep(nanoseconds: 600_000_000)
        guard let student = studentsDB[studentId] else {
            throw PipeKitError.custom("Student not found: \(studentId)")
        }
        guard let enrolledCourses = student["enrolledCourses"] as? [String],
              let gpa = student["gpa"] as? Double,
              let name = student["name"] as? String,
              let major = student["major"] as? String else {
            throw PipeKitError.custom("Invalid student data")
        }
        var courseRecords: [[String: Any]] = []
        for courseId in enrolledCourses {
            if let course = coursesDB[courseId] {
                let grade = ["A", "A-", "B+", "B", "B-"].randomElement() ?? "A"
                courseRecords.append([
                    "courseId": courseId,
                    "title": course["title"] ?? "",
                    "credits": course["credits"] ?? 0,
                    "grade": grade
                ])
            }
        }
        let transcriptId = "TRN-\(Int.random(in: 100000...999999))"
        let generatedDate = ISO8601DateFormatter().string(from: Date())
        return [
            "transcriptId": transcriptId,
            "studentId": studentId,
            "studentName": name,
            "major": major,
            "gpa": gpa,
            "courses": courseRecords,
            "generatedDate": generatedDate
        ]
    }

    @Rewire("Generate Transcript string")
    static func generateTranscriptWithGpa(studentId: String) async throws -> String{
        try await Task.sleep(nanoseconds: 600_000_000)
        guard let student = studentsDB[studentId] else {
            throw PipeKitError.custom("Student not found: \(studentId)")
        }
        guard let enrolledCourses = student["enrolledCourses"] as? [String],
              let gpa = student["gpa"] as? Double,
              let name = student["name"] as? String,
              let major = student["major"] as? String else {
            throw PipeKitError.custom("Invalid student data")
        }
        var courseRecords: [[String: Any]] = []
        for courseId in enrolledCourses {
            if let course = coursesDB[courseId] {
                let grade = ["A", "A-", "B+", "B", "B-"].randomElement() ?? "A"
                courseRecords.append([
                    "courseId": courseId,
                    "title": course["title"] ?? "",
                    "credits": course["credits"] ?? 0,
                    "grade": grade
                ])
            }
        }
        let transcriptId = "TRN-\(Int.random(in: 100000...999999))"
        let generatedDate = ISO8601DateFormatter().string(from: Date())
        return "\(gpa)"
    }
}
// MARK: - Alert Presenter

@MainActor
final class AlertPresenter: ObservableObject {
    static let shared = AlertPresenter()

    @Published var isPresented = false
    @Published var title = ""
    @Published var message = ""

    private init() {}

    func show(title: String, message: String) {
        self.title = title
        self.message = message
        self.isPresented = true
    }
}

