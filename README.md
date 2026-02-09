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
- **Session management** — Freestyle recordings are automatically saved and appear alongside bundled songs in the song picker. You can also strip the background audio while keeping captured notes for learning mode.

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
- **Onboarding flow** — First-launch overlay explaining blow/draw mechanics and microphone permissions.

---

## 🏗️ Architecture

```
Harmonica/
├── App/
│   ├── HarmonicaLearnerApp.swift     # App entry point
│   └── ContentView.swift             # Root view
├── Audio/
│   └── AudioEngineService.swift      # AudioKit pitch detection & freestyle recording
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
