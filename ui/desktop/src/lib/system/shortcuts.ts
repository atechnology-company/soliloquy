/**
 * Keyboard Shortcuts System for Soliloquy Browser
 * 
 * Centralized keyboard shortcut handling with customization support
 */

import { get } from 'svelte/store';
import { browserStore, commandBarStore } from '$lib/stores/browser';

export interface Shortcut {
	id: string;
	key: string;
	modifiers: Array<'ctrl' | 'meta' | 'alt' | 'shift'>;
	description: string;
	category: 'navigation' | 'tabs' | 'workspaces' | 'search' | 'general';
	action: () => void;
	/** Whether this shortcut works when command bar is open */
	globalWhenCommandBarOpen?: boolean;
}

// Platform detection
const isMac = typeof navigator !== 'undefined' && /Mac|iPod|iPhone|iPad/.test(navigator.platform);
const cmdKey = isMac ? 'meta' : 'ctrl';

// Default shortcuts
export const DEFAULT_SHORTCUTS: Shortcut[] = [
	// Command bar
	{
		id: 'open-command-bar',
		key: 'k',
		modifiers: [cmdKey],
		description: 'Open command bar',
		category: 'general',
		action: () => commandBarStore.toggle()
	},
	{
		id: 'open-command-bar-alt',
		key: '\\',
		modifiers: [cmdKey],
		description: 'Open command bar (alternative)',
		category: 'general',
		action: () => commandBarStore.toggle()
	},
	
	// Tab management
	{
		id: 'new-tab',
		key: 't',
		modifiers: [cmdKey],
		description: 'New tab',
		category: 'tabs',
		action: () => browserStore.openTab('about:blank', { activate: true })
	},
	{
		id: 'close-tab',
		key: 'w',
		modifiers: [cmdKey],
		description: 'Close current tab',
		category: 'tabs',
		action: () => {
			const state = get(browserStore);
			if (state.activeTabId) {
				browserStore.closeTab(state.activeTabId);
			}
		}
	},
	{
		id: 'next-tab',
		key: 'Tab',
		modifiers: ['ctrl'],
		description: 'Next tab',
		category: 'tabs',
		action: () => navigateTab(1)
	},
	{
		id: 'prev-tab',
		key: 'Tab',
		modifiers: ['ctrl', 'shift'],
		description: 'Previous tab',
		category: 'tabs',
		action: () => navigateTab(-1)
	},
	{
		id: 'search-tabs',
		key: 'f',
		modifiers: [cmdKey, 'shift'],
		description: 'Search tabs',
		category: 'tabs',
		action: () => {
			commandBarStore.open();
			commandBarStore.setMode('tabs');
		}
	},
	
	// Workspace management
	{
		id: 'next-workspace',
		key: ']',
		modifiers: [cmdKey],
		description: 'Next workspace',
		category: 'workspaces',
		action: () => navigateWorkspace(1)
	},
	{
		id: 'prev-workspace',
		key: '[',
		modifiers: [cmdKey],
		description: 'Previous workspace',
		category: 'workspaces',
		action: () => navigateWorkspace(-1)
	},
	{
		id: 'workspace-1',
		key: '1',
		modifiers: [cmdKey, 'alt'],
		description: 'Switch to workspace 1',
		category: 'workspaces',
		action: () => switchToWorkspaceByIndex(0)
	},
	{
		id: 'workspace-2',
		key: '2',
		modifiers: [cmdKey, 'alt'],
		description: 'Switch to workspace 2',
		category: 'workspaces',
		action: () => switchToWorkspaceByIndex(1)
	},
	{
		id: 'workspace-3',
		key: '3',
		modifiers: [cmdKey, 'alt'],
		description: 'Switch to workspace 3',
		category: 'workspaces',
		action: () => switchToWorkspaceByIndex(2)
	},
	
	// Navigation
	{
		id: 'go-back',
		key: '[',
		modifiers: [cmdKey],
		description: 'Go back',
		category: 'navigation',
		action: () => window.history.back()
	},
	{
		id: 'go-forward',
		key: ']',
		modifiers: [cmdKey],
		description: 'Go forward',
		category: 'navigation',
		action: () => window.history.forward()
	},
	{
		id: 'reload',
		key: 'r',
		modifiers: [cmdKey],
		description: 'Reload page',
		category: 'navigation',
		action: () => window.location.reload()
	},
	
	// Search
	{
		id: 'focus-search',
		key: 'l',
		modifiers: [cmdKey],
		description: 'Focus address bar / search',
		category: 'search',
		action: () => commandBarStore.open()
	},
	{
		id: 'search-in-page',
		key: 'f',
		modifiers: [cmdKey],
		description: 'Find in page',
		category: 'search',
		action: () => {
			// This would trigger page find functionality
			console.log('Find in page triggered');
		}
	},
	
	// Bookmarks
	{
		id: 'bookmark-page',
		key: 'd',
		modifiers: [cmdKey],
		description: 'Bookmark current page',
		category: 'general',
		action: () => {
			const state = get(browserStore);
			const activeTab = state.tabs.find(t => t.id === state.activeTabId);
			if (activeTab) {
				browserStore.addBookmark(activeTab.url, activeTab.title);
			}
		}
	}
];

