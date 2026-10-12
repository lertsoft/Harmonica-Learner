<script lang="ts">
	import Landing from "$lib/Landing.svelte";
	import Seo from "$lib/components/Seo.svelte";
	import { PAGES, jsonLd } from "$lib/site";
	import { FAQS, faqSchema } from "$lib/faq";
	import { themeState } from "$lib/theme.svelte";
</script>

<Seo {...PAGES[0]} />
<svelte:head>
 {@html `<script type="application/ld+json">${jsonLd(faqSchema(FAQS.slice(0, 3)))}</script>`}
</svelte:head>

<main
	class="page-container"
	class:is-light={themeState.current === "light"}
	data-theme={themeState.current}
>
	<Landing theme={themeState.current} onToggleTheme={() => themeState.toggleTheme()} />
</main>

<style>
	.page-container {
		min-height: 100vh;
		position: relative;
	}
</style>
