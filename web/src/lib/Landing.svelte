<script lang="ts">
	import { APP_URL, SONGS } from "$lib/content";
	import { resolve } from "$app/paths";
	import FaqList from "$lib/components/FaqList.svelte";
	import { FAQS } from "$lib/faq";
	import AppPhoneMockup from "$lib/components/AppPhoneMockup.svelte";
	import InteractiveHarmonica from "$lib/components/InteractiveHarmonica.svelte";
	import ToleranceMeterDemo from "$lib/components/ToleranceMeterDemo.svelte";
	import SongConverterDemo from "$lib/components/SongConverterDemo.svelte";
	import SiteNav from "$lib/components/SiteNav.svelte";
	import SiteFooter from "$lib/components/SiteFooter.svelte";

	interface Props {
		theme?: "dark" | "light";
		onToggleTheme?: () => void;
	}

	let { theme = "dark", onToggleTheme }: Props = $props();
</script>

<div class="bubbly-root" class:theme-light={theme === "light"}>
	<!-- Cheerful Floating Bubble Accents -->
	<div class="ambient-bubble bubble-1" aria-hidden="true"></div>
	<div class="ambient-bubble bubble-2" aria-hidden="true"></div>
	<div class="ambient-bubble bubble-3" aria-hidden="true"></div>

	<!-- Top Friendly Navigation -->
	<SiteNav activePage="home" />

	<!-- Hero Section: Friendly, Bubbly & Welcoming -->
	<section class="bubbly-hero" id="top">
		<div class="hero-left">
			<div class="super-friendly-badge">
				<span class="badge-icon">🎈</span>
				<span class="badge-text"
					>REALLY FUN • SUPER EASY • ZERO MUSIC THEORY</span
				>
			</div>

			<h1 class="bubbly-title">
				Learn the songs you love on harmonica ♪ <span
					class="gradient-pop">one note at a time!</span
				>
			</h1>

			<p class="bubbly-lead">
				Start with a built-in song on your 10-hole C harmonica. Follow
				the hole and breath cues, hear a reference note, and use live
				pitch feedback to find the right sound.
			</p>

			<div class="hero-buttons-row">
				<a href={APP_URL || "#download"} class="bubbly-primary-btn">
					<svg
						class="apple-glyph"
						viewBox="0 0 24 24"
						fill="currentColor"
					>
						<path
							d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.62-.76 1.04-1.82.93-2.87-.9.04-2 .6-2.64 1.36-.57.65-.98 1.73-.85 2.76 1.01.08 1.94-.49 2.56-1.25z"
						/>
					</svg>
					<span>Get the app</span>
					<span class="btn-star">⭐</span>
				</a>
				<a href="#play" class="bubbly-ghost-btn">
					<span>Live the experience</span>
					<span class="btn-hand">👉</span>
				</a>
			</div>

			<!-- Studio Pro Hardware & Audio Specs (Bubbly Edition) -->
			<div class="specs-pill-bar">
				<div class="spec-pill">
					<span class="label">Harmonica</span>
					<span class="val">10-Hole Diatonic (Key C)</span>
				</div>
				<div class="spec-pill">
					<span class="label">Pitch Detection</span>
					<span class="val">On-device feedback</span>
				</div>
				<div class="spec-pill">
					<span class="label">Practice modes</span>
					<span class="val">Guided & Freestyle</span>
				</div>
			</div>
		</div>

		<!-- Right Side: Phone Mockup with Playful Floating Stickers -->
		<div class="hero-right">
			<div class="floating-sticker sticker-top">
				<span class="sticker-emoji">🌬️</span>
				<div>
					<strong>+4 Blow</strong>
					<span>Exhale gently</span>
				</div>
			</div>

			<div class="floating-sticker sticker-right">
				<span class="sticker-emoji">⭐</span>
				<div>
					<strong>Hold it steady</strong>
					<span>Then move to the next note</span>
				</div>
			</div>

			<div class="floating-sticker sticker-bottom">
				<span class="sticker-emoji">🎉</span>
				<div>
					<strong>In Tune!</strong>
					<span>See your pitch feedback</span>
				</div>
			</div>

			<div class="phone-holder">
				<AppPhoneMockup {theme} scale={1} />
				<p class="preview-caption">
					Interactive illustration · synthesized audio
				</p>
			</div>
		</div>
	</section>

	<!-- 3-Step Bubbly Journey -->
	<section class="bubbly-section" id="how">
		<div class="section-center-head">
			<div class="bubble-section-pill">HOW IT WORKS</div>
			<h2>From your first note to a whole melody.</h2>
			<p>
				Start with a built-in song or add your own audio. Read the tabs,
				then practice one note at a time.
			</p>
		</div>

		<div class="steps-candy-grid">
			<div class="candy-step-card step-card-1">
				<div class="step-badge-circle">01</div>
				<div class="step-illu-emoji">🎧</div>
				<h3>Choose a song</h3>
				<p>
					Choose a beginner song, drop any song from your music
					library, or record a song playing nearby. Audio becomes a
					suggested practice line and are mapped to your harmonica.
				</p>
			</div>

			<div class="candy-step-card step-card-2">
				<div class="step-badge-circle">02</div>
				<div class="step-illu-emoji">🫧</div>
				<h3>Follow the notes ♪</h3>
				<p>
					See exactly which hole to play. Blue arrow up means blow out
					(🌬️). Arrow down means breathe in (🎈). It is that easy!
				</p>
			</div>

			<div class="candy-step-card step-card-3">
				<div class="step-badge-circle">03</div>
				<div class="step-illu-emoji">⭐</div>
				<h3>Match and move</h3>
				<p>
					Your device listens as you play. Land 3 steady notes in a
					row and the app automatically steps to the next note!
				</p>
			</div>
		</div>
	</section>

	<!-- Dual Practice Engine (Guided vs Freestyle) from Studio Pro -->
	<section class="bubbly-section" id="modes">
		<div class="section-center-head">
			<div class="bubble-section-pill">PRACTICE MODES</div>
			<h2>Follow a song. Or save your own riff.</h2>
			<p>
				Use Guided mode for a saved melody and Freestyle for recording
				your own ideas.
			</p>
		</div>

		<div class="modes-bubbly-grid">
			<!-- Mode 1: Guided Practice -->
			<div class="mode-card-bubbly guided">
				<div class="mode-badge-pill guided-badge">GUIDED PRACTICE</div>
				<h3>Listen • Match • Move</h3>
				<p>
					Follow melodies note by note. The app listens to your
					microphone and moves on when you hold the target note
					steadily in tune.
				</p>
				<div class="mode-bullets">
					<div class="b-item">
						<span class="check-bubble">✓</span>
						<span
							><strong>Hole and breath cues:</strong> Highlighting
							+4 Blow (↑) or -4 Draw (↓) as you play.</span
						>
					</div>
					<div class="b-item">
						<span class="check-bubble">✓</span>
						<span
							><strong>Steady-note auto-advance:</strong> Move to the
							next note when your pitch settles.</span
						>
					</div>
					<div class="b-item">
						<span class="check-bubble">✓</span>
						<span
							><strong>Song progress:</strong> See the notes ahead
							and how far you have played.</span
						>
					</div>
				</div>
			</div>

			<!-- Mode 2: Freestyle Studio -->
			<div class="mode-card-bubbly freestyle">
				<div class="mode-badge-pill freestyle-badge">
					FREESTYLE STUDIO
				</div>
				<h3>Get Creative • Capture Ideas</h3>
				<p>
					Play anything you want! The real-time tuner gauge detects
					notes as they leave your harmonica, making it perfect for
					bending exercises and capturing riff ideas.
				</p>
				<div class="mode-bullets">
					<div class="b-item">
						<span class="check-bubble">✓</span>
						<span
							><strong>Real-Time Tuner:</strong> Live needle shows
							sharp, flat, or locked in tune (-50 to +50).</span
						>
					</div>
					<div class="b-item">
						<span class="check-bubble">✓</span>
						<span
							><strong>Built-In Session Recording:</strong> Capture
							audio and note sequences to hear your riffs.</span
						>
					</div>
					<div class="b-item">
						<span class="check-bubble">✓</span>
						<span
							><strong>Saved practice lines:</strong> Return to a recorded
							riff for guided practice.</span
						>
					</div>
				</div>
			</div>
		</div>
	</section>

	<!-- Playable Bubbly Harmonica Section -->
	<section class="bubbly-section" id="play">
		<div class="section-center-head">
			<div class="bubble-section-pill">PLAYABLE VIRTUAL HARP</div>
			<h2>Hear the notes on a C harmonica.</h2>
			<p>
				Click on any of the holes or press keys 1 through 0 on your
				keyboard to hear synthesized harmonica-style tones. Use the Blow
				and Draw buttons to change breath direction.
			</p>
		</div>

		<div class="bubbly-instrument-card">
			<InteractiveHarmonica variant="bubbly" {theme} showNotes={true} />
		</div>
	</section>

	<!-- Instant Song-to-Tab Converter Demo from Studio/HUD -->
	<section class="bubbly-section" id="converter">
		<div class="section-center-head">
			<div class="bubble-section-pill">SAMPLE ARRANGEMENT</div>
			<h2>Explore a sample harmonica arrangement.</h2>
			<p>
				Choose a preset and hear a synthesized preview. This browser
				example does not analyze links or record your microphone. In the
				app, imported arrangements may change key or register; results
				vary with the recording.
			</p>
		</div>

		<div class="converter-bubbly-wrapper">
			<SongConverterDemo {theme} />
		</div>
	</section>

	<!-- Friendly Song Library with Pro Metrics -->
	<section class="bubbly-section" id="songs">
		<div class="section-center-head">
			<div class="bubble-section-pill">BUILT-IN SONGS</div>
			<h2>7 Songs to start practicing.</h2>
			<p>
				Jump right into beginner tunes and classic blues licks built
				right into the app.
			</p>
		</div>

		<div class="bubbly-songs-grid">
			{#each SONGS as song}
				<div class="bubbly-song-item">
					<div class="song-top-row">
						<span class="fun-tag-pill">{song.tag}</span>
						<span class="fun-bpm">⚡ {song.bpm} BPM</span>
					</div>
					<h3 class="bubbly-song-name">{song.title}</h3>
					<div class="song-metrics-row">
						<span>Key of C</span>
						<span class="sep">•</span>
						<span>{song.notes} Notes</span>
						<span class="sep">•</span>
						<span>Richter tuned</span>
					</div>
				</div>
			{/each}
		</div>
	</section>

	<!-- Adaptive Pitch Window (Friendly Explanation) -->
	<section class="bubbly-section" id="tuner">
		<div class="section-center-head">
			<div class="bubble-section-pill">PITCH FEEDBACK</div>
			<h2>A smaller pitch window as you practice.</h2>
			<p>
				Harmonica Learner starts with a gentle, forgiving pitch window
				(±30) and tightens automatically as your confidence grows!
			</p>
		</div>

		<div class="tolerance-bubbly-wrap">
			<ToleranceMeterDemo {theme} />
		</div>
	</section>

	<!-- Big Cheerful Download CTA -->
	<section class="bubbly-section" id="faq">
		<div class="section-center-head">
			<div class="bubble-section-pill">QUESTIONS & ANSWERS</div>
			<h2>Before you pick up your harmonica.</h2>
		</div>
		<FaqList items={FAQS.slice(0, 3)} />
		<p class="faq-link">
			<a href={resolve("/faq")}
				>Read all questions about songs, imports, and practice →</a
			>
		</p>
	</section>

	<section class="bubbly-cta-section" id="download">
		<div class="bubbly-cta-bubble">
			<div class="cta-emoji-party">🎈 🎶 ✨ 🎵</div>
			<h2>Ready to play your first song?</h2>
			<p>
				Start with a built-in beginner song. Try up to five Music
				Library imports; a one-time purchase is required to continue
				after the fifth. No subscription.
			</p>
			{#if APP_URL}
				<a href={APP_URL} class="bubbly-primary-btn large">
					<svg
						class="apple-glyph"
						viewBox="0 0 24 24"
						fill="currentColor"
					>
						<path
							d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.81-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M15.97 6.37c.62-.76 1.04-1.82.93-2.87-.9.04-2 .6-2.64 1.36-.57.65-.98 1.73-.85 2.76 1.01.08 1.94-.49 2.56-1.25z"
						/>
					</svg>
					<span>Get Harmonica: Learn to Play</span>
					<span class="btn-arrow">→</span>
				</a>
			{:else}<p class="download-status">
					App Store link coming soon.
				</p>{/if}
		</div>
	</section>

	<!-- Cheerful Footer -->
	<SiteFooter isFaq={false} />
</div>

<style>
	.bubbly-root:not(.theme-light) .bubble-section-pill {
		color: #93c5fd;
	}

	.preview-caption {
		font-size: 12px;
		line-height: 1.5;
		text-align: center;
		max-width: 310px;
		margin: 16px auto 0;
		color: #94a3b8;
	}
	.faq-link {
		text-align: center;
		margin-top: 28px;
	}
	.download-status {
		font-weight: 700;
	}

	.bubbly-root {
		background: #0d111a;
		color: #f8fafc;
		font-family: "Plus Jakarta Sans", system-ui, sans-serif;
		min-height: 100vh;
		position: relative;
		overflow-x: hidden;
		line-height: 1.55;
		transition:
			background 0.25s ease,
			color 0.25s ease;
	}

	/* Light Mode Override */
	.bubbly-root.theme-light {
		background: #fbfbf9;
		color: #1e293b;
	}

	/* Ambient Bubbles */
	.ambient-bubble {
		position: absolute;
		border-radius: 50%;
		filter: blur(80px);
		pointer-events: none;
		z-index: 0;
	}

	.bubble-1 {
		top: -80px;
		left: -60px;
		width: 480px;
		height: 480px;
		background: radial-gradient(
			circle,
			rgba(59, 130, 246, 0.25) 0%,
			transparent 70%
		);
	}

	.bubble-2 {
		top: 300px;
		right: -100px;
		width: 520px;
		height: 520px;
		background: radial-gradient(
			circle,
			rgba(245, 158, 11, 0.2) 0%,
			transparent 70%
		);
	}

	.bubble-3 {
		bottom: 15%;
		left: 10%;
		width: 450px;
		height: 450px;
		background: radial-gradient(
			circle,
			rgba(236, 72, 153, 0.18) 0%,
			transparent 70%
		);
	}

	.theme-light .bubble-1 {
		background: radial-gradient(
			circle,
			rgba(59, 130, 246, 0.14) 0%,
			transparent 70%
		);
	}

	.theme-light .bubble-2 {
		background: radial-gradient(
			circle,
			rgba(251, 191, 36, 0.18) 0%,
			transparent 70%
		);
	}

	/* Hero Section */
	.bubbly-hero {
		max-width: 1200px;
		margin: 0 auto;
		padding: 60px 24px 80px;
		display: grid;
		grid-template-columns: minmax(0, 1.15fr) minmax(0, 0.85fr);
		gap: 48px;
		align-items: center;
		position: relative;
		z-index: 1;
	}

	.super-friendly-badge {
		display: inline-flex;
		align-items: center;
		gap: 8px;
		background: rgba(245, 158, 11, 0.15);
		border: 1px solid rgba(245, 158, 11, 0.3);
		color: #fbbf24;
		padding: 6px 14px;
		border-radius: 99px;
		font-size: 11.5px;
		font-weight: 800;
		letter-spacing: 0.08em;
		margin-bottom: 20px;
	}

	.theme-light .super-friendly-badge {
		background: #fef3c7;
		border-color: #fde68a;
		color: #d97706;
	}

	.bubbly-title {
		font-family: "Outfit", sans-serif;
		font-size: clamp(38px, 4.8vw, 62px);
		font-weight: 900;
		line-height: 1.05;
		letter-spacing: -0.03em;
		margin: 0 0 20px;
	}

	.gradient-pop {
		background: #60a5fa;
		background-clip: text;
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
	}

	.bubbly-lead {
		font-size: 18px;
		color: #94a3b8;
		line-height: 1.6;
		margin: 0 0 30px;
		max-width: 560px;
	}

	.theme-light .bubbly-lead {
		color: #64748b;
	}

	.hero-buttons-row {
		display: flex;
		gap: 14px;
		align-items: center;
		flex-wrap: wrap;
		margin-bottom: 32px;
	}

	.bubbly-primary-btn {
		display: inline-flex;
		align-items: center;
		gap: 10px;
		background: linear-gradient(180deg, #3b82f6 0%, #2563eb 100%);
		color: #ffffff;
		text-decoration: none;
		padding: 15px 30px;
		border-radius: 99px;
		font-size: 15px;
		font-weight: 800;
		box-shadow: 0 10px 25px rgba(59, 130, 246, 0.4);
		transition: transform 0.18s cubic-bezier(0.34, 1.56, 0.64, 1);
	}

	.apple-glyph {
		width: 17px;
		height: 17px;
	}

	.bubbly-primary-btn:hover {
		transform: scale(1.05) translateY(-2px);
	}

	.bubbly-primary-btn:active {
		transform: scale(0.96);
	}

	.bubbly-primary-btn.large {
		padding: 18px 38px;
		font-size: 17px;
	}

	.bubbly-ghost-btn {
		display: inline-flex;
		align-items: center;
		gap: 8px;
		background: rgba(255, 255, 255, 0.07);
		border: 1px solid rgba(255, 255, 255, 0.12);
		color: inherit;
		text-decoration: none;
		padding: 15px 26px;
		border-radius: 99px;
		font-size: 15px;
		font-weight: 700;
		transition: all 0.15s ease;
	}

	.theme-light .bubbly-ghost-btn {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		box-shadow: 0 2px 8px rgba(0, 0, 0, 0.04);
	}

	.bubbly-ghost-btn:hover {
		transform: translateY(-2px);
		border-color: #3b82f6;
	}

	/* Studio Specs Pill Bar (Bubbly Edition) */
	.specs-pill-bar {
		display: flex;
		gap: 16px;
		flex-wrap: wrap;
		padding-top: 24px;
		border-top: 1px solid rgba(255, 255, 255, 0.08);
	}

	.theme-light .specs-pill-bar {
		border-top-color: rgba(0, 0, 0, 0.08);
	}

	.spec-pill {
		background: rgba(255, 255, 255, 0.05);
		border: 1px solid rgba(255, 255, 255, 0.08);
		padding: 8px 16px;
		border-radius: 14px;
		display: flex;
		flex-direction: column;
		gap: 2px;
	}

	.theme-light .spec-pill {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.06);
		box-shadow: 0 2px 6px rgba(0, 0, 0, 0.03);
	}

	.spec-pill .label {
		font-size: 10px;
		font-weight: 800;
		letter-spacing: 0.08em;
		color: #3b82f6;
		text-transform: uppercase;
	}

	.spec-pill .val {
		font-size: 12.5px;
		font-weight: 700;
		color: #cbd5e1;
	}

	.theme-light .spec-pill .val {
		color: #1e293b;
	}

	/* Hero Right: Mockup with Floating Stickers */
	.hero-right {
		position: relative;
		display: flex;
		justify-content: center;
	}

	.floating-sticker {
		position: absolute;
		z-index: 20;
		background: #1c2230;
		border: 1px solid rgba(255, 255, 255, 0.15);
		border-radius: 16px;
		padding: 8px 14px;
		display: flex;
		align-items: center;
		gap: 10px;
		box-shadow: 0 12px 30px rgba(0, 0, 0, 0.4);
	}

	.theme-light .floating-sticker {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		box-shadow: 0 12px 28px rgba(0, 0, 0, 0.1);
	}

	.floating-sticker strong {
		display: block;
		font-size: 12px;
		font-weight: 800;
		color: #f8fafc;
	}

	.theme-light .floating-sticker strong {
		color: #0f172a;
	}

	.floating-sticker span {
		font-size: 10px;
		color: #94a3b8;
	}

	.sticker-top {
		top: 10%;
		left: -20px;
	}

	.sticker-right {
		top: 45%;
		right: -24px;
	}

	.sticker-bottom {
		bottom: 12%;
		left: -10px;
	}

	@keyframes floatBounce {
		from {
			transform: translateY(0);
		}
		to {
			transform: translateY(-8px);
		}
	}

	.phone-holder {
		position: relative;
		z-index: 10;
	}

	/* Section Headings */
	.bubbly-section {
		max-width: 1200px;
		margin: 0 auto;
		padding: 80px 24px;
		position: relative;
		z-index: 1;
	}

	.section-center-head {
		text-align: center;
		max-width: 680px;
		margin: 0 auto 48px;
	}

	.bubble-section-pill {
		display: inline-block;
		font-size: 10.5px;
		font-weight: 800;
		letter-spacing: 0.12em;
		color: #3b82f6;
		background: rgba(59, 130, 246, 0.15);
		padding: 4px 14px;
		border-radius: 99px;
		margin-bottom: 12px;
	}

	.theme-light .bubble-section-pill {
		background: #dbeafe;
		color: #2563eb;
	}

	.section-center-head h2 {
		font-family: "Outfit", sans-serif;
		font-size: clamp(30px, 3.8vw, 44px);
		font-weight: 900;
		letter-spacing: -0.02em;
		margin: 0 0 12px;
	}

	.section-center-head p {
		font-size: 16.5px;
		color: #94a3b8;
		margin: 0;
	}

	.theme-light .section-center-head p {
		color: #64748b;
	}

	/* 3-Step Candy Grid */
	.steps-candy-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
		gap: 24px;
	}

	.candy-step-card {
		background: #141a27;
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 28px;
		padding: 36px 28px;
		display: flex;
		flex-direction: column;
		gap: 14px;
		position: relative;
		transition:
			transform 0.2s ease,
			box-shadow 0.2s ease;
	}

	.candy-step-card:hover {
		transform: translateY(-4px);
		box-shadow: 0 18px 40px rgba(0, 0, 0, 0.3);
	}

	.theme-light .candy-step-card {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.06);
		box-shadow: 0 4px 16px rgba(0, 0, 0, 0.04);
	}

	.theme-light .candy-step-card:hover {
		box-shadow: 0 18px 40px rgba(0, 0, 0, 0.08);
	}

	.step-badge-circle {
		width: 38px;
		height: 38px;
		border-radius: 50%;
		background: #2563eb;
		color: #ffffff;
		font-weight: 900;
		font-size: 14px;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.step-illu-emoji {
		font-size: 36px;
	}

	.candy-step-card h3 {
		font-family: "Outfit", sans-serif;
		font-size: 22px;
		font-weight: 800;
		margin: 0;
	}

	.candy-step-card p {
		font-size: 15px;
		color: #94a3b8;
		line-height: 1.6;
		margin: 0;
	}

	.theme-light .candy-step-card p {
		color: #64748b;
	}

	/* Dual Practice Engine (Bubbly Style) */
	.modes-bubbly-grid {
		display: grid;
		grid-template-columns: 1fr 1fr;
		gap: 24px;
	}

	.mode-card-bubbly {
		background: #141a27;
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 30px;
		padding: 38px 32px;
		display: flex;
		flex-direction: column;
		gap: 16px;
	}

	.theme-light .mode-card-bubbly {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.06);
		box-shadow: 0 8px 24px rgba(0, 0, 0, 0.04);
	}

	.mode-badge-pill {
		align-self: flex-start;
		font-size: 11px;
		font-weight: 800;
		letter-spacing: 0.08em;
		padding: 5px 14px;
		border-radius: 99px;
	}

	.guided-badge {
		background: rgba(59, 130, 246, 0.15);
		color: #60a5fa;
		border: 1px solid rgba(59, 130, 246, 0.3);
	}

	.theme-light .guided-badge {
		background: #dbeafe;
		color: #2563eb;
		border-color: #bfdbfe;
	}

	.freestyle-badge {
		background: rgba(16, 185, 129, 0.15);
		color: #34d399;
		border: 1px solid rgba(16, 185, 129, 0.3);
	}

	.theme-light .freestyle-badge {
		background: #d1fae5;
		color: #059669;
		border-color: #a7f3d0;
	}

	.mode-card-bubbly h3 {
		font-family: "Outfit", sans-serif;
		font-size: 24px;
		font-weight: 800;
		margin: 0;
	}

	.mode-card-bubbly p {
		font-size: 15px;
		color: #94a3b8;
		line-height: 1.6;
		margin: 0;
	}

	.theme-light .mode-card-bubbly p {
		color: #64748b;
	}

	.mode-bullets {
		display: flex;
		flex-direction: column;
		gap: 12px;
		margin-top: 8px;
	}

	.b-item {
		display: flex;
		gap: 12px;
		font-size: 13.5px;
		color: #cbd5e1;
		line-height: 1.5;
	}

	.theme-light .b-item {
		color: #475569;
	}

	.b-item strong {
		color: inherit;
	}

	.check-bubble {
		width: 22px;
		height: 22px;
		border-radius: 50%;
		background: #2563eb;
		color: #ffffff;
		display: flex;
		align-items: center;
		justify-content: center;
		font-weight: 900;
		font-size: 11px;
		flex-shrink: 0;
	}

	/* Instrument Card */
	.bubbly-instrument-card {
		background: #141a27;
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 32px;
		padding: 36px;
	}

	.theme-light .bubbly-instrument-card {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		box-shadow: 0 8px 30px rgba(0, 0, 0, 0.05);
	}

	/* Converter Wrapper */
	.converter-bubbly-wrapper {
		max-width: 900px;
		margin: 0 auto;
	}

	/* Bubbly Songs Grid */
	.bubbly-songs-grid {
		display: grid;
		grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
		gap: 18px;
	}

	.bubbly-song-item {
		background: #141a27;
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 22px;
		padding: 24px;
		display: flex;
		flex-direction: column;
		gap: 10px;
		transition: transform 0.18s ease;
	}

	.bubbly-song-item:hover {
		transform: translateY(-3px);
		border-color: #3b82f6;
	}

	.theme-light .bubbly-song-item {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.06);
		box-shadow: 0 4px 16px rgba(0, 0, 0, 0.03);
	}

	.song-top-row {
		display: flex;
		justify-content: space-between;
		font-size: 11px;
	}

	.fun-tag-pill {
		background: rgba(59, 130, 246, 0.15);
		color: #60a5fa;
		font-weight: 800;
		padding: 3px 10px;
		border-radius: 99px;
	}

	.theme-light .fun-tag-pill {
		background: #dbeafe;
		color: #2563eb;
	}

	.fun-bpm {
		color: #818cf8;
		font-weight: 700;
	}

	.bubbly-song-name {
		font-family: "Outfit", sans-serif;
		font-size: 18px;
		font-weight: 800;
		margin: 0;
	}

	.song-metrics-row {
		display: flex;
		align-items: center;
		gap: 8px;
		font-size: 12px;
		color: #838ea3;
	}

	.sep {
		opacity: 0.4;
	}

	/* Tolerance Wrap */
	.tolerance-bubbly-wrap {
		max-width: 800px;
		margin: 0 auto;
	}

	/* Big Cheerful CTA */
	.bubbly-cta-section {
		max-width: 1200px;
		margin: 0 auto;
		padding: 60px 24px 100px;
	}

	.bubbly-cta-bubble {
		background: linear-gradient(135deg, #1e283d 0%, #151a28 100%);
		border: 1px solid rgba(59, 130, 246, 0.3);
		border-radius: 36px;
		padding: 64px 32px;
		text-align: center;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 16px;
	}

	.theme-light .bubbly-cta-bubble {
		background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
		border-color: #bfdbfe;
	}

	.cta-emoji-party {
		font-size: 32px;
	}

	.bubbly-cta-bubble h2 {
		font-family: "Outfit", sans-serif;
		font-size: clamp(32px, 4vw, 50px);
		font-weight: 900;
		margin: 0;
	}

	.theme-light .bubbly-cta-bubble h2 {
		color: #1e3a8a;
	}

	.bubbly-cta-bubble p {
		font-size: 17px;
		color: #94a3b8;
		max-width: 520px;
		margin: 0 0 12px;
	}

	.theme-light .bubbly-cta-bubble p {
		color: #2563eb;
	}

	@media (max-width: 900px) {
		.bubbly-hero {
			grid-template-columns: 1fr;
		}
		.floating-sticker {
			display: none;
		}
		.modes-bubbly-grid {
			grid-template-columns: 1fr;
		}
	}
</style>
