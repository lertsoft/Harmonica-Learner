<script lang="ts">
	import { FEATURES } from '$lib/content';
</script>

<section id="features">
	<div class="section-head">
		<h2>Everything between “first note” and “one more song.”</h2>
		<p>
			A focused toolset for learning by doing — whether you’re working through a tune or just
			exploring what your harmonica can do.
		</p>
	</div>
	<div class="features">
		{#each FEATURES as feature}
			<article class="feature">
				<div class="feature-mark" aria-hidden="true">{feature.mark}</div>
				<h3>{feature.title}</h3>
				<p>{feature.body}</p>
			</article>
		{/each}
	</div>
</section>

<style>
	#features {
		scroll-margin-top: 24px;
		margin-bottom: 100px;
	}
	.features {
		display: grid;
		grid-template-columns: 1fr 1fr;
		border-top: 1px solid var(--line);
	}
	.feature {
		padding: 32px 32px 32px 0;
		border-bottom: 1px solid var(--line);
	}
	.feature:nth-child(even) {
		padding-left: 32px;
		border-left: 1px solid var(--line);
	}
	.feature-mark {
		width: 40px;
		height: 40px;
		border-radius: 50%;
		display: grid;
		place-items: center;
		background: linear-gradient(180deg, var(--brass-soft), var(--brass));
		color: #2b2000;
		font-weight: 800;
		margin-bottom: 22px;
	}
	.feature:nth-child(2) .feature-mark {
		background: linear-gradient(180deg, #6ee7f5, var(--cyan));
		color: #06333c;
	}
	.feature:nth-child(3) .feature-mark {
		background: linear-gradient(180deg, #ff9d8d, var(--coral));
		color: #451209;
	}
	.feature:nth-child(4) .feature-mark {
		background: linear-gradient(180deg, #8fe6b8, var(--mint));
		color: #0b2f1f;
	}
	h3 {
		font-size: 22px;
		margin: 0 0 10px;
		letter-spacing: -0.02em;
		font-family: var(--font-display);
	}
	p {
		color: var(--muted);
		line-height: 1.58;
		max-width: 470px;
		margin: 0;
	}
	@media (max-width: 850px) {
		#features {
			margin-bottom: 76px;
		}
		.features {
			grid-template-columns: 1fr;
		}
		.feature,
		.feature:nth-child(even) {
			padding: 26px 0;
			border-left: 0;
		}
	}
</style>
