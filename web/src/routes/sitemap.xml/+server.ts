import { PAGES, canonicalUrl } from '$lib/site';
export const prerender = true;
export function GET() {
 const urls = PAGES.map(({ path }) => `<url><loc>${canonicalUrl(path)}</loc></url>`).join('');
 return new Response(`<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${urls}</urlset>\n`, {
  headers: { 'Content-Type': 'application/xml; charset=utf-8' }
 });
}
