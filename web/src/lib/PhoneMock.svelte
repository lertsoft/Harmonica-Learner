<script lang="ts">
	// Visual iPhone practice mock. Pure presentational, no app logic.
	const tabs = [
		{ hole: '4↑', sub: 'blow', active: false },
		{ hole: '5↓', sub: 'draw', active: true },
		{ hole: '5↑', sub: 'blow', active: false },
		{ hole: '6↑', sub: 'blow', active: false }
	];
</script>

<div class="phone" aria-hidden="true">
	<div class="phone-top"><div class="notch"></div></div>
	<div class="phone-screen">
		<div class="tiny">NOW PRACTICING</div>
		<div class="song-title">Starter Blues</div>
		<div class="song-meta">Key of C · 98 BPM · 8 notes</div>
		<div class="pitch-cent">
			<div class="pitch-scale"><span>-50¢</span><span>pitch</span><span>+50¢</span></div>
			<div class="pitch-track"><div class="pitch-needle"></div></div>
			<div class="pitch-states"><span>flat</span><strong>● in tune</strong><span>sharp</span></div>
		</div>
		<div class="tab-row">
			{#each tabs as t}
				<div class="hole" class:active={t.active}>{t.hole}<span>{t.sub}</span></div>
			{/each}
		</div>
		<div class="now">
			<div class="now-label">Up next</div>
			<div class="now-note"><strong>5↓ — Draw hole 5</strong><span>F5</span></div>
		</div>
	</div>
</div>

<style>
	.phone {
		position: absolute;
		right: 0;
		bottom: 0;
		z-index: 3;
		width: 252px;
		background: #0d1525;
		color: #fff;
		border: 7px solid #0d1525;
		border-radius: 34px;
		box-shadow: 0 24px 50px rgba(0, 0, 0, 0.3);
		overflow: hidden;
	}
	.phone-top {
		height: 20px;
		display: flex;
		justify-content: center;
	}
	.notch {
		width: 76px;
		height: 16px;
		border-radius: 0 0 14px 14px;
		background: #000;
	}
	.phone-screen {
		background: linear-gradient(#fbfcff, #e9efff);
		color: #14213a;
		border-radius: 26px;
		padding: 14px 15px 17px;
		min-height: 428px;
	}
	.tiny {
		font-size: 10px;
		letter-spacing: 0.12em;
		font-weight: 800;
		color: #68758d;
		margin-bottom: 12px;
	}
	.song-title {
		font-family: var(--font-display);
		font-size: 24px;
		line-height: 1;
		margin-bottom: 4px;
	}
	.song-meta {
		font-size: 10.5px;
		color: #778197;
	}
	.pitch-cent {
		margin: 13px 0 14px;
		padding: 9px;
		background: rgba(255, 255, 255, 0.75);
		border: 1px solid #dbe2ef;
		border-radius: 10px;
	}
	.pitch-scale,
	.pitch-states {
		display: flex;
		justify-content: space-between;
		align-items: center;
		font-size: 7px;
		color: #778197;
		font-weight: 700;
	}
	.pitch-track {
		height: 20px;
		margin: 5px 0;
		position: relative;
		border-radius: 5px;
		background:
			repeating-linear-gradient(90deg, #c5cee0 0 1px, transparent 1px 10%),
			linear-gradient(90deg, #ffd2cc 0 34%, #c9f0db 42% 58%, #d8e0f1 66% 100%);
	}
	.pitch-track::after {
		content: '';
		position: absolute;
		left: 50%;
		top: 0;
		bottom: 0;
		width: 1px;
		background: #278762;
	}
	.pitch-needle {
		position: absolute;
		left: 53%;
		top: -4px;
		width: 3px;
		height: 28px;
		border-radius: 4px;
		background: #278762;
		box-shadow: 0 0 0 3px rgba(39, 135, 98, 0.15);
		transform: translateX(-50%);
	}
	.pitch-states strong {
		color: #278762;
		font-size: 8px;
	}
	.tab-row {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: 6px;
	}
	.hole {
		padding: 8px 0;
		text-align: center;
		background: #fff;
		border: 1px solid #dbe2ef;
		border-radius: 8px;
		font-size: 11px;
		font-weight: 800;
	}
	.hole.active {
		background: #2347d8;
		color: #fff;
		border-color: #2347d8;
	}
	.hole span {
		display: block;
		font-size: 8px;
		opacity: 0.72;
		margin-top: 2px;
		font-weight: 600;
	}
	.now {
		margin-top: 14px;
		background: #fff;
		border-radius: 12px;
		padding: 12px;
		border: 1px solid #e4eaf4;
	}
	.now-label {
		font-size: 9px;
		color: #778197;
		text-transform: uppercase;
		letter-spacing: 0.08em;
		font-weight: 800;
	}
	.now-note {
		display: flex;
		justify-content: space-between;
		align-items: center;
		margin-top: 6px;
		font-size: 12px;
	}
	.now-note span {
		font-weight: 800;
		background: #eef3ff;
		padding: 3px 8px;
		border-radius: 99px;
	}
	@media (max-width: 850px) {
		.phone {
			position: relative;
			align-self: flex-end;
			width: 230px;
			margin-top: -180px;
		}
	}
	@media (max-width: 420px) {
		.phone {
			width: 212px;
			margin-top: -100px;
			align-self: center;
		}
		.phone-screen {
			min-height: 390px;
		}
	}
</style>
