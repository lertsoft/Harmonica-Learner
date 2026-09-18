<script lang="ts">
	import { TRUST } from '$lib/content';
</script>

<section class="trust" aria-label="Product highlights">
	{#each TRUST as item}
		<div>{item.value}<span>{item.hint}</span></div>
	{/each}
</section>
<p class="hardware-notice">Optimized for Key of C 10-Hole Diatonic</p>

<style>
	.trust {
		border-top: 1px solid var(--line);
		border-bottom: 1px solid var(--line);
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		padding: 20px 0;
	}
	.trust div {
		text-align: center;
		font-weight: 800;
		font-size: 17px;
		letter-spacing: -0.01em;
	}
	.trust span {
		display: block;
		color: var(--muted);
		font-size: 12.5px;
		font-weight: 500;
		margin-top: 3px;
	}
	.hardware-notice {
		text-align: center;
		color: var(--muted);
		font-size: 12.5px;
		font-weight: 700;
		letter-spacing: 0.12em;
		text-transform: uppercase;
		margin: 18px 0 96px;
	}
	@media (max-width: 850px) {
		.trust {
			grid-template-columns: 1fr;
			gap: 16px;
		}
		.trust div:not(:last-child) {
			padding-bottom: 16px;
			border-bottom: 1px solid var(--line);
		}
		.hardware-notice {
			margin-bottom: 72px;
		}
	}
</style>
