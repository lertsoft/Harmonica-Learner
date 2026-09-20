<script lang="ts">
	import { playHarmonicaSound } from './audio';

	interface Props {
		theme?: 'dark' | 'light';
	}

	let { theme = 'dark' }: Props = $props();

	let attemptCount = $state(4);
	let currentTolerance = $derived(Math.max(15, Math.round(30 - (attemptCount / 20) * 15)));
	let testPitchCents = $state(18);
	let isTesting = $state(false);
	let isPass = $derived(Math.abs(testPitchCents) <= currentTolerance);

	function runPitchTest(centsOffset: number) {
		testPitchCents = centsOffset;
		isTesting = true;
		const baseFreq = 523.25; // C5
		const testFreq = baseFreq * Math.pow(2, centsOffset / 1200);
		playHarmonicaSound(testFreq, 0.6);
		setTimeout(() => {
			isTesting = false;
		}, 700);
	}
</script>

<div class="tolerance-box" class:theme-light={theme === 'light'}>
	<div class="tolerance-header">
		<div>
			<div class="badge">SMART ADAPTIVE ENGINE</div>
			<div class="title">Dynamic Pitch Tolerance Window</div>
		</div>
		<div class="window-metric">
			<span class="value">±{currentTolerance}¢</span>
			<span class="label">Target Window</span>
		</div>
	</div>

	<p class="description">
		Harmonica Learner automatically loosens pitch tolerance (±30¢) while you discover breath mechanics, then tightens to studio precision (±15¢) as your control solidifies.
	</p>

	<!-- Attempt Slider -->
	<div class="slider-row">
		<div class="slider-label">
			<span>Practice Attempt: <strong>#{attemptCount}</strong></span>
			<span class="attempt-stage">{attemptCount < 7 ? 'Gentle Onboarding' : attemptCount < 14 ? 'Skill Building' : 'Mastery Calibration'}</span>
		</div>
		<input
			type="range"
			min="1"
			max="20"
			bind:value={attemptCount}
			class="attempt-slider"
			aria-label="Practice attempt counter"
		/>
	</div>

	<!-- Pitch Gauge Bar -->
	<div class="gauge-card">
		<div class="gauge-labels">
			<span>-50¢ (Flat)</span>
			<span>Target: C5 (0¢)</span>
			<span>+50¢ (Sharp)</span>
		</div>
		<div class="gauge-track">
			<!-- Tolerance Window Zone -->
			<div
				class="tolerance-zone"
				style="width: {(currentTolerance * 2)}%; left: {50 - currentTolerance}%"
			>
				<span class="zone-tag">±{currentTolerance}¢</span>
			</div>
			<!-- Center Target Line -->
			<div class="center-line"></div>
			<!-- Current Played Note Indicator -->
			<div
				class="pitch-needle"
				class:hit={isPass}
				class:miss={!isPass}
				style="left: {50 + testPitchCents}%"
			></div>
		</div>

		<div class="gauge-footer">
			<div class="test-buttons">
				<span>Simulate note test:</span>
				<button class="chip-btn" onclick={() => runPitchTest(4)}>In Tune (+4¢)</button>
				<button class="chip-btn" onclick={() => runPitchTest(18)}>Slight Bend (+18¢)</button>
				<button class="chip-btn" onclick={() => runPitchTest(-28)}>Loose Breath (-28¢)</button>
			</div>
			<div class="result-feedback" class:pass={isPass}>
				{#if isPass}
					✓ Hit Registered (+{testPitchCents}¢ within ±{currentTolerance}¢)
				{:else}
					✕ Needs adjustment ({testPitchCents > 0 ? '+' : ''}{testPitchCents}¢ outside ±{currentTolerance}¢)
				{/if}
			</div>
		</div>
	</div>
</div>

<style>
	.tolerance-box {
		background: #13161f;
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 20px;
		padding: 24px;
		display: flex;
		flex-direction: column;
		gap: 16px;
	}

	.tolerance-header {
		display: flex;
		justify-content: space-between;
		align-items: flex-start;
		gap: 16px;
	}

	.badge {
		font-size: 10px;
		font-weight: 800;
		letter-spacing: 0.12em;
		color: #10b981;
	}

	.title {
		font-size: 18px;
		font-weight: 800;
		color: #ffffff;
		margin-top: 2px;
	}

	.window-metric {
		text-align: right;
		background: #1c212d;
		padding: 6px 14px;
		border-radius: 12px;
		border: 1px solid rgba(255, 255, 255, 0.06);
	}

	.window-metric .value {
		display: block;
		font-size: 18px;
		font-weight: 900;
		color: #10b981;
		font-family: 'JetBrains Mono', monospace;
	}

	.window-metric .label {
		font-size: 9px;
		color: #838ea3;
		text-transform: uppercase;
		letter-spacing: 0.06em;
	}

	.description {
		font-size: 13.5px;
		color: #94a0b5;
		line-height: 1.55;
		margin: 0;
	}

	.slider-row {
		display: flex;
		flex-direction: column;
		gap: 8px;
	}

	.slider-label {
		display: flex;
		justify-content: space-between;
		font-size: 12px;
		color: #cbd5e1;
	}

	.slider-label strong {
		color: #ffffff;
	}

	.attempt-stage {
		color: #3b82f6;
		font-weight: 600;
	}

	.attempt-slider {
		width: 100%;
		accent-color: #3b82f6;
		cursor: pointer;
	}

	.gauge-card {
		background: #0d0f15;
		border-radius: 14px;
		padding: 16px;
		border: 1px solid rgba(255, 255, 255, 0.05);
		display: flex;
		flex-direction: column;
		gap: 12px;
	}

	.gauge-labels {
		display: flex;
		justify-content: space-between;
		font-size: 10px;
		color: #64748b;
		font-weight: 600;
	}

	.gauge-track {
		height: 36px;
		background: #181c26;
		border-radius: 10px;
		position: relative;
		overflow: hidden;
		border: 1px solid rgba(255, 255, 255, 0.06);
	}

	.tolerance-zone {
		position: absolute;
		top: 0;
		bottom: 0;
		background: rgba(16, 185, 129, 0.18);
		border-left: 1.5px dashed #10b981;
		border-right: 1.5px dashed #10b981;
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.25s ease;
	}

	.zone-tag {
		font-size: 9px;
		font-weight: 800;
		color: #10b981;
		background: rgba(16, 185, 129, 0.25);
		padding: 1px 6px;
		border-radius: 4px;
	}

	.center-line {
		position: absolute;
		left: 50%;
		top: 0;
		bottom: 0;
		width: 2px;
		background: #3b82f6;
	}

	.pitch-needle {
		position: absolute;
		top: 4px;
		bottom: 4px;
		width: 4px;
		border-radius: 4px;
		transform: translateX(-50%);
		transition: left 0.3s ease;
		box-shadow: 0 0 10px currentColor;
	}

	.pitch-needle.hit {
		background: #10b981;
		color: #10b981;
	}

	.pitch-needle.miss {
		background: #ef4444;
		color: #ef4444;
	}

	.gauge-footer {
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 12px;
	}

	.test-buttons {
		display: flex;
		align-items: center;
		gap: 8px;
		font-size: 11px;
		color: #828ca1;
	}

	.chip-btn {
		background: #1c212c;
		border: 1px solid rgba(255, 255, 255, 0.08);
		color: #d1d5db;
		padding: 4px 10px;
		border-radius: 6px;
		font-size: 11px;
		font-weight: 600;
		cursor: pointer;
		transition: background 0.15s ease;
	}

	.chip-btn:hover {
		background: #28303f;
		color: #ffffff;
	}

	.result-feedback {
		font-size: 11.5px;
		font-weight: 700;
		color: #ef4444;
	}

	.result-feedback.pass {
		color: #10b981;
	}

	/* Light Mode Styles */
	.tolerance-box.theme-light {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		box-shadow: 0 8px 24px rgba(0, 0, 0, 0.04);
		color: #0f172a;
	}
	.theme-light .title {
		color: #0f172a;
	}
	.theme-light .description {
		color: #475569;
	}
	.theme-light .window-metric {
		background: #f1f5f9;
		border-color: rgba(0, 0, 0, 0.06);
	}
	.theme-light .window-metric .label {
		color: #64748b;
	}
	.theme-light .slider-label {
		color: #0f172a;
	}
	.theme-light .slider-label strong {
		color: #0f172a;
	}
	.theme-light .gauge-card {
		background: #f8fafc;
		border-color: rgba(0, 0, 0, 0.06);
	}
	.theme-light .gauge-labels {
		color: #64748b;
	}
	.theme-light .gauge-track {
		background: #e2e8f0;
		border-color: rgba(0, 0, 0, 0.06);
	}
	.theme-light .chip-btn {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		color: #0f172a;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
	}
	.theme-light .chip-btn:hover {
		background: #f1f5f9;
	}
</style>
