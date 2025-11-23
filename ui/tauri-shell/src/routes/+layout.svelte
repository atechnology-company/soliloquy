<script lang="ts">
	import '../app.css';
	import StatusBar from '$lib/components/StatusBar.svelte';
	import LauncherGrid from '$lib/components/LauncherGrid.svelte';
	import WebviewPlaceholder from '$lib/components/WebviewPlaceholder.svelte';
</script>

<div class="soliloquy-shell h-screen flex flex-col bg-gray-900">
	<!-- Top Status Bar -->
	<StatusBar />
	
	<!-- Main Content Area -->
	<main class="flex-1 flex flex-col overflow-hidden">
		<!-- Launcher Grid -->
	<LauncherGrid />
		
		<!-- Embedded Webview Placeholder -->
	<WebviewPlaceholder />
	</main>
</div>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
		font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
	}
	
	.soliloquy-shell {
		user-select: none;
		-webkit-user-select: none;
		overflow: hidden;
	}
</style>