// Helper functions
function navigateTab(direction: 1 | -1) {
	const state = get(browserStore);
	const workspaceTabs = state.tabs.filter(t => t.workspaceId === state.activeWorkspaceId);
	
	if (workspaceTabs.length === 0) return;
	
	const currentIndex = workspaceTabs.findIndex(t => t.id === state.activeTabId);
	let newIndex = currentIndex + direction;
	
	// Wrap around
	if (newIndex < 0) newIndex = workspaceTabs.length - 1;
	if (newIndex >= workspaceTabs.length) newIndex = 0;
	
	browserStore.activateTab(workspaceTabs[newIndex].id);
}

function navigateWorkspace(direction: 1 | -1) {
	const state = get(browserStore);
	const currentIndex = state.workspaces.findIndex(w => w.id === state.activeWorkspaceId);
	let newIndex = currentIndex + direction;
	
	// Wrap around
	if (newIndex < 0) newIndex = state.workspaces.length - 1;
	if (newIndex >= state.workspaces.length) newIndex = 0;
	
	browserStore.switchWorkspace(state.workspaces[newIndex].id);
}

function switchToWorkspaceByIndex(index: number) {
	const state = get(browserStore);
	if (index >= 0 && index < state.workspaces.length) {
		browserStore.switchWorkspace(state.workspaces[index].id);
	}
}

/**
 * Check if a keyboard event matches a shortcut
 */
export function matchesShortcut(event: KeyboardEvent, shortcut: Shortcut): boolean {
	// Check key
	if (event.key.toLowerCase() !== shortcut.key.toLowerCase()) return false;
	
	// Check modifiers
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

/**
 * Format shortcut for display
 */
export function formatShortcut(shortcut: Shortcut): string {
	const parts: string[] = [];
	
	if (shortcut.modifiers.includes('ctrl')) parts.push(isMac ? '⌃' : 'Ctrl');
	if (shortcut.modifiers.includes('meta')) parts.push(isMac ? '⌘' : 'Win');
	if (shortcut.modifiers.includes('alt')) parts.push(isMac ? '⌥' : 'Alt');
	if (shortcut.modifiers.includes('shift')) parts.push(isMac ? '⇧' : 'Shift');
	
	// Format key
	const keyMap: Record<string, string> = {
		'Tab': '⇥',
		'Enter': '↵',
		'Escape': 'Esc',
		'ArrowUp': '↑',
		'ArrowDown': '↓',
		'ArrowLeft': '←',
		'ArrowRight': '→',
		'Backspace': '⌫',
		'Delete': '⌦',
		' ': 'Space'
	};
	
	const displayKey = keyMap[shortcut.key] || shortcut.key.toUpperCase();
	parts.push(displayKey);
	
	return parts.join(isMac ? '' : '+');
}

/**
 * Create keyboard event handler
 */
export function createShortcutHandler(
	shortcuts: Shortcut[] = DEFAULT_SHORTCUTS,
	options: { preventDefault?: boolean } = {}
): (event: KeyboardEvent) => void {
	const { preventDefault = true } = options;
	
	return (event: KeyboardEvent) => {
		// Don't handle if typing in an input
		const target = event.target as HTMLElement;
		if (
			target.tagName === 'INPUT' || 
			target.tagName === 'TEXTAREA' || 
			target.isContentEditable
		) {
			return;
		}
		
		for (const shortcut of shortcuts) {
			if (matchesShortcut(event, shortcut)) {
				if (preventDefault) {
					event.preventDefault();
					event.stopPropagation();
				}
				shortcut.action();
				return;
			}
		}
	};
}

/**
 * Get shortcuts grouped by category
 */
export function getShortcutsByCategory(
	shortcuts: Shortcut[] = DEFAULT_SHORTCUTS
): Record<string, Shortcut[]> {
	const grouped: Record<string, Shortcut[]> = {};
	
	for (const shortcut of shortcuts) {
		if (!grouped[shortcut.category]) {
			grouped[shortcut.category] = [];
		}
		grouped[shortcut.category].push(shortcut);
	}
	
	return grouped;
}
