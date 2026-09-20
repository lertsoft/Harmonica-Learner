<script lang="ts">
	import { playHarmonicaSound, HARMONICA_C_MAP } from './audio';

	interface Props {
		compact?: boolean;
		showNotes?: boolean;
		variant?: 'standard' | 'bubbly';
		theme?: 'dark' | 'light';
	}

	let { compact = false, showNotes = true, variant = 'standard', theme = 'dark' }: Props = $props();

	let direction = $state<'blow' | 'draw'>('blow');
	let activeHole = $state<number | null>(null);
	let lastPlayed = $state<{ hole: number; dir: 'blow' | 'draw'; note: string; freq: number } | null>(null);

	function playHole(hole: number, dir = direction) {
		const info = HARMONICA_C_MAP[hole];
		if (!info) return;
		const target = dir === 'blow' ? info.blow : info.draw;
		activeHole = hole;
		lastPlayed = { hole, dir, note: target.note, freq: target.freq };
		playHarmonicaSound(target.freq, 0.65);
		setTimeout(() => {
			if (activeHole === hole) {
				activeHole = null;
			}
		}, 600);
	}

	function handleKeydown(e: KeyboardEvent) {
		// Ignore if typing in input
		if (['INPUT', 'TEXTAREA'].includes((e.target as HTMLElement)?.tagName)) return;

		if (e.code === 'Space') {
			e.preventDefault();
			direction = direction === 'blow' ? 'draw' : 'blow';
			return;
		}

		const keyNum = parseInt(e.key, 10);
		if (!isNaN(keyNum)) {
			const hole = keyNum === 0 ? 10 : keyNum;
			if (hole >= 1 && hole <= 10) {
				playHole(hole);
			}
		}
	}
</script>

<svelte:window onkeydown={handleKeydown} />

