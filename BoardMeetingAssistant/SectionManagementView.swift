//
//  SectionManagementView.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 12/7/24.
//

import SwiftUI
import SwiftData
struct SectionManagementView: View {
    var project: Project?
    @Environment(\.modelContext) private var modelContext
    @State private var sections: [String: AAISection] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Analyzing sections...")
            } else if sections.isEmpty {
                Text("No sections identified")
                    .foregroundColor(.secondary)
            } else {
                List(sections.values.sorted(by: { $0.start < $1.start }), id: \.id) { section in
                    SectionRow(section: section)
                }
                
                Button("Transcribe Sections") {
                    transcribeSections()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear {
            identifySections()
        }
        .alert("Error", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Text(errorMessage ?? "Unknown error")
            Button("OK", role: .cancel) {}
        }
    }
    
    private func identifySections() {
        guard let project = project,
              let audioPath = project.audioFilePath else {
            errorMessage = "No audio file found"
            return
        }
        
        isLoading = true
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Python_Path)
        process.arguments = [
            "\(Documents_Path)/transcribe.py",
            "identify",
            AssemblyAI_APIKey,
            audioPath
        ]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8),
               let jsonData = output.data(using: .utf8) {
                let response = try JSONDecoder().decode(PythonResponse.self, from: jsonData)
                
                // Convert the Python response sections to our Section type
//                sections = response.sections.mapValues { sectionData in
//                    Section(
//                        name: sectionData.name,
//                        start: sectionData.start
////                        end: sectionData.end
//                    )
//                }
            }
        } catch {
            errorMessage = "Decoding error: \(error.localizedDescription)"
            print("Full error: \(error)")
        }
        
        isLoading = false
    }
    
//    private func identifySections() {
//        guard let project = project,
//              let audioPath = project.audioFilePath else {
//            errorMessage = "No audio file found"
//            return
//        }
//        
//        isLoading = true
//        
//        let process = Process()
//        process.executableURL = URL(fileURLWithPath: Python_Path)
//        process.arguments = [
//            "\(Documents_Path)/transcribe.py",
//            "identify",
//            AssemblyAI_APIKey,
//            audioPath
//        ]
//        
//        let pipe = Pipe()
//        process.standardOutput = pipe
//        process.standardError = pipe
//        
//        do {
//            try process.run()
//            process.waitUntilExit()
//            
//            let data = pipe.fileHandleForReading.readDataToEndOfFile()
//            if let output = String(data: data, encoding: .utf8),
//               let jsonData = output.data(using: .utf8) {
//                let response = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
//                if let sectionsData = response?["sections"] as? [String: [String: Any]] {
//                    sections = sectionsData.mapValues { sectionData in
//                        Section(
//                            name: sectionData["name"] as? String ?? "",
//                            start: sectionData["start"] as? Int ?? 0,
//                            end: sectionData["end"] as? Int ?? 0
//                        )
//                    }
//                }
//            }
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//        
//        isLoading = false
//    }
    
    private func transcribeSections() {
        // To be implemented
    }
}

struct SectionRow: View {
    let section: AAISection
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(section.name)
                .font(.headline)
            
            HStack {
                Text("Start: \(TimeInterval(section.start / 1000).formatTranscriptTime())")
                Spacer()
//                Text("End: \(TimeInterval(section.end / 1000).formatTranscriptTime())")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

