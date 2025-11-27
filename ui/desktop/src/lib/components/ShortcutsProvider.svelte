<script lang="ts">
	import { onMount } from 'svelte';
	import { 
		createShortcutHandler, 
		DEFAULT_SHORTCUTS, 
		type Shortcut 
	} from '$lib/system/shortcuts';
	import { commandBarStore } from '$lib/stores/browser';
	
	export let shortcuts: Shortcut[] = DEFAULT_SHORTCUTS;
	export let enabled = true;
	
	$: commandBarOpen = $commandBarStore.open;
	
	const handleShortcut = createShortcutHandler(shortcuts);
	
	function onKeyDown(event: KeyboardEvent) {
		if (!enabled) return;
		
		// Some shortcuts work even when command bar is open
		const globalShortcuts = shortcuts.filter(s => s.globalWhenCommandBarOpen);
		
		if (commandBarOpen) {
			// Only handle global shortcuts when command bar is open
			for (const shortcut of globalShortcuts) {
				if (matchesShortcut(event, shortcut)) {
					event.preventDefault();
					shortcut.action();
					return;
				}
			}
			return;
		}
		
		handleShortcut(event);
	}
	
	function matchesShortcut(event: KeyboardEvent, shortcut: Shortcut): boolean {
		if (event.key.toLowerCase() !== shortcut.key.toLowerCase()) return false;
		
		const hasCtrl = shortcut.modifiers.includes('ctrl');
		const hasMeta = shortcut.modifiers.includes('meta');
		const hasAlt = shortcut.modifiers.includes('alt');
		const hasShift = shortcut.modifiers.includes('shift');
		
		if (event.ctrlKey !== hasCtrl) return false;
		if (event.metaKey !== hasMeta) return false;
		if (event.altKey !== hasAlt) return false;
		if (event.shiftKey !== hasShift) return false;
		
		return true;
	}
</script>

<svelte:window on:keydown={onKeyDown} />

<slot />
