import assert from 'node:assert/strict';
import { readFile, readdir, stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { join, relative } from 'node:path';
import { gzipSync } from 'node:zlib';

const build = fileURLToPath(new URL('../build/', import.meta.url));
const read = (path) => readFile(join(build, path), 'utf8');
const sitemap = await read('sitemap.xml');
const urls = [...sitemap.matchAll(/<loc>([^<]+)<\/loc>/g)].map((m) => new URL(m[1]));
assert(urls.length > 0, 'Sitemap must contain pages');
assert.equal(new Set(urls.map(String)).size, urls.length, 'Duplicate sitemap URL');
const origin = urls[0].origin;
const pages = new Map();
const pageFile = (path) => path === '/' ? 'index.html' : `${path.slice(1)}.html`;
for (const url of urls) {
 assert.equal(url.origin, origin, 'Mixed sitemap origins');
 assert(!url.search && !url.hash, 'Sitemap must contain clean canonical URLs');
 pages.set(url.pathname, await read(pageFile(url.pathname)));
}
const references = new Set(['/']);
const titles = new Set();
const descriptions = new Set();
const tagAttributes = (tag) => Object.fromEntries([...tag.matchAll(/([\w:-]+)="([^"]*)"/g)].map((m) => [m[1], m[2]]));
for (const [path, html] of pages) {
 assert.equal([...html.matchAll(/<h1\b/g)].length, 1, `${path}: expected one rendered H1`);
 assert(!/noindex/i.test(html), `${path}: noindex found`);
 assert(!/fonts\.googleapis|fonts\.gstatic/.test(html), `${path}: external fonts`);
 const title = html.match(/<title>([^<]+)<\/title>/)?.[1];
 assert(title && !titles.has(title), `${path}: missing or duplicate title`); titles.add(title);
 const metas = [...html.matchAll(/<meta\b[^>]*>/g)].map((m) => tagAttributes(m[0]));
 const descriptionTags = metas.filter((m) => m.name === 'description');
 assert.equal(descriptionTags.length, 1, `${path}: expected one description`);
 const description = descriptionTags[0].content;
 assert(description && !descriptions.has(description), `${path}: missing or duplicate description`); descriptions.add(description);
 const canonicals = [...html.matchAll(/<link\b[^>]*>/g)].map((m) => tagAttributes(m[0])).filter((a) => a.rel === 'canonical');
 assert.equal(canonicals.length, 1, `${path}: expected one canonical`);
 assert.equal(canonicals[0].href, new URL(path, origin).href, `${path}: canonical mismatch`);
 assert.equal(metas.find((m) => m.property === 'og:url')?.content, canonicals[0].href);
 const ids = [...html.matchAll(/\bid="([^"]+)"/g)].map((m) => m[1]);
 assert.equal(new Set(ids).size, ids.length, `${path}: duplicate element IDs`);
 for (const match of html.matchAll(/<(?:a|link|script|img)\b[^>]*>/g)) {
  const attrs = tagAttributes(match[0]);
  if (match[0].startsWith('<img')) {
   assert('alt' in attrs, `${path}: missing image alt`);
   assert(attrs.width && attrs.height, `${path}: image dimensions not reserved`);
   assert(!/\.(?:png|jpe?g)(?:$|\?)/i.test(attrs.src), `${path}: raster image needs a modern format`);
  }
  const href = attrs.href || attrs.src;
  if (!href || /^(data:|mailto:|tel:)/.test(href)) continue;
  const target = new URL(href, new URL(path, origin));
  if (target.origin !== origin) continue;
  if (pages.has(target.pathname)) {
   if (match[0].startsWith('<a')) references.add(target.pathname);
   if (target.hash) assert(pages.get(target.pathname).includes(`id="${decodeURIComponent(target.hash.slice(1))}"`), `${path}: broken fragment ${href}`);
  } else {
   assert((await stat(join(build, target.pathname))).isFile(), `${path}: missing asset or route ${href}`);
  }
 }
 const schemas = [...html.matchAll(/<script type="application\/ld\+json">([\s\S]*?)<\/script>/g)].map((m) => JSON.parse(m[1]));
 const faq = schemas.find((s) => s['@type'] === 'FAQPage');
 assert(faq && faq.mainEntity.length > 0, `${path}: missing FAQ schema`);
 for (const question of faq.mainEntity) {
  assert(html.includes(question.name), `${path}: FAQ question is not on page`);
  assert(html.includes(question.acceptedAnswer.text), `${path}: FAQ answer is not on page`);
 }
 if (path !== '/') assert(schemas.some((s) => s['@type'] === 'BreadcrumbList'), `${path}: missing breadcrumbs`);
 assert(gzipSync(html).length < 40_000, `${path}: compressed HTML exceeds 40KB budget`);
}
for (const path of pages.keys()) assert(references.has(path), `Orphan page: ${path}`);
const robots = await read('robots.txt');
assert(/User-agent: \*/.test(robots) && /Allow: \//.test(robots), 'Crawling must be allowed');
assert(!/Disallow:\s*\//i.test(robots), 'Crawling is blocked');
assert(robots.includes(`Sitemap: ${origin}/sitemap.xml`), 'robots sitemap mismatch');
const notFound = await read('404.html');
assert(notFound.includes('href="/"') && notFound.includes('href="/faq"'), '404 must provide recovery links');
assert(!notFound.includes('modulepreload'), '404 must not be an SPA fallback');
async function files(directory) {
 const items = await readdir(directory, { withFileTypes: true });
 return (await Promise.all(items.map((item) => item.isDirectory() ? files(join(directory, item.name)) : join(directory, item.name)))).flat();
}
const allFiles = await files(build);
const htmlFiles = allFiles.filter((file) => file.endsWith('.html') && relative(build, file) !== '404.html');
assert.equal(htmlFiles.length, pages.size, 'A built page is missing from the sitemap inventory');
for (const file of htmlFiles) assert([...pages.keys()].some((path) => pageFile(path) === relative(build, file)), `Page missing from sitemap: ${file}`);
const assets = allFiles.filter((file) => file.includes('_app/immutable/')); 
const totals = { jsGzip: 0, cssGzip: 0, fonts: 0 };
for (const asset of assets) {
 const data = await readFile(asset);
 if (asset.endsWith('.js')) totals.jsGzip += gzipSync(data).length;
 if (asset.endsWith('.css')) totals.cssGzip += gzipSync(data).length;
 if (asset.endsWith('.woff2')) totals.fonts += data.length;
}
assert(totals.jsGzip < 60_000, 'JavaScript exceeds 60KB gzip budget');
assert(totals.cssGzip < 15_000, 'CSS exceeds 15KB gzip budget');
assert(totals.fonts < 65_000, 'Fonts exceed 65KB budget');
console.log(`SEO audit passed: ${pages.size} prerendered pages; metadata, sitemap, robots, schema, internal links, assets, and budgets verified.`);
console.log(JSON.stringify(totals));
