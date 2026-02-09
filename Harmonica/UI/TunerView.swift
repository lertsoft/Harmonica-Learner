import SwiftUI

struct TunerView: View {
    let pitch: NotePitch?
    let matchState: NoteMatchState
    let targetNote: String?
    let targetHole: HarmonicaHole?
    let layout: HarmonicaLayout

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Detected")
                        .font(.caption.weight(.semibold))
                    Text(pitch?.fullName ?? "--")
                        .font(.title2.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Cents")
                        .font(.caption.weight(.semibold))
                    Text(centsString)
                        .font(.title3.monospacedDigit())
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Target")
                        .font(.caption.weight(.semibold))
                    Text(targetNote ?? "--")
                        .font(.title3.weight(.semibold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Hole")
                        .font(.caption.weight(.semibold))
                    Text(targetHole?.displayName ?? "--")
                        .font(.title3.weight(.semibold))
                }
            }

            RoundedRectangle(cornerRadius: 10)
                .fill(matchColor)
                .frame(height: 12)
                .overlay(
                    Text(matchLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(white: 0.1).opacity(0.08))
        )
    }

    private var centsString: String {
        guard let pitch else { return "--" }
        return String(format: "%+.0f", pitch.centsOffset)
    }

    private var matchColor: Color {
        switch matchState {
        case .hit:
            return Color.green
        case .miss:
            return Color.red
        case .idle:
            return Color.gray
        }
    }

    private var matchLabel: String {
        switch matchState {
        case .hit:
            return "Hit"
        case .miss:
            return "Miss"
        case .idle:
            return "Listening"
        }
    }
}
