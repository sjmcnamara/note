import SwiftUI

struct LockOverlayView: View {
    @EnvironmentObject private var lockService: AppLockService

    var body: some View {
        ZStack {
            Color.noteBg.ignoresSafeArea()

            VStack(spacing: Space.xl) {
                Text("NO.TE")
                    .font(NoteFont.displayL)
                    .tracking(0.8)
                    .foregroundStyle(Color.noteInk)

                Button {
                    lockService.evaluateIfNeeded()
                } label: {
                    VStack(spacing: Space.s) {
                        Image(systemName: "faceid")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(Color.noteInkDim)
                        Text("Tap to unlock")
                            .font(NoteFont.captionS)
                            .foregroundStyle(Color.noteInkMute)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .onAppear {
            lockService.evaluateIfNeeded()
        }
    }
}
