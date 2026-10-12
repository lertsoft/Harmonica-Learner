<script lang="ts">
 import { canonicalUrl } from '$lib/site';
 let { title, description, path }: { title: string; description: string; path: string } = $props();
</script>
<svelte:head>
 <title>{title}</title>
 <meta name="description" content={description} />
 <link rel="canonical" href={canonicalUrl(path)} />
 <meta property="og:title" content={title} />
 <meta property="og:description" content={description} />
 <meta property="og:url" content={canonicalUrl(path)} />
 <meta property="og:type" content="website" />
 <meta property="og:site_name" content="Harmonica: Learn to Play" />
 <meta name="twitter:card" content="summary" />
 <meta name="twitter:title" content={title} />
 <meta name="twitter:description" content={description} />
</svelte:head>
