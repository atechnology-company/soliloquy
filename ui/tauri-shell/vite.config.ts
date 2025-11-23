import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vite';

export default defineConfig({
	plugins: [sveltekit()],
	server: {
		port: 1420,
		strictPort: true,
		hmr: {
			port: 1421
		}
	}
});