<div class="harmonica-instrument" class:compact class:bubbly={variant === 'bubbly'} class:theme-light={theme === 'light'}>
	<!-- Top Controls: Breath Direction & Status -->
	<div class="harmonica-bar-header">
		<div class="breath-toggle-group">
			<button
				class="breath-toggle-btn"
				class:active={direction === 'blow'}
				onclick={() => (direction = 'blow')}
			>
				<span class="arrow">↑</span> BLOW (Exhale)
			</button>
			<button
				class="breath-toggle-btn"
				class:active={direction === 'draw'}
				onclick={() => (direction = 'draw')}
			>
				<span class="arrow">↓</span> DRAW (Inhale)
			</button>
		</div>

		<div class="hud-readout">
			{#if lastPlayed}
				<span class="readout-hole">Hole {lastPlayed.hole}</span>
				<span class="readout-note">{lastPlayed.note}</span>
				<span class="readout-dir">{lastPlayed.dir === 'blow' ? '↑ Blow' : '↓ Draw'}</span>
				<span class="readout-freq">{Math.round(lastPlayed.freq)} Hz</span>
			{:else}
				<span class="readout-idle">Click any hole or press keys 1–0</span>
			{/if}
		</div>
	</div>

	<!-- Physical Harmonica Body -->
	<div class="harmonica-body">
		<!-- Top Metallic Cover Plate -->
		<div class="metal-plate top-plate">
			<div class="engraving">
				<span class="brand">HARMONICA LEARNER</span>
				<span class="spec">10-HOLE DIATONIC • KEY OF C</span>
			</div>
			<div class="plate-screws left-screw"></div>
			<div class="plate-screws right-screw"></div>
		</div>

		<!-- Holes Row / Comb -->
		<div class="comb-row">
			{#each [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as hole}
				{@const holeData = HARMONICA_C_MAP[hole]}
				{@const currentNote = direction === 'blow' ? holeData.blow.note : holeData.draw.note}
				<button
					class="hole-slot"
					class:active={activeHole === hole}
					onclick={() => playHole(hole)}
					aria-label="Hole {hole} {direction} {currentNote}"
				>
					<span class="hole-number">{hole}</span>
					<div class="aperture">
						<div class="reed-indicator"></div>
					</div>
					{#if showNotes}
						<span class="hole-note">{currentNote}</span>
					{/if}
				</button>
			{/each}
		</div>

		<!-- Bottom Metallic Plate -->
		<div class="metal-plate bottom-plate">
			<div class="reed-air-vents">
				{#each Array(10) as _}
					<span class="vent"></span>
				{/each}
			</div>
		</div>
	</div>

	<div class="harmonica-tips">
		<span>Tip: Use keys <strong>1–9, 0</strong> on keyboard or press <strong>Spacebar</strong> to flip Blow/Draw</span>
	</div>
</div>

<style>
	.harmonica-instrument {
		width: 100%;
		max-width: 720px;
		margin: 0 auto;
		display: flex;
		flex-direction: column;
		gap: 12px;
		user-select: none;
	}

	.harmonica-bar-header {
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 12px;
	}

	.breath-toggle-group {
		display: inline-flex;
		background: #181b22;
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 12px;
		padding: 3px;
		gap: 4px;
	}

	.breath-toggle-btn {
		background: transparent;
		border: none;
		color: #949db0;
		font-size: 12px;
		font-weight: 700;
		padding: 7px 14px;
		border-radius: 9px;
		cursor: pointer;
		display: flex;
		align-items: center;
		gap: 6px;
		transition: all 0.18s ease;
	}

	.breath-toggle-btn .arrow {
		font-size: 14px;
		font-weight: 900;
	}

	.breath-toggle-btn.active {
		background: #3b82f6;
		color: #ffffff;
		box-shadow: 0 2px 10px rgba(59, 130, 246, 0.4);
	}

	.hud-readout {
		display: flex;
		align-items: center;
		gap: 10px;
		background: #14171f;
		border: 1px solid rgba(255, 255, 255, 0.06);
		padding: 6px 14px;
		border-radius: 99px;
		font-size: 12px;
	}

	.readout-hole {
		color: #e2e8f0;
		font-weight: 700;
	}

	.readout-note {
		color: #60a5fa;
		font-weight: 800;
		background: rgba(59, 130, 246, 0.15);
		padding: 2px 8px;
		border-radius: 6px;
	}

	.readout-dir {
		color: #94a3b8;
	}

	.readout-freq {
		font-family: 'JetBrains Mono', monospace;
		color: #10b981;
		font-weight: 600;
	}

	.readout-idle {
		color: #64748b;
		font-size: 11px;
	}

	/* Physical Harmonica Body Styling */
	.harmonica-body {
		background: #0f1117;
		border-radius: 16px;
		border: 1px solid rgba(255, 255, 255, 0.12);
		box-shadow:
			0 18px 45px rgba(0, 0, 0, 0.6),
			0 0 0 1px rgba(0, 0, 0, 0.8),
			inset 0 1px 0 rgba(255, 255, 255, 0.15);
		overflow: hidden;
		display: flex;
		flex-direction: column;
	}

	.metal-plate {
		position: relative;
		background: linear-gradient(180deg, #2c3240 0%, #1e222c 50%, #171a22 100%);
		border-bottom: 1px solid #101217;
		padding: 10px 24px;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.top-plate {
		box-shadow: inset 0 1px 1px rgba(255, 255, 255, 0.2);
	}

	.engraving {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 2px;
	}

	.engraving .brand {
		font-size: 11px;
		font-weight: 900;
		letter-spacing: 0.25em;
		color: #e2e8f0;
		text-shadow: 0 1px 2px rgba(0, 0, 0, 0.8);
	}

	.engraving .spec {
		font-size: 9px;
		font-weight: 700;
		letter-spacing: 0.15em;
		color: #94a3b8;
	}

	.plate-screws {
		position: absolute;
		top: 50%;
		transform: translateY(-50%);
		width: 10px;
		height: 10px;
		border-radius: 50%;
		background: radial-gradient(circle, #8a96aa 20%, #3e4757 80%);
		box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.8), 0 1px 1px rgba(255, 255, 255, 0.2);
	}

	.left-screw {
		left: 18px;
	}

	.right-screw {
		right: 18px;
	}

	/* Comb & Holes */
	.comb-row {
		display: grid;
		grid-template-columns: repeat(10, 1fr);
		gap: 6px;
		padding: 12px 14px;
		background: #090a0f;
	}

	.hole-slot {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 6px;
		background: #141720;
		border: 1px solid rgba(255, 255, 255, 0.06);
		border-radius: 8px;
		padding: 8px 0 6px;
		cursor: pointer;
		transition: all 0.15s ease;
		outline: none;
	}

	.hole-slot:hover {
		background: #1e2330;
		border-color: rgba(59, 130, 246, 0.4);
		transform: translateY(-2px);
	}

	.hole-slot.active {
		background: #2563eb;
		border-color: #60a5fa;
		box-shadow:
			0 0 16px rgba(59, 130, 246, 0.6),
			inset 0 0 8px rgba(255, 255, 255, 0.3);
		transform: translateY(1px);
	}

	.hole-number {
		font-size: 12px;
		font-weight: 800;
		color: #cbd5e1;
	}

	.hole-slot.active .hole-number {
		color: #ffffff;
	}

	.aperture {
		width: 18px;
		height: 30px;
		background: #050608;
		border-radius: 4px;
		box-shadow: inset 0 3px 6px rgba(0, 0, 0, 0.9);
		display: flex;
		align-items: center;
		justify-content: center;
		border: 1px solid rgba(255, 255, 255, 0.05);
	}

	.reed-indicator {
		width: 3px;
		height: 18px;
		border-radius: 1px;
		background: #b45309; /* Brass reed color */
		opacity: 0.6;
		transition: transform 0.1s ease;
	}

	.hole-slot.active .reed-indicator {
		background: #fbbf24;
		opacity: 1;
		transform: scaleY(1.2);
		box-shadow: 0 0 8px #fbbf24;
	}

	.hole-note {
		font-size: 10px;
		font-weight: 700;
		color: #94a3b8;
		font-family: 'JetBrains Mono', monospace;
	}

	.hole-slot.active .hole-note {
		color: #ffffff;
	}

	.bottom-plate {
		padding: 6px 20px;
		border-top: 1px solid #101217;
		border-bottom: none;
	}

	.reed-air-vents {
		display: grid;
		grid-template-columns: repeat(10, 1fr);
		gap: 14px;
		width: 80%;
		margin: 0 auto;
	}

	.vent {
		height: 4px;
		background: #0a0b10;
		border-radius: 2px;
		box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.9);
	}

	.harmonica-tips {
		text-align: center;
		font-size: 11px;
		color: #64748b;
	}

	.harmonica-tips strong {
		color: #94a3b8;
	}

	@media (max-width: 640px) {
		.comb-row {
			gap: 3px;
			padding: 8px 6px;
		}
		.aperture {
			width: 14px;
			height: 24px;
		}
		.hole-number {
			font-size: 10px;
		}
		.hole-note {
			font-size: 8px;
		}
	}

	/* Bubbly Variant Styles */
	.bubbly .harmonica-body {
		border-radius: 28px;
		box-shadow: 0 16px 40px rgba(59, 130, 246, 0.15), 0 4px 12px rgba(0, 0, 0, 0.1);
	}

	.bubbly .metal-plate {
		padding: 14px 28px;
	}

	.bubbly .brand {
		font-family: 'Outfit', sans-serif;
		font-weight: 800;
		letter-spacing: 0.12em;
	}

	.bubbly .hole-slot {
		border-radius: 16px;
		transition: transform 0.2s cubic-bezier(0.34, 1.56, 0.64, 1), background 0.15s;
	}

	.bubbly .hole-slot:hover {
		transform: translateY(-4px) scale(1.05);
	}

	.bubbly .hole-slot:active {
		transform: scale(0.95);
	}

	.bubbly .aperture {
		border-radius: 8px;
	}

	/* Theme Light Styling */
	.theme-light .breath-toggle-group {
		background: #e2e8f0;
		border-color: rgba(0, 0, 0, 0.08);
	}

	.theme-light .breath-toggle-btn {
		color: #475569;
	}

	.theme-light .breath-toggle-btn.active {
		background: #3b82f6;
		color: #ffffff;
	}

	.theme-light .hud-readout {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.05);
	}

	.theme-light .readout-hole {
		color: #0f172a;
	}

	.theme-light .readout-idle {
		color: #64748b;
	}

	.theme-light .harmonica-body {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.1);
		box-shadow: 0 14px 34px rgba(0, 0, 0, 0.08);
	}

	.theme-light .metal-plate {
		background: linear-gradient(180deg, #f8fafc 0%, #e2e8f0 100%);
		border-color: #cbd5e1;
	}

	.theme-light .brand {
		color: #0f172a;
		text-shadow: none;
	}

	.theme-light .spec {
		color: #64748b;
	}

	.theme-light .plate-screws {
		background: radial-gradient(circle, #cbd5e1 30%, #94a3b8 80%);
	}

	.theme-light .comb-row {
		background: #f1f5f9;
	}

	.theme-light .hole-slot {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
	}

	.theme-light .hole-slot:hover {
		background: #f8fafc;
	}

	.theme-light .hole-slot.active {
		background: #3b82f6;
		color: #ffffff;
	}

	.theme-light .hole-number {
		color: #0f172a;
	}

	.theme-light .hole-slot.active .hole-number {
		color: #ffffff;
	}

	.theme-light .aperture {
		background: #e2e8f0;
		border-color: rgba(0, 0, 0, 0.06);
		box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.06);
	}

	.theme-light .hole-note {
		color: #64748b;
	}

	.theme-light .hole-slot.active .hole-note {
		color: #ffffff;
	}

	.theme-light .vent {
		background: #cbd5e1;
	}
</style>
