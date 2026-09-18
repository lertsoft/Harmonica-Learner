<script lang="ts">
	import { QUOTE } from '$lib/content';
</script>

<section class="quote">
	<div class="quote-art" aria-hidden="true">
		<svg viewBox="0 0 220 130" fill="none">
			<rect x="8" y="26" width="204" height="78" rx="21" fill="#F6C85F" stroke="#17233B" stroke-width="7" />
			<path d="M23 42h174M23 89h174" stroke="#17233B" stroke-width="6" />
			<g fill="#17233B">
				<circle cx="37" cy="65" r="7" /><circle cx="54" cy="65" r="7" />
				<circle cx="71" cy="65" r="7" /><circle cx="88" cy="65" r="7" />
				<circle cx="105" cy="65" r="7" /><circle cx="122" cy="65" r="7" />
				<circle cx="139" cy="65" r="7" /><circle cx="156" cy="65" r="7" />
				<circle cx="173" cy="65" r="7" /><circle cx="190" cy="65" r="7" />
			</g>
		</svg>
	</div>
	<div>
		<blockquote>“{QUOTE.text}”</blockquote>
		<cite>{QUOTE.name} — {QUOTE.role}</cite>
	</div>
</section>

<style>
	.quote {
		display: grid;
		grid-template-columns: 240px 1fr;
		gap: 48px;
		align-items: center;
		margin-bottom: 100px;
		background: var(--surface);
		border: 1px solid var(--line);
		border-radius: var(--radius-lg);
		padding: 40px;
	}
	.quote-art {
		height: 220px;
		border-radius: 22px;
		background:
			radial-gradient(220px 140px at 50% 20%, rgba(245, 183, 66, 0.5), transparent 70%),
			linear-gradient(135deg, var(--coral), #a92c18);
		display: grid;
		place-items: center;
		padding: 20px;
	}
	.quote-art svg {
		width: 150px;
		height: auto;
	}
	blockquote {
		font-family: var(--font-display);
		font-size: clamp(26px, 3.4vw, 44px);
		line-height: 1.1;
		letter-spacing: -0.03em;
		margin: 0 0 16px;
		text-wrap: balance;
	}
	cite {
		font-style: normal;
		color: var(--muted);
		font-size: 14px;
	}
	@media (max-width: 850px) {
		.quote {
			grid-template-columns: 1fr;
			gap: 24px;
			margin-bottom: 76px;
			padding: 28px;
		}
		.quote-art {
			width: 180px;
			height: 150px;
		}
	}
</style>
