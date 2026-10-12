<script lang="ts">
	import { resolve } from "$app/paths";
	import Seo from "$lib/components/Seo.svelte";
	import FaqList from "$lib/components/FaqList.svelte";
	import SiteNav from "$lib/components/SiteNav.svelte";
	import SiteFooter from "$lib/components/SiteFooter.svelte";
	import AmbientBubbles from "$lib/components/AmbientBubbles.svelte";
	import { FAQS, faqSchema } from "$lib/faq";
	import { PAGES, canonicalUrl, jsonLd } from "$lib/site";
	import { APP_URL } from "$lib/content";
	import { themeState } from "$lib/theme.svelte";

	const metadata = PAGES[1];
	const breadcrumbs = {
		"@context": "https://schema.org",
		"@type": "BreadcrumbList",
		itemListElement: [
			{
				"@type": "ListItem",
				position: 1,
				name: "Harmonica",
				item: canonicalUrl("/"),
			},
			{
				"@type": "ListItem",
				position: 2,
				name: "FAQ",
				item: canonicalUrl("/faq"),
			},
		],
	};
</script>

<Seo {...metadata} />
<svelte:head>
	{@html `<script type="application/ld+json">${jsonLd(faqSchema(FAQS))}</script>`}
	{@html `<script type="application/ld+json">${jsonLd(breadcrumbs)}</script>`}
</svelte:head>

<div
	class="bubbly-root"
	class:theme-light={themeState.current === "light"}
	data-theme={themeState.current}
>
	<AmbientBubbles />
	<SiteNav activePage="faq" />

	<main class="faq-page-main" id="top">
		<!-- Pill Breadcrumb Navigation -->
		<nav aria-label="Breadcrumb" class="bubbly-breadcrumb-nav">
			<ol class="breadcrumb-list">
				<li>
					<a href={resolve("/")} class="breadcrumb-link">
						<span class="crumb-icon">🎵</span>
						<span>Harmonica</span>
					</a>
				</li>
				<li aria-current="page" class="breadcrumb-current">
					<span>FAQ</span>
				</li>
			</ol>
		</nav>

		<!-- Cheerful Hero Header -->
		<header class="faq-hero-header">
			<div class="bubble-section-pill">QUESTIONS & ANSWERS</div>
			<h1 class="faq-title">
				Harmonica app questions, <span class="pop-highlight"
					>answered.</span
				>
			</h1>
			<p class="faq-subtitle">
				All the questions I thought off that you might need to know
				about compatible harmonicas, guided audio practice, imports, and
				device setup.
			</p>
		</header>

		<!-- FAQ Accordion List -->
		<section class="faq-accordion-section" aria-label="Questions list">
			<FaqList items={FAQS} />
		</section>

		<!-- Helpful Practice Tip Card -->
		<section class="faq-help-card-section">
			<div class="faq-help-card">
				<div class="help-card-icon">💡</div>
				<div class="help-card-content">
					<h3>Quick tip for best note detection</h3>
					<p>
						Play single, clean notes close to your device’s
						microphone in a quiet room. A standard 10-hole diatonic
						harmonica in the Key of C is all you need to get
						started!
					</p>
				</div>
			</div>
		</section>

		<!-- Cheerful Download CTA -->
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
				{:else}
					<p class="download-status">App Store link coming soon.</p>
				{/if}
			</div>
		</section>
	</main>

	<SiteFooter isFaq={true} />
</div>

