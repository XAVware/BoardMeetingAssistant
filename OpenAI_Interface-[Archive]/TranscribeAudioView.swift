//
//  TranscribeAudioView.swift
//  Recording Transcriber
//
//  Created by Smetana, Ryan on 5/22/23.
//

import SwiftUI
import AVKit

struct TranscribeAudioView: View {
    @StateObject var docMan: DocManager = DocManager()
    let segmentLength: Int = 420
    @State var progressMessage: String = ""
    
    @State var audioPaths: [URL] = []
    @State var audioSegments: [Segment] = []
    @State var isTimerRunning = false
    @State private var startTime = Date()
    @State var interval = TimeInterval()
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    // Initialize the OpenAI client
    let client = OpenAIClient(config: OpenAIConfig(
        apiKey: "YOUR_API_KEY"
    ))
    
    @State var formatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    func showFilePicker() {
        let dialog = NSOpenPanel();
        
        dialog.title = "Choose the audio file."
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.allowsMultipleSelection = false
        dialog.canChooseDirectories = false
        dialog.allowedContentTypes = [.mp3, .mpeg4Audio, .m4a]
        
        if dialog.runModal() == NSApplication.ModalResponse.OK {
            if let result = dialog.url {
                docMan.selectedFilePath = result.path
                guard !docMan.rootOutputFolderPath.isEmpty else { return }
                let dirPath = URL(string: docMan.rootOutputFolderPath)!.appendingPathComponent(docMan.outputFolderName)
                
                do {
                    try FileManager.default.createDirectory(atPath: dirPath.path, withIntermediateDirectories: true, attributes: nil)
                    docMan.outputFolderPath = dirPath.path
                } catch {
                    print("Unable to create directory \(error.localizedDescription)")
                }
                print("Output Dir Path = \(dirPath)")
            }
        }
    }
    
    func transcribeTapped() {
        guard let url = URL(string: docMan.selectedFilePath) else {
            print("Error converting selected path to URL")
            return
        }
        
        startTime = Date()
        isTimerRunning = true
        
        Task {
            await splitFile(path: url)
        }
    }
    
    func splitFile(path: URL) async {
        var numOfFullSegments: Int = 0
        var lastSegmentLength: Int = 0
        progressMessage = "Fetching File..."
        
        let fileURL: URL = URL(string: "file://\(path)")!
        
        progressMessage = "Analyzing File..."
        let asset: AVAsset = AVAsset(url: fileURL)
        
        do {
            progressMessage = "Analyzing File Length..."
            let duration = try await CMTimeGetSeconds(asset.load(.duration))
            
            numOfFullSegments = Int(ceil(duration / Double(segmentLength)) - 1)
            lastSegmentLength = Int(Int(duration) - (numOfFullSegments * segmentLength))
            
            progressMessage = "Splitting audio file into \(numOfFullSegments + 1) segments"
            
            for index in 0...numOfFullSegments {
                let segmentStartTime = Int64(segmentLength * index)
                let segmentEndTime = index < numOfFullSegments ? Int64(segmentLength * (index + 1)) : Int64(segmentStartTime + Int64(lastSegmentLength))
                
                splitAudio(asset: asset, segment: index, start: segmentStartTime, end: segmentEndTime) { assetUrl in
                    audioPaths.append(assetUrl)
                    if numOfFullSegments + 1 == audioPaths.count {
                        progressMessage = "Finished exporting audio segments. Transcribing..."
                        Task {
                            await transcribeAudioFiles()
                        }
                    }
                }
            }
        } catch {
            progressMessage = "Error getting duration: \(error.localizedDescription)"
        }
    }
    
    func splitAudio(asset: AVAsset, segment: Int, start: Int64, end: Int64, completion: @escaping (URL) -> Void) {
        let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A)!
        exporter.outputFileType = AVFileType.m4a
        let startTime = CMTimeMake(value: start, timescale: 1)
        let endTime = CMTimeMake(value: end, timescale: 1)
        
        exporter.timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        exporter.outputURL = URL(string: "file://\(docMan.outputFolderPath)/\(segment).m4a")
        
