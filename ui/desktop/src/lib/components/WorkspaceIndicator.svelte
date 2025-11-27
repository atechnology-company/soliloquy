<script lang="ts">
	import { fly } from 'svelte/transition';
	import { 
		browserStore, 
		activeWorkspace, 
		workspaceTabCounts,
		commandBarStore
	} from '$lib/stores/browser';
	
	let showDropdown = false;
	let dropdownRef: HTMLDivElement | null = null;
	
	$: workspace = $activeWorkspace;
	$: workspaces = $browserStore.workspaces;
	$: tabCounts = $workspaceTabCounts;
	
	function toggleDropdown() {
		showDropdown = !showDropdown;
	}
	
	function switchWorkspace(workspaceId: string) {
		browserStore.switchWorkspace(workspaceId);
		showDropdown = false;
	}
	
	function handleClickOutside(event: MouseEvent) {
		if (dropdownRef && !dropdownRef.contains(event.target as Node)) {
			showDropdown = false;
		}
	}
	
	function openCommandBar() {
		commandBarStore.open();
		commandBarStore.setMode('workspace');
		showDropdown = false;
	}
</script>

<svelte:window on:click={handleClickOutside} />

<div class="relative" bind:this={dropdownRef}>
	<button
		type="button"
		class="flex items-center gap-2 rounded-lg px-3 py-2 text-sm font-medium transition hover:bg-white/10"
		style="background-color: {workspace.color}20; color: {workspace.color}"
		on:click={toggleDropdown}
	>
		<span class="text-base">{workspace.icon}</span>
		<span>{workspace.name}</span>
		<span class="ml-1 rounded-full bg-white/20 px-1.5 py-0.5 text-xs">
			{tabCounts[workspace.id] || 0}
		</span>
		<svg 
			class="h-4 w-4 transition-transform" 
			class:rotate-180={showDropdown}
			fill="none" 
			stroke="currentColor" 
			viewBox="0 0 24 24"
		>
			<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
		</svg>
	</button>
	
	{#if showDropdown}
		<div 
			class="absolute left-0 top-full z-50 mt-2 min-w-48 overflow-hidden rounded-xl border border-white/10 bg-gray-900/95 shadow-xl backdrop-blur-sm"
			transition:fly={{ y: -10, duration: 150 }}
		>
			<div class="border-b border-white/10 px-3 py-2">
				<p class="text-xs font-medium uppercase tracking-wider text-white/50">Workspaces</p>
			</div>
			
			{#each workspaces as ws (ws.id)}
				{@const isActive = ws.id === workspace.id}
				<button
					type="button"
					class="flex w-full items-center justify-between gap-3 px-3 py-2.5 text-left transition hover:bg-white/5 {isActive ? 'bg-white/10' : ''}"
					on:click={() => switchWorkspace(ws.id)}
				>
					<div class="flex items-center gap-2">
						<span 
							class="flex h-6 w-6 items-center justify-center rounded text-sm"
							style="background-color: {ws.color}20"
						>
							{ws.icon}
						</span>
						<span class="text-sm font-medium text-white">{ws.name}</span>
					</div>
					<span class="text-xs text-white/40">{tabCounts[ws.id] || 0}</span>
				</button>
			{/each}
			
			<div class="border-t border-white/10">
				<button
					type="button"
					class="flex w-full items-center gap-2 px-3 py-2.5 text-left text-sm text-white/60 transition hover:bg-white/5 hover:text-white"
					on:click={openCommandBar}
				>
					<span>➕</span>
					<span>New Workspace</span>
					<span class="ml-auto text-xs text-white/40">⌘K</span>
				</button>
			</div>
		</div>
	{/if}
</div>
