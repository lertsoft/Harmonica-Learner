import test from "node:test";
import assert from "node:assert/strict";
import worker, { extractSpotifyTrackID, mapSpotifyAnalysisToNotes } from "./spotify-worker.mjs";

test("extractSpotifyTrackID accepts canonical track links", () => {
  assert.equal(
    extractSpotifyTrackID("https://open.spotify.com/track/11dFghVXANMlKmJXsNCbNl?si=abc"),
    "11dFghVXANMlKmJXsNCbNl",
  );
});

test("extractSpotifyTrackID rejects lookalike domains and non-track links", () => {
  assert.equal(extractSpotifyTrackID("https://open.spotify.com.evil.example/track/11dFghVXANMlKmJXsNCbNl"), null);
  assert.equal(extractSpotifyTrackID("https://open.spotify.com/album/11dFghVXANMlKmJXsNCbNl"), null);
});

test("mapSpotifyAnalysisToNotes maps chroma, filters noise, and merges runs", () => {
  const c = [0.9, 0.1, 0.1, 0.1, 0.2, 0.1, 0.1, 0.7, 0.1, 0.1, 0.1, 0.1];
  const d = [0.1, 0.1, 0.8, 0.1, 0.1, 0.1, 0.1, 0.2, 0.1, 0.1, 0.1, 0.1];
  const notes = mapSpotifyAnalysisToNotes({
    segments: [
      { duration: 0.3, confidence: 0.9, loudness_max: -10, pitches: c },
      { duration: 0.4, confidence: 0.9, loudness_max: -10, pitches: c },
      { duration: 0.3, confidence: 0.9, loudness_max: -10, pitches: d },
      { duration: 1, confidence: 0.1, loudness_max: -10, pitches: d },
    ],
  });
  assert.deepEqual(notes, [
    { note: "C5", duration: 0.7, hole: "4B" },
    { note: "D5", duration: 0.3, hole: "4D" },
  ]);
});

test("mapSpotifyAnalysisToNotes samples across an oversized result", () => {
  const segments = Array.from({ length: 20 }, (_, index) => {
    const pitches = Array(12).fill(0.05);
    pitches[index % 2 === 0 ? 0 : 2] = 0.9;
    return { duration: 0.2, confidence: 0.9, loudness_max: -8, pitches };
  });
  const notes = mapSpotifyAnalysisToNotes({ segments }, 4);
  assert.equal(notes.length, 4);
  assert.deepEqual(notes.map((note) => note.note), ["C5", "D5", "C5", "D5"]);
});

test("worker converts official Spotify responses into the iOS transcription contract", async () => {
  const originalFetch = globalThis.fetch;
  const pitches = [0.9, 0.1, 0.1, 0.1, 0.2, 0.1, 0.1, 0.7, 0.1, 0.1, 0.1, 0.1];
  globalThis.fetch = async (url) => {
    const value = String(url);
    if (value.includes("/api/token")) return Response.json({ access_token: "spotify-token" });
    if (value.includes("/v1/tracks/")) {
      return Response.json({ name: "Test Track", artists: [{ name: "Test Artist" }] });
    }
    if (value.includes("/v1/audio-analysis/")) {
      return Response.json({
        track: { tempo: 101.6 },
        segments: [{ duration: 0.5, confidence: 0.9, loudness_max: -8, pitches }],
      });
    }
    return new Response(null, { status: 404 });
  };

  try {
    const request = new Request("https://worker.example/transcribe", {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: "Bearer app-token" },
      body: JSON.stringify({
        sourceURL: "https://open.spotify.com/track/11dFghVXANMlKmJXsNCbNl",
        provider: "spotify",
        harmonicaKey: "C",
        layout: "diatonicC",
      }),
    });
    const response = await worker.fetch(request, {
      SPOTIFY_CLIENT_ID: "client",
      SPOTIFY_CLIENT_SECRET: "secret",
      HARMONICA_API_TOKEN: "app-token",
    });
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), {
      title: "Test Track — Test Artist",
      bpm: 102,
      notes: [{ note: "C5", duration: 0.5, hole: "4B" }],
    });
  } finally {
    globalThis.fetch = originalFetch;
  }
});
