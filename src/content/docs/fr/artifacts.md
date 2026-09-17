---
title: Artefacts
description: Pages interactives construites avec Claude en travaillant sur mes projets — cartographies, audits et simulateurs qui complètent les cours.
---

En travaillant sur mes dépôts avec [Claude Code](https://code.claude.com/docs/fr/overview), certaines analyses deviennent une page interactive (un *artefact*) plutôt qu'une leçon : une cartographie, un audit, un simulateur. Elles sont hébergées sur claude.ai, s'ouvrent dans n'importe quel navigateur, et sont référencées ici et depuis les cours qu'elles illustrent.

:::note[Des instantanés, pas des cours]
Chaque artefact est daté et décrit un dépôt à un moment donné. Contrairement aux leçons, ils ne sont pas tenus à jour. Certains sont uniquement en anglais ou en français.
:::

## Développement assisté par IA

### Playbook SDLC × IX

[Ouvrir l'artefact](https://claude.ai/code/artifact/9e67e00d-d2a6-4490-b2ed-d485e34be6ab) · français · 2026-09-13 · IX à `2a84de4`

Les douze plays de l'[AI-Native SDLC Playbook](https://academy.claude.com/courses/ai-native-sdlc-playbook) d'Anthropic (plan, design, build, test, deploy, maintain), confrontés un par un à ce que font réellement les dépôts IX et Demerzel. Chaque play reçoit un verdict dans la logique hexavalente de l'écosystème, avec la preuve sur laquelle il repose et l'écart à combler. La page se termine par les cinq écarts prioritaires et quatre idées de leçons pour la série sur l'IA agentique : les tests verts qui ne testent rien, les hooks comme gates d'approbation, la séparation des rôles avec un agent, et décider avant d'implémenter.

### Demerzel × ComfyUI — Governed Asset Pipeline

[Ouvrir l'artefact](https://claude.ai/code/artifact/cc15cb21-c3f9-486a-b758-4127000246c8) · anglais · 2026-07-18

Comment la génération d'images [ComfyUI](https://docs.comfy.org/) a été branchée dans Demerzel comme fournisseur gouverné : chaque demande de texture passe par une gate budgétaire, s'exécute localement sur le GPU et laisse un enregistrement de provenance (seed, hash du workflow, prompt, consommateur). La gate budgétaire est interactive : choisissez un fournisseur et un coût, et voyez-la autoriser, bloquer ou échouer en mode fermé.

## Musique et guitare

### Banc de Placement

[Ouvrir l'artefact](https://claude.ai/code/artifact/f685cdc7-8e42-4b1f-9711-c9abb14d378a) · français et anglais · 2026-08-20

Un banc 3D pour placer deux micros sur une guitare acoustique. Déplacez les micros et lisez l'écart entre les deux trajets, le décalage temporel et la fréquence de la première annulation (filtre en peigne) quand les deux canaux sont sommés en mono. Le modèle peut se superposer à l'image d'une caméra pour vérifier une installation réelle.

### Atlas des Douze

[Ouvrir l'artefact](https://claude.ai/artifact/Qh4oMxFH5aPx9dYC4xGjyn) · français et anglais · 2026-09-17 · GA à `a826864`

Onze planches 3D interactives (three.js WebGPU) pour le cours Théorie musicale pour Guitar Alchemist : les douze classes de hauteurs disposées en atelier, manche, hélice, bracelets, sept modes, vecteur d'intervalles, cercle des quintes, accords d'une tonalité, machine à cadences, OPTIC-K et accordages. Le rail de chaque planche explique ce qu'elle montre et où le cours et GA divergent. Certaines textures de pierre et de bois ont été générées avec ComfyUI (SDXL base 1.0), ce que la page indique à côté de chacune.
