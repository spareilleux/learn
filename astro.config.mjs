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
									label: 'F# for C#/Java developers',
									translations: { fr: 'F# pour développeurs C#/Java', es: 'F# para desarrolladores C#/Java' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'fsharp' } }],
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
									label: 'Advanced TypeScript',
									translations: { fr: 'TypeScript avancé', es: 'TypeScript avanzado' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'typescript-advanced' } }],
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
								{
									label: 'three.js for C#/Java developers',
									translations: { fr: 'three.js pour développeurs C#/Java', es: 'three.js para desarrolladores C#/Java' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'threejs' } }],
								},
							],
						},
						{
							label: 'Infrastructure & tooling',
							translations: { fr: 'Infrastructure et outillage', es: 'Infraestructura y herramientas' },
							items: [
								{
									label: 'WSL containers',
									translations: { fr: 'Conteneurs WSL', es: 'Contenedores WSL' },
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
									label: 'PostgreSQL and Amazon Aurora',
									translations: { fr: 'PostgreSQL et Amazon Aurora', es: 'PostgreSQL y Amazon Aurora' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'postgresql-aurora' } }],
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
							label: 'Modeling & formal methods',
							translations: { fr: 'Modélisation et méthodes formelles', es: 'Modelado y métodos formales' },
							items: [
								{
									label: 'Petri nets and what they are good for',
									translations: { fr: 'Réseaux de Petri et à quoi ils servent', es: 'Redes de Petri y para qué sirven' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'petri-nets' } }],
								},
							],
						},
						{
							label: 'Architecture & design',
							translations: { fr: 'Architecture et conception', es: 'Arquitectura y diseño' },
							items: [
								{
									label: 'Hexagonal Architecture: Ports & Adapters',
									translations: { fr: 'Architecture hexagonale : Ports et adaptateurs', es: 'Arquitectura hexagonal: Puertos y adaptadores' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'hexagonal-architecture' } }],
								},
								{
									label: 'Architecture patterns: choosing boundaries',
									translations: { fr: 'Patterns d’architecture : choisir les frontières', es: 'Patrones de arquitectura: elegir límites' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'architecture-patterns' } }],
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
								{
									label: 'SlashForge, workflow commands for Claude Code',
									translations: { fr: 'SlashForge, des commandes de workflow pour Claude Code', es: 'SlashForge, comandos de flujo de trabajo para Claude Code' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'slashforge' } }],
								},
								{
									label: 'TypeSafe AI System One and Jev',
									translations: { fr: 'TypeSafe AI System One et Jev', es: 'TypeSafe AI System One y Jev' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'typesafe-ai-system-one' } }],
								},
								{
									label: 'Repository Dogfooding Lab',
									translations: { fr: 'Laboratoire de dogfooding des dépôts', es: 'Laboratorio de dogfooding de repositorios' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'repository-dogfooding-lab' } }],
								},
								{
									label: 'Gaia: coordinating agents with evidence',
									translations: { fr: 'Gaia : coordonner des agents avec des preuves', es: 'Gaia: coordinar agentes con evidencia' },
									collapsed: true,
									items: [{ autogenerate: { directory: 'gaia' } }],
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
						{
							label: "Candle: Hugging Face's machine learning in Rust",
							translations: { fr: "Candle : le ML en Rust de Hugging Face", es: 'Candle: el ML en Rust de Hugging Face' },
							collapsed: true,
							items: [{ autogenerate: { directory: 'candle' } }],
						},
						{
							label: 'ComfyUI: image generation with diffusion models',
							translations: { fr: 'ComfyUI : générer des images avec les modèles de diffusion', es: 'ComfyUI: generar imágenes con modelos de difusión' },
							collapsed: true,
							items: [{ autogenerate: { directory: 'comfyui' } }],
						},
					],
				},
				{
					label: '3D & graphics',
					translations: { fr: '3D et graphisme', es: '3D y gráficos' },
					items: [
						{
							label: 'Blender for developers',
							translations: { fr: 'Blender pour les développeurs', es: 'Blender para desarrolladores' },
							collapsed: true,
							items: [{ autogenerate: { directory: 'blender' } }],
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
						{
							label: 'Guitar Alchemist Lab',
							translations: { fr: 'Laboratoire Guitar Alchemist', es: 'Laboratorio Guitar Alchemist' },
							collapsed: true,
							items: [{ autogenerate: { directory: 'ga-lab' } }],
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
