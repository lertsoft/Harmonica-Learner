import SwiftUI

struct NoteBlockView: View {
    let note: String
    let hole: HarmonicaHole?
    let isActive: Bool
    let matchState: NoteMatchState

    var body: some View {
        VStack(spacing: 4) {
            Text(note)
                .font(.caption.weight(.semibold))
            Text(hole?.displayName ?? "--")
                .font(.caption2)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(blockColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(isActive ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }

    private var blockColor: Color {
        guard isActive else { return Color(white: 0.15).opacity(0.08) }
        switch matchState {
        case .hit:
            return Color.green.opacity(0.8)
        case .miss:
            return Color.red.opacity(0.8)
        case .idle:
            return Color.orange.opacity(0.35)
        }
    }
}
