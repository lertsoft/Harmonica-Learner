<script lang="ts">
	import { playHarmonicaSound, playNoteByHole, HARMONICA_C_MAP } from './audio';

	interface Props {
		mode?: 'guided' | 'freestyle';
		interactive?: boolean;
		scale?: number;
		theme?: 'dark' | 'light';
	}

	let { mode = 'guided', interactive = true, scale = 1, theme = 'dark' }: Props = $props();

	let activeMode = $state<'guided' | 'freestyle'>('guided');

	$effect(() => {
		activeMode = mode;
	});

	let isPlaying = $state(false);
	let isListening = $state(true);

	// Guided mode state
	const guidedSequence = [
		{ hole: 4, dir: 'blow' as const, note: 'C5', label: '+4 Blow', sub: '↑ BLOW OUT' },
		{ hole: 4, dir: 'draw' as const, note: 'D5', label: '-4 Draw', sub: '↓ DRAW IN' },
		{ hole: 5, dir: 'blow' as const, note: 'E5', label: '+5 Blow', sub: '↑ BLOW OUT' },
		{ hole: 5, dir: 'draw' as const, note: 'F5', label: '-5 Draw', sub: '↓ DRAW IN' },
		{ hole: 6, dir: 'blow' as const, note: 'G5', label: '+6 Blow', sub: '↑ BLOW OUT' },
		{ hole: 6, dir: 'draw' as const, note: 'A5', label: '-6 Draw', sub: '↓ DRAW IN' },
		{ hole: 7, dir: 'draw' as const, note: 'B5', label: '-7 Draw', sub: '↓ DRAW IN' },
		{ hole: 7, dir: 'blow' as const, note: 'C6', label: '+7 Blow', sub: '↑ BLOW OUT' }
	];

	let currentIndex = $state(0);
	let currentStep = $derived(guidedSequence[currentIndex]);
	let progressPercent = $derived(((currentIndex + 1) / guidedSequence.length) * 100);

	// Freestyle tuner state
	let freestyleDetecting = $state(false);
	let freestyleCents = $state(3);
	let detectedNote = $state('C5');

	function handleHoleClick(hole: number) {
		if (!interactive) return;
		const dir = currentStep.dir;
		playNoteByHole(hole, dir);
	}

	function playCurrentStepSound() {
		const target = HARMONICA_C_MAP[currentStep.hole];
		const noteData = currentStep.dir === 'blow' ? target.blow : target.draw;
		isPlaying = true;
		playHarmonicaSound(noteData.freq, 0.7);
		setTimeout(() => {
			isPlaying = false;
		}, 700);
	}

	function nextStep() {
		currentIndex = (currentIndex + 1) % guidedSequence.length;
		playCurrentStepSound();
	}

	function prevStep() {
		currentIndex = (currentIndex - 1 + guidedSequence.length) % guidedSequence.length;
		playCurrentStepSound();
	}

	function togglePractice() {
		if (isPlaying) {
			isPlaying = false;
		} else {
			playCurrentStepSound();
		}
	}

	function toggleFreestyleRecord() {
		freestyleDetecting = !freestyleDetecting;
		if (freestyleDetecting) {
			playHarmonicaSound(523.25, 0.5);
			detectedNote = 'C5';
			freestyleCents = 1;
		}
	}
</script>

