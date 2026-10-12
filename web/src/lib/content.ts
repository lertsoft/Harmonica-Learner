// Built-in song catalog; visible landing copy lives in Landing.svelte.
export { APP_URL } from '$lib/site';

export const SONGS = [
	{ title: 'C Major Scale', bpm: 90, notes: 15, tag: 'Fundamentals' },
	{ title: 'Mary Had a Little Lamb', bpm: 96, notes: 13, tag: 'Beginner' },
	{ title: 'Twinkle Twinkle', bpm: 90, notes: 14, tag: 'Beginner' },
	{ title: 'Oh Susannah', bpm: 104, notes: 16, tag: 'Folk' },
	{ title: 'Starter Blues', bpm: 98, notes: 8, tag: 'Blues' },
	{ title: 'C Chord Drill', bpm: 88, notes: 11, tag: 'Technique' },
	{ title: 'I–IV–V Chord Walk', bpm: 92, notes: 22, tag: 'Chords' }
];
