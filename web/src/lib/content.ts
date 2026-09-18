// Single source of truth for landing copy.
// Mirrors the original "Harmonica Learner Landing Page.html" + README features.
// No imports from the iOS app — this package stays independent.

export const APP_URL = 'https://getharmonica.app';

export const NAV_LINKS = [
	{ label: 'How it works', href: '#how' },
	{ label: 'Practice', href: '#practice' },
	{ label: 'Songs', href: '#songs' },
	{ label: 'Features', href: '#features' }
];

export const HERO = {
	eyebrow: 'Your pocket harmonica coach',
	titleA: 'Turn the songs you love',
	titleAccent: 'into playable harmonica tabs.',
	lead: 'Paste a Spotify or YouTube song link. Harmonica Learner extracts the lead melody and maps it to tabs for a Key of C diatonic harmonica, then gives you live pitch feedback as you practice.',
	primaryCta: 'Start learning',
	secondaryCta: 'See practice mode',
	finePrint: 'Requires a standard 10-hole diatonic harmonica in Key of C.'
};

export const TRUST = [
	{ value: 'Any song', hint: 'Start from Spotify or YouTube' },
	{ value: 'Instant feedback', hint: 'Real-time pitch detection' },
	{ value: 'Your pace', hint: 'Beginner-friendly pitch windows' }
];

export const STEPS = [
	{
		num: '01',
		title: 'Paste your song',
		body: 'Drop in a Spotify or YouTube link. Harmonica Learner extracts the lead melody for a Key of C diatonic harmonica.',
		visual: 'link' as const,
		visualText: 'youtube.com/watch?v=your-song'
	},
	{
		num: '02',
		title: 'Get playable tabs',
		body: 'See each hole and breath direction in a simple sequence you can follow at a glance.',
		visual: 'tabs' as const,
		visualText: '4↑ 5↓ 5↑ 6↑'
	},
	{
		num: '03',
		title: 'Play. Hear. Improve.',
		body: 'Your phone listens as you play and guides you toward the right note without breaking your flow.',
		visual: 'feedback' as const,
		visualText: ''
	}
];

export type DemoNote = { tab: string; action: string; pitch: string };

export const DEMO_NOTES: DemoNote[] = [
	{ tab: '4↑', action: 'Blow through hole 4', pitch: 'C5' },
	{ tab: '5↓', action: 'Draw through hole 5', pitch: 'F5' },
	{ tab: '5↑', action: 'Blow through hole 5', pitch: 'E5' },
	{ tab: '6↑', action: 'Blow through hole 6', pitch: 'G5' }
];

export const FEATURES = [
	{
		mark: '~',
		title: 'Live pitch detection',
		body: 'See the note you’re playing in real time and make small adjustments while the sound is still fresh.'
	},
	{
		mark: '↕',
		title: 'Blow and draw guidance',
		body: 'Clear hole numbers and breath directions remove the guesswork from reading harmonica tabs.'
	},
	{
		mark: '◉',
		title: 'Freestyle recording',
		body: 'Capture practice sessions and listen back to the phrases you want to keep — or clean up.'
	},
	{
		mark: '±',
		title: 'Adaptive tolerance',
		body: 'Loosen the feedback while you learn the shape of a song, then raise the bar as your control improves. 30¢ → 15¢ over 20 attempts.'
	}
];

export const SONGS = [
	{ title: 'C Major Scale', bpm: 90, notes: 15, tag: 'Fundamentals' },
	{ title: 'Mary Had a Little Lamb', bpm: 96, notes: 13, tag: 'Beginner' },
	{ title: 'Twinkle Twinkle', bpm: 90, notes: 14, tag: 'Beginner' },
	{ title: 'Oh Susannah', bpm: 104, notes: 16, tag: 'Folk' },
	{ title: 'Starter Blues', bpm: 98, notes: 8, tag: 'Blues' },
	{ title: 'C Chord Drill', bpm: 88, notes: 11, tag: 'Technique' },
	{ title: 'I–IV–V Chord Walk', bpm: 92, notes: 22, tag: 'Chords' }
];

export const QUOTE = {
	text: 'I finally practice because the songs are mine. One note at a time, and the app hears me.',
	name: 'Early player',
	role: 'Harmonica Learner beta'
};

export const FINAL = {
	title: 'Your next song is already in your pocket.',
	body: 'Choose a track. Pick up your harmonica. Start with one note.',
	cta: 'Get Harmonica Learner'
};
