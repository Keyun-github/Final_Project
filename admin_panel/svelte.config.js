import adapter from '@sveltejs/adapter-node';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/** @type {import('@sveltejs/kit').Config} */
const config = {
	preprocess: vitePreprocess(),
	kit: {
		// adapter-node runs the SvelteKit app as a Node server. We expose it
		// directly from the container; Dokploy can route external traffic to
		// the container's port (default 3000).
		adapter: adapter({
			out: 'build',
		}),
	},
};

export default config;
