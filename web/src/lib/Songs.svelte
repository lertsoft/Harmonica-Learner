<script lang="ts">
	import { SONGS } from '$lib/content';
</script>

<section id="songs">
	<div class="section-head">
		<h2>Start with seven. Stay for any song.</h2>
		<p>
			Bundled songs take you from fundamentals to blues. Then import audio, record a tune, or paste
			a link to make anything playable.
		</p>
	</div>
	<div class="grid">
		{#each SONGS as song}
			<article>
				<div class="tag">{song.tag}</div>
				<h3>{song.title}</h3>
				<div class="meta">{song.bpm} BPM · {song.notes} notes</div>
			</article>
		{/each}
		<article class="yours">
			<h3>Your song →</h3>
			<div class="meta">Spotify · YouTube · audio file · mic recording</div>
		</article>
	</div>
</section>

<style>
	#songs {
		margin-bottom: 110px;
		scroll-margin-top: 24px;
	}
	.grid {
		display: grid;
		grid-template-columns: repeat(4, 1fr);
		gap: 14px;
	}
	article {
		background: var(--surface);
		border: 1px solid var(--line);
		border-radius: 16px;
		padding: 20px;
		transition:
			transform 0.18s ease,
			box-shadow 0.18s ease;
	}
	article:hover {
		transform: translateY(-2px);
		box-shadow: var(--shadow-small);
	}
	.tag {
		display: inline-block;
		font-size: 11px;
		font-weight: 800;
		letter-spacing: 0.1em;
		text-transform: uppercase;
		color: var(--blue-deep);
		background: color-mix(in srgb, var(--blue) 10%, transparent);
		border: 1px solid var(--line);
		padding: 4px 9px;
		border-radius: 99px;
		margin-bottom: 14px;
	}
	h3 {
		margin: 0 0 8px;
		font-size: 17px;
		letter-spacing: -0.015em;
		font-family: var(--font-display);
	}
	.meta {
		color: var(--muted);
		font-size: 13px;
	}
	.yours {
		background:
			linear-gradient(135deg, rgba(245, 183, 66, 0.22), transparent 55%),
			var(--surface);
		border-style: dashed;
		border-color: var(--line-strong);
		display: flex;
		flex-direction: column;
		justify-content: center;
	}
	@media (max-width: 850px) {
		#songs {
			margin-bottom: 76px;
		}
		.grid {
			grid-template-columns: repeat(2, 1fr);
		}
	}
	@media (max-width: 480px) {
		.grid {
			grid-template-columns: 1fr;
		}
	}
</style>
