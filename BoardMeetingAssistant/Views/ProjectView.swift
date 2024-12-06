////
////  AudioPlayerView.swift
////  BoardMeetingAssistant
////
////  Created by Ryan Smetana on 9/8/24.
////

import SwiftUI
import SwiftData
import AVFoundation

struct ProjectView: View {
    var project: Project?
    @StateObject private var audioVM = AudioPlayerViewModel()
    @Environment(NavigationContext.self) private var navigationContext
    @Environment(\.modelContext) private var modelContext
    
    let suggestions: [String] = ["Suggestion 1", "Suggestion 2"]
    
    @State private var utterances: [AAIUtterance] = []
    @State private var speakerOptions: [String] = [""]
    @State private var selectedSpeaker: String = ""
    
    /// Delays saving until after the user is finished typing
    @State private var typingDelayTask: DispatchWorkItem?
    @State private var hasEdited = false
    @FocusState private var focusedField: Int?
    
    func loadTranscriptionData() {
        hasEdited = false
        let u = project?.transcript?.utterances ?? [AAIUtterance(text: "Error", start: 0, end: 10, confidence: 1.0, speaker: "Error", speakerName: "Err")]
        self.utterances = u
        var speakers = Set<String>()
        speakers.insert("")
        u.forEach({ speakers.insert($0.speaker) })
        speakerOptions = Array(speakers).sorted()
    }
    
    func saveUpdatedData() {
        project?.transcript?.utterances = self.utterances
        do {
            try modelContext.save()
        } catch {
            print("Error saving utterances: \(error)")
        }
    }
    
    func propogateSpeaker(name: String, toLetter: String, endTime: Int) {
        for i in 0 ..< utterances.count {
            if utterances[i].speaker == toLetter && utterances[i].end > endTime {
                utterances[i].speakerName = name
            }
        }
    }
    
    /// Debounce typing, to delay saving after the user finishes typing
    private func handleTypingFinished() {
        typingDelayTask?.cancel()
        
        // Set a new task to save after 1 second of no typing
        typingDelayTask = DispatchWorkItem {
            saveUpdatedData()
        }
        
        // Execute the new save task after 1 second of delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: typingDelayTask!)
    }
    
