//
//  CropFileView.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 12/6/24.
//

import SwiftUI
import AVFoundation
import UniformTypeIdentifiers

struct CropFileView: View {
    @State private var audioURL: URL?
    @State private var startTime: TimeInterval = 0
    @State private var endTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var isPlaying = false
    @State private var audioPlayer: AVAudioPlayer?
    @State private var waveformSamples: [Float] = []
    @State private var isExporting = false
    @State private var isProcessing = false
    @State private var exportError: String?
    
    var body: some View {
        VStack(spacing: 20) {
            // File selection button
            Button(action: selectAudioFile) {
                HStack {
                    Image(systemName: "music.note")
                    Text(audioURL?.lastPathComponent ?? "Select Audio File")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            
            if let audioURL = audioURL {
                // Waveform and trim controls
                VStack {
                    
                        if isProcessing {
                            ProgressView("Processing audio...")
                                .progressViewStyle(CircularProgressViewStyle())
                                .foregroundColor(.white)
                        } else {
                            // Time display
                            ZStack {
                                HStack {
                                    Text(formatTime(startTime))
                                    Spacer()
                                    Text(formatTime(endTime))
                                }
                                WaveformView(samples: waveformSamples)
                                // Trim slider
                                TrimSlider(startTime: $startTime,
                                           endTime: $endTime,
                                           duration: duration)
                            }
                            .frame(height: 72)
                        }
                    
                    
                    
                    // Playback controls
                    HStack(spacing: 20) {
                        Button(action: playPause) {
                            Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 24))
                        }
                        
                        Button(action: stopPlayback) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 24))
                        }
                    }
                    .padding()
                    
                    // Export button
                    Button(action: exportTrimmedAudio) {
                        Text("Export Trimmed Audio")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .padding()
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func selectAudioFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.audio]
        
        if panel.runModal() == .OK {
            if let url = panel.url {
                audioURL = url
                setupAudioPlayer(url: url)
                generateWaveformSamples(url: url)
            }
        }
    }
    
    private func setupAudioPlayer(url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            duration = audioPlayer?.duration ?? 0
            endTime = duration
            audioPlayer?.prepareToPlay()
        } catch {
            print("Error loading audio file: \(error)")
        }
    }
    
    private func generateWaveformSamples(url: URL) {
        isProcessing = true

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let audioFile = try AVAudioFile(forReading: url)
                let format = audioFile.processingFormat
                let frameCount = UInt32(audioFile.length)
                
                // Chunk
                let chunkSize = 1024 * 32
                var samples: [Float] = []
                let targetSampleCount = 200 // Number of waveform bars to display
                
                for startFrame in stride(from: 0, to: Int(frameCount), by: chunkSize) {
                    let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(min(chunkSize, Int(frameCount) - startFrame)))!
                    try audioFile.read(into: buffer, frameCount: UInt32(min(chunkSize, Int(frameCount) - startFrame)))
                    
                    if let channelData = buffer.floatChannelData?[0] {
                        let chunk = Array(UnsafeBufferPointer(start: channelData, count: Int(buffer.frameLength)))
                        samples.append(contentsOf: chunk)
                    }
                }
                
                // Downsample
                let samplesPerSegment = max(samples.count / targetSampleCount, 1)
                var processedSamples: [Float] = []
                
                for i in stride(from: 0, to: samples.count, by: samplesPerSegment) {
                    let endIndex = min(i + samplesPerSegment, samples.count)
                    let segmentSamples = Array(samples[i..<endIndex])
                    let maxAmplitude = segmentSamples.map { abs($0) }.max() ?? 0
                    processedSamples.append(maxAmplitude)
                }
                
                // Normalize
                if let maxAmplitude = processedSamples.max(), maxAmplitude > 0 {
                    processedSamples = processedSamples.map { $0 / maxAmplitude }
                }
                
                DispatchQueue.main.async {
                    self.waveformSamples = processedSamples
                    self.isProcessing = false
                }
            } catch {
                print("[Error] Error generating waveform: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                }
            }
        }
    }
    
    private func playPause() {
        guard let player = audioPlayer else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.currentTime = startTime
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = startTime
        isPlaying = false
    }
    
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct WaveformView: View {
    let samples: [Float]
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 1) {
                ForEach(0..<samples.count, id: \.self) { index in
                    Rectangle()
                        .fill(Color.blue)
                        .frame(width: 2)
                        .frame(height: CGFloat(samples[index]) * geometry.size.height)
                }
            }
            .frame(maxHeight: .infinity, alignment: .center)
        }
    }
}


