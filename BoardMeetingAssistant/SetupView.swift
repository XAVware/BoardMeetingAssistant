//
//  SetupView.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 10/2/24.
//

import SwiftUI
import SwiftData

struct SetupView: View {
    var project: Project?
    @Environment(NavigationContext.self) var navigationContext
    @Environment(\.modelContext) private var modelContext
    @State private var selectedFilePath: String?
    @State private var showFileImporter: Bool = false
    @State var isLoading: Bool = false
    
    @State var newProjectName: String = ""
    @State var transcript: Transcript?
    
    private func setupFields() {
        self.newProjectName = project?.name ?? ""
        self.selectedFilePath = project?.audioFilePath ?? ""
        self.transcript = project?.transcript
    }
    
    private func save() {
        if let project {
            project.name = self.newProjectName
            project.audioFilePath = self.selectedFilePath
            project.transcript = self.transcript
            navigationContext.project = project
            do {
                try modelContext.save()
            } catch {
                print("Error saving")
            }
        }
    }
    
    private func transcribeTapped() {
        guard let selectedFilePath = selectedFilePath else { return }
        let documentsPath = Documents_Path
//        let scriptPath = documentsPath + "/transcribe.py"
        let projectPath = documentsPath + "/\(newProjectName)"
        let audioPath = String(selectedFilePath.dropFirst(7)) // Removes the 'file://' from the beginning of the path.
        
        try? FileManager.default.createDirectory(
            atPath: projectPath,
            withIntermediateDirectories: true
        )
        
        /// When the file is local remove preceding text otherwise URL audio wont play.
        if selectedFilePath.starts(with: "file://") {
            self.selectedFilePath = audioPath
        }
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: Python_Path)
        process.arguments = [
            documentsPath + "/transcribe.py",
            "identify",
            navigationContext.key,
            audioPath,
            projectPath
        ]
        
        self.isLoading.toggle()
        do {
            let pipe = Pipe()
            process.standardOutput = pipe
            try process.run()
            process.waitUntilExit()
            self.isLoading.toggle()
            debugPrint("Original transcript response")
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let encodedData = try? JSONSerialization.data(withJSONObject: jsonData) {
                
                try encodedData.write(to: URL(fileURLWithPath: projectPath + "/original.json"))
                
                let decoder = JSONDecoder()
//                let t = try decoder.decode(AAITranscript.self, from: encodedData)
                let t = try decoder.decode(PythonResponse.self, from: encodedData)
                print("Successfully decoded data --")
                print(t)
                if let project = self.project {
                    self.transcript = Transcript(audio_url: t.audio_url, utterances: t.utterances, sections: t.sections, project: project)
                }
                save()
            }
        } catch {
            print("Error: \(error)")
        }
    }
    
    var body: some View {
        @Bindable var navigationContext = navigationContext
        VStack {
            TextField("Project Name", text: $newProjectName, prompt: Text("Project Name"))
                .textFieldStyle(.plain)
            
                .modifier(OutlinedFieldMod(title: "Name"))
                .padding(.vertical, 8)
            
            HStack {
                Text(selectedFilePath?.split(separator: "/").last ?? "No file selected")
                    .font(.subheadline)
                    .opacity(selectedFilePath == nil ? 0.6 : 1.0)
                Spacer()
                Button("Choose File") {
                    showFileImporter = true
                }
                .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.audio, .mpeg4Movie, .mp3], allowsMultipleSelection: false) { result in
                    do {
                        let fileUrl = try result.get().first?.absoluteString
                        selectedFilePath = fileUrl
                    } catch {
                        print("Error selecting file: \(error)")
                    }
                }
                
            } //: HStack
            .modifier(OutlinedFieldMod(title: "Audio File"))
            .padding(.vertical, 8)
            .onAppear {
                setupFields()
            }
            .onChange(of: project) { oldValue, newValue in
                setupFields()
            }
            
            Button {
                transcribeTapped()
            } label: {
                Text("Transcribe")
            }
            .buttonStyle(BorderedProminentButtonStyle())
            
            if isLoading { ProgressView() }
            
            Spacer()
            
        } //: VStack
    } //: Body
    
    
}

//#Preview {
//    SetupView(project: Project(name: "Sample"))
//        .padding()
//        .frame(width: 420, height: 540)
//}
