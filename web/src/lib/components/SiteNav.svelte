<script lang="ts">
	import { resolve } from "$app/paths";
	import { APP_URL } from "$lib/content";
	import { themeState } from "$lib/theme.svelte";

	interface Props {
		activePage?: "home" | "faq";
	}

	let { activePage = "home" }: Props = $props();
</script>

<header class="bubbly-nav">
	<div class="nav-wrapper">
		<a
			href={activePage === "faq" ? resolve("/") : "#top"}
			class="bubbly-brand"
		>
			<div class="brand-mascot-emoji">🎵</div>
			<span class="brand-text"
				>Harmonica: <span class="pop-highlight">Learn to Play</span
				></span
			>
			<span class="cute-tag">For C harmonica</span>
		</a>

		<nav class="nav-links" aria-label="Main navigation">
			<a href={activePage === "faq" ? `${resolve("/")}#how` : "#how"}
				>How It Works</a
			>
			<a href={activePage === "faq" ? `${resolve("/")}#songs` : "#songs"}
				>Songs</a
			>
			<a
				href={resolve("/faq")}
				class:active={activePage === "faq"}
				aria-current={activePage === "faq" ? "page" : undefined}
			>
				FAQ
			</a>
		</nav>

		<div class="nav-actions-group">
			<button
				type="button"
				class="nav-theme-btn"
				onclick={() => themeState.toggleTheme()}
				aria-label="Toggle light or dark theme"
				title="Toggle Light/Dark (Press T)"
			>
				<span class="theme-icon"
					>{themeState.current === "dark" ? "☀️" : "🌙"}</span
				>
				<span class="theme-label"
					>{themeState.current === "dark" ? "Light" : "Dark"}</span
				>
			</button>
			<a
				href={APP_URL ||
					(activePage === "faq"
						? `${resolve("/")}#download`
						: "#download")}
				class="squishy-pill-cta"
			>
				<span>{APP_URL ? "Get the app ★" : "Start learning ✨"}</span>
			</a>
		</div>
	</div>
</header>

<style>
	.bubbly-nav {
		position: sticky;
		top: 0;
		z-index: 100;
		background: rgba(13, 17, 26, 0.85);
		backdrop-filter: blur(20px);
		-webkit-backdrop-filter: blur(20px);
		border-bottom: 1px solid rgba(255, 255, 255, 0.08);
		transition:
			background 0.25s ease,
			border-color 0.25s ease;
	}

	:global(.theme-light) .bubbly-nav,
	:global([data-theme="light"]) .bubbly-nav {
		background: rgba(251, 251, 249, 0.88);
		border-bottom: 1px solid rgba(0, 0, 0, 0.06);
	}

	.nav-wrapper {
		max-width: 1200px;
		margin: 0 auto;
		padding: 16px 24px;
		display: flex;
		align-items: center;
		justify-content: space-between;
	}

	.bubbly-brand {
		display: flex;
		align-items: center;
		gap: 10px;
		text-decoration: none;
		color: inherit;
	}

	.brand-mascot-emoji {
		font-size: 24px;
	}

	.brand-text {
		font-family: "Outfit", sans-serif;
		font-size: 20px;
		font-weight: 800;
		letter-spacing: -0.02em;
	}

	.pop-highlight {
		color: #3b82f6;
	}

	.cute-tag {
		background: rgba(59, 130, 246, 0.15);
		color: #60a5fa;
		font-size: 11px;
		font-weight: 800;
		padding: 3px 10px;
		border-radius: 99px;
	}

	:global(.theme-light) .cute-tag,
	:global([data-theme="light"]) .cute-tag {
		background: #dbeafe;
		color: #2563eb;
	}

	.nav-links {
		display: flex;
		gap: 28px;
		align-items: center;
	}

	.nav-links a {
		text-decoration: none;
		color: #94a3b8;
		font-size: 14.5px;
		font-weight: 600;
		transition: color 0.15s ease;
		position: relative;
	}

	.nav-links a:hover {
		color: #3b82f6;
	}

	:global(.theme-light) .nav-links a,
	:global([data-theme="light"]) .nav-links a {
		color: #64748b;
	}

	:global(.theme-light) .nav-links a:hover,
	:global([data-theme="light"]) .nav-links a:hover {
		color: #2563eb;
	}

	.nav-links a.active {
		color: #60a5fa;
		font-weight: 700;
	}

	:global(.theme-light) .nav-links a.active,
	:global([data-theme="light"]) .nav-links a.active {
		color: #2563eb;
	}

	.nav-links a.active::after {
		content: "";
		position: absolute;
		bottom: -6px;
		left: 0;
		right: 0;
		height: 2px;
		background: #3b82f6;
		border-radius: 99px;
	}

	:global(.theme-light) .nav-links a.active::after,
	:global([data-theme="light"]) .nav-links a.active::after {
		background: #2563eb;
	}

	.nav-actions-group {
		display: flex;
		align-items: center;
		gap: 12px;
	}

	.nav-theme-btn {
		display: inline-flex;
		align-items: center;
		gap: 6px;
		background: rgba(255, 255, 255, 0.08);
		border: 1px solid rgba(255, 255, 255, 0.12);
		color: #e2e8f0;
		padding: 8px 14px;
		border-radius: 99px;
		font-size: 12.5px;
		font-weight: 700;
		cursor: pointer;
		transition: all 0.18s ease;
	}

	.nav-theme-btn:hover {
		background: rgba(255, 255, 255, 0.14);
		border-color: #3b82f6;
		transform: translateY(-1px);
	}

	:global(.theme-light) .nav-theme-btn,
	:global([data-theme="light"]) .nav-theme-btn {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.08);
		color: #334155;
		box-shadow: 0 1px 3px rgba(0, 0, 0, 0.04);
	}

	:global(.theme-light) .nav-theme-btn:hover,
	:global([data-theme="light"]) .nav-theme-btn:hover {
		background: #f1f5f9;
		border-color: #2563eb;
	}

	.theme-icon {
		font-size: 14px;
		line-height: 1;
	}

	.theme-label {
		font-size: 12px;
	}

	.squishy-pill-cta {
		display: inline-flex;
		align-items: center;
		gap: 8px;
		background: #2563eb;
		color: #ffffff;
		text-decoration: none;
		padding: 10px 20px;
		border-radius: 99px;
		font-size: 13.5px;
		font-weight: 800;
		box-shadow: 0 4px 16px rgba(59, 130, 246, 0.35);
		transition: transform 0.18s cubic-bezier(0.34, 1.56, 0.64, 1);
	}

	.squishy-pill-cta:hover {
		transform: scale(1.05) translateY(-1px);
	}

	.squishy-pill-cta:active {
		transform: scale(0.96);
	}

	@media (max-width: 900px) {
		.nav-links {
			display: none;
		}
	}

	@media (max-width: 600px) {
		.nav-wrapper {
			padding: 14px 16px;
			gap: 12px;
		}
		.bubbly-brand {
			min-width: 0;
			flex: 1;
		}
		.brand-text {
			font-size: 16px;
		}
		.cute-tag,
		.theme-label {
			display: none;
		}
		.nav-actions-group {
			gap: 8px;
			flex-shrink: 0;
		}
		.nav-theme-btn {
			min-width: 40px;
			min-height: 40px;
			padding: 8px;
			justify-content: center;
		}
		.squishy-pill-cta {
			padding: 10px 12px;
			font-size: 12px;
			white-space: nowrap;
		}
	}
</style>
