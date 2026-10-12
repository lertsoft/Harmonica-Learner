<script lang="ts">
	import { onMount } from 'svelte';
	import '$lib/theme.css';
	import favicon from '$lib/assets/favicon.svg';
	import outfit from '$lib/assets/fonts/outfit-latin.woff2';
	import { SEARCH_CONSOLE_VERIFICATION } from '$lib/site';
	import { themeState } from '$lib/theme.svelte';

	let { children } = $props();

	onMount(() => {
		themeState.init();
	});

	function handleKeydown(e: KeyboardEvent) {
		if (['INPUT', 'TEXTAREA'].includes((e.target as HTMLElement)?.tagName)) return;
		if (e.key.toLowerCase() === 't') {
			themeState.toggleTheme();
		}
	}
</script>

<svelte:window onkeydown={handleKeydown} />

<svelte:head>
	<link rel="icon" href={favicon} />
	<link rel="preload" href={outfit} as="font" type="font/woff2" crossorigin="anonymous" />
	{#if SEARCH_CONSOLE_VERIFICATION}<meta name="google-site-verification" content={SEARCH_CONSOLE_VERIFICATION} />{/if}
</svelte:head>

<div class="layout-root" class:theme-light={themeState.current === 'light'} data-theme={themeState.current}>
	{@render children()}
</div>
