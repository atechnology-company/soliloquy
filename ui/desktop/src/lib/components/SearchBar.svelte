<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import { fade } from 'svelte/transition';

	export let value = '';
	export let placeholder = 'what can we get started for you today?';
	export let loading = false;

	const dispatch = createEventDispatcher<{ submit: string; input: string }>();

	let focused = false;

	function handleSubmit(event: SubmitEvent) {
		event.preventDefault();
		if (value.trim()) {
			dispatch('submit', value.trim());
		}
	}

	function handleInput() {
		dispatch('input', value);
	}
</script>

<form class="search-bar" on:submit={handleSubmit}>
	<div class="search-input-wrapper" class:focused>
		<input
			type="text"
			bind:value
			{placeholder}
			on:input={handleInput}
			on:focus={() => (focused = true)}
			on:blur={() => (focused = false)}
			class="search-input"
			disabled={loading}
		/>
		{#if loading}
			<div class="search-loading" transition:fade={{ duration: 150 }}>
				<svg class="animate-spin h-5 w-5" viewBox="0 0 24 24">
					<circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" fill="none"></circle>
					<path
						class="opacity-75"
						fill="currentColor"
						d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
					></path>
				</svg>
			</div>
		{/if}
	</div>
</form>

<style>
	.search-bar {
		width: 100%;
	}

	.search-input-wrapper {
		position: relative;
		width: 100%;
		transition: all 0.3s ease;
	}

	.search-input-wrapper.focused {
		transform: scale(1.01);
	}

	.search-input {
		width: 100%;
		background: transparent;
		border: none;
		font-size: 3rem;
		font-weight: 300;
		color: white;
		outline: none;
		transition: all 0.3s ease;
	}

	.search-input::placeholder {
		color: rgb(255 255 255 / 0.4);
	}

	.search-input:focus::placeholder {
		color: rgb(255 255 255 / 0.3);
	}

	.search-loading {
		position: absolute;
		right: 0;
		top: 50%;
		transform: translateY(-50%);
		color: rgb(255 255 255 / 0.6);
	}

	@media (min-width: 768px) {
		.search-input {
			font-size: 4.5rem;
		}
	}

	@keyframes spin {
		to {
			transform: rotate(360deg);
		}
	}

	.animate-spin {
		animation: spin 1s linear infinite;
	}
</style>
