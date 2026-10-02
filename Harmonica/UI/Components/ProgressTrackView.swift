import SwiftUI

struct ProgressTrackView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let song: HarmonicaSong?
    let currentNoteIndex: Int
    let matchState: NoteMatchState
    let layout: HarmonicaLayout
    var arrangementExplanation: String? = nil
    @State private var showsArrangementDetails = false

    @ScaledMetric(relativeTo: .body) private var scaledNoteWidth: CGFloat = 58
    @ScaledMetric(relativeTo: .body) private var scaledNoteHeight: CGFloat = 58
    @ScaledMetric(relativeTo: .body) private var scaledNoteSpacing: CGFloat = 10

    private var noteWidth: CGFloat { min(90, max(58, scaledNoteWidth)) }
    private var noteHeight: CGFloat { min(86, max(58, scaledNoteHeight)) }
    private var noteSpacing: CGFloat { min(16, max(8, scaledNoteSpacing)) }

    private var visibleIndices: [Int] {
        guard let song, !song.notes.isEmpty else { return [] }
        let lowerBound = max(0, currentNoteIndex - 3)
        let upperBound = min(song.notes.count - 1, currentNoteIndex + 3)
        return Array(lowerBound...upperBound)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) {
                    trackTitle
                    HStack {
                        trackCount
                        Spacer()
                        arrangementButton
                    }
                }
            } else {
                HStack {
                    trackTitle
                    Spacer(minLength: 4)
                    trackCount
                    arrangementButton
                }
            }

            if dynamicTypeSize.isAccessibilitySize {
                VStack(spacing: 10) {
                    ForEach(visibleIndices.filter { $0 >= currentNoteIndex }, id: \.self) { index in
                        let note = song?.notes[index]
                        NoteChipView(
                            note: note?.note ?? "",
                            hole: note.flatMap { layout.hole(for: $0.note) },
                            state: chipState(for: index),
                            isActive: index == currentNoteIndex,
                            position: index + 1,
                            total: song?.notes.count ?? 0
                        )
                    }
                }
            } else {
                GeometryReader { geometry in
                    let centerX = geometry.size.width / 2
                    ZStack {
                        ForEach(visibleIndices.filter { index in
                            abs(CGFloat(index - currentNoteIndex) * (noteWidth + noteSpacing)) + noteWidth / 2 <= centerX
                        }, id: \.self) { index in
                            let note = song?.notes[index]
                            NoteChipView(
                                note: note?.note ?? "",
                                hole: note.flatMap { layout.hole(for: $0.note) },
                                state: chipState(for: index),
                                isActive: index == currentNoteIndex,
                                position: index + 1,
                                total: song?.notes.count ?? 0
                            )
                            .frame(width: noteWidth)
                            .position(
                                x: centerX + CGFloat(index - currentNoteIndex) * (noteWidth + noteSpacing),
                                y: noteHeight / 2
                            )
                        }
                    }
                    .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.82), value: currentNoteIndex)
                }
                .frame(height: noteHeight)
                .mask(
                    LinearGradient(
                        colors: [.clear, .white, .white, .white, .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }

            progressBar
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .liquidGlass(cornerRadius: 16, intensity: 0.03)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("progress-track")
        .sheet(isPresented: $showsArrangementDetails) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(arrangementExplanation ?? "")
                            .accessibilityIdentifier("arrangement-explanation")
                        Text("Practice notes are adapted for your harmonica. Transposition and register changes can make them differ from the original audio.")
                    }
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
                .navigationTitle("Arrangement Details")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showsArrangementDetails = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var trackTitle: some View {
        Text(displaySongTitle)
            .font(AppTypography.bodyStrong)
            .foregroundStyle(AppColors.textPrimary)
            .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.4)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var trackCount: some View {
        if let song {
            Text("\(min(currentNoteIndex + 1, song.notes.count))/\(song.notes.count)")
                .font(AppTypography.caption.monospacedDigit())
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.5)
        }
    }

    @ViewBuilder
    private var arrangementButton: some View {
        if arrangementExplanation != nil {
            Button { showsArrangementDetails = true } label: {
                Image(systemName: "info.circle")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Arrangement details")
            .accessibilityIdentifier("arrangement-details-button")
        }
    }

    private var progressBar: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.1))
                Capsule()
                    .fill(AppGradients.primary)
                    .frame(width: progressWidth(in: geometry.size.width))
                    .animation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.8), value: currentNoteIndex)
            }
        }
        .frame(height: 5)
    }

    private func chipState(for index: Int) -> NoteChipState {
        if index < currentNoteIndex {
            return .completed
        } else if index == currentNoteIndex {
            return matchState == .hit ? .active : .current
        } else {
            return .upcoming
        }
    }

    private func progressWidth(in totalWidth: CGFloat) -> CGFloat {
        guard let song, !song.notes.isEmpty else { return 0 }
        let progress = CGFloat(currentNoteIndex + 1) / CGFloat(song.notes.count)
        return totalWidth * min(1, max(0, progress))
    }

    private var displaySongTitle: String {
        guard let title = song?.songTitle else { return "No Song" }
        let parts = title.components(separatedBy: " • ")
        guard parts.first == "Freestyle", parts.count >= 2 else { return title }
        return "Freestyle • \(parts[1])"
    }
}

enum NoteChipState {
    case completed
    case current
    case active
    case upcoming
}

struct NoteChipView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let note: String
    let hole: HarmonicaHole?
    let state: NoteChipState
    let isActive: Bool
    let position: Int
    let total: Int

    var body: some View {
        VStack(spacing: 1) {
            Text(tabText)
                .font(dynamicTypeSize.isAccessibilitySize ? .system(.title3, design: .rounded).bold() : .system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            if hole != nil {
                Text(note)
                    .font(AppTypography.caption)
                    .foregroundStyle(textColor.opacity(0.75))
                    .lineLimit(1)
                    .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 1 : 0.62)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(backgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(borderColor, lineWidth: isActive ? 1.2 : 0.8)
        )
        .scaleEffect(isActive ? 1.05 : 1.0)
        .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.75), value: isActive)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    private var backgroundColor: Color {
        switch state {
        case .completed: return AppColors.hitGradientStart.opacity(0.18)
        case .current, .active: return AppColors.primaryGradientStart.opacity(0.2)
        case .upcoming: return Color.white.opacity(0.05)
        }
    }

    private var borderColor: Color {
        switch state {
        case .completed: return AppColors.hitGradientStart.opacity(0.45)
        case .current, .active: return AppColors.primaryGradientStart.opacity(0.7)
        case .upcoming: return Color.white.opacity(0.1)
        }
    }

    private var textColor: Color {
        switch state {
        case .completed: return AppColors.hitGradientStart
        case .current, .active: return AppColors.textPrimary
        case .upcoming: return AppColors.textTertiary
        }
    }

    private var tabText: String {
        guard let hole else { return "—" }
        return "\(hole.airflow == .blow ? "+" : "−")\(hole.index)"
    }

    private var accessibilitySummary: String {
        let instruction = hole.map { "hole \($0.index), \($0.airflow == .blow ? "blow" : "draw")" } ?? "unmapped note"
        let status: String
        switch state {
        case .completed: status = "completed"
        case .current, .active: status = "current"
        case .upcoming: status = "upcoming"
        }
        return "Note \(position) of \(total), \(note), \(instruction), \(status)"
    }
}

#Preview {
    ZStack {
        AppColors.backgroundDeep.ignoresSafeArea()
        ProgressTrackView(
            song: nil,
            currentNoteIndex: 2,
            matchState: .idle,
            layout: .diatonicC
        )
        .padding()
    }
}
