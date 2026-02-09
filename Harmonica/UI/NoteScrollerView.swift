import SwiftUI

struct NoteScrollerView: View {
    let song: HarmonicaSong?
    let currentNoteIndex: Int
    let matchState: NoteMatchState
    let layout: HarmonicaLayout

    private let laneHeight: CGFloat = 26
    private let laneSpacing: CGFloat = 6
    private let noteSpacing: CGFloat = 70

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                laneBackground
                notesLayer(width: geometry.size.width)
                playhead
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: laneHeight * 10 + laneSpacing * 9 + 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.1).opacity(0.05))
        )
    }

    private var laneBackground: some View {
        VStack(spacing: laneSpacing) {
            ForEach((1...10).reversed(), id: \.self) { index in
                HStack(spacing: 6) {
                    Text("\(index)")
                        .font(.caption2.weight(.semibold))
                        .frame(width: 22)
                        .foregroundStyle(.secondary)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.1).opacity(0.08))
                        .frame(height: laneHeight)
                }
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, 14)
    }

    private func notesLayer(width: CGFloat) -> some View {
        let notes = song?.notes ?? []
        let startX = width * 0.55
        let offset = -CGFloat(currentNoteIndex) * noteSpacing

        return ZStack {
            ForEach(Array(notes.enumerated()), id: \.0) { index, note in
                let hole = HarmonicaHole.fromCode(note.hole)
                let laneIndex = hole?.index ?? 1
                let laneY = yPosition(for: laneIndex)
                let xPosition = startX + CGFloat(index) * noteSpacing + offset
                NoteBlockView(
                    note: note.note,
                    hole: hole,
                    isActive: index == currentNoteIndex,
                    matchState: matchState
                )
                .position(x: xPosition, y: laneY)
                .animation(.easeInOut(duration: 0.35), value: currentNoteIndex)
            }
        }
    }

    private func yPosition(for laneIndex: Int) -> CGFloat {
        let reversed = 11 - laneIndex
        return CGFloat(reversed - 1) * (laneHeight + laneSpacing) + laneHeight / 2 + 10
    }

    private var playhead: some View {
        Rectangle()
            .fill(Color.accentColor)
            .frame(width: 2)
            .padding(.leading, 12)
            .opacity(0.6)
    }
}
