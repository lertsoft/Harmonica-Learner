import SwiftUI

struct DetectedPitchView: View {
    let pitch: NotePitch?
    let matchState: NoteMatchState

    @State private var animatedCents: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Detected")
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textTertiary)

                    Text(pitch?.fullName ?? "--")
                        .font(.custom("AvenirNextCondensed-DemiBold", size: 30))
                        .foregroundStyle(noteColor)
                        .contentTransition(.numericText())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(centsString)
                        .font(AppTypography.mono.monospacedDigit())
                        .foregroundStyle(centsColor)

                    Text(tuningLabel)
                        .font(AppTypography.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            meter
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: 16, intensity: 0.03)
        .onAppear {
            animatedCents = CGFloat(pitch?.centsOffset ?? 0)
        }
        .onChange(of: pitch?.centsOffset) { _, newValue in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                animatedCents = CGFloat(newValue ?? 0)
            }
        }
    }

    private var meter: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1)).frame(height: 10)

                Rectangle()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: 1, height: 14)
                    .position(x: width / 2, y: 5)

                Circle()
                    .fill(centsColor)
                    .frame(width: 14, height: 14)
                    .offset(x: indicatorOffset(width: width), y: -2)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: animatedCents)
            }
        }
        .frame(height: 10)
    }

    private func indicatorOffset(width: CGFloat) -> CGFloat {
        let clamped = max(-50, min(50, animatedCents))
        let normalized = (clamped + 50) / 100
        return normalized * max(0, width - 14)
    }

    private var centsString: String {
        guard let pitch else { return "--¢" }
        let cents = Int(pitch.centsOffset.rounded())
        return cents >= 0 ? "+\(cents)¢" : "\(cents)¢"
    }

    private var tuningLabel: String {
        guard let pitch else { return "No signal" }
        let absCents = abs(pitch.centsOffset)
        if absCents <= 8 { return "In tune" }
        return pitch.centsOffset > 0 ? "Sharp" : "Flat"
    }

    private var centsColor: Color {
        guard let pitch else { return AppColors.textTertiary }
        let absCents = abs(pitch.centsOffset)
        if absCents <= 10 { return AppColors.hitGradientStart }
        if absCents <= 25 { return AppColors.idleGradientStart }
        return AppColors.missGradientStart
    }

    private var noteColor: Color {
        switch matchState {
        case .hit: return AppColors.hitGradientStart
        case .miss: return AppColors.missGradientStart
        case .idle: return AppColors.textPrimary
        }
    }
}

#Preview {
    ZStack {
        AppColors.backgroundDeep.ignoresSafeArea()
        DetectedPitchView(
            pitch: NotePitch(noteName: "C", octave: 4, centsOffset: 5),
            matchState: .hit
        )
        .padding()
    }
}
