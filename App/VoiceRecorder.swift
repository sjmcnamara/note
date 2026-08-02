import AVFoundation
import Foundation

/// Wraps AVAudioRecorder for the voice note overlay: permission request,
/// record / pause / resume, and either discard (file removed) or finish
/// (file kept, name + duration returned).
@MainActor
final class VoiceRecorder: NSObject, ObservableObject {

    enum Phase {
        case idle
        case recording
        case paused
        case denied
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var elapsed: TimeInterval = 0

    private var recorder: AVAudioRecorder?
    private var fileName: String?
    private var timer: Timer?

    private static let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44_100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
    ]

    func start() async {
        guard phase == .idle else { return }
        guard await AVAudioApplication.requestRecordPermission() else {
            phase = .denied
            return
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let name = VoiceNotes.newFileName()
            let recorder = try AVAudioRecorder(url: VoiceNotes.url(for: name), settings: Self.settings)
            guard recorder.record() else {
                phase = .denied
                return
            }
            self.recorder = recorder
            self.fileName = name
            phase = .recording
            startTimer()
        } catch {
            print("VoiceRecorder start error: \(error)")
            phase = .denied
        }
    }

    func togglePause() {
        guard let recorder else { return }
        switch phase {
        case .recording:
            recorder.pause()
            phase = .paused
        case .paused:
            recorder.record()
            phase = .recording
        default:
            break
        }
    }

    /// Stops and deletes the recording.
    func discard() {
        let name = fileName
        stop()
        if let name { try? FileManager.default.removeItem(at: VoiceNotes.url(for: name)) }
    }

    /// Stops and keeps the recording.
    func finish() -> (fileName: String, duration: TimeInterval)? {
        guard let name = fileName, elapsed > 0 else {
            discard()
            return nil
        }
        let duration = recorder?.currentTime ?? elapsed
        stop()
        return (name, max(duration, elapsed))
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        recorder?.stop()
        recorder = nil
        fileName = nil
        phase = .idle
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self, let recorder = self.recorder else { return }
                // currentTime holds still while paused, so elapsed tracks
                // recorded audio, not wall-clock time.
                if self.phase == .recording { self.elapsed = recorder.currentTime }
            }
        }
    }
}
