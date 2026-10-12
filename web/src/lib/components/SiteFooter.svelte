<script lang="ts">
	import { resolve } from "$app/paths";

	interface Props {
		isFaq?: boolean;
	}

	let { isFaq = false }: Props = $props();
</script>

<footer class="bubbly-footer">
	<div class="footer-inner">
		<div class="footer-nav-links">
			{#if isFaq}
				<a href={resolve("/")}>← Back to Harmonica</a>
				<a href={`${resolve("/")}#how`}>How practice works</a>
				<a href={`${resolve("/")}#songs`}>Explore built-in songs</a>
			{:else}
				<a href={resolve("/faq")}>Questions & answers (FAQ)</a>
				<a href="#how">How practice works</a>
				<a href="#songs">Built-in songs</a>
			{/if}
		</div>
		<span class="footer-specs">
			Requires 10-hole Key of C diatonic harmonica • iPhone & iPad • iOS
			17.6+</span
		>
		<span class="footer-copy"
			>© 2025 - {new Date().getFullYear()} Harmonica: Learn to Play by KosuKobo,
			LLC - Made with ❤️ for harmonica lovers everywhere</span
		>
	</div>
</footer>

<style>
	.bubbly-footer {
		border-top: 1px solid rgba(255, 255, 255, 0.08);
		padding: 32px 24px;
		font-size: 13px;
		color: #94a3b8;
		position: relative;
		z-index: 1;
		transition:
			border-color 0.25s ease,
			color 0.25s ease;
	}

	:global(.theme-light) .bubbly-footer,
	:global([data-theme="light"]) .bubbly-footer {
		border-top: 1px solid rgba(0, 0, 0, 0.06);
		color: #64748b;
	}

	.footer-inner {
		max-width: 1200px;
		margin: 0 auto;
		display: flex;
		justify-content: space-between;
		align-items: center;
		flex-wrap: wrap;
		gap: 16px;
	}

	.footer-nav-links {
		display: flex;
		flex-wrap: wrap;
		gap: 18px;
	}

	.footer-nav-links a {
		text-decoration: none;
		color: inherit;
		transition: color 0.15s ease;
	}

	.footer-nav-links a:hover {
		color: #3b82f6;
		text-decoration: underline;
	}

	:global(.theme-light) .footer-nav-links a:hover,
	:global([data-theme="light"]) .footer-nav-links a:hover {
		color: #2563eb;
	}

	@media (max-width: 768px) {
		.footer-inner {
			flex-direction: column;
			align-items: flex-start;
			gap: 12px;
		}
	}
</style>
