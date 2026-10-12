# Harmonica landing page

Independent SvelteKit site for <https://www.getharmonica.app/>. The landing page and FAQ are rendered on the server at build time and exported as complete HTML. JavaScript hydrates the audio examples; page content, links, metadata, FAQ answers, and breadcrumbs do not depend on it.

## Develop and verify

```bash
cd web
npm install
npm run dev
npm run check
npm run build
npm run check:seo
npm run preview
```

`build/` contains the deployable static site, including `index.html`, `faq.html`, `sitemap.xml`, `robots.txt`, and a standalone `404.html`. There is no SPA fallback. Unknown URLs must return HTTP 404 instead of rewriting to the home page.

## Configuration

Copy `.env.example` to `.env` for local settings, or set these variables in the hosting build environment:

- `PUBLIC_SITE_URL`: canonical HTTPS origin, default `https://www.getharmonica.app`.
- `PUBLIC_APP_STORE_URL`: direct `https://apps.apple.com/...` product URL. Leave empty until a real listing is available; the download section explains that the link is coming soon.
- `PUBLIC_GOOGLE_SITE_VERIFICATION`: optional Search Console URL-prefix verification token. The domain property is already verified, so this is normally unnecessary.

Rebuild after changing these variables. Never use the landing page itself as the App Store destination.