<div class="mockup-wrapper" style="--scale: {scale}">
	<div class="iphone-frame" class:theme-light={theme === 'light'}>
		<!-- Screen Glass Glow / Reflection -->
		<div class="glass-reflection" aria-hidden="true"></div>

		<!-- Titanium Hardware Accents -->
		<div class="dynamic-island" aria-hidden="true">
			<div class="camera-lens"></div>
		</div>

		<!-- Status Bar -->
		<div class="status-bar" aria-hidden="true">
			<span class="time">12:45</span>
			<div class="status-icons">
				<svg class="icon" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3c-4.97 0-9 4.03-9 9 0 2.12.74 4.07 1.97 5.61L4.35 19.4c-.39.39-.39 1.02 0 1.41.39.39 1.02.39 1.41 0l1.9-1.9C9.28 19.58 10.59 20 12 20c4.97 0 9-4.03 9-9s-4.03-9-9-9z"/></svg>
				<span class="battery"><b>63</b></span>
			</div>
		</div>

		<!-- App Content Area (Exact Replica of Screenshots) -->
		<div class="app-screen">
			<!-- Header -->
			<div class="app-header">
				<div>
					<div class="app-title">Harmonica Practice</div>
					<div class="app-subtitle">Listen • Match • Move</div>
				</div>
				<div class="header-actions">
					<button class="icon-circle-btn" aria-label="Library">
						<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20"/><path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z"/></svg>
					</button>
					<button class="icon-circle-btn" aria-label="Settings">
						<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="4" y1="21" x2="4" y2="14"/><line x1="4" y1="10" x2="4" y2="3"/><line x1="12" y1="21" x2="12" y2="12"/><line x1="12" y1="8" x2="12" y2="3"/><line x1="20" y1="21" x2="20" y2="16"/><line x1="20" y1="12" x2="20" y2="3"/><line x1="1" y1="14" x2="7" y2="14"/><line x1="9" y1="8" x2="15" y2="8"/><line x1="17" y1="16" x2="23" y2="16"/></svg>
					</button>
				</div>
			</div>

			<!-- Segmented Control: Guided vs Freestyle -->
			<div class="segmented-control" role="tablist">
				<button
					class="segment"
					class:active={activeMode === 'guided'}
					onclick={() => (activeMode = 'guided')}
					role="tab"
					aria-selected={activeMode === 'guided'}
				>
					Guided
				</button>
				<button
					class="segment"
					class:active={activeMode === 'freestyle'}
					onclick={() => (activeMode = 'freestyle')}
					role="tab"
					aria-selected={activeMode === 'freestyle'}
				>
					Freestyle
				</button>
			</div>

			<!-- Mode Content -->
			{#if activeMode === 'guided'}
				<!-- Guided Practice View -->
				<div class="card song-pill-card">
					<div class="card-caption">Song</div>
					<div class="song-name">C Major Scale</div>
				</div>

				<!-- Main Play Card -->
				<div class="card play-card">
					<div class="play-label">PLAY</div>

					<div class="play-hero-row">
						<button class="round-control" onclick={prevStep} aria-label="Restart note">
							<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><path d="M1 4v6h6"/><path d="M3.51 15a9 9 0 1 0 2.13-9.36L1 10"/></svg>
						</button>

						<div class="hero-note-display" class:pulse-hit={isPlaying}>
							<div class="note-main-text">{currentStep.label}</div>
							<div class="note-pitch-text">Concert pitch {currentStep.note}</div>
						</div>

						<button class="round-control" onclick={nextStep} aria-label="Next note">
							<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"><polygon points="5 4 15 12 5 20 5 4"/><line x1="19" y1="5" x2="19" y2="19"/></svg>
						</button>
					</div>

					<!-- 10-Hole Harmonica Visualizer Strip -->
					<div class="harmonica-strip">
						<div class="hole-indicators">
							{#each [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as hole}
								<div class="indicator-col">
									<div class="dot-marker"></div>
									{#if hole === currentStep.hole}
										<div class="arrow-cue" class:draw={currentStep.dir === 'draw'}>
											{currentStep.dir === 'blow' ? '↑' : '↓'}
										</div>
									{:else}
										<div class="arrow-cue spacer"></div>
									{/if}
									<button
										class="hole-btn"
										class:active={hole === currentStep.hole}
										onclick={() => handleHoleClick(hole)}
										aria-label="Hole {hole}"
									>
										{hole}
									</button>
								</div>
							{/each}
						</div>
						<div class="airflow-text" class:draw={currentStep.dir === 'draw'}>
							{currentStep.sub}
						</div>
					</div>

					<!-- Microphone Status Inner Card -->
					<div class="mic-status-row">
						<div class="mic-info">
							<div class="mic-headline">
								{#if isListening}
									<span class="active-dot"></span> Listening in real time
								{:else}
									Microphone off
								{/if}
							</div>
							<div class="mic-sub">
								{isListening ? 'Play note on your harmonica' : 'Start practice when you’re ready.'}
							</div>
						</div>
						<button
							class="speaker-btn"
							onclick={() => (isListening = !isListening)}
							aria-label="Audio feedback"
						>
							<svg viewBox="0 0 24 24" fill="currentColor">
								<path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/>
							</svg>
						</button>
					</div>
				</div>

				<!-- Note Progression Card -->
				<div class="card queue-card">
					<div class="queue-header">
						<span class="queue-title">C Major Scale</span>
						<span class="queue-step">{currentIndex + 1}/{guidedSequence.length}</span>
					</div>
					<div class="queue-pills-row">
						{#each guidedSequence as item, i}
							<button
								class="queue-chip"
								class:active={i === currentIndex}
								class:passed={i < currentIndex}
								onclick={() => {
									currentIndex = i;
									playCurrentStepSound();
								}}
							>
								<span class="chip-tab">{item.dir === 'blow' ? `+${item.hole}` : `-${item.hole}`}</span>
								<span class="chip-note">{item.note}</span>
							</button>
						{/each}
					</div>
					<!-- Progress Track -->
					<div class="progress-bar-track">
						<div class="progress-bar-fill" style="width: {progressPercent}%"></div>
					</div>
				</div>

				<!-- Sticky Bottom Action Bar -->
				<div class="bottom-action-dock">
					<button class="primary-blue-btn" onclick={togglePractice}>
						<svg class="btn-icon" viewBox="0 0 24 24" fill="currentColor">
							<path d="M12 14c1.66 0 3-1.34 3-3V5c0-1.66-1.34-3-3-3S9 3.34 9 5v6c0 1.66 1.34 3 3 3z"/>
							<path d="M17 11c0 2.76-2.24 5-5 5s-5-2.24-5-5H5c0 3.53 2.61 6.43 6 6.92V21h2v-3.08c3.39-.49 6-3.39 6-6.92h-2z"/>
						</svg>
						<span>{isPlaying ? 'Playing Note...' : 'Start Practice'}</span>
					</button>
					<button class="secondary-btn" aria-label="Tabs song sheet">
						<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2"><path d="M9 18V5l12-2v13"/><circle cx="6" cy="18" r="3"/><circle cx="18" cy="16" r="3"/></svg>
					</button>
				</div>
			{:else}
				<!-- Freestyle Mode View (Exact Replica of Screenshot 2 & 3) -->
				<div class="card song-pill-card">
					<div class="card-caption">Free play</div>
					<div class="song-name">Capture a new idea</div>
				</div>

				<!-- Freestyle Pitch & Tuner Card -->
				<div class="card freestyle-card">
					<div class="tuner-top-row">
						<span class="status-badge" class:detecting={freestyleDetecting}>
							<span class="dot">●</span> {freestyleDetecting ? 'Recording' : 'Ready'}
						</span>
						<span class="timer-display">{freestyleDetecting ? '00:14' : '00:00'}</span>
					</div>

					<div class="detected-label">Detected</div>
					<div class="detected-main-row">
						<span class="detected-pitch">{freestyleDetecting ? detectedNote : '--'}</span>
						<span class="detected-cents" class:in-tune={freestyleDetecting && Math.abs(freestyleCents) < 5}>
							{freestyleDetecting ? `+${freestyleCents}¢ In tune` : '--¢ No signal'}
						</span>
					</div>

					<!-- Tuner Gauge Bar with center notch -->
					<div class="tuner-slider-track">
						<div class="tuner-center-mark"></div>
						<div
							class="tuner-thumb-dot"
							style="left: {freestyleDetecting ? 50 + freestyleCents * 2 : 50}%"
						></div>
					</div>

					<div class="freestyle-guidance">
						{freestyleDetecting ? 'Listening to audio signal via microphone.' : 'Start recording when you’re ready to capture notes and audio.'}
					</div>
				</div>

				<!-- Freestyle Bottom Action Bar -->
				<div class="bottom-action-dock">
					<button
						class="primary-blue-btn record-style"
						class:is-rec={freestyleDetecting}
						onclick={toggleFreestyleRecord}
					>
						<span class="record-dot"></span>
						<span>{freestyleDetecting ? 'Stop Recording' : 'Record Freestyle'}</span>
					</button>
				</div>
			{/if}

			<!-- Home Bar Indicator -->
			<div class="home-indicator" aria-hidden="true"></div>
		</div>
	</div>
</div>

<style>
	.mockup-wrapper {
		display: inline-flex;
		justify-content: center;
		transform: scale(var(--scale, 1));
		transform-origin: center top;
	}

	.iphone-frame {
		width: 320px;
		height: 680px;
		background: #090b0e;
		border-radius: 46px;
		border: 11px solid #1c212a;
		box-shadow:
			0 0 0 1px rgba(255, 255, 255, 0.12),
			0 30px 80px -10px rgba(0, 0, 0, 0.85),
			0 12px 30px rgba(0, 0, 0, 0.6);
		position: relative;
		overflow: hidden;
		user-select: none;
		display: flex;
		flex-direction: column;
		font-family: 'Inter', -apple-system, BlinkMacSystemFont, system-ui, sans-serif;
	}

	.glass-reflection {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		height: 240px;
		background: linear-gradient(135deg, rgba(255, 255, 255, 0.07) 0%, rgba(255, 255, 255, 0) 60%);
		pointer-events: none;
		z-index: 10;
	}

	.dynamic-island {
		position: absolute;
		top: 10px;
		left: 50%;
		transform: translateX(-50%);
		width: 90px;
		height: 25px;
		background: #000;
		border-radius: 20px;
		z-index: 30;
		display: flex;
		align-items: center;
		justify-content: flex-end;
		padding-right: 12px;
	}

	.camera-lens {
		width: 9px;
		height: 9px;
		border-radius: 50%;
		background: radial-gradient(circle, #101c38 30%, #050811 80%);
		border: 1px solid rgba(255, 255, 255, 0.15);
	}

	.status-bar {
		height: 44px;
		padding: 12px 22px 0;
		display: flex;
		justify-content: space-between;
		align-items: center;
		color: #ffffff;
		font-size: 13px;
		font-weight: 600;
		z-index: 20;
	}

	.status-icons {
		display: flex;
		align-items: center;
		gap: 6px;
	}

	.icon {
		width: 14px;
		height: 14px;
	}

	.battery {
		background: rgba(255, 255, 255, 0.2);
		padding: 1px 5px;
		border-radius: 4px;
		font-size: 10px;
	}

	.app-screen {
		flex: 1;
		background: #111317;
		padding: 6px 14px 14px;
		display: flex;
		flex-direction: column;
		gap: 10px;
		color: #fff;
		overflow: hidden;
		position: relative;
	}

	/* App Header */
	.app-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 2px 2px 0;
	}

	.app-title {
		font-size: 18px;
		font-weight: 800;
		letter-spacing: -0.02em;
		color: #f3f4f6;
	}

	.app-subtitle {
		font-size: 11px;
		color: #838a99;
		margin-top: 1px;
	}

	.header-actions {
		display: flex;
		gap: 8px;
	}

	.icon-circle-btn {
		width: 32px;
		height: 32px;
		border-radius: 50%;
		background: #242831;
		border: 1px solid rgba(255, 255, 255, 0.08);
		color: #cdd3df;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		padding: 7px;
	}

	/* Segmented Control */
	.segmented-control {
		display: grid;
		grid-template-columns: 1fr 1fr;
		background: #1c2027;
		padding: 3px;
		border-radius: 12px;
		border: 1px solid rgba(255, 255, 255, 0.05);
	}

	.segment {
		background: transparent;
		border: none;
		color: #9098a8;
		font-size: 12px;
		font-weight: 600;
		padding: 6px 0;
		border-radius: 9px;
		cursor: pointer;
		transition: all 0.2s ease;
	}

	.segment.active {
		background: #474f5d;
		color: #ffffff;
		box-shadow: 0 2px 6px rgba(0, 0, 0, 0.35);
	}

	/* Card common */
	.card {
		background: #1b1e25;
		border-radius: 16px;
		border: 1px solid rgba(255, 255, 255, 0.07);
		padding: 10px 12px;
	}

	.song-pill-card {
		padding: 8px 12px;
	}

	.card-caption {
		font-size: 9px;
		color: #7b8394;
		text-transform: uppercase;
		letter-spacing: 0.06em;
		font-weight: 600;
	}

	.song-name {
		font-size: 13px;
		font-weight: 700;
		color: #f3f5f8;
		margin-top: 1px;
	}

	/* Play Card */
	.play-card {
		padding: 12px 10px;
		display: flex;
		flex-direction: column;
		gap: 8px;
		background: #1c2027;
	}

	.play-label {
		text-align: center;
		font-size: 9px;
		color: #7c8597;
		letter-spacing: 0.14em;
		font-weight: 700;
	}

	.play-hero-row {
		display: flex;
		justify-content: space-between;
		align-items: center;
		padding: 0 4px;
	}

	.round-control {
		width: 32px;
		height: 32px;
		border-radius: 50%;
		background: #272d37;
		border: 1px solid rgba(255, 255, 255, 0.09);
		color: #a0aab9;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		padding: 8px;
	}

	.hero-note-display {
		text-align: center;
		transition: transform 0.15s ease;
	}

	.hero-note-display.pulse-hit {
		transform: scale(1.08);
	}

	.note-main-text {
		font-size: 28px;
		font-weight: 900;
		color: #ffffff;
		letter-spacing: -0.03em;
		line-height: 1;
	}

	.note-pitch-text {
		font-size: 10px;
		color: #8c95a6;
		margin-top: 3px;
	}

	/* Harmonica Strip */
	.harmonica-strip {
		background: #15181f;
		border-radius: 12px;
		padding: 8px 6px 6px;
		border: 1px solid rgba(255, 255, 255, 0.04);
	}

	.hole-indicators {
		display: grid;
		grid-template-columns: repeat(10, 1fr);
		gap: 2px;
		align-items: end;
	}

	.indicator-col {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 2px;
	}

	.dot-marker {
		width: 3px;
		height: 3px;
		border-radius: 50%;
		background: #505869;
	}

	.arrow-cue {
		font-size: 11px;
		font-weight: 900;
		color: #3b82f6;
		line-height: 1;
		height: 12px;
	}

	.arrow-cue.draw {
		color: #60a5fa;
	}

	.arrow-cue.spacer {
		visibility: hidden;
	}

	.hole-btn {
		width: 100%;
		height: 24px;
		border-radius: 5px;
		background: #242934;
		border: 1px solid rgba(255, 255, 255, 0.05);
		color: #929bb0;
		font-size: 10px;
		font-weight: 700;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		padding: 0;
	}

	.hole-btn.active {
		background: #3b82f6;
		color: #ffffff;
		box-shadow: 0 0 10px rgba(59, 130, 246, 0.45);
	}

	.airflow-text {
		text-align: center;
		font-size: 9px;
		font-weight: 800;
		color: #3b82f6;
		letter-spacing: 0.08em;
		margin-top: 5px;
	}

	.airflow-text.draw {
		color: #60a5fa;
	}

	/* Mic status */
	.mic-status-row {
		display: flex;
		justify-content: space-between;
		align-items: center;
		background: #222631;
		border-radius: 10px;
		padding: 6px 10px;
	}

	.mic-headline {
		font-size: 11px;
		font-weight: 700;
		color: #e5e7eb;
		display: flex;
		align-items: center;
		gap: 6px;
	}

	.active-dot {
		width: 6px;
		height: 6px;
		border-radius: 50%;
		background: #10b981;
		box-shadow: 0 0 8px #10b981;
	}

	.mic-sub {
		font-size: 9px;
		color: #7e8799;
	}

	.speaker-btn {
		width: 26px;
		height: 26px;
		border-radius: 50%;
		background: #2f3645;
		border: none;
		color: #a3adc2;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		padding: 5px;
	}

	/* Queue Card */
	.queue-card {
		padding: 8px 10px;
		display: flex;
		flex-direction: column;
		gap: 6px;
	}

	.queue-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		font-size: 11px;
	}

	.queue-title {
		font-weight: 700;
		color: #e2e5eb;
	}

	.queue-step {
		color: #7b8599;
		font-size: 10px;
	}

	.queue-pills-row {
		display: flex;
		gap: 6px;
		overflow-x: auto;
		padding-bottom: 2px;
	}

	.queue-pills-row::-webkit-scrollbar {
		display: none;
	}

	.queue-chip {
		min-width: 44px;
		height: 38px;
		border-radius: 8px;
		background: #232833;
		border: 1px solid rgba(255, 255, 255, 0.06);
		color: #a3acc2;
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		padding: 2px 4px;
	}

	.queue-chip.active {
		border-color: #3b82f6;
		background: rgba(59, 130, 246, 0.18);
		color: #ffffff;
		box-shadow: 0 0 10px rgba(59, 130, 246, 0.25);
	}

	.queue-chip.passed {
		opacity: 0.5;
	}

	.chip-tab {
		font-size: 11px;
		font-weight: 800;
	}

	.chip-note {
		font-size: 8px;
		opacity: 0.75;
	}

	.progress-bar-track {
		height: 3px;
		background: #242934;
		border-radius: 2px;
		overflow: hidden;
	}

	.progress-bar-fill {
		height: 100%;
		background: #3b82f6;
		transition: width 0.3s ease;
	}

	/* Freestyle Card */
	.freestyle-card {
		padding: 14px 12px;
		display: flex;
		flex-direction: column;
		gap: 12px;
	}

	.tuner-top-row {
		display: flex;
		justify-content: space-between;
		font-size: 11px;
	}

	.status-badge {
		color: #9aa2b4;
		font-weight: 600;
		display: flex;
		align-items: center;
		gap: 4px;
	}

	.status-badge.detecting {
		color: #10b981;
	}

	.status-badge .dot {
		color: #10b981;
	}

	.timer-display {
		font-family: 'JetBrains Mono', monospace;
		font-weight: 700;
		color: #d1d5db;
	}

	.detected-label {
		font-size: 10px;
		color: #7b8599;
	}

	.detected-main-row {
		display: flex;
		justify-content: space-between;
		align-items: baseline;
	}

	.detected-pitch {
		font-size: 28px;
		font-weight: 900;
		color: #fff;
	}

	.detected-cents {
		font-size: 11px;
		color: #7b8599;
		font-weight: 600;
	}

	.detected-cents.in-tune {
		color: #10b981;
	}

	.tuner-slider-track {
		height: 6px;
		background: #262c38;
		border-radius: 99px;
		position: relative;
		margin: 4px 0;
	}

	.tuner-center-mark {
		position: absolute;
		left: 50%;
		top: -2px;
		bottom: -2px;
		width: 2px;
		background: #4b5563;
	}

	.tuner-thumb-dot {
		position: absolute;
		top: 50%;
		width: 12px;
		height: 12px;
		border-radius: 50%;
		background: #10b981;
		box-shadow: 0 0 10px rgba(16, 185, 129, 0.6);
		transform: translate(-50%, -50%);
		transition: left 0.15s ease;
	}

	.freestyle-guidance {
		font-size: 9.5px;
		color: #727c90;
		line-height: 1.4;
	}

	/* Bottom Action Dock */
	.bottom-action-dock {
		margin-top: auto;
		display: flex;
		gap: 8px;
		padding-top: 2px;
	}

	.primary-blue-btn {
		flex: 1;
		height: 42px;
		border-radius: 12px;
		background: #3b82f6;
		border: none;
		color: #ffffff;
		font-size: 13px;
		font-weight: 700;
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 8px;
		cursor: pointer;
		box-shadow: 0 4px 14px rgba(59, 130, 246, 0.4);
		transition: transform 0.15s, background 0.15s;
	}

	.primary-blue-btn:hover {
		background: #2563eb;
		transform: translateY(-1px);
	}

	.primary-blue-btn.is-rec {
		background: #ef4444;
		box-shadow: 0 4px 14px rgba(239, 68, 68, 0.4);
	}

	.btn-icon {
		width: 16px;
		height: 16px;
	}

	.record-dot {
		width: 10px;
		height: 10px;
		border-radius: 50%;
		background: #ffffff;
	}

	.secondary-btn {
		width: 42px;
		height: 42px;
		border-radius: 12px;
		background: #242934;
		border: 1px solid rgba(255, 255, 255, 0.08);
		color: #c0c8db;
		display: flex;
		align-items: center;
		justify-content: center;
		cursor: pointer;
		padding: 9px;
	}

	.home-indicator {
		width: 108px;
		height: 4px;
		background: #5a6477;
		border-radius: 99px;
		margin: 6px auto 0;
	}

	/* Light Mode iPhone Styling */
	.iphone-frame.theme-light {
		background: #f8fafc;
		border-color: #cbd5e1;
		box-shadow:
			0 0 0 1px rgba(0, 0, 0, 0.08),
			0 24px 60px -10px rgba(0, 0, 0, 0.18),
			0 8px 24px rgba(0, 0, 0, 0.1);
	}
	.theme-light .status-bar {
		color: #0f172a;
	}
	.theme-light .battery {
		background: rgba(0, 0, 0, 0.08);
		color: #0f172a;
	}
	.theme-light .app-screen {
		background: #f8fafc;
		color: #0f172a;
	}
	.theme-light .app-title {
		color: #0f172a;
	}
	.theme-light .app-subtitle {
		color: #64748b;
	}
	.theme-light .icon-circle-btn {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		color: #475569;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
	}
	.theme-light .segmented-control {
		background: #e2e8f0;
		border-color: rgba(0, 0, 0, 0.04);
	}
	.theme-light .segment {
		color: #64748b;
	}
	.theme-light .segment.active {
		background: #ffffff;
		color: #0f172a;
		box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
	}
	.theme-light .card {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.06);
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
	}
	.theme-light .card-caption {
		color: #64748b;
	}
	.theme-light .song-name {
		color: #0f172a;
	}
	.theme-light .play-label {
		color: #64748b;
	}
	.theme-light .round-control {
		background: #f1f5f9;
		border-color: rgba(0, 0, 0, 0.06);
		color: #475569;
	}
	.theme-light .note-main-text {
		color: #0f172a;
	}
	.theme-light .note-pitch-text {
		color: #64748b;
	}
	.theme-light .harmonica-strip {
		background: #f1f5f9;
		border-color: rgba(0, 0, 0, 0.04);
	}
	.theme-light .dot-marker {
		background: #94a3b8;
	}
	.theme-light .hole-btn {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		color: #475569;
	}
	.theme-light .hole-btn.active {
		background: #3b82f6;
		color: #ffffff;
	}
	.theme-light .mic-status-row {
		background: #f1f5f9;
	}
	.theme-light .mic-headline {
		color: #0f172a;
	}
	.theme-light .mic-sub {
		color: #64748b;
	}
	.theme-light .speaker-btn {
		background: #ffffff;
		color: #475569;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
	}
	.theme-light .queue-title {
		color: #0f172a;
	}
	.theme-light .queue-chip {
		background: #f1f5f9;
		border-color: rgba(0, 0, 0, 0.06);
		color: #475569;
	}
	.theme-light .queue-chip.active {
		background: rgba(59, 130, 246, 0.12);
		border-color: #3b82f6;
		color: #2563eb;
	}
	.theme-light .progress-bar-track {
		background: #e2e8f0;
	}
	.theme-light .secondary-btn {
		background: #f1f5f9;
		border-color: rgba(0, 0, 0, 0.08);
		color: #475569;
	}
	.theme-light .home-indicator {
		background: #cbd5e1;
	}
	.theme-light .detected-pitch {
		color: #0f172a;
	}
	.theme-light .tuner-slider-track {
		background: #e2e8f0;
	}
</style>
