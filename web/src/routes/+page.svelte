<script lang="ts">
	import Nav from '$lib/Nav.svelte';
	import Hero from '$lib/Hero.svelte';
	import TrustBar from '$lib/TrustBar.svelte';
	import HowItWorks from '$lib/HowItWorks.svelte';
	import PracticeDemo from '$lib/PracticeDemo.svelte';
	import Songs from '$lib/Songs.svelte';
	import Features from '$lib/Features.svelte';
	import Quote from '$lib/Quote.svelte';
	import FinalCta from '$lib/FinalCta.svelte';
	import Footer from '$lib/Footer.svelte';
</script>

<svelte:head>
	<title>Harmonica Learner — Turn songs into playable harmonica tabs</title>
</svelte:head>

<Nav />
<main>
	<Hero />
	<TrustBar />
	<HowItWorks />
	<PracticeDemo />
	<Songs />
	<Features />
	<Quote />
	<FinalCta />
</main>
<Footer />
