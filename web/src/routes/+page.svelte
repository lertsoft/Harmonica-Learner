<script lang="ts">
	import { onMount } from "svelte";
	import Landing from "$lib/Landing.svelte";

	let theme = $state<"dark" | "light">("dark");

	onMount(() => {
		const params = new URLSearchParams(window.location.search);
		const tParam = params.get("theme");
		if (tParam === "light" || tParam === "dark") {
			theme = tParam;
		} else {
			const saved = localStorage.getItem("harmonica_theme");
			if (saved === "light" || saved === "dark") {
				theme = saved;
			}
		}
	});

	function handleToggleTheme() {
		theme = theme === "dark" ? "light" : "dark";
		if (typeof window !== "undefined") {
			localStorage.setItem("harmonica_theme", theme);
			const url = new URL(window.location.href);
			url.searchParams.set("theme", theme);
			window.history.replaceState({}, "", url.toString());
		}
	}
</script>

<svelte:head>
	<title
		>Harmonica: Learn to Play - Turn any song into playable harmonica tabs</title
	>
</svelte:head>

<main
	class="page-container"
	class:is-light={theme === "light"}
	data-theme={theme}
>
	<Landing {theme} onToggleTheme={handleToggleTheme} />
</main>

<style>
	.page-container {
		min-height: 100vh;
		position: relative;
	}
</style>
