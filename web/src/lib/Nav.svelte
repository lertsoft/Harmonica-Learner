<script lang="ts">
	import { APP_URL, NAV_LINKS } from '$lib/content';
</script>

<nav aria-label="Main navigation">
	<a class="brand" href="#top" aria-label="Harmonica Learner home">
		<span class="brand-mark" aria-hidden="true">
			<svg viewBox="0 0 44 28" fill="none" aria-hidden="true">
				<rect x="2" y="4" width="40" height="20" rx="6" fill="currentColor" opacity="0.14" />
				<rect x="2" y="4" width="40" height="20" rx="6" stroke="currentColor" stroke-width="2" />
				<g fill="currentColor">
					<circle cx="10" cy="14" r="1.8" /><circle cx="16" cy="14" r="1.8" />
					<circle cx="22" cy="14" r="1.8" /><circle cx="28" cy="14" r="1.8" />
					<circle cx="34" cy="14" r="1.8" />
				</g>
			</svg>
		</span>
		<span class="brand-word">Harmonica <em>Learner</em></span>
	</a>
	<div class="links">
		{#each NAV_LINKS as link}
			<a href={link.href}>{link.label}</a>
		{/each}
		<a class="nav-cta" href={APP_URL}>Get the app&nbsp; →</a>
	</div>
</nav>

<style>
	nav {
		min-height: 76px;
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 20px;
		padding-block: 14px;
		font-size: 14px;
		font-weight: 600;
	}
	.brand {
		display: inline-flex;
		align-items: center;
		gap: 10px;
		text-decoration: none;
	}
	.brand-mark {
		width: 42px;
		color: var(--ink);
		display: grid;
		place-items: center;
	}
	.brand-mark svg {
		width: 100%;
		height: auto;
	}
	.brand-word {
		font-family: var(--font-display);
		font-size: 19px;
		letter-spacing: -0.02em;
	}
	.brand-word em {
		font-style: italic;
		color: var(--blue-deep);
	}
	.links {
		display: flex;
		align-items: center;
		gap: 26px;
	}
	.links a {
		text-decoration: none;
		color: var(--muted);
	}
	.links a:hover {
		color: var(--ink);
	}
	.nav-cta {
		background: var(--ink);
		color: var(--paper) !important;
		padding: 11px 17px;
		border-radius: 10px;
	}
	@media (max-width: 850px) {
		.links a:not(.nav-cta) {
			display: none;
		}
		nav {
			min-height: 64px;
		}
	}
</style>
