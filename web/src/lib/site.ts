import * as buildEnv from '$env/static/public';
const env: Record<string, string | undefined> = { ...buildEnv };

// Shared by metadata, the sitemap, and robots.txt. Set at build time.
const configuredOrigin = env.PUBLIC_SITE_URL || 'https://www.getharmonica.app';
const origin = new URL(configuredOrigin);
if (origin.protocol !== 'https:' || origin.pathname !== '/' || origin.search || origin.hash || origin.username || origin.password) {
    throw new Error('PUBLIC_SITE_URL must be an HTTPS origin without a path or credentials.');
}
export const SITE_URL = origin.origin;
export const APP_URL = env.PUBLIC_APP_STORE_URL || '';
if (APP_URL && (new URL(APP_URL).protocol !== 'https:' || new URL(APP_URL).hostname !== 'apps.apple.com' || !/^\/(?:[a-z]{2}\/)?app\/(?:[^/]+\/)?id\d+\/?$/.test(new URL(APP_URL).pathname))) {
    throw new Error('PUBLIC_APP_STORE_URL must link directly to apps.apple.com.');
}
export const SEARCH_CONSOLE_VERIFICATION = env.PUBLIC_GOOGLE_SITE_VERIFICATION || '';
export const PAGES = [
    { path: '/', title: 'Harmonica: Learn to Play — C Harmonica Practice App', description: 'Learn harmonica with guided songs, clear hole and breath cues, and live pitch feedback. Practice on a 10-hole C harmonica with your iPhone or iPad.' },
    { path: '/faq', title: 'Harmonica App FAQ — Songs, Imports & Guided Practice', description: 'Find answers about guided practice, audio imports, the five Music Library import trial, and the one-time purchase in Harmonica: Learn to Play.' }
];
export const canonicalUrl = (path: string) => new URL(path, SITE_URL).href;
export const jsonLd = (value: unknown) => JSON.stringify(value).replace(/</g, '\\u003c');
