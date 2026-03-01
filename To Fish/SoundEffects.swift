//
//  SoundEffects.swift
//  To Fish
//
//  Created by alya Alabdulrahim on 08/09/1447 AH.
//
import AVFoundation

private var bubblePlayer: AVAudioPlayer?
// BUG-13: backgroundPlayer made private
private var backgroundPlayer: AVAudioPlayer?

func configureAudioSession() {
    do {
        try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [])
        try AVAudioSession.sharedInstance().setActive(true)
    } catch {
        // BUG-22: print the error instead of silently swallowing it
        print("Audio session configuration error: \(error)")
    }
}

func playBubblesSound() {
    guard let url = Bundle.main.url(forResource: "bubbles", withExtension: "mp3") else { return }
    // BUG-13: stop the previous player before reassigning to avoid overlapping instances
    bubblePlayer?.stop()
    bubblePlayer = try? AVAudioPlayer(contentsOf: url)
    bubblePlayer?.play()
}

func startBackgroundMusic() {
    guard let url = Bundle.main.url(forResource: "underwater", withExtension: "mp3") else { return }
    do {
        backgroundPlayer = try AVAudioPlayer(contentsOf: url)
        backgroundPlayer?.numberOfLoops = -1
        backgroundPlayer?.volume = 0.2
        backgroundPlayer?.prepareToPlay()
        backgroundPlayer?.play()
    } catch {
        // BUG-22: print the error instead of silently swallowing it
        print("Background music error: \(error)")
    }
}
