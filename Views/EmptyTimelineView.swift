import SwiftUI

// MARK: - EmptyTimelineView
//
// Shown by TimelineView when there are no notes yet. Header + compose bar
// are still rendered by TimelineView — this view only fills the middle.

struct EmptyTimelineView: View {
    let onStartNote: () -> Void
    @State private var toastMessage: String?

    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                Spacer(minLength: 60)

                Hero()
                    .padding(.bottom, Space.l)

                SubText()
                    .padding(.bottom, Space.sectionGap)

                VStack(spacing: Space.base) {
                    EmptyCTA(systemIcon: "plus", label: "Start a note", action: onStartNote)
                    EmptyCTA(systemIcon: "mic",  label: "Record a voice memo") {
                        showToast("Voice memos land later.")
                    }
                }
                .padding(.horizontal, Space.gutterH)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Empty notes list. Two options below.")

            if let toastMessage {
                Toast(message: toastMessage)
                    .padding(.horizontal, Space.gutterH)
                    .padding(.top, Space.m)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private func showToast(_ message: String) {
        withAnimation(.spring(duration: 0.25)) { toastMessage = message }
        Task {
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeOut(duration: 0.2)) { toastMessage = nil }
        }
    }
}

// MARK: - Hero

private struct Hero: View {
    var body: some View {
        VStack(spacing: Space.l) {
            Circle()
                .fill(Color.noteInk)
                .frame(width: 10, height: 10)

            (
                Text("A quiet place, ")
                    .font(Font.custom("Inter Tight", size: 22, relativeTo: .title2).weight(.medium))
                + Text("ready.")
                    .font(NoteFont.italic(24))
            )
            .foregroundStyle(Color.noteInk)
            .multilineTextAlignment(.center)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("A quiet place, ready.")
        }
    }
}

// MARK: - Sub text

private struct SubText: View {
    var body: some View {
        Text("Write anything — a thought, a list, a dream. Only you will see it.")
            .font(Font.custom("Inter Tight", size: 13.5, relativeTo: .callout))
            .foregroundStyle(Color.noteInkDim)
            .lineSpacing(4)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Space.sectionGap)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - CTA row

private struct EmptyCTA: View {
    let systemIcon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Space.l) {
                Image(systemName: systemIcon)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.noteInk)
                    .frame(width: 32, height: 32)
                    .background(Color.noteAlt, in: Circle())

                Text(label)
                    .font(NoteFont.body.weight(.medium))
                    .foregroundStyle(Color.noteInk)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.noteInkMute)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.noteBg, in: RoundedRectangle(cornerRadius: Radius.xl))
            .overlay {
                RoundedRectangle(cornerRadius: Radius.xl)
                    .strokeBorder(Color.noteRule, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Toast

private struct Toast: View {
    let message: String

    var body: some View {
        Text(message)
            .font(NoteFont.captionS)
            .foregroundStyle(Color.noteInk)
            .padding(.horizontal, Space.l)
            .padding(.vertical, Space.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.noteAlt, in: RoundedRectangle(cornerRadius: Radius.m))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.m)
                    .strokeBorder(Color.noteRule, lineWidth: 1)
            )
            .composeShadow()
    }
}

// MARK: - Preview

#Preview {
    EmptyTimelineView(onStartNote: {})
        .background(Color.noteBg.ignoresSafeArea())
}
