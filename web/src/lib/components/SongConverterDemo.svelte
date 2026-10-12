<script lang="ts">
	import { onDestroy } from "svelte";
	import { playHarmonicaSound, HARMONICA_C_MAP } from "./audio";

	interface Props {
		theme?: "dark" | "light";
	}

	let { theme = "dark" }: Props = $props();

	interface SongPreset {
		title: string;
		artist: string;
		key: string;
		tempo: string;
		tabs: Array<{
			hole: number;
			dir: "blow" | "draw";
			note: string;
			duration: number;
			lyric?: string;
		}>;
	}

	const PRESETS: SongPreset[] = [
		{
			title: "Never Gonna Give You Up",
			artist: "Rick Astley",
			key: "Key of C Diatonic",
			tempo: "113 BPM",
			tabs: [
				{
					hole: 4,
					dir: "draw",
					note: "D5",
					duration: 260,
					lyric: "Ne-",
				},
				{
					hole: 5,
					dir: "blow",
					note: "E5",
					duration: 260,
					lyric: "ver",
				},
				{
					hole: 6,
					dir: "blow",
					note: "G5",
					duration: 260,
					lyric: "gon-",
				},
				{
					hole: 5,
					dir: "blow",
					note: "E5",
					duration: 260,
					lyric: "na",
				},
				{
					hole: 7,
					dir: "draw",
					note: "B5",
					duration: 350,
					lyric: "give",
				},
				{
					hole: 7,
					dir: "draw",
					note: "B5",
					duration: 350,
					lyric: "you",
				},
				{
					hole: 6,
					dir: "draw",
					note: "A5",
					duration: 650,
					lyric: "up",
				},
				{
					hole: 4,
					dir: "draw",
					note: "D5",
					duration: 260,
					lyric: "Ne-",
				},
				{
					hole: 5,
					dir: "blow",
					note: "E5",
					duration: 260,
					lyric: "ver",
				},
				{
					hole: 6,
					dir: "blow",
					note: "G5",
					duration: 260,
					lyric: "gon-",
				},
				{
					hole: 5,
					dir: "blow",
					note: "E5",
					duration: 260,
					lyric: "na",
				},
				{
					hole: 6,
					dir: "draw",
					note: "A5",
					duration: 350,
					lyric: "let",
				},
				{
					hole: 6,
					dir: "draw",
					note: "A5",
					duration: 350,
					lyric: "you",
				},
				{
					hole: 6,
					dir: "blow",
					note: "G5",
					duration: 700,
					lyric: "down",
				},
			],
		},
		{
			title: "Piano Man (Intro Riff)",
			artist: "Billy Joel",
			key: "Key of C Diatonic",
			tempo: "176 BPM (3/4)",
			tabs: [
				{
					hole: 5,
					dir: "blow",
					note: "E5",
					duration: 300,
					lyric: "Sing",
				},
				{
					hole: 6,
					dir: "blow",
					note: "G5",
					duration: 300,
					lyric: "us",
				},
				{ hole: 6, dir: "draw", note: "A5", duration: 350, lyric: "a" },
				{
					hole: 7,
					dir: "blow",
					note: "C6",
					duration: 600,
					lyric: "song",
				},
				{
					hole: 6,
					dir: "draw",
					note: "A5",
					duration: 350,
					lyric: "you're",
				},
				{
					hole: 6,
					dir: "blow",
					note: "G5",
					duration: 500,
					lyric: "the",
				},
			],
		},
	];

	let selectedSong = $state<SongPreset>(PRESETS[0]);
	let playbackIndex = $state<number | null>(null);
	let playbackGeneration = 0;
	onDestroy(() => {
		playbackGeneration++;
	});
	function selectPreset(preset: SongPreset) {
		playbackGeneration++;
		selectedSong = preset;
		playbackIndex = null;
	}
	async function playTabSequence() {
		const generation = ++playbackGeneration;
		const tabs = selectedSong.tabs;
		for (let i = 0; i < tabs.length; i++) {
			if (generation !== playbackGeneration) return;
			playbackIndex = i;
			const item = tabs[i];
			const target = HARMONICA_C_MAP[item.hole][item.dir];
			playHarmonicaSound(target.freq, item.duration / 1000);
			await new Promise((r) => setTimeout(r, item.duration + 80));
		}
		if (generation === playbackGeneration) playbackIndex = null;
	}
</script>

