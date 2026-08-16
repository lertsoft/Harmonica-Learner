const NOTE_FOR_PITCH_CLASS = [
  ["C5", "4B"],
  ["C5", "4B"],
  ["D5", "4D"],
  ["E5", "5B"],
  ["E5", "5B"],
  ["F5", "5D"],
  ["G5", "6B"],
  ["G5", "6B"],
  ["A5", "6D"],
  ["A5", "6D"],
  ["B5", "7D"],
  ["B5", "7D"],
];

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

export function mapSpotifyAnalysisToNotes(analysis, maximumNotes = 512) {
  const runs = [];
  for (const segment of analysis?.segments ?? []) {
    const pitches = segment.pitches;
    if (!Array.isArray(pitches) || pitches.length !== 12) continue;
    if ((segment.confidence ?? 0) < 0.2 || (segment.loudness_max ?? -60) < -45) continue;

    let pitchClass = 0;
    for (let index = 1; index < pitches.length; index += 1) {
      if (pitches[index] > pitches[pitchClass]) pitchClass = index;
    }
    if (!Number.isFinite(pitches[pitchClass]) || pitches[pitchClass] < 0.35) continue;

    const [note, hole] = NOTE_FOR_PITCH_CLASS[pitchClass];
    const duration = Math.min(2, Math.max(0.1, Number(segment.duration) || 0.1));
    const last = runs.at(-1);
    if (last?.note === note && last.duration < 4) {
      last.duration = Math.min(4, last.duration + duration);
    } else {
      runs.push({ note, duration, hole });
    }
  }

  const stable = runs.filter((event) => event.duration >= 0.12);
  if (stable.length <= maximumNotes) return stable;
  const stride = stable.length / maximumNotes;
  return Array.from({ length: maximumNotes }, (_, index) => stable[Math.floor(index * stride)]);
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