    func exportProjectToJSON() {
        guard let project = project else {
            print("Project is nil")
            return
        }
        // Convert Project to its exportable form
        let projectExport = project.toExportModel()
        
        // Create a JSON encoder
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            // Encode the project as JSON
            let jsonData = try encoder.encode(projectExport)
            
            // Save it to the same directory as the python scripts.
            let documentsPath = "\(Documents_Path)\(project.name)/updated.json"
            let fileURL = URL(fileURLWithPath: documentsPath)
            try jsonData.write(to: fileURL)
            
            print("Exported JSON to: \(fileURL.path)")
        } catch {
            print("Error exporting project to JSON: \(error)")
        }
    }
    
    func createDoc() {
        guard let project = project else { return }
        let projectExport = project.toExportModel()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let jsonData = try encoder.encode(projectExport)
            guard let jsonString = String(data: jsonData, encoding: .utf8) else {
                print("Error converting JSON data to string")
                return
            }
            
            let pythonInterpreter = Python_Path
            let documentsPath = Documents_Path
            let scriptPath = documentsPath + "/createDocument.py"
            let process = Process()
            process.executableURL = URL(fileURLWithPath: pythonInterpreter)
            process.arguments = [scriptPath, jsonString, project.name]
            try process.run()
            process.waitUntilExit()
        } catch {
            print("Error exporting project to JSON: \(error)")
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let path = project?.audioFilePath {
                AudioPlayerView(vm: audioVM)
                    .onAppear {
                        audioVM.setupAudio(with: path)
                    }
            }
            
            HStack {
                Picker(selection: $selectedSpeaker) {
                    ForEach(speakerOptions, id: \.self) { letter in
                        Text(letter)
                    }
                } label: {
                    Text("Speaker:")
                }
                .pickerStyle(.menu)
                .frame(width: 140)
                
                Spacer()
            } //: HStack
            .onChange(of: project) { oldValue, newValue in
                loadTranscriptionData()
            }
            
            ScrollView {
                LazyVStack {
                    ForEach(utterances.indices, id: \.self) { index in
                        if selectedSpeaker.isEmpty || utterances[index].speaker == selectedSpeaker {
                            HStack {
                                Text(TimeInterval(utterances[index].start / 1000).formatTranscriptTime())
                                
                                Divider()
                            } //: HStack
                            
                            VStack(alignment: .leading) {
                                HStack(alignment: .top) {
                                    ZStack {
                                        TextField("Speaker Name", text: $utterances[index].speakerName ?? "")
                                            .textFieldStyle(.plain)
                                            .padding(8)
                                            .scrollContentBackground(.hidden)
                                            .disableAutocorrection(true)
                                            .font(.subheadline)
                                        
                                        if let suggestion = suggestions.filter({
                                            $0.lowercased().contains((utterances[index].speakerName ?? "").lowercased())
                                        }).first {
                                            Text(suggestion)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .padding(.leading, 8)
                                                .font(.subheadline)
                                        }
                                    } //: ZStack
                                    .frame(maxWidth: 240)
                                    .overlay(
                                        HStack {
                                            Text("(\(utterances[index].speaker))")
                                                .foregroundStyle(Color.gray)
                                            Button {
                                                let speakerLetter = utterances[index].speaker
                                                if let speakerName = utterances[index].speakerName {
                                                    propogateSpeaker(name: speakerName, toLetter: speakerLetter, endTime: utterances[index].end)
                                                }
                                            } label: {
                                                Image(systemName: "arrow.down")
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                            .padding(.trailing, 6)
                                        , alignment: .trailing
                                    )
                                    
                                    Spacer()
                                    VStack(alignment: .trailing) {
                                        Text(String(format: "%.2f%%", utterances[index].confidence * 100))
                                            .font(.caption2)
                                            .foregroundStyle(Color.gray)
                                        
                                        HStack {
                                            Spacer()
                                            Button {
                                                utterances[index - 1].text.append(" " + utterances[index].text)
                                                utterances[index - 1].end = utterances[index].end
                                                utterances.remove(at: index)
                                            } label: {
                                                Image(systemName: "arrow.up")
                                            }
                                            .foregroundStyle(.accent)
                                            .buttonStyle(BorderlessButtonStyle())
                                            
                                            Button {
                                                audioVM.togglePlay(at: Double(utterances[index].start) / 1000.0)
                                            } label: {
                                                Image(systemName: "play")
                                            }
                                            
                                            Button {
                                                utterances.remove(at: index)
                                            } label: {
                                                Image(systemName: "trash")
                                            }
                                            .foregroundStyle(Color.red)
                                            .buttonStyle(BorderlessButtonStyle())
                                        } //: HStack
                                        .frame(maxWidth: 120)
                                    } //: HStack
                                } //: VStack
                                .frame(maxWidth: .infinity)
                                
                                TextEditor(text: $utterances[index].text)
                                    .frame(maxWidth: .infinity)
                                    .font(.title)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(1.5)
                                    .scrollDisabled(true)
                                    .scrollContentBackground(.hidden)
                                    .focused($focusedField, equals: index)
                                    .onChange(of: utterances[index].text) {
                                        if hasEdited {
                                            handleTypingFinished()
                                        }
                                    }
                                    .onChange(of: focusedField) { oldFocus, newFocus in
                                        if oldFocus == nil && newFocus != nil {
                                            hasEdited = true
                                        }
                                    }
                            } //: VStack
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                            .listStyle(.plain)
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(Color.gray.opacity(0.1))
                        } //: If
                    } //: List
                    .scrollContentBackground(.hidden)
                }
            }
        } //: VStack
        .padding()
        .background(.bg)
        .onAppear(perform: loadTranscriptionData)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("To DocX") {
                    createDoc()
                    
                }
            }
            
//            ToolbarItem(placement: .automatic) {
//                Button("Export") {
//                    exportProjectToJSON()
//                }
//            }
        }
    } //: Body
    
    
}

extension TimeInterval {
    func formatTranscriptTime() -> String {
        let hours = Int(self) / 3600
        let minutes = Int(self) % 3600 / 60
        let seconds = Int(self) % 60
        let formatted = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        //        print("Converting \(self)ms to \(formatted)")
        return formatted
    }
}

#Preview {
    ModelContainerPreview(ModelContainer.sample) {
        ProjectView(project: .p)
            .environment(NavigationContext())
    }
}

func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}
