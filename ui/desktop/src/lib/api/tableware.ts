export type PickupCard = {
label: string;
title: string;
source?: string;
description?: string;
actionUrl?: string;
device?: string;
};

export type User = {
id: string;
email: string;
name: string;
picture?: string;
onboardingComplete?: boolean;
};

const DEFAULT_TABLEWARE_BASE_URL = import.meta.env.VITE_TABLEWARE_BASE_URL ?? 'http://localhost:3030';

function resolveBaseUrl() {
return DEFAULT_TABLEWARE_BASE_URL.replace(/\/$/, '');
}

function normalizePickup(raw: any): PickupCard {
const pickup = raw?.pickup ?? raw ?? {};
return {
label: pickup.label ?? pickup.context ?? 'Pickup from phone',
title: pickup.title ?? pickup.summary ?? 'Open session',
source: pickup.source ?? pickup.device?.name ?? pickup.deviceName ?? 'Tableware',
description: pickup.description ?? pickup.notes ?? pickup.snippet,
actionUrl: pickup.url ?? pickup.link,
device: pickup.device?.name ?? pickup.deviceName ?? pickup.device ?? undefined
};
}

export async function fetchCurrentPickup(fetcher: typeof fetch = fetch): Promise<PickupCard | null> {
const endpoint = `${resolveBaseUrl()}/api/pickups/current`;
try {
const res = await fetcher(endpoint, {
headers: { Accept: 'application/json' },
credentials: 'include'
});
if (!res.ok) {
console.warn('[tableware] pickups.current responded with', res.status);
return null;
}
const data = await res.json().catch(() => null);
if (!data) return null;
return normalizePickup(data);
} catch (error) {
console.warn('[tableware] Unable to reach Tableware endpoint', error);
return null;
}
}

export async function getAuthUser(fetcher: typeof fetch = fetch): Promise<User | null> {
const endpoint = `${resolveBaseUrl()}/api/auth/user`;
try {
const res = await fetcher(endpoint, {
credentials: 'include'
});
if (!res.ok) return null;
const data = await res.json();
return data;
} catch {
return null;
}
}

export async function logout(fetcher: typeof fetch = fetch): Promise<void> {
await fetcher(`${resolveBaseUrl()}/api/auth/logout`, {
method: 'POST',
credentials: 'include'
});
}

export function getGoogleAuthURL(): string {
return `${resolveBaseUrl()}/api/auth/google`;
}

export async function completeOnboarding(fetcher: typeof fetch = fetch): Promise<void> {
await fetcher(`${resolveBaseUrl()}/api/user/onboarding`, {
method: 'POST',
credentials: 'include',
headers: { 'Content-Type': 'application/json' },
body: JSON.stringify({ onboardingComplete: true })
});
}
