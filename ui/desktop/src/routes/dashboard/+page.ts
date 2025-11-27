import type { PageLoad } from './$types';
import { fetchCurrentPickup } from '$lib/api/tableware';

export const load: PageLoad = async ({ fetch, parent }) => {
const { user } = await parent();
const pickup = await fetchCurrentPickup(fetch);
return { pickup, user };
};
