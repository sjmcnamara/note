import SwiftUI
import UIKit

// MARK: - VoiceRecorderOverlay
//
// Bottom-anchored recording card over a dim backdrop (same treatment as
// SearchView). Starts recording on appear; delete discards, save hands the
// finished file back to TimelineView.

struct VoiceRecorderOverlay: View {
    let onSave: (_ fileName: String, _ duration: TimeInterval) -> Void
    let onDismiss: () -> Void
    @StateObject private var recorder = VoiceRecorder()

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.28)
                .ignoresSafeArea()
                .onTapGesture { cancel() }

            card
                .padding(.horizontal, Space.gutterH)
                .padding(.bottom, 24)
        }
        .task { await recorder.start() }
    }

    private var card: some View {
        VStack(spacing: 0) {
            if recorder.phase == .denied {
                deniedContent
            } else {
                recordingContent
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Space.sectionGap)
        .padding(.vertical, Space.sectionGap)
        .background(Color.noteBg, in: RoundedRectangle(cornerRadius: Radius.sheet))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.sheet)
                .strokeBorder(Color.noteRule, lineWidth: 1)
        )
        .sheetShadow()
    }

    // MARK: - Recording state

    private var recordingContent: some View {
        VStack(spacing: Space.xl) {
            HStack(spacing: Space.m) {
                RecordingDot(active: recorder.phase == .recording)
                Text(recorder.phase == .paused ? "Paused" : "Recording")
                    .font(NoteFont.caption)
                    .foregroundStyle(Color.noteInkDim)
            }

            Text(VoiceNotes.formatDuration(recorder.elapsed))
                .font(NoteFont.displayXL)
                .foregroundStyle(Color.noteInk)
                .monospacedDigit()
                .accessibilityLabel("Recorded \(VoiceNotes.formatDuration(recorder.elapsed))")

            HStack(spacing: Space.sectionGap) {
                RoundControl(systemName: "trash", label: "Delete recording") {
                    cancel()
                }

                RoundControl(
                    systemName: recorder.phase == .paused ? "play.fill" : "pause.fill",
                    label: recorder.phase == .paused ? "Resume recording" : "Pause recording"
                ) {
                    recorder.togglePause()
                }

                Button {
                    if let result = recorder.finish() {
                        onSave(result.fileName, result.duration)
                    }
                    onDismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.noteBg)
                        .frame(width: 52, height: 52)
                        .background(Color.noteInk, in: Circle())
                }
                .buttonStyle(.plain)
                .disabled(recorder.elapsed < 1)
                .opacity(recorder.elapsed < 1 ? 0.4 : 1)
                .accessibilityLabel("Save voice note")
            }
        }
    }

    // MARK: - Denied state

    private var deniedContent: some View {
        VStack(spacing: Space.l) {
            Text("Microphone access is off.")
                .font(NoteFont.titleM)
                .foregroundStyle(Color.noteInk)

            Text("Allow the microphone in Settings to record voice notes.")
                .font(NoteFont.bodyS)
                .foregroundStyle(Color.noteInkDim)
                .multilineTextAlignment(.center)

            HStack(spacing: Space.xl) {
                Button("Not now") { onDismiss() }
                    .font(NoteFont.body)
                    .foregroundStyle(Color.noteInkDim)
                    .buttonStyle(.plain)

                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    onDismiss()
                } label: {
                    Text("Open Settings")
                        .font(NoteFont.body.weight(.medium))
                        .foregroundStyle(Color.noteBg)
                        .padding(.horizontal, Space.xxl)
                        .padding(.vertical, Space.base)
                        .background(Color.noteInk, in: RoundedRectangle(cornerRadius: Radius.pill))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, Space.xs)
        }
    }

    private func cancel() {
        recorder.discard()
        onDismiss()
    }
}

// MARK: - Recording dot

private struct RecordingDot: View {
    let active: Bool
    @State private var pulsing = false

    var body: some View {
        Circle()
            .fill(active ? Color.noteOk : Color.noteInkMute)
            .frame(width: 8, height: 8)
            .scaleEffect(active && pulsing ? 1.35 : 1.0)
            .opacity(active && pulsing ? 0.6 : 1.0)
            .animation(
                active ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                value: pulsing
            )
            .onAppear { pulsing = true }
    }
}

// MARK: - Round control

private struct RoundControl: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color.noteInk)
                .frame(width: 52, height: 52)
                .background(Color.noteAlt, in: Circle())
                .overlay(Circle().strokeBorder(Color.noteRule, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Preview

#Preview {
    VoiceRecorderOverlay(onSave: { _, _ in }, onDismiss: {})
        .background(Color.noteBg.ignoresSafeArea())
}
