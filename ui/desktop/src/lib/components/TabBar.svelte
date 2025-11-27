<script lang="ts">
	import { fly, fade } from 'svelte/transition';
	import { 
		browserStore, 
		workspaceTabs, 
		activeTab,
		commandBarStore
	} from '$lib/stores/browser';
	
	export let compact = false;
	
	$: tabs = $workspaceTabs;
	$: current = $activeTab;
	
	let hoveredTabId: string | null = null;
	
	function closeTab(tabId: string, event: Event) {
		event.stopPropagation();
		browserStore.closeTab(tabId);
	}
	
	function openCommandBar() {
		commandBarStore.open();
		commandBarStore.setMode('tabs');
	}
</script>

{#if compact}
	<!-- Compact mode: just show count and current tab -->
	<div class="flex items-center gap-2">
		<button
			type="button"
			class="flex items-center gap-2 rounded-lg bg-white/5 px-3 py-2 text-sm transition hover:bg-white/10"
			on:click={openCommandBar}
		>
			<span class="text-white/60">📑</span>
			<span class="font-medium text-white">{tabs.length} tabs</span>
			<kbd class="ml-2 rounded bg-white/10 px-1.5 py-0.5 text-xs text-white/40">⌘K</kbd>
		</button>
		
		{#if current}
			<div class="flex items-center gap-2 rounded-lg bg-white/5 px-3 py-2">
				<span class="text-sm">{current.favicon || '🌐'}</span>
				<span class="max-w-48 truncate text-sm text-white">{current.title || 'Untitled'}</span>
			</div>
		{/if}
	</div>
{:else}
	<!-- Full mode: horizontal scrollable tab pills -->
	<div class="flex items-center gap-2">
		<!-- Open command bar button -->
		<button
			type="button"
			class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg bg-white/5 text-white/60 transition hover:bg-white/10 hover:text-white"
			on:click={openCommandBar}
			title="Search tabs (⌘K)"
		>
			<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
				<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
			</svg>
		</button>
		
		<!-- Scrollable tabs -->
		<div class="flex flex-1 items-center gap-1.5 overflow-x-auto scrollbar-hide">
			{#each tabs as tab (tab.id)}
				{@const isActive = tab.id === current?.id}
				<button
					type="button"
					class="group relative flex shrink-0 items-center gap-2 rounded-lg px-3 py-2 text-sm transition {isActive ? 'bg-white/10 text-white' : 'bg-white/5 text-white/70 hover:bg-white/10'}"
					on:click={() => browserStore.activateTab(tab.id)}
					on:mouseenter={() => hoveredTabId = tab.id}
					on:mouseleave={() => hoveredTabId = null}
				>
					<!-- Favicon -->
					<span class="text-xs">{tab.favicon || '🌐'}</span>
					
					<!-- Title -->
					<span class="max-w-32 truncate">{tab.title || 'Untitled'}</span>
					
					<!-- Loading indicator -->
					{#if tab.loading}
						<span class="h-1.5 w-1.5 animate-pulse rounded-full bg-blue-400"></span>
					{/if}
					
					<!-- Pinned indicator -->
					{#if tab.pinned}
						<span class="text-xs text-amber-400">📌</span>
					{/if}
					
					<!-- Close button -->
					<span
						role="button"
						tabindex="0"
						class="ml-1 flex h-4 w-4 items-center justify-center rounded opacity-0 transition hover:bg-white/20 group-hover:opacity-100"
						on:click={(e) => closeTab(tab.id, e)}
						on:keydown={(e) => e.key === 'Enter' && closeTab(tab.id, e)}
						title="Close tab"
					>
						<svg class="h-3 w-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
							<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
						</svg>
					</span>
				</button>
			{/each}
			
			<!-- New tab button -->
			<button
				type="button"
				class="flex h-9 w-9 shrink-0 items-center justify-center rounded-lg text-white/40 transition hover:bg-white/10 hover:text-white"
				on:click={() => browserStore.openTab('about:blank')}
				title="New tab"
			>
				<svg class="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
					<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
				</svg>
			</button>
		</div>
		
		<!-- Tab count -->
		<div class="shrink-0 text-xs text-white/40">
			{tabs.length} tab{tabs.length !== 1 ? 's' : ''}
		</div>
	</div>
	
	<!-- Tab preview popup -->
	{#if hoveredTabId}
		{@const hoveredTab = tabs.find(t => t.id === hoveredTabId)}
		{#if hoveredTab && hoveredTab.preview}
			<div 
				class="absolute left-1/2 top-full z-50 mt-2 -translate-x-1/2 overflow-hidden rounded-xl border border-white/10 bg-gray-900/95 shadow-xl"
				transition:fade={{ duration: 100 }}
			>
				<img 
					src={hoveredTab.preview} 
					alt={hoveredTab.title}
					class="h-48 w-72 object-cover object-top"
				/>
				<div class="p-3">
					<p class="truncate text-sm font-medium text-white">{hoveredTab.title}</p>
					<p class="truncate text-xs text-white/50">{hoveredTab.url}</p>
				</div>
			</div>
		{/if}
	{/if}
{/if}

<style>
	.scrollbar-hide {
		-ms-overflow-style: none;
		scrollbar-width: none;
	}
	.scrollbar-hide::-webkit-scrollbar {
		display: none;
	}
</style>
