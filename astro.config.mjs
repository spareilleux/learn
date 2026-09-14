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
				es: { label: 'Español', lang: 'es' },
			},
			social: [{ icon: 'github', label: 'GitHub', href: 'https://github.com/spareilleux/learn' }],
			editLink: { baseUrl: 'https://github.com/spareilleux/learn/edit/main/' },
			lastUpdated: true,
			customCss: ['./src/styles/custom.css'],
			sidebar: [
				{ label: 'Method', translations: { fr: 'Méthode', es: 'Método' }, slug: 'method' },
				{ label: 'Artifacts', translations: { fr: 'Artefacts', es: 'Artefactos' }, slug: 'artifacts' },
				{
					label: 'Software Engineering',
					translations: { fr: 'Génie logiciel', es: 'Ingeniería de software' },
					items: [
						{
							label: 'Languages & frameworks',
							translations: { fr: 'Langages et frameworks', es: 'Lenguajes y frameworks' },
							items: [
								{
									label: 'Rust for C#/Java developers',
									translations: { fr: 'Rust pour développeurs C#/Java', es: 'Rust para desarrolladores C#/Java' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'rust-for-csharp-java' } }],
								},
								{
									label: 'Java for C# developers',
									translations: { fr: 'Java pour développeurs C#', es: 'Java para desarrolladores C#' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'java-for-csharp' } }],
								},
							],
						},
						{
							label: 'Infrastructure & tooling',
							translations: { fr: 'Infrastructure et outillage', es: 'Infraestructura y herramientas' },
							items: [
								{
									label: 'WSL containers',
									translations: { es: 'Contenedores WSL' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'wsl-containers' } }],
								},
								{
									label: 'GitHub Actions',
									collapsed: true,
									items: [{ autogenerate: { directory: 'github-actions' } }],
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
