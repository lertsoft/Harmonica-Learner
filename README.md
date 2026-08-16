# 🎵 Harmonica Learner

This is anative iOS app that helps you learn and practice your harmonica skills. It uses real-time pitch detection, guided note progression, and freestyle recording sessions to help us folks who are learning to play the harmonica get better at it.

---

## ✨ Features

### 🎯 Guided Practice Mode
- **Real-time pitch detection** — Uses the microphone to detect the note you're playing and compares it to a target note in real time.
- **Note-by-note progression** — Work through songs one note at a time. Land three consecutive hits on a target note to automatically advance to the next.
- **Hole & airflow guidance** — Each target note shows the corresponding harmonica hole number and whether to blow or draw, so you always know what to do.
- **Cents-accurate tuner** — A precision tuning meter shows exactly how sharp or flat your pitch is, with animated feedback and color-coded indicators.
- **Adaptive tolerance** — Pitch tolerance starts lenient and tightens as you improve across attempts, powered by the `AttemptToleranceModel` (30¢ → 15¢ over 20 attempts).
- **Haptic feedback** — Subtle haptic cues for hits and misses keep you engaged without looking at the screen.

### 🎤 Freestyle Mode
- **Free play with recording** — Switch to freestyle mode to play freely while the app captures your notes and audio.
- **Audio + note capture** — Records M4A audio and simultaneously logs every detected note event with timing and duration data.
- **Playback** — Replay your recorded freestyle sessions with full audio playback.
- **Silent note-by-note practice** — Saved performances become visual note targets automatically; audio stays off unless you choose to hear a reference note or the original recording.
- **Session management** — Freestyle recordings are automatically saved and appear alongside bundled songs in the song picker. Saved items can be renamed or deleted, and playback audio can be removed while keeping captured notes.

### ➕ Add Your Own Songs
- **Audio import** — Use the add button to choose an audio file from Files.
- **Device Music Library** — Choose downloaded, unprotected music owned by the user. Apple Music subscription downloads and other DRM-protected items are intentionally rejected because iOS does not expose their audio data.
- **Record a playing song** — Capture audio through the microphone, then analyze the recording locally into suggested harmonica notes. This works well for a song playing from another device or an acoustic performance.
- **Song-link entry** — Paste Spotify, YouTube, Apple Music, or direct audio links. Direct audio URLs are downloaded and analyzed locally; protected streaming links are routed through an optional licensed transcription endpoint.
- **Harmonica suggestions** — The app analyzes dominant pitches and turns them into a compact line of playable harmonica notes with hole and blow/draw guidance.
- **Synthesized cover preview** — Hear the complete suggested line as a newly generated harmonica-like performance; the imported recording is not mixed into the cover.
- **Full-mix fallback** — If a song has no clear lead pitch, the app supplies a starter harmonica phrase so the song still has useful practice targets.
- **Optional listening** — Imported audio is preserved for on-demand playback; practicing the suggested line remains silent by default.

### 📖 Built-in Song Library
Includes 7 bundled songs ranging from fundamentals to blues:

| Song | BPM | Notes | Description |
|------|-----|-------|-------------|
| C Major Scale | 90 | 15 | Full ascending/descending scale |
| Mary Had a Little Lamb | 96 | 13 | Classic beginner melody |
| Twinkle Twinkle | 90 | 14 | Familiar nursery tune |
| Oh Susannah | 104 | 16 | American folk classic |
| Starter Blues | 98 | 8 | Simple blues riff |
| C Chord Drill | 88 | 11 | Arpeggio practice |
| I-IV-V Chord Walk | 92 | 22 | Chord progression exercise |

### 🎨 Modern UI
- **Liquid Glass design** — Glassmorphism-inspired UI with frosted glass cards, gradient borders, and ambient lighting.
- **iOS 18 Mesh Gradients** — Rich, dynamic backgrounds using `MeshGradient` with fallbacks for older versions.
- **Spring animations** — Smooth, physics-based animations throughout (note transitions, success pulses, panel gestures).
- **Draggable controls panel** — Swipe-down to dismiss the controls panel; tap to bring it back.
- **Adaptive layouts** — Scroll-safe phone layouts, compact landscape controls, two-column wide-screen practice, and Dynamic Type support keep controls usable without clipping or overlap.
- **Onboarding flow** — First-launch overlay explaining blow/draw mechanics and microphone permissions.

---

## 🏗️ Architecture

