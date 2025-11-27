import type { LayoutLoad } from './$types';
import { getAuthUser } from '$lib/api/tableware';

export const load: LayoutLoad = async ({ fetch }) => {
const user = await getAuthUser(fetch);
return { user };
};
