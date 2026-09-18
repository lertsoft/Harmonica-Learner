# Harmonica Learner — Landing Page (`web/`)

Independent SvelteKit landing page. No dependency on the iOS app in `../Harmonica/`.
Static export for GitHub Pages / Netlify / Vercel / Cloudflare.

## Develop

```bash
cd web
npm install
npm run dev
```

## Check + build

```bash
npm run check
npm run build
npm run preview
```

Output goes to `web/build/` via `@sveltejs/adapter-static` (`fallback: index.html`).

## Structure

- `src/routes/+page.svelte` — page composition
- `src/lib/content.ts` — all copy (single source of truth)
- `src/lib/*.svelte` — Nav, Hero, TrustBar, HowItWorks, PracticeDemo, Songs, Features, Quote, FinalCta, Footer, PhoneMock
- `src/lib/theme.css` — design tokens, light/dark, responsive
- `static/` — robots, favicon output, OG assets

## Deploy

Any static host serving `build/` works. Example (Cloudflare Pages, ` Harmonica` repo):

- Build command: `npm --prefix web install && npm --prefix web run build`
- Output directory: `web/build`