<div class="converter-card" class:theme-light={theme === "light"}>
	<header>
		<div>
			<p class="badge">INTERACTIVE EXAMPLE</p>
			<h3>Hear a preset arrangement</h3>
		</div>
		<div class="presets" aria-label="Choose a sample arrangement">
			{#each PRESETS as preset}
				<button
					class:selected={selectedSong.title === preset.title}
					aria-pressed={selectedSong.title === preset.title}
					onclick={() => selectPreset(preset)}>{preset.title}</button
				>
			{/each}
		</div>
	</header>
	<p class="demo-note">Preset tabs and synthesized audio.</p>
	<div class="result-box">
		<div class="track-meta">
			<div>
				<strong>{selectedSong.title}</strong>
				<p>
					{selectedSong.artist} · {selectedSong.key} · {selectedSong.tempo}
				</p>
			</div>
			<button onclick={playTabSequence} disabled={playbackIndex !== null}
				>{playbackIndex !== null
					? "Playing example…"
					: "Hear example tabs"}</button
			>
		</div>
		<div class="tab-blocks-grid" aria-label="Sample harmonica tabs">
			{#each selectedSong.tabs as item, i}
				<div
					class="tab-pill"
					class:active={playbackIndex === i}
					class:draw={item.dir === "draw"}
				>
					<span>{item.dir === "blow" ? "↑ BLOW" : "↓ DRAW"}</span>
					<strong>{item.dir === "blow" ? "+" : "−"}{item.hole}</strong
					>
					<span>{item.note}</span>
				</div>
			{/each}
		</div>
		<p class="demo-note">Sample arrangement for a 10-hole C harmonica.</p>
	</div>
</div>

<style>
	.converter-card {
		padding: 28px;
		border: 1px solid #334155;
		border-radius: 24px;
		background: #13161f;
		color: #f8fafc;
	}
	header,
	.track-meta {
		display: flex;
		flex-wrap: wrap;
		gap: 20px;
		align-items: center;
		justify-content: space-between;
	}
	h3 {
		font-family: "Outfit", sans-serif;
		font-size: 24px;
		margin: 4px 0;
	}
	.badge {
		font-size: 11px;
		color: #93c5fd;
		font-weight: 700;
		letter-spacing: 0.08em;
		margin: 0;
	}
	.presets {
		display: flex;
		flex-wrap: wrap;
		gap: 8px;
	}
	button {
		background: #1e293b;
		color: inherit;
		border: 1px solid #475569;
		padding: 10px 14px;
		border-radius: 12px;
		cursor: pointer;
	}
	button.selected {
		border-color: #60a5fa;
		background: #1e3a5f;
	}
	button:disabled {
		cursor: default;
		opacity: 0.7;
	}
	.demo-note,
	.track-meta p {
		font-size: 13px;
		line-height: 1.6;
		color: #94a3b8;
	}
	.result-box {
		margin-top: 24px;
		padding: 20px;
		background: #0d111a;
		border-radius: 16px;
		min-height: 260px;
	}
	.track-meta p {
		margin: 4px 0;
	}
	.tab-blocks-grid {
		display: grid;
		grid-template-columns: repeat(8, minmax(0, 1fr));
		gap: 10px;
		margin-top: 24px;
	}
	.tab-pill {
		display: flex;
		flex-direction: column;
		text-align: center;
		gap: 8px;
		padding: 12px 4px;
		border: 1px solid #3b82f6;
		border-radius: 12px;
		color: #93c5fd;
	}
	.tab-pill.draw {
		color: #fbbf24;
		border-color: #b45309;
	}
	.tab-pill span {
		font-size: 10px;
	}
	.tab-pill strong {
		font:
			700 24px ui-monospace,
			monospace;
	}
	.tab-pill.active {
		background: #1e3a5f;
		box-shadow: 0 0 0 2px #60a5fa;
	}
	.theme-light {
		background: #fff;
		color: #1e293b;
		border-color: #cbd5e1;
	}
	.theme-light .result-box {
		background: #f1f5f9;
	}
	.theme-light button {
		background: #fff;
		border-color: #cbd5e1;
	}
	.theme-light button.selected,
	.theme-light .tab-pill.active {
		background: #dbeafe;
	}
	.theme-light .tab-pill {
		color: #1d4ed8;
	}
	.theme-light .tab-pill.draw {
		color: #92400e;
	}
	.theme-light .demo-note,
	.theme-light .track-meta p {
		color: #475569;
	}
	.theme-light .badge {
		color: #1d4ed8;
	}
	@media (max-width: 600px) {
		.converter-card {
			padding: 18px;
		}
		.result-box {
			padding: 14px;
		}
		.tab-blocks-grid {
			grid-template-columns: repeat(4, minmax(0, 1fr));
		}
	}
</style>
