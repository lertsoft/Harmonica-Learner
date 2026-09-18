<script lang="ts">
	import { APP_URL } from '$lib/content';
</script>

<footer>
	<span>Harmonica Learner — pocket harmonica coach</span>
	<span><a href={APP_URL}>getharmonica.app</a> · iPhone · Key of C</span>
</footer>

<style>
	footer {
		padding: 24px 0 38px;
		display: flex;
		justify-content: space-between;
		gap: 8px;
		color: var(--muted);
		font-size: 13px;
	}
	footer a {
		color: var(--muted);
	}
	@media (max-width: 850px) {
		footer {
			flex-direction: column;
		}
	}
</style>
