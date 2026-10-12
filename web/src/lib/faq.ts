export const FAQS = [
    { question: 'What harmonica do I need?', answer: 'Use a standard 10-hole diatonic harmonica in the key of C with Richter tuning. The tabs show which hole to play and whether to blow or draw. We personally use a Lee Oskar.' },
    { question: 'How does guided practice work?', answer: 'Choose a built-in song or a saved practice line. Your device listens through the microphone and shows live pitch feedback. Hold the target note steadily in tune to move to the next note. You can also hear a reference tone.' },
    { question: 'Is Harmonica free to use?', answer: 'Start with built-in songs and up to five successfully saved Music Library imports. After the fifth Music Library import, a one-time purchase is required to continue practicing and importing. There is no subscription. The app shows the current localized price and lets you restore an existing purchase.' },
    { question: 'Can I import my own songs?', answer: 'You can add an MP3 audio file from Files, choose a downloaded and unprotected Music Library track, or record a song playing nearby. Harmonica analyzes the audio on your device and suggests a C-harmonica arrangement when it finds usable notes. Cloud-only items and Apple Music subscription tracks cannot be imported through Music Library.' },
    { question: 'How accurate are imported harmonica tabs?', answer: 'Arrangements are approximate. Clear melodies are easier to analyze than dense mixes. Suggestions may change key or register and turn chord tones into notes you play one at a time. If no reliable notes are found, the app saves the original audio without inventing a practice melody.' },
    { question: 'Can I paste a Spotify or YouTube link?', answer: 'Not at the moment' },
    { question: 'Can I record my own riffs?', answer: 'Freestyle mode lets you record audio and captured notes. Save a riff to your local library, listen back, or return to its notes for guided practice.' },
    { question: 'Which devices does Harmonica support?', answer: 'Harmonica supports iPhone and iPad running iOS or iPadOS 17.6 or later. You need microphone permission for live pitch feedback and recording.' }
];
export const faqSchema = (items: typeof FAQS) => ({
    '@context': 'https://schema.org', '@type': 'FAQPage',
    mainEntity: items.map(({ question, answer }) => ({ '@type': 'Question', name: question, acceptedAnswer: { '@type': 'Answer', text: answer } }))
});
