const PITCH_NAMES = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
const NATURAL_HOLES = { C5: "4B", D5: "4D", E5: "5B", F5: "5D", G5: "6B", A5: "6D", B5: "7D" };

export function extractSpotifyTrackID(value) {
  let url;
  try {
    url = new URL(value);
  } catch {
    return null;
  }
  if (url.hostname !== "open.spotify.com") return null;
  const parts = url.pathname.split("/").filter(Boolean);
  const trackIndex = parts.indexOf("track");
  const id = trackIndex >= 0 ? parts[trackIndex + 1] : null;
  return id && /^[A-Za-z0-9]{10,32}$/.test(id) ? id : null;
}

// Chroma supplies pitch classes, not octave-resolved notes or verified chord labels.
// Retain strong classes and timing so the client can arrange them consistently.
export function mapSpotifyAnalysisToNotes(analysis) {
  const runs = [];
  let cursor = 0;
  for (const segment of analysis?.segments ?? []) {
    const duration = Number(segment.duration);
    if (!Number.isFinite(duration) || duration <= 0) continue;
    const startTime = Number.isFinite(segment.start) && segment.start >= 0 ? segment.start : cursor;
    cursor = startTime + duration;
    const pitches = segment.pitches;
    if (!Array.isArray(pitches) || pitches.length !== 12 || pitches.some((pitch) => !Number.isFinite(pitch))) continue;
    if ((segment.confidence ?? 0) < 0.2 || (segment.loudness_max ?? -60) < -45) continue;
    const strongest = Math.max(...pitches);
    if (strongest < 0.35) continue;
    const classes = pitches.map((strength, index) => ({ strength, index }))
      .filter(({ strength }) => strength >= Math.max(0.35, strongest * 0.55))
      .sort((a, b) => b.strength - a.strength).slice(0, 4)
      .map(({ index }) => index).sort((a, b) => a - b);
    const sourceNotes = classes.map((index) => `${PITCH_NAMES[index]}5`);
    if (!sourceNotes.length) continue;
    const note = sourceNotes[0];
    const last = runs.at(-1);
    if (last && last.sourceNotes.join(",") === sourceNotes.join(",")
        && Math.abs(last.startTime + last.duration - startTime) < 0.00001) {
      last.duration += duration;
    } else {
      runs.push({ note, duration, hole: NATURAL_HOLES[note] ?? "", startTime, sourceNotes });
    }
  }
  return runs;
}

async function spotifyToken(env) {
  if (!env.SPOTIFY_CLIENT_ID || !env.SPOTIFY_CLIENT_SECRET) {
    throw new Error("Spotify credentials are not configured");
  }
  const credentials = btoa(`${env.SPOTIFY_CLIENT_ID}:${env.SPOTIFY_CLIENT_SECRET}`);
  const response = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      Authorization: `Basic ${credentials}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: "grant_type=client_credentials",
  });
  if (!response.ok) throw new Error(`Spotify token request failed (${response.status})`);
  return (await response.json()).access_token;
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json; charset=utf-8" },
  });
}

export default {
  async fetch(request, env) {
    if (request.method !== "POST") return json({ error: "Method not allowed" }, 405);
    if (env.HARMONICA_API_TOKEN) {
      const supplied = request.headers.get("Authorization");
      if (supplied !== `Bearer ${env.HARMONICA_API_TOKEN}`) {
        return json({ error: "Unauthorized" }, 401);
      }
    }

    let payload;
    try {
      payload = await request.json();
    } catch {
      return json({ error: "Invalid JSON" }, 400);
    }
    if (payload.provider !== "spotify") {
      return json({ error: "This deployment only supports Spotify Audio Analysis" }, 422);
    }

    const trackID = extractSpotifyTrackID(payload.sourceURL);
    if (!trackID) return json({ error: "Invalid Spotify track URL" }, 400);

    try {
      const token = await spotifyToken(env);
      const headers = { Authorization: `Bearer ${token}` };
      const [trackResponse, analysisResponse] = await Promise.all([
        fetch(`https://api.spotify.com/v1/tracks/${trackID}`, { headers }),
        fetch(`https://api.spotify.com/v1/audio-analysis/${trackID}`, { headers }),
      ]);
      if (!trackResponse.ok || !analysisResponse.ok) {
        const status = analysisResponse.status === 403 ? 403 : 502;
        return json(
          {
            error: status === 403
              ? "This Spotify developer app does not have Audio Analysis access"
              : "Spotify could not analyze this track",
          },
          status,
        );
      }

      const [track, analysis] = await Promise.all([trackResponse.json(), analysisResponse.json()]);
      const notes = mapSpotifyAnalysisToNotes(analysis);
      if (!notes.length) return json({ error: "Spotify returned no stable pitches" }, 422);
      return json({
        title: `${track.name} — ${(track.artists ?? []).map((artist) => artist.name).join(", ")}`,
        bpm: Math.round(analysis.track?.tempo || 90),
        notes,
      });
    } catch (error) {
      return json({ error: error instanceof Error ? error.message : "Unexpected error" }, 500);
    }
  },
};
