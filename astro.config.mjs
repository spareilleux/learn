// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import streelingSidebar from './src/streeling-sidebar.json';

// https://astro.build/config
export default defineConfig({
	site: 'https://spareilleux.github.io',
	base: '/learn',
	integrations: [
		starlight({
			title: 'learn',
			description: 'Learning in public — courses and progress notes.',
			defaultLocale: 'root',
			locales: {
				root: { label: 'English', lang: 'en' },
				fr: { label: 'Français', lang: 'fr' },
			},
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/spareilleux/learn' }],
			editLink: { baseUrl: 'https://github.com/spareilleux/learn/edit/main/' },
			lastUpdated: true,
			sidebar: [
				{ label: 'Method', translations: { fr: 'Méthode' }, slug: 'method' },
				{
					label: 'Software Engineering',
					translations: { fr: 'Génie logiciel' },
					items: [
						{
							label: 'Languages & frameworks',
							translations: { fr: 'Langages et frameworks' },
							items: [
								{
									label: 'Rust for C#/Java developers',
									translations: { fr: 'Rust pour développeurs C#/Java' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'rust-for-csharp-java' } }],
								},
							],
						},
						{
							label: 'Infrastructure & tooling',
							translations: { fr: 'Infrastructure et outillage' },
							items: [
								{
									label: 'WSL containers',
									collapsed: true,
									items: [{ autogenerate: { directory: 'wsl-containers' } }],
								},
							],
						},
					],
				},
				{
					label: 'Streeling University',
					collapsed: true,
					items: streelingSidebar,
				},
			],
		}),
	],
});
