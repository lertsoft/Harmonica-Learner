<script lang="ts">
	import { DEMO_NOTES } from '$lib/content';

	let ix = $state(0);
	let busy = $state(false);
	let locked = $state(false);
	let detectTimer: ReturnType<typeof setTimeout> | undefined;
	let advanceTimer: ReturnType<typeof setTimeout> | undefined;

	let note = $derived(DEMO_NOTES[ix]);
	let status = $derived(
		locked ? `Note Detected: ${note.pitch} (+2 cents)` : busy ? 'Listening...' : 'Ready to listen'
	);

	function clear() {
		clearTimeout(detectTimer);
		clearTimeout(advanceTimer);
	}

	function reset() {
		clear();
		busy = false;
		locked = false;
	}

	function move(step: number) {
		reset();
		ix = (ix + step + DEMO_NOTES.length) % DEMO_NOTES.length;
	}

	function toggle() {
		if (busy) {
			reset();
			return;
		}
		busy = true;
		locked = false;
		detectTimer = setTimeout(() => {
			busy = false;
			locked = true;
			advanceTimer = setTimeout(() => {
				ix = (ix + 1) % DEMO_NOTES.length;
				reset();
			}, 1150);
		}, 1250);
	}
</script>

<section class="practice" id="practice">
	<div>
		<div class="eyebrow light">Guided practice mode</div>
		<h2>Practice that actually listens.</h2>
		<p>
			Follow one note at a time. Real-time pitch detection lets you know when you’ve got it, while
			adaptive tolerance keeps early sessions encouraging and later ones precise.
		</p>
		<ul>
			<li><strong>3 consecutive hits</strong> advance to the next note</li>
			<li><strong>Cents-accurate meter</strong> shows sharp / flat</li>
			<li><strong>Hole + airflow</strong> on every target</li>
		</ul>
	</div>
	<div class="demo" class:playing={busy} class:locked={locked}>
		<div class="demo-head"><b>Guided practice</b><span class="status" aria-live="polite">{status}</span></div>
		<div class="big-note">{note.tab}</div>
		<div class="direction">{note.action}</div>
		<div class="demo-controls">
			<button class="skip" onclick={() => move(-1)} aria-label="Previous note">← Back</button>
			<button
				class="play"
				onclick={toggle}
				aria-label={busy ? 'Stop practice demo' : locked ? 'Note locked' : 'Start practice demo'}
			>
				{#if busy}■{:else if locked}✓{:else}▶{/if}
			</button>
			<button class="skip" onclick={() => move(1)} aria-label="Next note">Next →</button>
		</div>
		<div class="demo-meter" aria-hidden="true"><span></span></div>
	</div>
</section>

<style>
	.practice {
		background:
			radial-gradient(520px 300px at 85% 10%, rgba(245, 183, 66, 0.28), transparent 60%),
			radial-gradient(600px 380px at 10% 100%, rgba(18, 181, 212, 0.22), transparent 60%),
			linear-gradient(135deg, #2b53e0, #16309e 70%);
		color: #fff;
		padding: 64px;
		border-radius: 26px;
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 60px;
		align-items: center;
		margin-bottom: 110px;
		position: relative;
		overflow: hidden;
		border: 1px solid rgba(255, 255, 255, 0.18);
	}
	.practice::after {
		content: '';
		position: absolute;
		width: 260px;
		height: 260px;
		border: 56px solid rgba(255, 255, 255, 0.07);
		border-radius: 50%;
		right: -110px;
		top: -120px;
	}
	.eyebrow.light {
		color: #cdd9ff;
	}
	.eyebrow.light::before {
		background: var(--brass-soft);
	}
	h2 {
		font-family: var(--font-display);
		font-size: clamp(40px, 4.6vw, 66px);
		line-height: 0.96;
		letter-spacing: -0.04em;
		margin: 16px 0 18px;
	}
	p {
		color: #dbe5ff;
		line-height: 1.62;
		font-size: 17px;
		margin: 0;
	}
	ul {
		margin: 22px 0 0;
		padding: 0;
		list-style: none;
		display: grid;
		gap: 10px;
		color: #eaf0ff;
		font-size: 14.5px;
	}
	ul strong {
		color: #fff;
	}
	ul li::before {
		content: '✓ ';
		color: var(--brass-soft);
		font-weight: 800;
	}
	.demo {
		background: var(--surface);
		color: var(--ink);
		border-radius: 20px;
		padding: 26px;
		position: relative;
		z-index: 1;
		box-shadow: 0 25px 55px rgba(8, 24, 80, 0.32);
	}
	.demo-head {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-bottom: 20px;
		gap: 16px;
	}
	.demo-head b {
		font-size: 17px;
		letter-spacing: -0.01em;
	}
	.status {
		font-size: 12px;
		font-weight: 700;
		color: var(--muted);
		text-align: right;
		min-height: 18px;
	}
	.locked .status {
		color: var(--mint);
	}
	.big-note {
		font-family: var(--font-display);
		font-size: 84px;
		line-height: 1;
		text-align: center;
		margin: 14px 0 6px;
	}
	.playing .big-note {
		animation: beat 0.8s ease-in-out infinite alternate;
	}
	.locked .big-note {
		color: var(--mint);
	}
	.direction {
		text-align: center;
		color: var(--muted);
		font-weight: 700;
		font-size: 14px;
	}
	.demo-controls {
		display: flex;
		align-items: center;
		justify-content: center;
		gap: 16px;
		margin-top: 22px;
	}
	.play {
		width: 54px;
		height: 54px;
		border: 0;
		border-radius: 50%;
		background: var(--blue);
		color: #fff;
		cursor: pointer;
		font-size: 19px;
		transition: transform 0.15s ease;
	}
	.play:hover {
		transform: scale(1.05);
	}
	.skip {
		border: 0;
		background: transparent;
		color: var(--muted);
		cursor: pointer;
		font-weight: 700;
		font-size: 14px;
	}
	.demo-meter {
		height: 9px;
		background: var(--line);
		border-radius: 8px;
		overflow: hidden;
		margin-top: 24px;
		transition: box-shadow 0.25s;
	}
	.demo-meter span {
		display: block;
		height: 100%;
		width: 6%;
		background: var(--cyan);
		transition:
			width 0.35s,
			background 0.25s;
	}
	.playing .demo-meter span {
		width: 64%;
		animation: listen 1s ease-in-out infinite alternate;
	}
	.locked .demo-meter {
		box-shadow:
			0 0 0 5px rgba(39, 135, 98, 0.14),
			0 0 22px rgba(39, 135, 98, 0.35);
	}
	.locked .demo-meter span {
		width: 52%;
		background: var(--mint);
		animation: lock-pulse 0.55s ease-in-out infinite alternate;
	}
	@keyframes listen {
		from { width: 48%; }
		to { width: 72%; }
	}
	@keyframes beat {
		from { transform: scale(1); }
		to { transform: scale(1.045); }
	}
	@keyframes lock-pulse {
		from { opacity: 0.75; }
		to { opacity: 1; }
	}
	@media (max-width: 850px) {
		.practice {
			grid-template-columns: 1fr;
			padding: 42px 22px;
			gap: 32px;
			margin-bottom: 76px;
		}
	}
	@media (prefers-reduced-motion: reduce) {
		.playing .big-note,
		.playing .demo-meter span,
		.locked .demo-meter span {
			animation: none;
		}
	}
</style>
