<script lang="ts">
	import { APP_URL, HERO } from '$lib/content';
	import PhoneMock from '$lib/PhoneMock.svelte';
</script>

<section class="hero">
	<div>
		<div class="eyebrow rise rise-1">{HERO.eyebrow}</div>
		<h1 class="rise rise-2">{HERO.titleA} <em>{HERO.titleAccent}</em></h1>
		<p class="lead rise rise-3">{HERO.lead}</p>
		<div class="actions rise rise-4">
			<a class="button primary" href={APP_URL}>{HERO.primaryCta}&nbsp; →</a>
			<a class="button secondary" href="#practice">{HERO.secondaryCta}</a>
		</div>
		<p class="fine rise rise-4">{HERO.finePrint}</p>
		<div class="spec-row rise rise-4" aria-label="App facts">
			<span><strong>iOS 17+</strong> iPhone</span>
			<span class="dot" aria-hidden="true">•</span>
			<span><strong>Offline</strong> pitch analysis</span>
			<span class="dot" aria-hidden="true">•</span>
			<span><strong>7</strong> bundled songs</span>
		</div>
	</div>

	<div class="hero-visual rise rise-3" aria-label="Harmonica player alongside an app practice screen">
		<div class="photo-card">
			<div class="photo-art" aria-hidden="true">
				<svg viewBox="0 0 520 560" role="img" aria-label="Stylized harmonica player">
					<defs>
						<linearGradient id="stage" x1="0" y1="0" x2="1" y2="1">
							<stop offset="0" stop-color="#2f5bff" />
							<stop offset="0.55" stop-color="#16309e" />
							<stop offset="1" stop-color="#0b1440" />
						</linearGradient>
						<radialGradient id="spot" cx="0.5" cy="0.32" r="0.7">
							<stop offset="0" stop-color="#ffd97a" stop-opacity="0.85" />
							<stop offset="0.4" stop-color="#f5b742" stop-opacity="0.25" />
							<stop offset="1" stop-color="#f5b742" stop-opacity="0" />
						</radialGradient>
					</defs>
					<rect width="520" height="560" fill="url(#stage)" />
					<rect width="520" height="560" fill="url(#spot)" />
					<g opacity="0.22" stroke="#ffffff" stroke-width="1.5">
						{#each Array(9) as _, i}
							<line x1={40 + i * 52} y1="0" x2={10 + i * 52} y2="560" />
						{/each}
					</g>
					<!-- player silhouette -->
					<circle cx="260" cy="205" r="86" fill="#0e1630" />
					<circle cx="260" cy="198" r="72" fill="#e8b48c" />
					<path d="M188 198 Q192 128 260 124 Q328 128 332 198 Q300 168 260 170 Q220 168 188 198" fill="#1c2340" />
					<rect x="198" y="258" width="124" height="34" rx="9" fill="#f6c85f" stroke="#17233b" stroke-width="5" />
					<g fill="#17233b">
						<circle cx="216" cy="275" r="4" /><circle cx="230" cy="275" r="4" />
						<circle cx="244" cy="275" r="4" /><circle cx="258" cy="275" r="4" />
						<circle cx="272" cy="275" r="4" /><circle cx="286" cy="275" r="4" />
						<circle cx="300" cy="275" r="4" />
					</g>
					<rect x="150" y="310" width="220" height="150" rx="24" fill="#0e1630" opacity="0.55" />
					<g stroke="#ffd97a" stroke-width="3" opacity="0.9" fill="none">
						<path d="M180 360 Q230 340 260 368 T340 356" />
						<path d="M180 390 Q230 370 260 398 T340 386" opacity="0.6" />
					</g>
					<g fill="#fff" opacity="0.9">
						<circle cx="200" cy="470" r="3" /><circle cx="250" cy="488" r="2.4" />
						<circle cx="310" cy="470" r="3.4" /><circle cx="350" cy="500" r="2" />
					</g>
				</svg>
			</div>
			<div class="photo-note"><span class="pulse" aria-hidden="true"></span> Listening in real time</div>
		</div>
		<PhoneMock />
	</div>
</section>

<style>
	.hero {
		display: grid;
		grid-template-columns: 1.02fr 0.98fr;
		gap: 44px;
		align-items: center;
		padding: 36px 0 64px;
	}
	h1 {
		font-family: var(--font-display);
		font-size: clamp(52px, 6.6vw, 92px);
		line-height: 0.92;
		letter-spacing: -0.05em;
		margin: 20px 0 22px;
		text-wrap: balance;
	}
	h1 em {
		font-style: italic;
		color: var(--blue);
		font-variation-settings: 'opsz' 100;
	}
	.lead {
		font-size: 19px;
		line-height: 1.6;
		color: var(--muted);
		max-width: 580px;
		margin: 0;
	}
	.actions {
		display: flex;
		gap: 12px;
		align-items: center;
		margin-top: 28px;
		flex-wrap: wrap;
	}
	.fine {
		font-size: 13px;
		color: var(--muted);
		margin: 14px 0 0;
	}
	.spec-row {
		display: flex;
		gap: 10px;
		align-items: center;
		flex-wrap: wrap;
		margin-top: 18px;
		font-size: 13px;
		color: var(--muted);
	}
	.spec-row strong {
		color: var(--ink);
	}
	.dot {
		opacity: 0.5;
	}
	.hero-visual {
		position: relative;
		min-height: 580px;
	}
	.photo-card {
		position: absolute;
		inset: 0 42px 30px 0;
		border-radius: 22px 110px 22px 22px;
		overflow: hidden;
		box-shadow: var(--shadow);
		border: 1px solid var(--line);
		background: #16309e;
	}
	.photo-art svg {
		width: 100%;
		height: 100%;
		display: block;
		object-fit: cover;
	}
	.photo-art {
		position: absolute;
		inset: 0;
	}
	.photo-art::after {
		content: '';
		position: absolute;
		inset: 0;
		background: linear-gradient(180deg, transparent 52%, rgba(8, 16, 40, 0.6));
	}
	.photo-note {
		position: absolute;
		z-index: 2;
		left: 26px;
		bottom: 24px;
		color: #fff;
		font-weight: 700;
		font-size: 14px;
		display: flex;
		align-items: center;
		gap: 10px;
		text-shadow: 0 2px 12px rgba(0, 0, 0, 0.4);
	}
	.pulse {
		width: 14px;
		height: 14px;
		background: var(--cyan);
		border: 3px solid rgba(255, 255, 255, 0.75);
		border-radius: 50%;
		box-shadow: 0 0 0 8px rgba(18, 181, 212, 0.25);
	}
	@media (max-width: 850px) {
		.hero {
			grid-template-columns: 1fr;
			padding: 28px 0 56px;
		}
		h1 {
			font-size: clamp(50px, 14vw, 76px);
		}
		.hero-visual {
			min-height: 0;
			display: flex;
			flex-direction: column;
		}
		.photo-card {
			position: relative;
			inset: auto;
			width: calc(100% - 40px);
			height: 460px;
		}
	}
	@media (max-width: 420px) {
		.actions {
			flex-direction: column;
			align-items: stretch;
		}
		.button {
			justify-content: center;
		}
		.photo-card {
			width: 100%;
			height: 360px;
			border-radius: 18px 64px 18px 18px;
		}
	}
</style>
