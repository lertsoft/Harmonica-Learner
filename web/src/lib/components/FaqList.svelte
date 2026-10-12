<script lang="ts">
	import { FAQS } from '$lib/faq';

	interface Props {
		items?: typeof FAQS;
	}

	let { items = FAQS }: Props = $props();
</script>

<div class="faq-list">
	{#each items as item}
		<details class="faq-item">
			<summary class="faq-summary">
				<span class="faq-question-text">{item.question}</span>
				<span class="faq-chevron-badge" aria-hidden="true">
					<svg class="chevron-svg" viewBox="0 0 20 20" fill="currentColor" width="18" height="18">
						<path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd" />
					</svg>
				</span>
			</summary>
			<div class="faq-content">
				<p>{item.answer}</p>
			</div>
		</details>
	{/each}
</div>

<style>
	.faq-list {
		max-width: 820px;
		margin: 0 auto;
		display: flex;
		flex-direction: column;
		gap: 14px;
		text-align: left;
	}

	.faq-item {
		background: #141a27;
		border: 1px solid rgba(255, 255, 255, 0.08);
		border-radius: 20px;
		overflow: hidden;
		transition: transform 0.2s ease, box-shadow 0.2s ease, border-color 0.2s ease, background 0.2s ease;
	}

	:global(.theme-light) .faq-item,
	:global([data-theme="light"]) .faq-item {
		background: #ffffff;
		border-color: rgba(0, 0, 0, 0.07);
		box-shadow: 0 4px 14px rgba(0, 0, 0, 0.03);
	}

	.faq-item:hover {
		transform: translateY(-2px);
		border-color: rgba(59, 130, 246, 0.4);
		box-shadow: 0 12px 28px rgba(0, 0, 0, 0.25);
	}

	:global(.theme-light) .faq-item:hover,
	:global([data-theme="light"]) .faq-item:hover {
		box-shadow: 0 12px 28px rgba(37, 99, 235, 0.08);
		border-color: rgba(37, 99, 235, 0.3);
	}

	.faq-item[open] {
		border-color: rgba(59, 130, 246, 0.55);
		background: #151e2f;
	}

	:global(.theme-light) .faq-item[open],
	:global([data-theme="light"]) .faq-item[open] {
		border-color: #3b82f6;
		background: #fbfcfe;
		box-shadow: 0 8px 24px rgba(37, 99, 235, 0.06);
	}

	.faq-summary {
		display: flex;
		align-items: center;
		justify-content: space-between;
		gap: 16px;
		padding: 20px 24px;
		cursor: pointer;
		user-select: none;
		list-style: none;
	}

	.faq-summary::-webkit-details-marker {
		display: none;
	}

	.faq-question-text {
		font-family: 'Outfit', sans-serif;
		font-size: 18.5px;
		font-weight: 700;
		line-height: 1.35;
		color: #f8fafc;
		letter-spacing: -0.01em;
	}

	:global(.theme-light) .faq-question-text,
	:global([data-theme="light"]) .faq-question-text {
		color: #0f172a;
	}

	.faq-chevron-badge {
		width: 32px;
		height: 32px;
		border-radius: 50%;
		background: rgba(59, 130, 246, 0.15);
		color: #60a5fa;
		display: flex;
		align-items: center;
		justify-content: center;
		flex-shrink: 0;
		transition: transform 0.25s ease, background 0.2s ease, color 0.2s ease;
	}

	:global(.theme-light) .faq-chevron-badge,
	:global([data-theme="light"]) .faq-chevron-badge {
		background: #dbeafe;
		color: #2563eb;
	}

	.faq-item[open] .faq-chevron-badge {
		transform: rotate(180deg);
		background: #2563eb;
		color: #ffffff;
	}

	.faq-content {
		padding: 0 24px 22px;
		border-top: 1px solid rgba(255, 255, 255, 0.05);
		margin-top: 2px;
		padding-top: 16px;
	}

	:global(.theme-light) .faq-content,
	:global([data-theme="light"]) .faq-content {
		border-top: 1px solid rgba(0, 0, 0, 0.05);
	}

	.faq-content p {
		margin: 0;
		font-size: 16px;
		line-height: 1.7;
		color: #94a3b8;
		max-width: 72ch;
	}

	:global(.theme-light) .faq-content p,
	:global([data-theme="light"]) .faq-content p {
		color: #475569;
	}

	@media (max-width: 640px) {
		.faq-summary {
			padding: 18px 18px;
			gap: 12px;
		}

		.faq-question-text {
			font-size: 16.5px;
		}

		.faq-content {
			padding: 0 18px 18px;
			padding-top: 14px;
		}

		.faq-content p {
			font-size: 15px;
		}
	}
</style>
