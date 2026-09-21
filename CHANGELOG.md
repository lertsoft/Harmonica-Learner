# Changelog

All notable changes to the **Harmonica Learner** project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), organized by release month.

---

## [September 2026]

### Added
- **SvelteKit Companion Web Application**:
  - Full-featured companion website and learner landing page built with SvelteKit, TypeScript, and Vite in `/web`.
  - Modern responsive landing experience featuring hero typography, step-by-step feature breakdown, interactive practice showcase, song library catalog, and social proof.
- **Interactive Web Audio Harmonica (`InteractiveHarmonica.svelte`)**:
  - 10-hole interactive Key of C diatonic harmonica simulator running directly in the browser.
  - Custom polyphonic Web Audio API synthesis engine (`audio.ts`) providing authentic reed timbre, blow/draw note mapping, and visual key depression states.
- **Interactive Song-to-Tabs Converter Demo (`SongConverterDemo.svelte`)**:
  - Browser-based interactive simulation of the song import and transcription pipeline.
  - Interactive presets (blues riffs, folk standards, pop melodies) and live simulation of audio transcription into playable hole/airflow tab notation.
- **Interactive Tolerance Meter Visualizer (`ToleranceMeterDemo.svelte`)**:
  - Live interactive visualization of the app's cents-accurate tuning meter and adaptive tolerance curve (30¢ down to 15¢).
- **Realistic Interactive Phone Mockup (`AppPhoneMockup.svelte`)**:
  - High-fidelity interactive iOS device frame showcasing the live practice screen with real-time note hit progression, pitch detection needle, and audio feedback.
- **Searchable Practice Library Modal (`HeaderView.swift`)**:
  - Dedicated sheet-based song library interface separating songs into "Built In" and "My Practice" sections.
  - Real-time search filtering across song titles and note counts.
  - Swipe actions and context menus for renaming and deleting custom recordings directly within the library.

### Changed & Improved
- **Header Navigation Redesign**:
  - Swapped dense dropdown controls for a streamlined, compact header layout with prominent current song title, mode pill, and quick library trigger.
  - Added dedicated compact mode heuristics for smaller phone displays and landscape orientations.
- **Note Lookup & Layout Caching**:
  - Optimized note-to-hole frequency matching in `HarmonicaLayout.swift` with cached lookup tables for Standard Richter Diatonic C and Lee Oskar C layouts.
- **Practice View Layout Tuning**:
  - Refined layout constraints in `PracticeView.swift` to prevent clipping on compact screens while maintaining dual-column responsiveness on iPads and larger viewports.

---

## [August 2026]

### Added
- **"Add Your Own Songs" Audio Ingestion Engine**:
  - **Local File Import**: Document picker integration (`UIDocumentPickerViewController`) allowing users to import audio files (`.mp3`, `.m4a`, `.wav`, `.aiff`, `.caf`, `.aac`, `.flac`) directly from the Files app.
  - **Device Music Library Picker (`MusicLibraryPicker.swift`)**: Native `MPMediaPickerController` integration allowing users to import non-DRM music from their personal device library with explicit DRM error reporting for protected tracks.
  - **Live Microphone Acoustic Recording**: In-app recording flow enabling users to record an acoustic instrument or external playback, and analyze it locally into playable harmonica tabs.
  - **Song-Link Transcription Seam (`SongLinkImportService.swift`)**: Support for pasting Spotify, YouTube, Apple Music, or direct media links, with automatic format validation and direct media downloading up to 200 MB.
- **On-Device Audio Pitch Analyzer (`ImportedSongAnalyzer.swift`)**:
  - High-performance offline pitch analysis powered by Apple's `Accelerate` framework (`vDSP` FFT and windowing).
  - Downsampling to 11,025 Hz, frame-by-frame dominant frequency detection, observation clustering, and noise filtering.
  - Automatic mapping to nearest playable harmonica notes with duration clamping and consecutive duplicate note merging.
  - Musical fallback phrase generation for complex polyphonic tracks lacking an isolated lead melody.
- **Synthesized Reference Audio (`NotePlaybackService.swift`)**:
  - Built-in synthesizer engine that plays back the extracted harmonica line as an isolated reference performance without mixing into the original audio.
