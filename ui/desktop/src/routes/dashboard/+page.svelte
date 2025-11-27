<script lang="ts">
import { fade } from 'svelte/transition';
import { goto } from '$app/navigation';
import { clockDisplay, systemClock } from '$lib/stores/system';
import { batteryStore, weatherStore } from '$lib/stores/device';
import { runSystemAction } from '$lib/system/actions';
import { logout as apiLogout } from '$lib/api/tableware';
import { performSearch, type SearchCard } from '$lib/api/search';
import SearchBar from '$lib/components/SearchBar.svelte';
import SearchCarousel from '$lib/components/SearchCarousel.svelte';
import type { SystemAction } from '$lib/system/actions';
import type { PickupCard } from '$lib/api/tableware';
import type { PageData } from './$types';

export let data: PageData;

type NavFilter = { label: string; action: SystemAction };

const navFilters: NavFilter[] = [
{ label: 'FILES', action: 'files.open' },
{ label: 'CHATS', action: 'sessions.resume' },
{ label: 'TABS', action: 'tabs.restore' }
];

const fallbackPickup: PickupCard = {
label: 'Pickup from phone',
title: 'No active pickups',
source: 'Tableware',
description: 'Create a pickup session from your phone or browser',
actionUrl: undefined
};

const dateFormatter = new Intl.DateTimeFormat('en-US', {
weekday: 'long',
month: 'long',
day: 'numeric'
});

let commandQuery = '';
let showProfileMenu = false;
let searchLoading = false;
let searchCards: SearchCard[] = [];

$: dayStamp = dateFormatter.format($systemClock);
$: heroStatus = `${$clockDisplay.time} ⋅ ${dayStamp}`;
$: featuredMedia = data.pickup ?? fallbackPickup;

function handlePickupOpen() {
if (featuredMedia.actionUrl && typeof window !== 'undefined') {
window.open(featuredMedia.actionUrl, '_blank', 'noopener');
return;
}
runSystemAction('sessions.resume');
}

async function handleSearch(event: CustomEvent<string>) {
const query = event.detail;
searchLoading = true;
searchCards = [];

const response = await performSearch(query);
searchLoading = false;

if (response) {
searchCards = response.cards;
}
}

function handleSearchInput(event: CustomEvent<string>) {
// TODO: Show suggestions dropdown
}

function handleCardClick(card: SearchCard) {
console.info('[search-card]', card.card_type, card.title);

if (card.card_type === 'browser' && card.url) {
window.open(card.url, '_blank', 'noopener');
} else if (card.card_type === 'command') {
// Execute Plates command
console.info('[command]', card.metadata.command);
} else if (card.card_type === 'cupboard') {
// Show memory details
console.info('[cupboard]', card.id);
}
}

async function handleLogout() {
showProfileMenu = false;
await apiLogout();
goto('/');
}

function handleSettings() {
showProfileMenu = false;
goto('/settings');
}

function handleAccount() {
showProfileMenu = false;
console.info('[profile] Navigate to account settings');
}
</script>

<main class="flex min-h-screen flex-col bg-black text-white">
<header class="flex items-center justify-between px-6 py-8 sm:px-12 lg:px-24">
<nav class="flex gap-8 text-sm font-semibold uppercase tracking-[0.4em]">
{#each navFilters as filter}
<button
type="button"
class="text-white/50 transition hover:text-white"
on:click={() => runSystemAction(filter.action)}
>
{filter.label}
</button>
{/each}
</nav>

<div class="flex items-center gap-6 text-sm">
<span class="font-semibold">{heroStatus}</span>
<span class="text-white/60">{$weatherStore.emoji} {$weatherStore.temp}°</span>
<span class="text-white/60">{$batteryStore.level}%</span>

<div class="relative">
<button
type="button"
class="h-10 w-10 overflow-hidden rounded-full border border-white/20"
on:click={() => (showProfileMenu = !showProfileMenu)}
>
<img
src={data.user?.picture ?? 'https://placehold.co/80x80'}
alt={data.user?.name ?? 'Profile'}
class="h-full w-full object-cover"
/>
</button>

{#if showProfileMenu}
<div
class="absolute right-0 top-12 w-48 rounded-2xl border border-white/10 bg-black/90 py-2 shadow-2xl backdrop-blur-xl"
transition:fade={{ duration: 150 }}
>
<button
type="button"
class="w-full px-4 py-2 text-left text-sm text-white/80 hover:bg-white/5 hover:text-white"
on:click={handleSettings}
>
Settings
</button>
<button
type="button"
class="w-full px-4 py-2 text-left text-sm text-white/80 hover:bg-white/5 hover:text-white"
on:click={handleAccount}
>
Account
</button>
<div class="my-1 h-px bg-white/10"></div>
<button
type="button"
class="w-full px-4 py-2 text-left text-sm text-white/80 hover:bg-white/5 hover:text-white"
on:click={handleLogout}
>
Sign out
</button>
</div>
{/if}
</div>
</div>
</header>

<section class="flex-1 px-6 py-12 sm:px-12 lg:px-24" transition:fade={{ duration: 220 }}>
<SearchBar bind:value={commandQuery} loading={searchLoading} on:submit={handleSearch} on:input={handleSearchInput} />
<SearchCarousel cards={searchCards} onCardClick={handleCardClick} />
</section>

<aside class="fixed bottom-6 left-6 space-y-3 text-white" transition:fade={{ delay: 120, duration: 240 }}>
<p class="text-xs font-semibold uppercase tracking-[0.4em] text-white/50">{featuredMedia.label}</p>
<h3 class="text-2xl font-semibold text-white/90">{featuredMedia.title}</h3>
{#if featuredMedia.description}
<p class="text-sm text-white/60">{featuredMedia.description}</p>
{/if}
<p class="text-base text-white/60">{featuredMedia.source ?? featuredMedia.device ?? 'Tableware pickup'}</p>
<button
type="button"
class="text-xs font-semibold uppercase tracking-[0.4em] text-white/60 underline underline-offset-4"
on:click={handlePickupOpen}
>
Open pickup
</button>
</aside>
</main>
