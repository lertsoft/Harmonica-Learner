<script lang="ts">
	import '$lib/theme.css';
	import favicon from '$lib/assets/favicon.svg';

	let { children } = $props();
</script>

<svelte:head>
	<link rel="icon" href={favicon} />
	<meta
		name="description"
		content="Harmonica Learner turns Spotify and YouTube songs into playable Key of C harmonica tabs with live pitch feedback."
	/>
	<meta property="og:title" content="Harmonica Learner — Turn songs into playable harmonica tabs" />
	<meta
		property="og:description"
		content="Paste a song link. Get hole + blow/draw tabs. Practice with real-time pitch feedback."
	/>
	<meta property="og:type" content="website" />
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="anonymous" />
	<!-- eslint-disable-next-line svelte/no-navigation-without-resolve -->
	<link
		href="https://fonts.googleapis.com/css2?family=Fraunces:ital,opsz,wght@0,9..144,500;0,9..144,650;0,9..144,750;1,9..144,550;1,9..144,650&family=Instrument+Sans:wght@400;500;600;700&display=swap"
		rel="stylesheet"
	/>
</svelte:head>

<div class="wrap" id="top">
	{@render children()}
</div>
