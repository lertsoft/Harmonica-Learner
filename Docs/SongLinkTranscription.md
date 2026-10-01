# Song-link transcription

Harmonica accepts four link classes from **Add Song → Paste Song Link**:

| Link | Current behavior |
| --- | --- |
| Direct `.mp3`, `.m4a`, `.wav`, `.aiff`, `.caf`, `.aac`, or `.flac` URL | Downloads up to 200 MB, analyzes locally, then stores it like a file import. |
| Spotify track | Recognized and sent to the configured licensed transcription endpoint. |
| YouTube / YouTube Music video | Recognized and sent to the configured licensed transcription endpoint. |
| Apple Music song | Recognized and sent to the configured licensed transcription endpoint. |

If no transcription endpoint is configured, protected-service links show a provider-specific explanation and the user can fall back to a local audio file they are allowed to use.

## Why protected links need a service agreement

- Spotify's 30-second `preview_url` is deprecated, and Spotify restricted Audio Features and Audio Analysis for new Web API integrations in November 2024.
- YouTube's Developer Policies prohibit downloading, separating, or modifying the audio component of YouTube content.
- Apple Music exposes `PreviewAsset` URLs through MusicKit, but the public iTunes Search API terms restrict previews to streaming promotional use and prohibit downloading or caching them.

The iOS client therefore does not scrape pages, bypass DRM, run `yt-dlp`, or treat provider playback as an audio file. A production backend must have its own authorization to access or transcribe the referenced recording.

Official references:

- [Spotify Web API changes](https://developer.spotify.com/blog/2024-11-27-changes-to-the-web-api)
- [Spotify track object and deprecated preview URL](https://developer.spotify.com/documentation/web-api/reference/get-track)
- [YouTube API developer policies](https://developers.google.com/youtube/terms/developer-policies)
- [Apple MusicKit Song](https://developer.apple.com/documentation/musickit/song)
- [Apple MusicKit PreviewAsset](https://developer.apple.com/documentation/musickit/previewasset)
- [Apple iTunes Search API terms](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/)

## Backend contract

Set `HarmonicaTranscriptionAPIURL` in the app target's Info properties to an HTTPS endpoint. The app makes a JSON `POST` request:

```json
{
  "sourceURL": "https://open.spotify.com/track/example",
  "provider": "spotify",
  "harmonicaKey": "C",
  "layout": "diatonicC"
}
```

The endpoint returns note events rather than source audio:

```json
{
  "title": "Example Song",
  "bpm": 96,
  "notes": [
    { "note": "C5", "duration": 0.5, "hole": "4B" },
    { "note": "D5", "duration": 0.5, "hole": "4D" }
  ]
}
```

Legacy note events remain supported. Optional `startTime` (seconds) allows gaps and simultaneous pitches; optional `sourceNotes` carries a detected pitch group such as `["C5", "E5", "G5"]`. Send one event per pitch group, or overlapping timed single-note events. The client estimates one transposition and register for the song, moves unavailable registers by octaves, and approximates remaining accidentals rather than dropping them. Chords become sequential single-hole arpeggios. All valid events are retained without the old 512-event cap or duration rounding. Nonfinite/nonpositive durations and invalid timestamps are ignored. Hole guidance is computed locally.

The client stores `sourceNotes`, `startTime`, and `sourceDuration` alongside the playable notes so source timing survives a slowed arpeggio. These fields are optional for old recordings. They describe estimated source evidence, not verified chord labels.

## Deployable Spotify implementation

`Backend/spotify-worker.mjs` is a Cloudflare Worker-compatible implementation of this contract. For Spotify developer applications that still have access to the deprecated Audio Analysis endpoint, it:

1. validates the shared URL and extracts a Spotify track ID;
2. obtains an app access token with client credentials kept on the worker;
3. requests official track metadata and Audio Analysis chroma segments;
4. filters low-confidence and quiet segments;
5. retains up to four strong pitch classes per segment, including accidentals, with original timing across the whole song;
6. returns estimated pitch-group events to the iOS app without downloading Spotify audio.

Chroma has no octave information. The worker assigns octave 5 as a practice register and returns pitch-class estimates; the iOS client performs the playable arrangement. This is not a verified transcription of individual instruments.

Copy `Backend/wrangler.toml.example` to `Backend/wrangler.toml`, then configure secrets:

```sh
wrangler secret put SPOTIFY_CLIENT_ID
wrangler secret put SPOTIFY_CLIENT_SECRET
wrangler secret put HARMONICA_API_TOKEN
wrangler deploy --config Backend/wrangler.toml
```

Set the deployed URL as `HarmonicaTranscriptionAPIURL` and set the same shared token as `HarmonicaTranscriptionAPIToken` in a development configuration. A production release should replace the shared app token with App Attest or another short-lived authorization exchange because values packaged in an iOS app can be recovered.

The worker returns `403` when the Spotify developer application is not eligible for Audio Analysis. YouTube and Apple Music still require a separately licensed implementation of the same JSON contract.

Authentication should be added by the backend deployment (for example, an app-attestation exchange that returns a short-lived bearer token). Do not embed a permanent provider or transcription-service secret in the iOS app.
