---
title: Exécuter et rejeter un réglage de décroissance du mi à vide
description: Exécuter et rejeter un réglage de décroissance du mi à vide — Acoustique de la guitare et synthèse sonore
sidebar:
  label: GAS-004 · Exécuter et rejeter un réglage de décroissance du mi à vide
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/guitar-acoustics/fr/gas-004-run-open-e-decay-candidate.fr.md
---

:::note[Streeling University]
**GAS-004** · Exécuter et rejeter un réglage de décroissance du mi à vide · intermédiaire · 45 minutes

Généré par le département *Acoustique de la guitare et synthèse sonore* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/guitar-acoustics/fr/gas-004-run-open-e-decay-candidate.fr.md) · [Mon journal](../../journal/)

Prérequis: [GAS-003](../../guitar-acoustics/gas-003-decay-calibration-open-e/)
:::

> **Brouillon rédigé par IA.** Les validations humaines par un spécialiste du domaine, un réviseur maîtrisant la langue et un apprenant restent à réaliser. La publication HTML du cours reste en attente.

## La question d'ingénierie

[GAS-003](../../guitar-acoustics/gas-003-decay-calibration-open-e/) proposait de faire passer la décroissance de base de GA de **0.9978** à **0.9976** et d'exiger une réduction d'au moins **1 dB** de l'erreur absolue par rapport à la décroissance d'un mi à vide enregistré. Ce cours présente l'expérience exécutée. Le réglage améliore légèrement la mesure retenue et échoue au critère défini au préalable. Votre livrable est un compte rendu de rejet étayé, dont la provenance permet à un autre ingénieur de reproduire la décision.

Consultez le [laboratoire commun](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/README.md) et le [guide des preuves](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/README.md) en parallèle. Le laboratoire compile sans modification le [code du moteur GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs), figé à `dc2e74cbd992a298f67efb928b5b3754615e1924`. Le [jeu de référence historique](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/state/streeling/fixtures/guitar-acoustics/gas-001/README.md) est figé à `5c4967454ddc740ed937c87719ca4d71a3522e4b`.

## Fixer la comparaison avant de mesurer

Chaque variante démarre avec un moteur neuf à **44100 Hz**, le profil de guitare par défaut **0**, une fréquence E2 demandée de **82.4069 Hz**, une vélocité de **0.1** et une durée de **4 secondes**, soit **176400 échantillons**. Réinitialiser le moteur évite de transmettre à l'autre variante les états de retard, de filtre ou de réverbération d'une note précédente. Les réglages de brillance, de décroissance de l'attaque, de dispersion et de réverbération restent fixes.

