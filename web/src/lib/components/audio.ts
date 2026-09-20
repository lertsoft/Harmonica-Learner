// Realistic Web Audio harmonica reed synthesizer
// Generates warm acoustic reed tones with harmonic overtone richness

let audioCtx: AudioContext | null = null;

function getAudioContext(): AudioContext | null {
	if (typeof window === 'undefined') return null;
	if (!audioCtx) {
		const AudioContextClass = window.AudioContext || (window as unknown as { webkitAudioContext: typeof AudioContext }).webkitAudioContext;
		if (AudioContextClass) {
			audioCtx = new AudioContextClass();
		}
	}
	if (audioCtx && audioCtx.state === 'suspended') {
		audioCtx.resume();
	}
	return audioCtx;
}

export interface HarmonicaNote {
	hole: number;
	direction: 'blow' | 'draw';
	noteName: string;
	freq: number;
}

export const HARMONICA_C_MAP: Record<number, { blow: { note: string; freq: number }; draw: { note: string; freq: number } }> = {
	1: { blow: { note: 'C4', freq: 261.63 }, draw: { note: 'D4', freq: 293.66 } },
	2: { blow: { note: 'E4', freq: 329.63 }, draw: { note: 'G4', freq: 392.00 } },
	3: { blow: { note: 'G4', freq: 392.00 }, draw: { note: 'B4', freq: 493.88 } },
	4: { blow: { note: 'C5', freq: 523.25 }, draw: { note: 'D5', freq: 587.33 } },
	5: { blow: { note: 'E5', freq: 659.25 }, draw: { note: 'F5', freq: 698.46 } },
	6: { blow: { note: 'G5', freq: 783.99 }, draw: { note: 'A5', freq: 880.00 } },
	7: { blow: { note: 'C6', freq: 1046.50 }, draw: { note: 'B5', freq: 987.77 } },
	8: { blow: { note: 'E6', freq: 1318.51 }, draw: { note: 'D6', freq: 1174.66 } },
	9: { blow: { note: 'G6', freq: 1567.98 }, draw: { note: 'F6', freq: 1396.91 } },
	10: { blow: { note: 'C7', freq: 2093.00 }, draw: { note: 'A6', freq: 1760.00 } }
};

let currentStopFn: (() => void) | null = null;

export function playHarmonicaSound(freq: number, durationSec = 0.85): () => void {
	const ctx = getAudioContext();
	if (!ctx) return () => {};

	// Stop previous if any
	if (currentStopFn) {
		currentStopFn();
		currentStopFn = null;
	}

	const now = ctx.currentTime;

	// Master gain
	const masterGain = ctx.createGain();
	masterGain.gain.setValueAtTime(0, now);
	masterGain.gain.linearRampToValueAtTime(0.18, now + 0.05); // quick breath attack
	masterGain.gain.exponentialRampToValueAtTime(0.12, now + 0.35); // sustain
	masterGain.gain.exponentialRampToValueAtTime(0.0001, now + durationSec); // decay

	// Lowpass filter for warm reed warmth
	const filter = ctx.createBiquadFilter();
	filter.type = 'lowpass';
	filter.frequency.setValueAtTime(freq * 3.8, now);
	filter.Q.setValueAtTime(2.5, now);

	// Primary oscillator (triangle wave gives body)
	const osc1 = ctx.createOscillator();
	osc1.type = 'triangle';
	osc1.frequency.setValueAtTime(freq, now);

	// Secondary oscillator (pulse / saw for reed buzzing texture)
	const osc2 = ctx.createOscillator();
	osc2.type = 'sawtooth';
	osc2.frequency.setValueAtTime(freq * 1.002, now); // slight chorus detune

	const osc2Gain = ctx.createGain();
	osc2Gain.gain.setValueAtTime(0.25, now);

	// Sub-oscillator for warmth
	const osc3 = ctx.createOscillator();
	osc3.type = 'sine';
	osc3.frequency.setValueAtTime(freq * 0.5, now);
	const osc3Gain = ctx.createGain();
	osc3Gain.gain.setValueAtTime(0.1, now);

	// Connect nodes
	osc1.connect(filter);
	osc2.connect(osc2Gain);
	osc2Gain.connect(filter);
	osc3.connect(osc3Gain);
	osc3Gain.connect(filter);

	filter.connect(masterGain);
	masterGain.connect(ctx.destination);

	osc1.start(now);
	osc2.start(now);
	osc3.start(now);

	const stopTime = now + durationSec + 0.05;
	osc1.stop(stopTime);
	osc2.stop(stopTime);
	osc3.stop(stopTime);

	const stopFn = () => {
		try {
			masterGain.gain.cancelScheduledValues(ctx.currentTime);
			masterGain.gain.linearRampToValueAtTime(0.0001, ctx.currentTime + 0.05);
			setTimeout(() => {
				try {
					osc1.stop();
					osc2.stop();
					osc3.stop();
				} catch {
					// already stopped
				}
			}, 60);
		} catch {
			// ignore
		}
	};

	currentStopFn = stopFn;
	return stopFn;
}

export function playNoteByHole(hole: number, direction: 'blow' | 'draw'): { note: string; freq: number } {
	const info = HARMONICA_C_MAP[hole] || HARMONICA_C_MAP[4];
	const target = direction === 'blow' ? info.blow : info.draw;
	playHarmonicaSound(target.freq);
	return target;
}
