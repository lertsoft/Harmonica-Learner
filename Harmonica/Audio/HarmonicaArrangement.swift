import Foundation

/// Source pitches and timing are retained separately from the playable adaptation.
nonisolated struct HarmonicaArrangementSummary: Codable, Hashable {
    let transpositionSemitones: Int
    let detectedChordCount: Int
    var octaveShift: Int = 0

    var explanation: String {
        let shift = transpositionSemitones == 0
            ? "Transposed 0 semitones"
            : "Transposed \(transpositionSemitones > 0 ? "+" : "")\(transpositionSemitones) semitones"
        let register = octaveShift == 0 ? "" : " • Register \(octaveShift > 0 ? "+" : "")\(octaveShift) octaves"
        return "Approximate arrangement • \(shift)\(register) • \(detectedChordCount) chord groups played as arpeggios"
    }
}

nonisolated struct HarmonicaArrangement {
    let notes: [HarmonicaNoteEvent]
    let summary: HarmonicaArrangementSummary

    static func make(
        from observations: [PitchObservation], layout: HarmonicaLayout, minimumRunDuration: TimeInterval = 0.07
    ) -> Self {
        struct Run {
            let pitches: [Int]
            let start: TimeInterval
            var duration: TimeInterval
        }
        var runs: [Run] = []
        var time: TimeInterval = 0
        // Rests break runs. Mapping happens afterwards so distinct source notes stay distinct.
        for observation in observations {
            guard observation.duration.isFinite, observation.duration > 0 else { continue }
            let pitches = Array(Set(observation.frequencies.compactMap { frequency -> Int? in
                guard frequency.isFinite, frequency > 0,
                      let pitch = NoteMapper.pitch(for: frequency) else { return nil }
                return NoteMapper.midiNumber(for: pitch.fullName)
            })).sorted()
            if !observation.startsNewNote, let last = runs.last, last.pitches == pitches,
               abs(last.start + last.duration - time) < 0.0001 {
                runs[runs.count - 1].duration += observation.duration
            } else {
                runs.append(Run(pitches: pitches, start: time, duration: observation.duration))
            }
            time += observation.duration
        }
        let stable = runs.filter { !$0.pitches.isEmpty && $0.duration >= minimumRunDuration }
        let naturalClasses = Set(layout.noteToHole.keys.compactMap { NoteMapper.midiNumber(for: $0).map { $0 % 12 } })
        // One global shift preserves intervals better than snapping every chromatic note independently.
        // Prefer the original key when tied, then the smallest shift.
        let shifts = ([-6, -5, -4, -3, -2, -1, 0, 1, 2, 3, 4, 5]).sorted {
            abs($0) == abs($1) ? $0 < $1 : abs($0) < abs($1)
        }
        var shift = 0
        var bestScore = -Double.infinity
        for candidate in shifts {
            let score = stable.reduce(0.0) { total, run in
                total + run.pitches.reduce(0.0) { score, midi in
                    score + (naturalClasses.contains(((midi + candidate) % 12 + 12) % 12) ? run.duration : 0)
                }
            }
            if score > bestScore + 0.000001 {
                bestScore = score
                shift = candidate
            }
        }
        // Choose one register for the phrase before folding individual outliers. This
        // avoids jumping an octave at low-register F/A gaps in Richter tuning.
        var octaveShift = 0
        var bestRegisterCost = Double.infinity
        for octave in [0, 1, -1, 2, -2, 3, -3] {
            let cost = stable.reduce(0.0) { total, run in
                total + run.pitches.reduce(0.0) { score, midi in
                    let target = midi + shift + octave * 12
                    guard let note = layout.playableNote(forMIDI: target),
                          let playable = NoteMapper.midiNumber(for: note) else { return score }
                    return score + Double(abs(playable - target)) * run.duration
                }
            }
            if cost < bestRegisterCost - 0.000001 {
                bestRegisterCost = cost
                octaveShift = octave
            }
        }
        var notes: [HarmonicaNoteEvent] = []
        var chordCount = 0
        for run in stable {
            let sourceNames = run.pitches.compactMap { NoteMapper.pitch(for: NoteMapper.frequency(forMidi: $0))?.fullName }
            let playable = run.pitches.compactMap { layout.playableNote(forMIDI: $0 + shift + octaveShift * 12) }
            // A short chord becomes a short arpeggio, never a single unrelated root.
            // Slow the cover only when a group would require faster than 12.5 notes/second.
            let noteDuration = max(0.08, run.duration / Double(max(1, playable.count)))
            if run.pitches.count > 1 { chordCount += 1 }
            for (index, note) in playable.enumerated() {
                guard let hole = layout.hole(for: note) else { continue }
                notes.append(HarmonicaNoteEvent(
                    note: note,
                    duration: noteDuration,
                    hole: "\(hole.index)\(hole.airflow == .blow ? "B" : "D")",
                    startTime: run.start + Double(index) * run.duration / Double(max(1, playable.count)),
                    sourceNotes: sourceNames,
                    sourceDuration: run.duration / Double(max(1, playable.count))
                ))
            }
        }
        return Self(notes: notes, summary: HarmonicaArrangementSummary(
            transpositionSemitones: shift, detectedChordCount: chordCount, octaveShift: octaveShift
        ))
    }
}
