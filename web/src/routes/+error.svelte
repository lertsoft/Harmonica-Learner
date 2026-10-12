<script lang="ts">
 import { page } from '$app/state';
 import { resolve } from '$app/paths';
</script>
<svelte:head>
 <title>{page.status === 404 ? 'Page not found' : 'Page unavailable'} — Harmonica</title>
 <meta name="description" content="Return to the Harmonica app overview or find answers about songs, imports, and guided practice in the FAQ." />
</svelte:head>
<main>
 <p>Harmonica: Learn to Play</p>
 <h1>{page.status === 404 ? 'We couldn’t find that page.' : 'This page is temporarily unavailable.'}</h1>
 <p>Choose where to go next.</p>
 <nav aria-label="Find a page"><a href={resolve('/')}>Harmonica home</a><a href={resolve('/faq')}>Questions and answers</a></nav>
</main>
<style>
 main { max-width: 680px; margin: 12vh auto; padding: 24px; }
 h1 { font: 700 clamp(36px, 6vw, 56px)/1.15 'Outfit', sans-serif; }
 nav { display: flex; flex-wrap: wrap; gap: 24px; }
 a { color: #93c5fd; }
</style>
