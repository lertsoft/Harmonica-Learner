# Imported song arrangement investigation

The goal is to retain as much melody, harmony and rhythm as the supported 10-hole C harmonicas can express. Full-band audio remains an estimate: neither spectral analysis nor a limited diatonic instrument can guarantee an exact rendition of every recording.

## Findings and implemented changes

| Previous behavior | Result | Current behavior |
| --- | --- | --- |
| One autocorrelation pitch per nonoverlapping 8,192-frame window | Chords became one pitch, often a bass tone or overtone | Overlapping Hann-windowed FFTs estimate up to four strong simultaneous pitches, suppress likely harmonics and combine channel energies |
| Stereo channels averaged before pitch detection | Opposite-phase signals could disappear | Channel spectral powers are combined without cancelling waveforms |
| Only the first 180 seconds analyzed | Later sections disappeared | The entire decoded file is processed with progress and cancellation |
| Runs below 120 ms discarded; long sequences sampled to 128 notes | Fast passages and intervening note changes disappeared | Stable runs of at least 70 ms retained, without a note-count cap |
| Durations rounded to half seconds and clamped | Rhythm and sustained notes changed | Detected durations and source timestamps retained; playable arpeggios use at least 80 ms per tone |
| Missing observations skipped before run grouping | Notes across rests merged | Silence breaks runs, and cover playback keeps gaps |
| Each detected pitch mapped directly to the nearest available note | Bass notes crowded the bottom of the instrument; low F/A notes made register jumps | Choose one transposition and register for the arrangement, preserve pitch classes by octave folding, approximate unavailable accidentals last |
| No source harmonic context saved | Users could not tell what was adapted | Original estimated pitch groups, source timing, transposition and register are persisted and shown during practice |
| Generic starter phrase used when detection failed | A phrase unrelated to the song became its practice targets | Save original audio with no fabricated notes and explain that reliable pitches were not recovered |
| Linked notes dropped outside the layout, capped at 512, with durations clamped | Provider detail disappeared again | Shared arrangement logic retains valid events, overlapping pitches and rests, adapting unavailable notes |
| Cover durations clamped to 0.25–2 seconds; whole buffer limited to four minutes | Preview changed rhythm or failed for a detailed song | Cover streams through three half-second buffers, preserving timing and long sequences |

## What “playable chords” means here

The practice engine evaluates one hole at a time. Detected chord tones are therefore arranged as arpeggios: for an estimated C–E–G group, play C, E, then G with individual hole and breath guidance. This preserves the detected harmonic content while keeping the existing guided-practice interaction usable.

Richter harmonicas have real chord restrictions and repeated notes: low blow holes support the tonic chord and low draw holes support the dominant family. Arbitrary piano or guitar chords cannot all be played simultaneously with one breath. The supported layouts currently offer natural notes without bend/overblow instruction, so some accidentals must be approximated even after transposition. The original pitch group stays attached to the playable events so these adaptations do not erase the estimated source evidence.

One global semitone shift maximizes duration-weighted pitch classes available on the instrument, preferring the original key on ties. A global octave shift then minimizes register folding. Individual outliers can still move octaves. A very short chord is expanded enough to play its tones; following rests retain their original length. The displayed transposition describes the arrangement, which may no longer match the key of the source recording during original-audio playback.

## Sources and boundaries

- [HOHNER tuning designer](https://tuningdesigner.hohner.de/help.php?lang=en) describes the instrument's separate blow/draw reeds and supported tuning families.
- [HOHNER chord explanation](https://my.hohner.de/t/harmonica-terminology-2-cross-harp-straight-harp-and-positions/1263/5) gives the low-hole C-major and G7 chord relationships on a C Richter harmonica.
- [Spotify Basic Pitch](https://github.com/spotify/basic-pitch) documents polyphonic transcription and its preference for one instrument at a time. It is a useful reference for the limitations of transcription; this implementation does not bundle that model.

The local estimator is deterministic spectral analysis, not learned source separation or a verified chord-recognition model. It searches roughly 80–2,200 Hz and favors strong, stable peaks. Weak fundamentals, percussion, detuning, reverberation, closely overlapping harmonics, octave doubling, very fast runs, and more than four simultaneous strong tones may lose detail or produce incorrect estimates. The UI labels the arrangement approximate and retains original audio. There are no inferred chord names presented as verified.

The optional Spotify worker retains strong chroma pitch classes and timing. Chroma does not establish concert octaves, so it assigns octave 5 as an arrangement register. Its output remains estimated harmonic context. Live provider access and real-device microphone/Music Library behavior are separate from local generated-audio tests.

Existing saved songs are compatible and retain their current notes. Reimport to generate a new arrangement; the app does not silently rewrite existing user recordings.

## Validation

Generated audio tests cover a pure melody tone, C-major triads, harmonically rich single tones, multiple harmonic voices with broadband noise at 22,050 Hz, opposite-phase stereo, late notes after three minutes, progress/cancellation, and Music Library export through analysis and persistent storage. Arrangement tests cover chromatic key transposition, 210 fast note changes, rests between repeated pitches, and short chord groups that need more playing time. Streaming playback tests start and stop a 300-second cover and observe completion of a short cover.

The running-app journey imports a generated chord audio file through `PracticeViewModel.importSong`, reads the source chord context, advances through individual chord tones, starts/stops the cover through Playback options, and reopens the saved arrangement after relaunch. Backend HTTP tests cover the provider contract, access failures, complete long sequences and chromatic pitch groups separated by quiet gaps.

These checks validate the code paths and controlled acoustic fixtures. They do not establish transcription accuracy for arbitrary commercial mixes or audible quality on a physical harmonica/device.

Final validation passed: 74 focused tests in the full unit suite, followed by all 24 import/arrangement checks with the additional noisy harmonic fixture (75 unique focused tests across these runs); all ten existing iPhone UI journeys plus the new chord-import journey; the chord-import, landscape and accessibility journeys on both iPhone 16e and iPad Pro 11-inch; and six backend HTTP tests. Finalized device results show nine selected checks passing per device, including six pitch-mapping checks. `git diff --check` passed.