<style>
	.bubbly-root {
		min-height: 100vh;
		position: relative;
		overflow-x: hidden;
		background: #0d111a;
		color: #f8fafc;
		transition:
			background 0.25s ease,
			color 0.25s ease;
	}

	.bubbly-root.theme-light {
		background: #fbfbf9;
		color: #1e293b;
	}

	.faq-page-main {
		max-width: 960px;
		margin: 0 auto;
		padding: 36px 24px 80px;
		position: relative;
		z-index: 1;
	}

	/* Breadcrumb Navigation */
	.bubbly-breadcrumb-nav {
		margin-bottom: 24px;
	}

	.breadcrumb-list {
		display: inline-flex;
		align-items: center;
		flex-wrap: wrap;
		list-style: none;
		gap: 8px;
		padding: 6px 14px;
		margin: 0;
		background: rgba(255, 255, 255, 0.05);
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 99px;
		font-size: 13px;
		font-weight: 600;
	}

	:global(.theme-light) .breadcrumb-list {
		background: rgba(0, 0, 0, 0.03);
		border-color: rgba(0, 0, 0, 0.06);
	}

	.breadcrumb-list li + li::before {
		content: "/";
		color: #64748b;
		margin-right: 8px;
	}

	.breadcrumb-link {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		text-decoration: none;
		color: #94a3b8;
		transition: color 0.15s ease;
	}

	.breadcrumb-link:hover {
		color: #3b82f6;
	}

	:global(.theme-light) .breadcrumb-link {
		color: #64748b;
	}

	:global(.theme-light) .breadcrumb-link:hover {
		color: #2563eb;
	}

	.crumb-icon {
		font-size: 13px;
	}

	.breadcrumb-current {
		color: #60a5fa;
		font-weight: 700;
	}

	:global(.theme-light) .breadcrumb-current {
		color: #2563eb;
	}

	/* Hero Header */
	.faq-hero-header {
		text-align: center;
		padding: 24px 0 40px;
		max-width: 760px;
		margin: 0 auto;
	}

	.bubble-section-pill {
		display: inline-block;
		font-size: 12px;
		font-weight: 800;
		letter-spacing: 0.08em;
		background: rgba(59, 130, 246, 0.15);
		color: #93c5fd;
		padding: 4px 14px;
		border-radius: 99px;
		margin-bottom: 16px;
	}

	:global(.theme-light) .bubble-section-pill {
		background: #dbeafe;
		color: #2563eb;
	}

	.faq-title {
		font-family: "Outfit", sans-serif;
		font-size: clamp(34px, 5.5vw, 56px);
		font-weight: 900;
		line-height: 1.1;
		letter-spacing: -0.03em;
		margin: 0 0 16px;
	}

	.pop-highlight {
		color: #3b82f6;
	}

	.faq-subtitle {
		font-size: 18px;
		line-height: 1.6;
		color: #94a3b8;
		margin: 0 0 28px;
	}

	:global(.theme-light) .faq-subtitle {
		color: #64748b;
	}

	/* FAQ Accordion Section */
	.faq-accordion-section {
		margin: 20px 0 48px;
	}

	/* Help Tip Card */
	.faq-help-card-section {
		margin: 40px auto 60px;
		max-width: 820px;
	}

	.faq-help-card {
		display: flex;
		align-items: flex-start;
		gap: 20px;
		background: rgba(59, 130, 246, 0.08);
		border: 1px solid rgba(59, 130, 246, 0.2);
		border-radius: 24px;
		padding: 24px 28px;
	}

	:global(.theme-light) .faq-help-card {
		background: #eff6ff;
		border-color: #bfdbfe;
	}

	.help-card-icon {
		font-size: 28px;
		line-height: 1;
		flex-shrink: 0;
	}

	.help-card-content h3 {
		font-family: "Outfit", sans-serif;
		font-size: 18px;
		font-weight: 800;
		margin: 0 0 6px;
		color: #93c5fd;
	}

	:global(.theme-light) .help-card-content h3 {
		color: #1e40af;
	}

	.help-card-content p {
		margin: 0;
		font-size: 15px;
		line-height: 1.6;
		color: #94a3b8;
	}

	:global(.theme-light) .help-card-content p {
		color: #3b82f6;
	}

	/* CTA Banner Section */
	.bubbly-cta-section {
		max-width: 820px;
		margin: 0 auto 40px;
		padding: 0;
	}

	.bubbly-cta-bubble {
		background: linear-gradient(135deg, #1e283d 0%, #151a28 100%);
		border: 1px solid rgba(59, 130, 246, 0.3);
		border-radius: 36px;
		padding: 56px 32px;
		text-align: center;
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 16px;
	}

	:global(.theme-light) .bubbly-cta-bubble {
		background: linear-gradient(135deg, #eff6ff 0%, #dbeafe 100%);
		border-color: #bfdbfe;
	}

	.cta-emoji-party {
		font-size: 32px;
	}

	.bubbly-cta-bubble h2 {
		font-family: "Outfit", sans-serif;
		font-size: clamp(28px, 4vw, 42px);
		font-weight: 900;
		letter-spacing: -0.02em;
		margin: 0;
	}

	:global(.theme-light) .bubbly-cta-bubble h2 {
		color: #1e3a8a;
	}

	.bubbly-cta-bubble p {
		font-size: 16px;
		color: #94a3b8;
		max-width: 520px;
		margin: 0 0 12px;
		line-height: 1.6;
	}

	:global(.theme-light) .bubbly-cta-bubble p {
		color: #2563eb;
	}

	.bubbly-primary-btn {
		display: inline-flex;
		align-items: center;
		gap: 10px;
		background: linear-gradient(180deg, #3b82f6 0%, #2563eb 100%);
		color: #ffffff;
		text-decoration: none;
		padding: 16px 32px;
		border-radius: 99px;
		font-size: 15px;
		font-weight: 800;
		box-shadow: 0 10px 25px rgba(59, 130, 246, 0.4);
		transition: transform 0.18s cubic-bezier(0.34, 1.56, 0.64, 1);
	}

	.bubbly-primary-btn:hover {
		transform: scale(1.04) translateY(-2px);
	}

	.apple-glyph {
		width: 17px;
		height: 17px;
	}

	.btn-arrow {
		font-size: 16px;
	}

	.download-status {
		color: #64748b;
		font-size: 14px;
	}

	@media (max-width: 640px) {
		.faq-page-main {
			padding: 24px 16px 60px;
		}

		.faq-hero-header {
			padding: 16px 0 28px;
		}

		.faq-subtitle {
			font-size: 16px;
		}

		.bubbly-cta-bubble {
			padding: 40px 20px;
			border-radius: 28px;
		}

		.faq-help-card {
			padding: 18px 20px;
			gap: 14px;
		}
	}
</style>
