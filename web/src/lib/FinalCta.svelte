<script lang="ts">
	import { APP_URL, FINAL } from '$lib/content';
</script>

<section class="final">
	<div class="final-kicker">Key of C · 10-hole diatonic</div>
	<h2>{FINAL.title}</h2>
	<p>{FINAL.body}</p>
	<a class="button primary" href={APP_URL}>{FINAL.cta}&nbsp; →</a>
	<div class="final-note">Free to try · No account for offline practice</div>
</section>

<style>
	.final {
		background:
			radial-gradient(480px 240px at 50% 0%, rgba(201, 150, 43, 0.18), transparent 65%),
			var(--surface);
		border: 1px solid var(--line);
		padding: 72px 40px;
		text-align: center;
		border-radius: 88px 24px 24px 24px;
		margin-bottom: 30px;
	}
	.final-kicker {
		font-size: 12px;
		font-weight: 800;
		letter-spacing: 0.16em;
		text-transform: uppercase;
		color: var(--brass);
		margin-bottom: 18px;
	}
	h2 {
		font-family: var(--font-display);
		font-size: clamp(42px, 5.4vw, 72px);
		line-height: 0.96;
		letter-spacing: -0.04em;
		max-width: 760px;
		margin: 0 auto 18px;
		text-wrap: balance;
	}
	p {
		color: var(--muted);
		font-size: 18px;
		margin: 0 0 28px;
	}
	.final-note {
		margin-top: 16px;
		font-size: 13px;
		color: var(--muted);
	}
	@media (max-width: 850px) {
		.final {
			padding: 60px 22px;
			border-radius: 56px 18px 18px 18px;
		}
	}
</style>