- **Licensed Transcription Cloudflare Worker (`Backend/spotify-worker.mjs`)**:
  - Serverless worker implementation consuming Spotify's official Audio Analysis API chroma segments to extract dominant pitch classes without audio ripping.
  - Comprehensive unit test suite (`spotify-worker.test.mjs`) and deployment configuration (`wrangler.toml.example`).
  - Detailed architecture and legal policy documentation in `Docs/SongLinkTranscription.md`.
- **Adaptive Practice Layout Engine (`AdaptivePracticeLayout.swift`)**:
  - Responsive layout manager dynamically selecting between single-column scroll-safe mobile layouts, compact landscape views, and two-column widescreen interfaces.

### Changed & Improved
- **Audio Session Management (`AppAudioSession.swift`)**:
  - Centralized AVAudioSession routing supporting simultaneous microphone input, synthesized playback, and system background audio handling.
- **Freestyle Storage Model Enhancements**:
  - Extended `FreestyleRecording.swift` and `FreestyleRecordingStore.swift` with UUID-based persistent identity, metadata tagging, and audio-retention toggles.
- **Target Note & Pitch Visualization**:
  - Overhauled `TargetNoteView.swift` and `DetectedPitchView.swift` with smoother spring physics and clearer hit/miss/idle color states.

---

## [February 2026]

### Added
- **Initial Native iOS Application**:
  - Native iOS application target built with Swift 5.9+, SwiftUI, and Combine for iOS 17+.
- **Real-Time Pitch Detection Engine (`AudioEngineService.swift`)**:
  - Low-latency real-time pitch tracking powered by `AudioKit`, `AudioKitEX`, and `SoundpipeAudioKit` via `PitchTap`.
  - Continuous frequency extraction, amplitude gating to ignore ambient room noise, and cents deviation computation.
- **Guided Practice Mode**:
  - Note-by-note progression engine requiring 3 consecutive valid hits on a target note before advancing to the next.
  - Real-time hole and airflow visual guidance (Blow `↑` / Draw `↓` on holes 1 through 10).
  - Cents-accurate tuning needle with dynamic color transitions and haptic pulse feedback for hits and misses.
- **Adaptive Pitch Tolerance Model (`AttemptToleranceModel.swift`)**:
  - Dynamic tolerance curve starting forgivingly at ±30 cents for beginners and tightening down to ±15 cents over 20 attempts.
- **Freestyle Mode**:
  - Free play performance mode with concurrent M4A audio recording and real-time note event timestamp logging.
  - Automatic session saving, playback review, and silent note-by-note practice conversion.
- **Harmonica Layout System (`HarmonicaLayout.swift`, `HarmonicaHole.swift`)**:
  - Accurate note mappings for Standard Richter Diatonic C and Lee Oskar Diatonic C.
  - Frequency-to-note mathematical mapping (`NoteMapper.swift`) using MIDI standards.
- **Bundled Song Library (`songs.json`, `SongLibrary.swift`)**:
  - 7 introductory songs spanning fundamentals, chord drills, folk melodies, and blues riffs:
    - *C Major Scale* (15 notes, 90 BPM)
    - *Mary Had a Little Lamb* (13 notes, 96 BPM)
    - *Twinkle Twinkle* (14 notes, 90 BPM)
    - *Oh Susannah* (16 notes, 104 BPM)
    - *Starter Blues* (8 notes, 98 BPM)
    - *C Chord Drill* (11 notes, 88 BPM)
    - *I-IV-V Chord Walk* (22 notes, 92 BPM)
- **Modern "Liquid Glass" Visual Design (`AppTheme.swift`)**:
  - Frosted glass cards, gradient borders, ambient glow, and native iOS 18 `MeshGradient` backgrounds with graceful fallbacks.
  - Gesture-driven swipeable controls panel and animated progress tracks.
  - First-launch onboarding overlay explaining harmonica breathing mechanics and microphone permission requests.
- **Unit Test Suite (`HarmonicaTests/`)**:
  - Unit tests covering pitch evaluation (`NoteEvaluationTests`), tolerance calculations (`AttemptToleranceModelTests`), note mapping (`NoteMapperTests`), layout lookups (`HarmonicaLayoutTests`, `HarmonicaHoleTests`), persistence (`FreestyleRecordingStoreTests`), and practice state management (`PracticeViewModelTests`).
- **Comprehensive Documentation**:
  - Full project `README.md` detailing app features, architecture diagram, dependency specifications, and setup instructions.