```
Harmonica/
├── App/
│   ├── HarmonicaLearnerApp.swift     # App entry point
│   └── ContentView.swift             # Root view
├── Audio/
│   ├── AudioEngineService.swift      # AudioKit pitch detection & freestyle recording
│   ├── ImportedSongAnalyzer.swift    # Audio-file pitch analysis and harmonica suggestions
│   └── NotePlaybackService.swift     # Optional synthesized reference-note playback
├── Models/
│   ├── AttemptToleranceModel.swift    # Adaptive pitch tolerance curve
│   ├── FreestyleRecording.swift       # Freestyle session data model
│   ├── FreestyleRecordingStore.swift  # Persistent storage for freestyle sessions
│   ├── HarmonicaHole.swift           # Hole number + blow/draw representation
│   ├── HarmonicaLayout.swift         # Note-to-hole mapping (Diatonic C, Lee Oskar C)
│   ├── HarmonicaSong.swift           # Song & note event models
│   ├── NoteEvaluation.swift          # Pitch matching logic (hit/miss/idle)
│   ├── NoteMapper.swift              # Frequency → note name conversion (MIDI-based)
│   └── SongLibrary.swift             # Bundled song loader
├── Resources/
│   └── Songs/
│       └── songs.json                # Bundled song definitions
└── UI/
    ├── Components/
    │   ├── ControlsView.swift        # Sensitivity slider, buttons, presets
    │   ├── DetectedPitchView.swift    # Live pitch display with tuning meter
    │   ├── HeaderView.swift          # Song/key/layout picker + freestyle toggle
    │   ├── ProgressTrackView.swift   # Scrolling note track with progress bar
    │   └── TargetNoteView.swift      # Target note card with state pill
    ├── NoteBlockView.swift           # Individual note chip for the scroller
    ├── NoteScrollerView.swift        # Lane-based note visualizer
    ├── PracticeView.swift            # Main practice screen
    ├── PracticeViewModel.swift       # Core state management & business logic
    ├── TunerView.swift               # Standalone tuner view
    └── Theme/
        └── AppTheme.swift            # Colors, gradients, typography, glass modifier
```

### Key Design Decisions

- **AudioKit + SoundpipeAudioKit** for robust, low-latency pitch detection via `PitchTap`.
- **MVVM pattern** — `PracticeViewModel` owns all state; views are declarative and stateless.
- **Combine-driven** — Audio service publishes frequency/amplitude streams that the view model processes reactively.
- **Local persistence** — Freestyle recordings stored as JSON index + M4A audio files in the app's Documents directory.
- **Stable song identity** — Saved songs use UUID-backed identifiers, so renames and duplicate titles do not break selection or persistence.
- **Offline song suggestions** — Imported audio is analyzed locally; no account or network upload is required.
- **Licensed link-provider seam** — Set the `HarmonicaTranscriptionAPIURL` Info property to an HTTPS endpoint that accepts `{ sourceURL, provider, harmonicaKey, layout }` and returns `{ title, bpm, notes }`. The app never attempts to rip protected provider audio.
- **Spotify analysis worker** — `Backend/spotify-worker.mjs` implements that contract using Spotify's official Audio Analysis endpoint for eligible Spotify developer applications; credentials stay on the worker.

Provider behavior, official policy references, and the backend JSON contract are documented in [Docs/SongLinkTranscription.md](Docs/SongLinkTranscription.md).
- **Adaptive difficulty** — `AttemptToleranceModel` uses linear interpolation from a forgiving starting tolerance down to a precise target over configurable attempts.

---

## 🧪 Testing

```
HarmonicaTests/
├── AttemptToleranceModelTests.swift
├── FreestyleRecordingStoreTests.swift
├── FreestyleRecordingTests.swift
├── HarmonicaHoleTests.swift
├── HarmonicaLayoutTests.swift
├── ImportedSongAnalyzerTests.swift
├── NoteEvaluationTests.swift
├── NoteMapperTests.swift
├── PracticeViewModelTests.swift
└── SongLibraryTests.swift
```

Run tests via Xcode (`⌘U`) or from the command line:

```bash
xcodebuild test -scheme Harmonica -destination 'platform=iOS Simulator,name=iPhone 16'
```

---

## 🚀 Getting Started

### Requirements
- **Xcode 16+**
- **iOS 17.0+** (iOS 18+ recommended for Mesh Gradient backgrounds)
- **Physical device recommended** for real microphone input (Simulator has limited audio support)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/lertsoft/Harmonica-Learner
   cd Harmonica-Learner
   ```

2. **Open in Xcode**
   ```bash
   open Harmonica.xcodeproj
   ```

3. **Resolve packages** — AudioKit dependencies will resolve automatically via Swift Package Manager.

4. **Build & run** — Select a target device or simulator and hit `⌘R`.

> **Note:** The app requires microphone access. On first launch, an onboarding overlay will guide you through granting permission. A usage description is configured in `Info.plist` under `NSMicrophoneUsageDescription`.

---

## 📦 Dependencies

| Package | Purpose |
|---------|---------|
| [AudioKit](https://github.com/AudioKit/AudioKit) | Audio engine management |
| [AudioKitEX](https://github.com/AudioKit/AudioKitEX) | Extended AudioKit utilities |
| [SoundpipeAudioKit](https://github.com/AudioKit/SoundpipeAudioKit) | `PitchTap` for real-time frequency detection |

---

## 🎼 Adding Songs

Songs are defined in `Harmonica/Resources/Songs/songs.json`. Each song follows this structure:

```json
{
  "songTitle": "My New Song",
  "bpm": 100,
  "key": "C",
  "notes": [
    { "note": "C5", "duration": 0.5, "hole": "4B" },
    { "note": "D5", "duration": 0.5, "hole": "4D" },
    { "note": "E5", "duration": 1.0, "hole": "5B" }
  ]
}
```

**Hole codes:** The number is the hole (1–10), followed by `B` (blow) or `D` (draw). For example, `6D` means "draw on hole 6."

**Note names:** Standard scientific pitch notation (e.g., `C4`, `G5`, `A6`). The app maps these to the correct harmonica holes via `HarmonicaLayout`.

---

## 📄 License

This project is provided as-is for educational and personal use.
