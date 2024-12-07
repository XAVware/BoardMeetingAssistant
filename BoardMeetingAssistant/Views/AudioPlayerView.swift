//
//  AudioPlayerView.swift
//  BoardMeetingAssistant
//
//  Created by Ryan Smetana on 10/5/24.
//

import AVFoundation
import SwiftUI


class AudioPlayerViewModel: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime = TimeInterval(0)
    private var audioPlayer: AVAudioPlayer?
    var duration = TimeInterval(0)
    @Published var playbackRate: Float = 1.0 
    
    func setupAudio(with urlString: String) {
        var tempURLString: String = urlString
        if tempURLString.starts(with: "file://") {
            tempURLString = String(tempURLString.dropFirst(7))
        }
        
        let audioURL = URL(fileURLWithPath: tempURLString)
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.enableRate = true  // Enable rate adjustment
            audioPlayer?.rate = playbackRate  // Set the initial rate
            duration = audioPlayer?.duration ?? 0
        } catch {
            print("Audio player error: \(error.localizedDescription)")
        }
    }
    
    func togglePlay(at time: TimeInterval? = nil) {
        guard let audioPlayer = audioPlayer else { return }
        
        if let time = time {
            audioPlayer.currentTime = time
            currentTime = time
            audioPlayer.play()
            isPlaying = true
        } else {
            if audioPlayer.isPlaying {
                audioPlayer.pause()
                isPlaying = false
            } else {
                audioPlayer.play()
                isPlaying = true
            }
        }
        
        startTimer()
    }
    
    func updatePlaybackRate(to rate: Float) {
        playbackRate = rate
        audioPlayer?.rate = playbackRate
    }
    
    func seek(seconds: Double) {
        guard let audioPlayer = audioPlayer else { return }
        var time = audioPlayer.currentTime + seconds
        time = max(min(time, duration), 0)
        audioPlayer.currentTime = time
        currentTime = time
    }
    
    func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if let audioPlayer = self.audioPlayer, audioPlayer.isPlaying {
                let currentTimeMillis = audioPlayer.currentTime * 1000
                self.currentTime = audioPlayer.currentTime
            } else {
                timer.invalidate()
            }
        }
    }
    
    func sliderEditingChanged(editingStarted: Bool) {
        if editingStarted {
            audioPlayer?.pause()
        } else {
            if let newTime = audioPlayer?.duration {
                audioPlayer?.currentTime = newTime * currentTime / duration
                audioPlayer?.play()
            }
        }
    }
}


struct AudioPlayerView: View {
    @ObservedObject var vm: AudioPlayerViewModel
    private let playbackRates: [Float] = [1.0, 1.1, 1.25, 1.5, 2.0]

    var body: some View {
        VStack {
            HStack {
                Picker("Speed", selection: $vm.playbackRate) {
                    ForEach(playbackRates, id: \.self) { rate in
                        Text("\(rate, specifier: "%.1f")x")
                            .tag(rate)
                    }
                }
                .onChange(of: vm.playbackRate) { newRate in
                    vm.updatePlaybackRate(to: newRate)
                }
                .pickerStyle(.menu)
                .padding()
                .frame(maxWidth: 140)
                Spacer()
                HStack {
                    seekButton(seconds: -30, systemName: "gobackward.30")
                    seekButton(seconds: -5, systemName: "gobackward.5")
                    Button {
                        vm.togglePlay()
                    } label: {
                        Image(systemName: vm.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 50, height: 50)
                    }
                    .buttonStyle(PlainButtonStyle())
                    seekButton(seconds: 5, systemName: "goforward.5")
                    seekButton(seconds: 30, systemName: "goforward.30")
                } //: HStack
                .foregroundStyle(.accent)
                Spacer()
                Spacer()
                    .frame(maxWidth: 140)

            } //: HStack
            
            HStack {
                Text(($vm.currentTime.wrappedValue).formatTranscriptTime())
                Slider(value: $vm.currentTime, in: 0...vm.duration, onEditingChanged: vm.sliderEditingChanged)
                Text("-" + (vm.duration - vm.currentTime).formatTranscriptTime())
            } //: HStack
            
        } //: VStack
        .padding()
        .background(.ultraThinMaterial)
        .foregroundStyle(.accent)
        .clipShape(RoundedRectangle(cornerRadius: 12))

    }
    
    func seekButton(seconds: Double, systemName: String) -> some View {
        Button {
            vm.seek(seconds: seconds)
        } label: {
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
