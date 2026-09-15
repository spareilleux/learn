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
			components: {
				// Narration player (pre-generated audio) or browser speech fallback under the title
				PageTitle: './src/components/PageTitle.astro',
				// Button that hides or shows the left sidebar on wide screens
				SiteTitle: './src/components/SiteTitle.astro',
				// Renders ```mermaid code blocks as diagrams
				MarkdownContent: './src/components/MarkdownContent.astro',
			},
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
									label: 'C# for beginners',
									translations: { fr: 'C# pour débutants', es: 'C# para principiantes' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'csharp-beginner' } }],
								},
								{
									label: 'Advanced C#',
									translations: { fr: 'C# avancé', es: 'C# avanzado' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'csharp-advanced' } }],
								},
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
								{
									label: 'Spring Boot, Spring Cloud and Reactor for C# developers',
									translations: { fr: 'Spring Boot, Spring Cloud et Reactor pour développeurs C#', es: 'Spring Boot, Spring Cloud y Reactor para desarrolladores C#' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'spring-cloud-reactor' } }],
								},
								{
									label: 'V for C#/Java developers',
									translations: { fr: 'V pour développeurs C#/Java', es: 'V para desarrolladores C#/Java' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'v-for-csharp-java' } }],
								},
								{
									label: 'JavaScript for C#/Java developers',
									translations: { fr: 'JavaScript pour développeurs C#/Java', es: 'JavaScript para desarrolladores C#/Java' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'javascript-for-csharp-java' } }],
								},
								{
									label: 'TypeScript for C#/Java developers',
									translations: { fr: 'TypeScript pour développeurs C#/Java', es: 'TypeScript para desarrolladores C#/Java' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'typescript-for-csharp-java' } }],
								},
								{
									label: 'Python for C#/Java developers',
									translations: { fr: 'Python pour développeurs C#/Java', es: 'Python para desarrolladores C#/Java' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'python-for-csharp-java' } }],
								},
								{
									label: 'React (Vite) for C#/Java developers',
									translations: { fr: 'React (Vite) pour développeurs C#/Java', es: 'React (Vite) para desarrolladores C#/Java' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'react-vite' } }],
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
								{
									label: 'DuckDB',
									collapsed: true,
									items: [{ autogenerate: { directory: 'duckdb' } }],
								},
								{
									label: 'LadybugDB',
									collapsed: true,
									items: [{ autogenerate: { directory: 'ladybugdb' } }],
								},
								{
									label: 'RabbitMQ',
									translations: { fr: 'RabbitMQ', es: 'RabbitMQ' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'rabbitmq' } }],
								},
								{
									label: 'Kubernetes',
									translations: { fr: 'Kubernetes', es: 'Kubernetes' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'kubernetes' } }],
								},
							],
						},
						{
							label: 'AI-assisted development',
							translations: { fr: 'Développement assisté par IA', es: 'Desarrollo asistido por IA' },
							items: [
								{
									label: 'Agentic coding with Claude Code and Codex',
									translations: { fr: 'Programmation agentique avec Claude Code et Codex', es: 'Programación agéntica con Claude Code y Codex' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'agentic-coding' } }],
								},
							],
						},
					],
				},
				{
					label: 'Machine Learning',
					translations: { fr: 'Apprentissage automatique', es: 'Aprendizaje automático' },
					items: [
						{
							label: 'Machine learning, as applied in IX',
							translations: { fr: 'Apprentissage automatique, appliqué dans IX', es: 'Aprendizaje automático, aplicado en IX' },
							collapsed: true,
							items: [{ autogenerate: { directory: 'machine-learning-ix' } }],
						},
						{
							label: "GA's AI: OPTIC-K, ML, agents and the chatbot",
							translations: { fr: "L'IA de GA : OPTIC-K, ML, agents et chatbot", es: 'La IA de GA: OPTIC-K, ML, agentes y chatbot' },
							collapsed: true,
							items: [{ autogenerate: { directory: 'ga-ai' } }],
						},
					],
				},
				{
					label: 'Music',
					translations: { fr: 'Musique', es: 'Música' },
					items: [
						{
							label: 'Music theory for Guitar Alchemist',
							translations: { fr: 'Théorie musicale pour Guitar Alchemist', es: 'Teoría musical para Guitar Alchemist' },
							collapsed: true,
							items: [{ autogenerate: { directory: 'music-theory-ga' } }],
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
