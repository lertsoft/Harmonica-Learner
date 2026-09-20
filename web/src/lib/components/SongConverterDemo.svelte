<script lang="ts">
	import { playHarmonicaSound, HARMONICA_C_MAP } from "./audio";

	interface Props {
		theme?: "dark" | "light";
	}

	let { theme = "dark" }: Props = $props();

	interface SongPreset {
		title: string;
		artist: string;
		url: string;
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
			url: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
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
			url: "https://youtube.com/watch?v=gxEPV4kolz0",
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
	let inputUrl = $state(PRESETS[0].url);
	let isAnalyzing = $state(false);
	let playbackIndex = $state<number | null>(null);

	function selectPreset(preset: SongPreset) {
		selectedSong = preset;
		inputUrl = preset.url;
		triggerAnalysis();
	}

	function triggerAnalysis() {
		isAnalyzing = true;
		playbackIndex = null;

		const normalized = inputUrl.trim().toLowerCase();
		const matched = PRESETS.find(
			(p) =>
				p.url.toLowerCase() === normalized ||
				(p.url.includes("v=") &&
					normalized.includes(p.url.split("v=")[1])) ||
				(normalized.length > 5 &&
					p.url.toLowerCase().includes(normalized)) ||
				p.title.toLowerCase().includes(normalized) ||
				normalized.includes(p.artist.toLowerCase()),
		);
		if (matched) {
			selectedSong = matched;
		}

		setTimeout(() => {
			isAnalyzing = false;
		}, 850);
	}

	async function playTabSequence() {
		if (isAnalyzing) return;
		for (let i = 0; i < selectedSong.tabs.length; i++) {
			playbackIndex = i;
			const item = selectedSong.tabs[i];
			const holeData = HARMONICA_C_MAP[item.hole];
			const target = item.dir === "blow" ? holeData.blow : holeData.draw;
			playHarmonicaSound(target.freq, item.duration / 1000);
			await new Promise((r) => setTimeout(r, item.duration + 80));
		}
		playbackIndex = null;
	}
</script>

<div class="converter-card" class:theme-light={theme === "light"}>
	<div class="converter-header">
		<div>
			<div class="converter-badge">INSTANT MELODY CONVERTER</div>
			<div class="converter-title">Paste Any YouTube Song</div>
		</div>
		<div class="presets-row">
			{#each PRESETS as preset}
				<button
					class="preset-chip"
					class:selected={selectedSong.title === preset.title}
					onclick={() => selectPreset(preset)}
				>
					{preset.title}
				</button>
			{/each}
		</div>
	</div>

	<!-- Input Mockup -->
	<div class="input-bar-group">
		<div class="input-icon">
			<svg viewBox="0 0 24 24" fill="currentColor" class="media-icon">
				<path
					d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10 10-4.48 10-10S17.52 2 12 2zm-1 14.5v-9l6 4.5-6 4.5z"
				/>
			</svg>
		</div>
		<input
			type="text"
			bind:value={inputUrl}
			onkeydown={(e) => {
				if (e.key === "Enter") triggerAnalysis();
			}}
			placeholder="Paste Spotify or YouTube link here..."
			class="song-url-input"
		/>
		<button
			class="convert-btn"
			onclick={triggerAnalysis}
			disabled={isAnalyzing}
		>
			{#if isAnalyzing}
				<span class="spinner"></span> Extracting...
			{:else}
				Extract Tabs →
			{/if}
		</button>
	</div>

	<!-- Output Results Container -->
	<div class="result-box" class:loading={isAnalyzing}>
		{#if isAnalyzing}
			<div class="analyzing-state">
				<div class="wave-loader">
					<span></span><span></span><span></span><span></span><span
					></span>
				</div>
				<p>
					Separating lead vocal melody • Quantizing to Key of C
					diatonic reed map...
				</p>
			</div>
		{:else}
			<div class="result-details">
				<div class="track-meta">
					<div>
						<div class="track-title">{selectedSong.title}</div>
						<div class="track-artist">
							{selectedSong.artist} • {selectedSong.key} • {selectedSong.tempo}
						</div>
					</div>
					<button class="play-sequence-btn" onclick={playTabSequence}>
						<svg
							viewBox="0 0 24 24"
							fill="currentColor"
							class="play-triangle"
							><polygon points="5 3 19 12 5 21 5 3" /></svg
						>
						<span
							>{playbackIndex !== null
								? "Playing Sequence..."
								: "Play Harmonica Tabs"}</span
						>
					</button>
				</div>

				<!-- Tabs Visualization Row -->
				<div class="tab-blocks-grid">
					{#each selectedSong.tabs as item, i}
						<div
							class="tab-pill-box"
							class:active={playbackIndex === i}
							class:is-blow={item.dir === "blow"}
							class:is-draw={item.dir === "draw"}
						>
							<div class="direction-tag">
								{item.dir === "blow" ? "↑ BLOW" : "↓ DRAW"}
							</div>
							<div class="hole-num">
								{item.dir === "blow"
									? `+${item.hole}`
									: `-${item.hole}`}
							</div>
							<div class="note-name">{item.note}</div>
							{#if item.lyric}
								<div class="lyric-tag">{item.lyric}</div>
							{/if}
						</div>
					{/each}
				</div>

				<div class="conversion-summary">
					<span
						>✓ Extracted into 100% playable 10-hole Key of C
						diatonic tabs. Ready for Guided Practice.</span
					>
				</div>
			</div>
		{/if}
	</div>
</div>

<style>
	.converter-card {
		background: #11141b;
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 24px;
		padding: 24px;
		box-shadow: 0 20px 50px rgba(0, 0, 0, 0.5);
		display: flex;
		flex-direction: column;
		gap: 18px;
		width: 100%;
	}

	.converter-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-end;
		flex-wrap: wrap;
		gap: 16px;
	}

	.converter-badge {
		font-size: 10.5px;
		font-weight: 800;
		letter-spacing: 0.12em;
		color: #3b82f6;
		text-transform: uppercase;
	}

	.converter-title {
		font-size: 20px;
		font-weight: 800;
		color: #f8fafc;
		letter-spacing: -0.02em;
		margin-top: 2px;
	}

	.presets-row {
		display: flex;
		gap: 8px;
		flex-wrap: wrap;
	}

	.preset-chip {
		background: #1c202a;
		border: 1px solid rgba(255, 255, 255, 0.07);
		color: #94a3b8;
		padding: 6px 12px;
		border-radius: 99px;
		font-size: 12px;
		font-weight: 600;
		cursor: pointer;
		transition: all 0.15s ease;
	}

	.preset-chip:hover {
		color: #ffffff;
		border-color: rgba(255, 255, 255, 0.2);
	}

	.preset-chip.selected {
		background: #2563eb;
		color: #ffffff;
		border-color: #3b82f6;
	}

	.input-bar-group {
		display: flex;
		align-items: center;
		background: #181c25;
		border: 1px solid rgba(255, 255, 255, 0.1);
		border-radius: 14px;
		padding: 6px 8px 6px 14px;
		gap: 12px;
	}

	.input-icon {
		color: #64748b;
		display: flex;
		align-items: center;
	}

	.media-icon {
		width: 20px;
		height: 20px;
	}

	.song-url-input {
		flex: 1;
		background: transparent;
		border: none;
		color: #ffffff;
		font-size: 14px;
		outline: none;
		font-family: inherit;
	}

	.song-url-input::placeholder {
		color: #64748b;
	}

	.convert-btn {
		background: #3b82f6;
		color: #ffffff;
		border: none;
		border-radius: 10px;
		padding: 10px 18px;
		font-size: 13px;
		font-weight: 700;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 8px;
		transition: background 0.15s ease;
	}

	.convert-btn:hover {
		background: #2563eb;
	}

	.spinner {
		width: 14px;
		height: 14px;
		border: 2px solid rgba(255, 255, 255, 0.3);
		border-top-color: #ffffff;
		border-radius: 50%;
		animation: spin 0.6s linear infinite;
	}

	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}

	.result-box {
		background: #151821;
		border: 1px solid rgba(255, 255, 255, 0.06);
		border-radius: 18px;
		padding: 18px;
		min-height: 150px;
	}

	.analyzing-state {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		height: 120px;
		gap: 12px;
		color: #94a3b8;
		font-size: 13px;
	}

	.wave-loader {
		display: flex;
		gap: 5px;
		align-items: center;
		height: 24px;
	}

	.wave-loader span {
		width: 4px;
		height: 10px;
		background: #3b82f6;
		border-radius: 2px;
		animation: bounce 0.8s ease-in-out infinite alternate;
	}

	.wave-loader span:nth-child(2) {
		animation-delay: 0.15s;
	}
	.wave-loader span:nth-child(3) {
		animation-delay: 0.3s;
	}
	.wave-loader span:nth-child(4) {
		animation-delay: 0.45s;
	}
	.wave-loader span:nth-child(5) {
		animation-delay: 0.6s;
	}

	@keyframes bounce {
		to {
			height: 24px;
			background: #60a5fa;
		}
	}

	.result-details {
		display: flex;
		flex-direction: column;
		gap: 14px;
	}

	.track-meta {
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 12px;
	}

	.track-title {
		font-size: 16px;
		font-weight: 800;
		color: #ffffff;
	}

	.track-artist {
		font-size: 12px;
		color: #8b95a8;
		margin-top: 2px;
	}

	.play-sequence-btn {
		display: flex;
		align-items: center;
		gap: 8px;
		background: #232836;
		border: 1px solid rgba(255, 255, 255, 0.08);
		color: #e2e8f0;
		padding: 8px 16px;
		border-radius: 10px;
		font-size: 12px;
		font-weight: 700;
		cursor: pointer;
		transition: all 0.15s ease;
	}

	.play-sequence-btn:hover {
		background: #2d3445;
		color: #ffffff;
	}

	.play-triangle {
		width: 14px;
		height: 14px;
		color: #3b82f6;
	}

	.tab-blocks-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(84px, 1fr));
		gap: 8px;
	}

	.tab-pill-box {
		background: #1c212d;
		border: 1px solid rgba(255, 255, 255, 0.06);
		border-radius: 12px;
		padding: 10px 8px;
		text-align: center;
		display: flex;
		flex-direction: column;
		gap: 3px;
		transition: all 0.15s ease;
	}

	.tab-pill-box.active {
		border-color: #3b82f6;
		background: rgba(59, 130, 246, 0.2);
		transform: translateY(-2px);
		box-shadow: 0 0 15px rgba(59, 130, 246, 0.4);
	}

	.direction-tag {
		font-size: 9px;
		font-weight: 800;
		letter-spacing: 0.08em;
	}

	.is-blow .direction-tag {
		color: #3b82f6;
	}

	.is-draw .direction-tag {
		color: #60a5fa;
	}

	.hole-num {
		font-size: 18px;
		font-weight: 900;
		color: #ffffff;
	}

	.note-name {
		font-size: 10px;
		color: #94a3b8;
		font-family: "JetBrains Mono", monospace;
	}

	.lyric-tag {
		font-size: 11px;
		font-weight: 700;
		color: #cbd5e1;
		margin-top: 1px;
	}

	.tab-pill-box.active .lyric-tag {
		color: #ffffff;
		font-weight: 800;
	}

	.theme-light .lyric-tag {
		color: #475569;
	}

	.theme-light .tab-pill-box.active .lyric-tag {
		color: #1d4ed8;
	}

	.conversion-summary {
		font-size: 11.5px;
		color: #10b981;
		font-weight: 600;
	}

	/* Light Mode Styles */
	.converter-card.theme-light {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		box-shadow: 0 10px 30px rgba(0, 0, 0, 0.04);
		color: #0f172a;
	}
	.theme-light .converter-title {
		color: #0f172a;
	}
	.theme-light .preset-chip {
		background: #f1f5f9;
		border-color: rgba(0, 0, 0, 0.06);
		color: #475569;
	}
	.theme-light .preset-chip.selected {
		background: #3b82f6;
		color: #ffffff;
	}
	.theme-light .input-bar-group {
		background: #f8fafc;
		border-color: rgba(0, 0, 0, 0.08);
	}
	.theme-light .song-url-input {
		color: #0f172a;
	}
	.theme-light .result-box {
		background: #f8fafc;
		border-color: rgba(0, 0, 0, 0.06);
	}
	.theme-light .track-title {
		color: #0f172a;
	}
	.theme-light .track-artist {
		color: #64748b;
	}
	.theme-light .play-sequence-btn {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		color: #0f172a;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
	}
	.theme-light .tab-pill-box {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.03);
	}
	.theme-light .hole-num {
		color: #0f172a;
	}
</style>
