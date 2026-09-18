<script lang="ts">
	import { STEPS } from '$lib/content';
</script>

<section id="how">
	<div class="section-head">
		<h2>From link to lick in three steps.</h2>
		<p>Skip the hunt for confusing tab sheets. Bring the music you’re excited to play, and get a guided path through it.</p>
	</div>
	<div class="steps">
		{#each STEPS as step, i}
			<article class="step" style="--pos: {i}">
				<div class="step-num">{step.num}</div>
				<h3>{step.title}</h3>
				<p>{step.body}</p>
				{#if step.visual === 'link'}
					<div class="mini-link">{step.visualText}</div>
				{:else if step.visual === 'tabs'}
					<div class="mini-tabs" aria-label="Example tabs 4 blow, 5 draw, 5 blow, 6 blow">
						<i>4↑</i><i class="on">5↓</i><i>5↑</i><i>6↑</i>
					</div>
				{:else}
					<div class="mini-feedback" aria-hidden="true">
						<div class="feedback-line"></div>
						<div class="feedback-line hot"></div>
						<div class="feedback-line"></div>
					</div>
				{/if}
			</article>
		{/each}
	</div>
</section>

<style>
	#how {
		scroll-margin-top: 24px;
		margin-bottom: 110px;
	}
	.steps {
		display: grid;
		grid-template-columns: repeat(3, 1fr);
		gap: 18px;
	}
	.step {
		background: var(--surface);
		min-height: 330px;
		padding: 28px;
		border: 1px solid var(--line);
		position: relative;
		overflow: hidden;
		transition:
			transform 0.2s ease,
			box-shadow 0.2s ease;
	}
	.step:hover {
		transform: translateY(-3px);
		box-shadow: var(--shadow-small);
	}
	.step:nth-child(1) {
		border-radius: 64px 16px 16px 16px;
	}
	.step:nth-child(2) {
		border-radius: 16px;
	}
	.step:nth-child(3) {
		border-radius: 16px 16px 64px 16px;
	}
	.step::after {
		content: '';
		position: absolute;
		top: -40px;
		right: -40px;
		width: 130px;
		height: 130px;
		border-radius: 50%;
		background: radial-gradient(circle, rgba(201, 150, 43, 0.16), transparent 70%);
	}
	.step-num {
		font-family: var(--font-display);
		font-size: 52px;
		color: var(--blue);
		line-height: 1;
	}
	.step h3 {
		font-size: 21px;
		margin: 34px 0 10px;
		letter-spacing: -0.02em;
	}
	.step p {
		color: var(--muted);
		line-height: 1.58;
		margin: 0;
		font-size: 15.5px;
	}
	.mini-link {
		margin-top: 28px;
		background: var(--paper);
		border: 1px solid var(--line);
		padding: 13px;
		border-radius: 10px;
		font-size: 12.5px;
		color: var(--muted);
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		font-family: ui-monospace, monospace;
	}
	.mini-tabs {
		margin-top: 28px;
		display: flex;
		gap: 7px;
	}
	.mini-tabs i {
		width: 40px;
		height: 56px;
		border: 1px solid var(--line-strong);
		background: var(--paper);
		border-radius: 8px;
		display: flex;
		align-items: center;
		justify-content: center;
		font-style: normal;
		font-weight: 800;
	}
	.mini-tabs i.on {
		background: var(--blue);
		border-color: var(--blue);
		color: #fff;
	}
	.mini-feedback {
		margin-top: 28px;
	}
	.feedback-line {
		height: 8px;
		background: var(--line);
		border-radius: 5px;
		margin: 10px 0;
	}
	.feedback-line.hot {
		width: 78%;
		background: var(--cyan);
	}
	@media (max-width: 850px) {
		#how {
			margin-bottom: 76px;
		}
		.steps {
			grid-template-columns: 1fr;
		}
		.step {
			min-height: 260px;
		}
	}
</style>