L'initialisation sélectionne déjà le profil **0**. La référence conserve sa décroissance de base de **0.9978**. Pour le candidat, l'initialisation est suivie de `engine_set_decay` avec **0.9976**, puis de `engine_note_on`, puis du rendu. Sélectionner un profil après le setter écraserait la décroissance demandée. Lisez l'[adaptateur natif](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/native.rs) et le [programme d'exécution](https://github.com/spareilleux/learn/blob/main/code/streeling/guitar-runtime/run.mjs), au lieu de déduire l'ordre des appels du nom du candidat.

### Exercice 1 — Protéger l'intervention

Pourquoi faut-il sélectionner le profil avant de régler la décroissance, et utiliser un moteur neuf pour chaque variante ?

> **Réponse :** La sélection du profil écrit la décroissance ainsi que d'autres paramètres ; une sélection ultérieure pourrait donc effacer l'intervention. Un moteur neuf donne aux deux variantes le même état initial ; réutiliser un moteur confondrait le changement de paramètre avec les états accumulés des voix, des filtres et de la réverbération.

## Reproduire le périmètre des artefacts

Le laboratoire utilise [Rust](https://doc.rust-lang.org/rustc/command-line-arguments.html), la [cible WebAssembly](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html) et [Node.js](https://nodejs.org/en/learn/getting-started/nodejs-with-webassembly). Le relevé indique Windows x64, Rust **1.94.0** et Node **v24.12.0**. Il s'agit d'une compilation pédagogique avec optimisation du compilateur, distincte du profil de livraison du projet amont. L'exécution sous Linux/WSL et macOS reste à vérifier.

Depuis la racine du dépôt, le laboratoire a exécuté cette commande après avoir remplacé les deux paramètres fictifs par des chemins réels :

```text
node code/streeling/guitar-runtime/run.mjs <new-output-directory> <recorded-wav-path>
```

Utilisez un nouveau répertoire de sortie. La commande s'écrit de la même manière sur tous les systèmes pris en charge ; le programme choisit le suffixe de l'exécutable. Il vérifie l'empreinte du fichier de référence et utilise les outils installés sans télécharger de dépendances. Suivez les instructions d'acquisition du laboratoire avant de le lancer.

L'enregistrement est attribué à **collegefishiesd** et diffusé sous licence [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). Le fichier d'entrée exact a été conservé uniquement dans un cache d'expérience externe ; il n'est pas distribué dans ce laboratoire pédagogique. Le [relevé des entrées publiques](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/public-input-readback.json) consigne l'acquisition et l'attribution. Les nouveaux fichiers natifs, [audio de référence](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/baseline.wav) et [audio candidat](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/candidate.wav), sont conservés au format WAV PCM16. L'enregistrement d'entrée utilise un WAV IEEE float32 ; le décoder comme du PCM16 invaliderait la comparaison.

### Exercice 2 — Vérifier la reproductibilité

Quelles preuves établiraient que la nouvelle référence reproduit l'expérience historique, au-delà d'une décroissance arrondie similaire ?

> **Réponse :** Le WAV de référence possède exactement l'empreinte du fichier historique, et la réexécution du script de mesure primaire inchangé produit un JSON de référence entièrement identique aux mesures archivées. Une simple correspondance des décroissances arrondies pourrait masquer une autre forme d'onde ou une méthode de mesure modifiée.

## Mesurer le même événement

La méthode soustrait le niveau RMS de la fenêtre précoce de celui de la fenêtre tardive, en utilisant **0.2–0.4 seconde** et **1.0–1.2 seconde** après le début de la note. Dans l'enregistrement, ce début se situe à environ **1.1 seconde** ; une attaque supplémentaire survient vers **2.75 secondes**. Les fenêtres sélectionnées se trouvent donc à environ **1.3–1.5 seconde** et **2.1–2.3 secondes** depuis le début du fichier. Elles précèdent toutes deux cette nouvelle attaque. Le rendu commence à zéro.

Il s'agit d'une mesure locale de l'enveloppe, pas d'une constante de décroissance du fichier entier. Une autre guitare, un autre microphone, une autre pièce et un autre pincement ont fourni la référence. La variation de niveau au sein du fichier élimine une simple différence de gain, sans transformer l'enregistrement en cible physique universelle.

### Exercice 3 — Repérer une fenêtre contaminée

Une fenêtre de l'enregistrement commençant à **2.8 secondes** répondrait-elle à la même question sur la décroissance de la première note ?

> **Réponse :** Non. Elle commence après l'attaque supplémentaire vers **2.75 secondes** et introduit une nouvelle excitation. Conservez les fenêtres relatives au début de la note et documentez le caractère approximatif de ce repère ; sinon, l'expérience change de question tout en gardant la même étiquette.

## Lire les relevés sans arrondi

La [réexécution primaire](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/primary-measurement-replay.json) consigne une décroissance de référence de **−3.9221151304441193 dB**, l'utilisation du script primaire inchangé et la correspondance complète du JSON de référence. La [synthèse de référence](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/baseline-primary-measurements.json) et la [synthèse du candidat](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/candidate-primary-measurements.json) conservent ses autres mesures. Les valeurs suivantes, à leur précision enregistrée, proviennent des [résultats d'exécution](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/guitar-runtime-2026-10-22/results.json) ; le relevé de réexécution documente des écarts négligeables dus à l'ordre des opérations arithmétiques entre les implémentations.

| Variante native PCM16 | Décroissance, dB | Erreur absolue par rapport à l'enregistrement, dB |
|---|---:|---:|
| Référence | −1.0848117418372532 | 2.837303388606845 |
| Candidat | −1.198977891431639 | 2.723137239012459 |

L'amélioration enregistrée est de **0.11416614959438576 dB**. Pour un calcul lisible, **2.837303 − 2.723137 ≈ 0.114166 dB**. L'exigence préexistante de **1 dB** autoriserait une erreur candidate d'environ **1.837303 dB**, en partant de la référence non arrondie. L'erreur candidate réelle est d'environ **2.723137 dB** : le candidat échoue donc. Ne réduisez pas le seuil après avoir vu le résultat.

### Exercice 4 — Prendre la décision

Une amélioration positive de **0.114166 dB** satisfait-elle une exigence d'au moins **1 dB** ? Que doit indiquer le compte rendu ?

> **Réponse :** Elle échoue. Consignez que la décroissance de base **0.9976** a légèrement réduit cette erreur pour E2 dans les conditions fixées, sans atteindre le critère d'amélioration préexistant. Rejetez ce réglage selon ce critère. Ce résultat n'établit ni qu'il sonne moins bien ni que l'algorithme ne peut pas être amélioré.

## Garder les questions ouvertes

Une exécution réussie se distingue de l'acceptation du candidat. Le programme peut se terminer avec succès alors que `candidate_passes_decline_gate` vaut faux. Les assertions sur l'amplitude des échantillons, le silence et le découpage en blocs couvrent certaines propriétés d'exécution. Elles ne valident pas toutes les protections de GAS-003. Les synthèses primaires contiennent des observations de hauteur et de partiels, mais leurs valeurs arrondies ne prouvent pas la préservation de l'attaque ni de chaque propriété spectrale.

### Exercice 5 — Préparer la transmission suivante

Que doit-on encore examiner avant une décision sur le produit, même si un futur candidat satisfait le critère numérique ?

> **Réponse :** Gardez des travaux distincts pour la sensibilité au repérage du début de note, la préservation de l'attaque, les contrôles de hauteur et de suivi des partiels, les autres notes et vélocités, ainsi que l'écoute en aveugle à niveaux égalisés. Le rendu natif et l'exécution WebAssembly hors ligne ne certifient pas la capture AudioWorklet dans le navigateur, l'ordonnancement ou le comportement mémoire sur de longues durées. Les validations humaines par un spécialiste du domaine, un réviseur maîtrisant la langue et un apprenant, ainsi que la publication HTML du cours, restent également en attente.

Conservez les artefacts du candidat rejeté. Ils remplacent une hypothèse non testée par un résultat délimité et fournissent à l'expérience suivante une référence reproductible, sans transformer une mesure d'étalonnage en jugement d'écoute.
