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
    let boostedWords = ["LMCC", "Lake Mohawk", "Country Club", "Sparta", "Township"]
    
    struct ProcessError: Error {
        enum Kind {
            case processError
            case outputError
        }
        let kind: Kind
        let underlying: Error
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
            .onAppear(perform: setupFields)
            .onChange(of: project) { oldValue, newValue in
                setupFields()
            }
            
            Button("Transcribe") {
                Task {
                    await transcribeTapped()
                }
            }
            .buttonStyle(BorderedProminentButtonStyle())
            
            if isLoading { ProgressView() }
            
            Spacer()
        } //: VStack
    } //: Body
    
    private func setupFields() {
        self.newProjectName = project?.name ?? ""
        self.selectedFilePath = project?.audioFilePath ?? ""
        self.transcript = project?.transcript
    }
    
    @MainActor private func transcribeTapped() async {
        guard let selectedFilePath = selectedFilePath else { return }
        let scriptPath = Documents_Path + "/transcribe.py"
        let audioPath = String(selectedFilePath.dropFirst(7)) // Removes the 'file://' from the beginning of the path.
        let args = [scriptPath,
                    "identify",
                    navigationContext.key,
                    audioPath,
                    boostedWords.joined(separator: ",")
        ]
        
        /// When the file is local remove preceding text otherwise URL audio wont play.
        if selectedFilePath.starts(with: "file://") {
            self.selectedFilePath = audioPath
        }
        
        self.isLoading.toggle()
        do {
            let (status, outputData) = try await execTool(tool: URL(fileURLWithPath: Python_Path), arguments: args)
            self.isLoading.toggle()
            self.decodeResponse(data: outputData)
        } catch {
            self.isLoading.toggle()
            print("[Error] \(error)")
        }
    }
    
    private func execTool(tool: URL, arguments: [String]) async throws -> (terminationStatus: Int32, output: Data) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = tool
        process.arguments = arguments
        process.standardOutput = pipe.fileHandleForWriting
        
        let outputTask = Task {
            try await withUnsafeThrowingContinuation { continuation in
                pipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
                
                let notificationCenter = NotificationCenter.default
                var observer: NSObjectProtocol?
                observer = notificationCenter.addObserver(
                    forName: .NSFileHandleDataAvailable,
                    object: pipe.fileHandleForReading,
                    queue: nil
                ) { _ in
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    pipe.fileHandleForReading.closeFile()
                    if let observer = observer {
                        notificationCenter.removeObserver(observer)
                    }
                    continuation.resume(returning: data)
                }
            }
        }
        
        do {
            try process.run()
            pipe.fileHandleForWriting.closeFile()
            
            return try await withCheckedThrowingContinuation { continuation in
                process.terminationHandler = { proc in
                    Task {
                        do {
                            let output = try await outputTask.value
                            continuation.resume(returning: (proc.terminationStatus, output))
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }
        } catch {
            outputTask.cancel()
            throw ProcessError(kind: .processError, underlying: error)
        }
    }
    
    private func decodeResponse(data: Data) {
        do {
            let decoder = JSONDecoder()
            let response = try decoder.decode(AAIResponse.self, from: data)
            let sections = response.sections.mapValues { sectionData in
                AAISection(
                    name: sectionData.name,
                    start: sectionData.start
                )
            }
            
            if let project = self.project {
                self.transcript = Transcript(audio_url: response.audio_url, utterances: response.utterances, sections: sections, project: project)
            }
            save()
        } catch {
            print("[Error] \(error)")
        }
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
                print("[Error] Error while saving: \(error)")
            }
        }
    }
}

//#Preview {
//    SetupView(project: Project(name: "Sample"))
//        .padding()
//        .frame(width: 420, height: 540)
//}
