import test from "node:test";
import assert from "node:assert/strict";
import worker from "./spotify-worker.mjs";

const trackURL = "https://open.spotify.com/track/11dFghVXANMlKmJXsNCbNl?si=abc";
const env = {
  SPOTIFY_CLIENT_ID: "client",
  SPOTIFY_CLIENT_SECRET: "secret",
  HARMONICA_API_TOKEN: "app-token",
};

function request(sourceURL = trackURL, options = {}) {
  return new Request("https://worker.example/transcribe", {
    method: options.method ?? "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: options.authorization ?? "Bearer app-token",
    },
    body: (options.method ?? "POST") === "POST"
      ? JSON.stringify({ sourceURL, provider: options.provider ?? "spotify", harmonicaKey: "C", layout: "diatonicC" })
      : undefined,
  });
}

test("transcription request returns the iOS song contract from Spotify responses", async () => {
  const originalFetch = globalThis.fetch;
  const c = [0.9, 0.1, 0.1, 0.1, 0.2, 0.1, 0.1, 0.7, 0.1, 0.1, 0.1, 0.1];
  const d = [0.1, 0.1, 0.8, 0.1, 0.1, 0.1, 0.2, 0.1, 0.1, 0.1, 0.1, 0.1];
  globalThis.fetch = async (url) => {
    const value = String(url);
    if (value.includes("/api/token")) return Response.json({ access_token: "spotify-token" });
    if (value.includes("/v1/tracks/")) {
      return Response.json({ name: "Test Track", artists: [{ name: "Test Artist" }] });
    }
    if (value.includes("/v1/audio-analysis/")) {
      return Response.json({
        track: { tempo: 101.6 },
        segments: [
          { duration: 0.3, confidence: 0.9, loudness_max: -10, pitches: c },
          { duration: 0.4, confidence: 0.9, loudness_max: -10, pitches: c },
          { duration: 0.3, confidence: 0.9, loudness_max: -10, pitches: d },
          { duration: 1, confidence: 0.1, loudness_max: -10, pitches: d },
        ],
      });
    }
    return new Response(null, { status: 404 });
  };

  try {
    const response = await worker.fetch(request(), env);
    assert.equal(response.status, 200);
    assert.deepEqual(await response.json(), {
      title: "Test Track — Test Artist",
      bpm: 102,
      notes: [
        { note: "C5", duration: 0.7, hole: "4B" },
        { note: "D5", duration: 0.3, hole: "4D" },
      ],
    });
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("request boundary rejects unauthorized, unsupported, and misleading links before contacting Spotify", async () => {
  const originalFetch = globalThis.fetch;
  let fetchCount = 0;
  globalThis.fetch = async () => {
    fetchCount += 1;
    throw new Error("Spotify should not be contacted");
  };

  try {
    const cases = [
      [request(trackURL, { method: "GET" }), 405],
      [request(trackURL, { authorization: "Bearer wrong-token" }), 401],
      [request(trackURL, { provider: "youtube" }), 422],
      [request("https://open.spotify.com.evil.example/track/11dFghVXANMlKmJXsNCbNl"), 400],
      [request("https://open.spotify.com/album/11dFghVXANMlKmJXsNCbNl"), 400],
    ];
    for (const [incoming, status] of cases) {
      const response = await worker.fetch(incoming, env);
      assert.equal(response.status, status);
      assert.ok((await response.json()).error);
    }
    assert.equal(fetchCount, 0);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("Spotify analysis denial is returned to the app as a 403 response", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url) => {
    const value = String(url);
    if (value.includes("/api/token")) return Response.json({ access_token: "spotify-token" });
    if (value.includes("/v1/tracks/")) return Response.json({ name: "Test Track" });
    return new Response(null, { status: 403 });
  };

  try {
    const response = await worker.fetch(request(), env);
    assert.equal(response.status, 403);
    assert.match((await response.json()).error, /Audio Analysis access/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("oversized Spotify analysis stays within the app's note limit", async () => {
  const originalFetch = globalThis.fetch;
  const segments = Array.from({ length: 1536 }, (_, index) => {
    const pitches = Array(12).fill(0.05);
    pitches[index % 2 === 0 ? 0 : 2] = 0.9;
    return { duration: 0.2, confidence: 0.9, loudness_max: -8, pitches };
  });
  globalThis.fetch = async (url) => {
    const value = String(url);
    if (value.includes("/api/token")) return Response.json({ access_token: "spotify-token" });
    if (value.includes("/v1/tracks/")) return Response.json({ name: "Long Track", artists: [] });
    return Response.json({ track: { tempo: 90 }, segments });
  };

  try {
    const response = await worker.fetch(request(), env);
    assert.equal(response.status, 200);
    const song = await response.json();
    assert.equal(song.notes.length, 512);
    assert.deepEqual(song.notes.slice(0, 4).map((note) => note.note), ["C5", "D5", "C5", "D5"]);
  } finally {
    globalThis.fetch = originalFetch;
  }
});

test("a Spotify response with no stable pitches returns an actionable error", async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url) => {
    const value = String(url);
    if (value.includes("/api/token")) return Response.json({ access_token: "spotify-token" });
    if (value.includes("/v1/tracks/")) return Response.json({ name: "Silent Track", artists: [] });
    return Response.json({ track: { tempo: 90 }, segments: [] });
  };

  try {
    const response = await worker.fetch(request(), env);
    assert.equal(response.status, 422);
    assert.match((await response.json()).error, /no stable pitches/);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
