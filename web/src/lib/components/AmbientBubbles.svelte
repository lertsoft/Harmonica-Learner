<div class="ambient-bubble bubble-1" aria-hidden="true"></div>
<div class="ambient-bubble bubble-2" aria-hidden="true"></div>
<div class="ambient-bubble bubble-3" aria-hidden="true"></div>

<style>
	.ambient-bubble {
		position: absolute;
		border-radius: 50%;
		filter: blur(80px);
		pointer-events: none;
		z-index: 0;
	}

	.bubble-1 {
		top: -80px;
		left: -60px;
		width: 480px;
		height: 480px;
		background: radial-gradient(
			circle,
			rgba(59, 130, 246, 0.25) 0%,
			transparent 70%
		);
	}

	.bubble-2 {
		top: 300px;
		right: -100px;
		width: 520px;
		height: 520px;
		background: radial-gradient(
			circle,
			rgba(245, 158, 11, 0.2) 0%,
			transparent 70%
		);
	}

	.bubble-3 {
		bottom: 15%;
		left: 10%;
		width: 450px;
		height: 450px;
		background: radial-gradient(
			circle,
			rgba(236, 72, 153, 0.18) 0%,
			transparent 70%
		);
	}

	:global(.theme-light) .bubble-1,
	:global([data-theme="light"]) .bubble-1 {
		background: radial-gradient(
			circle,
			rgba(59, 130, 246, 0.14) 0%,
			transparent 70%
		);
	}

	:global(.theme-light) .bubble-2,
	:global([data-theme="light"]) .bubble-2 {
		background: radial-gradient(
			circle,
			rgba(251, 191, 36, 0.18) 0%,
			transparent 70%
		);
	}

	:global(.theme-light) .bubble-3,
	:global([data-theme="light"]) .bubble-3 {
		background: radial-gradient(
			circle,
			rgba(236, 72, 153, 0.12) 0%,
			transparent 70%
		);
	}
</style>