        exporter.exportAsynchronously {
            switch exporter.status {
            case .failed:
                print("Export failed: \(exporter.error?.localizedDescription ?? "unknown error")")
            default:
                progressMessage = "Exporting audio-\(segment) complete."
                if let outputURL = exporter.outputURL {
                    completion(outputURL)
                } else {
                    print("Error getting output URL for array.")
                }
            }
        }
    }
    
    func transcribeAudioFiles() async {
        progressMessage = "Transcribing. This may take a few minutes..."
        
        for segment in 0..<audioPaths.count {
            if let url = URL(string: "file://\(docMan.outputFolderPath)/\(segment).m4a") {
                do {
                    let audioData = try Data(contentsOf: url)
                    
                    do {
                        let response = try await client.createTranscription(
                            audioData: audioData,
                            filename: "\(segment).m4a",
                            model: .whisper1,
                            prompt: "Replace all period punctuation (.) with {AudioParameterTesting}",
                            language: .english
                            //                            config: config
                        )
                        
                        let transcribedSegment = Segment(index: segment, text: response.text)
                        audioSegments.append(transcribedSegment)
                        
                        if audioSegments.count == audioPaths.count {
                            await finishTranscribing()
                        }
                    } catch {
                        progressMessage = "Transcription error: \(error.localizedDescription)"
                    }
                } catch {
                    print("Error reading audio file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func finishTranscribing() async {
        progressMessage = "Finished Transcribing... Parsing..."
        audioSegments = audioSegments.sorted { $0.index < $1.index }
        
        var fullScript = ""
        for segment in audioSegments {
            fullScript.append(segment.text)
        }
        
        // Save original transcript
        if let url = URL(string: "file://\(docMan.outputFolderPath)/originalTranscript.txt") {
            do {
                try fullScript.write(to: url, atomically: true, encoding: .utf8)
                progressMessage = "Finished Saving Original Document... Cleaning..."
            } catch {
                print("Error saving original transcript: \(error.localizedDescription)")
            }
        }
        
        // Clean data
        let scriptComponents = fullScript.components(separatedBy: ".")
        var finalComponents: [String] = []
        
        for index in 0..<scriptComponents.count {
            let trimmedText = scriptComponents[index].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if scriptComponents[index].contains("?") {
                let questionComponents = scriptComponents[index].components(separatedBy: "?")
                
                for i in 0..<questionComponents.count {
                    let trimmed = questionComponents[i].trimmingCharacters(in: .whitespacesAndNewlines)
                    finalComponents.append(trimmed.appending(i == questionComponents.count - 1 ? "." : "?"))
                }
            } else {
                finalComponents.append(trimmedText.appending("."))
            }
        }
        
        var finalScript = ""
        for index in 0..<finalComponents.count {
            if finalComponents[index].count <= 1 {
                continue
            } else if index != 0 && finalComponents[index] != finalComponents[index - 1] {
                finalScript.append(finalComponents[index].appending("\n"))
            }
        }
        
        // Save clean transcript
        if let url = URL(string: "file://\(docMan.outputFolderPath)/cleanTranscript.txt") {
            do {
                try finalScript.write(to: url, atomically: true, encoding: .utf8)
                await MainActor.run {
                    progressMessage = "Finished Saving Final Document"
                    isTimerRunning = false
                }
            } catch {
                print("Error saving clean transcript: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Text(docMan.selectedFilePath.isEmpty ? "File Path..." : docMan.selectedFilePath)
                    .padding(4)
                    .foregroundColor(.gray)
                    .frame(maxWidth: 400, alignment: .leading)
                    .background(.white)
                    .cornerRadius(3)
                
                Button("Select File") {
                    showFilePicker()
                }
            }
            
            HStack(spacing: 8) {
                if isTimerRunning {
                    ProgressView()
                        .scaleEffect(0.5)
                    
                    Text("Time Elapsed: \(formatter.string(from: interval) ?? "")")
                        .font(.system(.footnote, design: .monospaced))
                        .onReceive(timer) { _ in
                            if isTimerRunning {
                                interval = Date().timeIntervalSince(startTime)
                            }
                        }
                }
            }
            .frame(height: 30)
            
            Text(progressMessage)
                .foregroundColor(.white)
            
            Button("Transcribe") {
                transcribeTapped()
            }
        }
        .padding()
    }
}

struct TranscribeAudioView_Previews: PreviewProvider {
    static var previews: some View {
        TranscribeAudioView()
            .environmentObject(DocManager())
    }
}