struct TrimSlider: View {
    @Binding var startTime: TimeInterval
    @Binding var endTime: TimeInterval
    let duration: TimeInterval
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                
                Rectangle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: (endTime - startTime) / duration * geometry.size.width)
                    .offset(x: startTime / duration * geometry.size.width)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .offset(x: startTime / duration * geometry.size.width - 6)
                    .gesture(DragGesture()
                        .onChanged { value in
                            let newStart = value.location.x / geometry.size.width * duration
                            startTime = max(0, min(newStart, endTime - 1))
                        })
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .offset(x: endTime / duration * geometry.size.width - 6)
                    .gesture(DragGesture()
                        .onChanged { value in
                            let newEnd = value.location.x / geometry.size.width * duration
                            endTime = min(duration, max(newEnd, startTime + 1))
                        })
            }
        }
    }
}

#Preview {
    CropFileView()
}

extension CropFileView {
    func exportTrimmedAudio() {
        guard let inputURL = audioURL else { return }
        
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.mp3, .m4a, .wav]
        savePanel.nameFieldStringValue = "trimmed_" + (inputURL.lastPathComponent)
        savePanel.message = "Choose where to save the trimmed audio file"
        savePanel.title = "Export Trimmed Audio"
        
        guard savePanel.runModal() == .OK,
              let outputURL = savePanel.url else { return }
        
        isExporting = true
        exportError = nil
        
        Task {
            do {
                let asset = AVAsset(url: inputURL)
                
                guard let exportSession = AVAssetExportSession(
                    asset: asset,
                    presetName: AVAssetExportPresetAppleM4A
                ) else {
                    throw ExportError.cantCreateExportSession
                }
                
                let startCMTime = CMTime(seconds: startTime, preferredTimescale: 1000)
                let endCMTime = CMTime(seconds: endTime, preferredTimescale: 1000)
                let timeRange = CMTimeRange(start: startCMTime, end: endCMTime)
                
                exportSession.outputURL = outputURL
                exportSession.outputFileType = .m4a
                exportSession.timeRange = timeRange
                
                await exportSession.export()
                
                try await MainActor.run {
                    isExporting = false
                    
                    switch exportSession.status {
                    case .completed:
                        let notification = NSUserNotification()
                        notification.title = "Export Complete"
                        notification.informativeText = "Audio file has been trimmed and saved successfully."
                        NSUserNotificationCenter.default.deliver(notification)
                        
                    case .failed:
                        throw exportSession.error ?? ExportError.unknown
                        
                    case .cancelled:
                        throw ExportError.cancelled
                        
                    default:
                        throw ExportError.unknown
                    }
                }
                
            } catch {
                await MainActor.run {
                    isExporting = false
                    exportError = error.localizedDescription
                }
            }
        }
    }
}

enum ExportError: LocalizedError {
    case cantCreateExportSession
    case cancelled
    case unknown
    
    var errorDescription: String? {
        return switch self {
        case .cantCreateExportSession: "Unable to create export session"
        case .cancelled: "Export was cancelled"
        case .unknown: "An unknown error occurred during export"
        }
    }
}

extension UTType {
    static let m4a = UTType(filenameExtension: "m4a")!
    static let mp3 = UTType(filenameExtension: "mp3")!
    static let wav = UTType(filenameExtension: "wav")!
}
