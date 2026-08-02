import AVFoundation
import SwiftUI

// MARK: - VoicePlayer

/// AVAudioPlayer wrapper backing the editor's playback card.
@MainActor
final class VoicePlayer: NSObject, ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var position: TimeInterval = 0
    // Published: load() runs from onAppear, after the card's first render —
    // the view only re-evaluates if loading announces itself.
    @Published private(set) var isLoaded = false

    private(set) var duration: TimeInterval = 0
    private var player: AVAudioPlayer?
    private var timer: Timer?

    func load(url: URL) {
        guard player == nil, let loaded = try? AVAudioPlayer(contentsOf: url) else { return }
        loaded.delegate = self
        loaded.prepareToPlay()
        player = loaded
        duration = loaded.duration
        isLoaded = true
    }

    func toggle() {
        guard let player else { return }
        if isPlaying {
            player.pause()
            isPlaying = false
            timer?.invalidate()
        } else {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try? AVAudioSession.sharedInstance().setActive(true)
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    func stop() {
        player?.stop()
        timer?.invalidate()
        timer = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let player = self.player else { return }
                self.position = player.currentTime
            }
        }
    }
}

extension VoicePlayer: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.isPlaying = false
            self.position = 0
            self.timer?.invalidate()
        }
    }
}

// MARK: - VoicePlayerCard

/// Bordered playback card shown in the editor for notes with a recording.
struct VoicePlayerCard: View {
    let fileName: String
    let duration: TimeInterval
    @StateObject private var player = VoicePlayer()

    private var total: TimeInterval {
        player.isLoaded ? player.duration : duration
    }

    private var progress: Double {
        total > 0 ? min(player.position / total, 1) : 0
    }

    var body: some View {
        Group {
            if player.isLoaded {
                playerRow
            } else {
                Text("Audio unavailable.")
                    .font(NoteFont.bodyS)
                    .foregroundStyle(Color.noteInkMute)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(Space.xl)
        .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.xl))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.xl)
                .strokeBorder(Color.noteRule, lineWidth: 1)
        )
        .padding(.bottom, Space.sectionGap)
        .onAppear { player.load(url: VoiceNotes.url(for: fileName)) }
        .onDisappear { player.stop() }
    }

    private var playerRow: some View {
        HStack(spacing: Space.xl) {
            Button {
                player.toggle()
            } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.noteBg)
                    .frame(width: 36, height: 36)
                    .background(Color.noteInk, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(player.isPlaying ? "Pause voice note" : "Play voice note")

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.noteRule)
                        .frame(height: 3)
                    Capsule()
                        .fill(Color.noteInk)
                        .frame(width: max(geo.size.width * progress, 0), height: 3)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 36)

            Text(VoiceNotes.formatDuration(player.isPlaying || player.position > 0 ? player.position : total))
                .font(NoteFont.captionS)
                .foregroundStyle(Color.noteInkDim)
                .monospacedDigit()
        }
    }
}

// MARK: - Preview

#Preview {
    VoicePlayerCard(fileName: "missing.m4a", duration: 42)
        .padding()
        .background(Color.noteBg)
}
