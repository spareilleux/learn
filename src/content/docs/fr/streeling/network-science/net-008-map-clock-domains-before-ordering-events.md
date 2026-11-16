---
title: Mettre en correspondance les domaines d'horloge avant d'ordonner les événements
description: Mettre en correspondance les domaines d'horloge avant d'ordonner les événements — Science des réseaux
sidebar:
  label: NET-008 · Mettre en correspondance les domaines d'horloge avant d'ordonner les événements
  order: 8
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/network-science/fr/net-008-map-clock-domains-before-ordering-events.fr.md
---

:::note[Streeling University]
**NET-008** · Mettre en correspondance les domaines d'horloge avant d'ordonner les événements · intermédiaire · 45 minutes

Généré par le département *Science des réseaux* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/network-science/fr/net-008-map-clock-domains-before-ordering-events.fr.md) · [Mon journal](../../journal/)

Prérequis: [NET-004](../../network-science/net-004-semantic-backpressure-and-evidence-dependencies/), [MCL-007](../../musicology/mcl-007-integrate-a-midi-tempo-map-before-scheduling/)
:::

> **Portée du brouillon.** Coordonnées d'horloges pédagogiques, calculs de modèle affine et lecture de sources primaires et de code. Les revues humaines technique, linguistique et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucune synchronisation d'horloges, mesure de navigateur, latence de messages d'agents ou temporisation matérielle n'ont été mesurées.

## La question du projet

Un agent audio rapporte une heure planifiée en secondes ; un agent d'interface rapporte l'heure d'un rappel en millisecondes. Un autre agent peut-il soustraire ces nombres ou déduire quelle action a eu lieu en premier ? [MCL-007](../../musicology/mcl-007-integrate-a-midi-tempo-map-before-scheduling/) convertit les coordonnées musicales en secondes. Ce cours distingue cette conversion d'une relation entre deux horloges. [NET-004](../../network-science/net-004-semantic-backpressure-and-evidence-dependencies/) exige des preuves liées à leur action ; un horodatage exige aussi l'identité et la portée de son horloge.

Le [brouillon de travail Web Audio 1.1 daté](https://www.w3.org/TR/2026/WD-webaudio-1.1-20260922/) décrit une chronologie audio et une estimation de correspondance via `getOutputTimestamp()`. [High Resolution Time](https://www.w3.org/TR/2026/WD-hr-time-3-20260901/) définit des horodatages de performance en millisecondes avec une origine temporelle. Les deux documents cités sont des brouillons de travail. Leur lecture n'établit pas les fonctions implémentées par un navigateur particulier.

## 1. Les unités seules n'alignent pas les origines

Notons c une coordonnée pédagogique de contexte audio en secondes et p une coordonnée d'horloge de performance en millisecondes. Posez le modèle :

```text
p = a + b*c
a = 10000 ms
b = 1000.1 ms per context second
```

Une cible à c = 10 correspond à p = 20001 ms. Un appel de planification à p = 19980 ms précède cette cible convertie de 21 ms. Multiplier des secondes par 1000 sans tenir compte de l'origine et du rythme des horloges ne produit pas cette comparaison.

### Exercice 1 — Comparer des coordonnées compatibles

Calculez l'avance entre l'appel et la cible. Pourquoi soustraire directement 19980 de 10 n'a-t-il aucun sens, et pourquoi la conversion d'unités seule reste-t-elle insuffisante ?

> **Réponse:** La cible convertie est à 20001 ms et l'avance est de 21 ms. Les nombres bruts utilisent des unités et origines différentes. Une conversion d'unités ne fournit ni le décalage de 10000 ms ni la relation supposée entre les rythmes des horloges. Le résultat est conditionné par le modèle, et non une marge de planification mesurée.

## 2. Deux points d'ancrage ajustent un rythme ; ils ne le valident pas

Utilisez les points d'ancrage pédagogiques (c = 0, p = 10000) et (c = 60, p = 70006). Leur pente est 60006/60 = 1000.1 ms par seconde de contexte. Par rapport à 1000 ms par seconde, la différence est de 100 parties par million. C'est un rythme apparent dans des données inventées, et non une dérive observée de périphérique.

Un point d'ancrage peut fixer un décalage seulement après avoir supposé un rythme. Deux points exacts déterminent une droite affine, mais ne peuvent pas établir que les horloges restent affines, identifier le bruit des échantillons ou justifier une extrapolation indéfinie.

### Exercice 2 — Identifier l'hypothèse manquante

Déduisez la pente, l'ordonnée à l'origine et la différence de rythme. Que ne pourrait-on pas identifier à partir du seul premier point d'ancrage ?

> **Réponse:** La pente vaut 1000.1, l'ordonnée à l'origine 10000 ms et la différence relative de rythme 100 parties par million. Avec un seul point d'ancrage, de nombreuses pentes avec les ordonnées à l'origine correspondantes passent par ce point. Il faut une hypothèse de rythme ou davantage d'observations appariées ; une droite ajustée seule ne prouve pas la stabilité d'une horloge.

## 3. Distinguer interpolation et extrapolation

Le [jeu d'essai d'horloges](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/tempo-clocks-2026-10-22/clock-map.json) prédit p = 40003 ms à c = 30 et p = 130012 ms à c = 120. Conserver la même ordonnée à l'origine tout en utilisant la pente nominale 1000 prédit 130000 ms à c = 120, soit un écart de 12 ms sous le modèle pédagogique. Le point à 30 est entre les points d'ancrage ; celui à 120 est au-delà.

### Exercice 3 — Borner l'affirmation d'horodatage

Calculez les deux prédictions et l'écart à 120. L'ajustement à deux points transforme-t-il la prédiction ultérieure en événement observé ou valide-t-il son incertitude ?

> **Réponse:** Les prédictions sont 40003 et 130012 ms ; la valeur au rythme nominal à 120 est 130000 ms, soit un écart de 12 ms. Aucune prédiction n'est un événement observé. L'extrapolation exige le maintien d'une hypothèse de modèle et sa propre évaluation d'erreur, surtout après une suspension, un redémarrage ou un changement de périphérique.

## 4. Propager les bornes avant d'accepter un point réservé

Supposez que la coordonnée de performance de chaque point d'ancrage comporte une erreur d'au plus 0.5 ms, que les coordonnées de contexte soient exactes et qu'une seule relation affine s'applique. À c = 90, les poids d'interpolation prolongés au-delà des points d'ancrage valent -0.5 et 1.5. La valeur centrale prédite est 100009 ms, avec une borne déterministe d'erreur de 1 ms. C'est une borne sous les hypothèses déclarées, et non un intervalle de confiance.

Fournissez maintenant une valeur pédagogique réservée de 100011 ms avec une erreur d'au plus 0.5 ms. L'intervalle de prédiction va de 100008 à 100010 ms ; l'intervalle du point réservé va de 100010.5 à 100011.5 ms. Ils ne se recoupent pas.

### Exercice 4 — Laisser le modèle échouer

Calculez la borne avec les valeurs absolues des poids et comparez le résidu de 2 ms à la marge d'erreur combinée. Qu'est-ce qui a été réfuté, et quelle cause reste inconnue ?

> **Réponse:** La borne est 0.5 fois (0.5 + 1.5) = 1 ms. Inclure l'erreur du point réservé permet au plus 1.5 ms de résidu, ce qui est inférieur aux 2 ms pédagogiques. La combinaison de relation affine, d'hypothèses de coordonnées et de bornes d'erreur est incompatible avec ce relevé réservé. Cela n'isole pas une dérive, une erreur d'horodatage, un changement d'origine ou une autre cause. Ne réajustez pas silencieusement le modèle pour rebaptiser le modèle initial « vérifié ».

## 5. Porter les preuves d'horloge dans la transmission

Le [composant de tableau de bord à la révision fixée](https://github.com/GuitarAlchemist/ga/blob/76efbffd5af82b46c3146957a6bd4504008eeb89/Apps/ga-dashboard/src/app/shared/progression.component.ts#L84-L167) planifie un rappel de navigateur, puis lit `AudioContext.currentTime` pour demander des démarrages d'oscillateurs. Le fichier examiné ne contient ni horodatages de sortie appariés ni correspondance d'horloges mesurée. C'est un démonstrateur sélectionné, et non une preuve concernant toutes les interfaces de lecture de GA.

L'horodatage apparié du brouillon Web Audio est une estimation proche d'une position du flux de sortie ; ce n'est ni une observation au microphone ni un protocole général de synchronisation entre hôtes. Le document avertit aussi de ne pas traiter la différence entre `currentTime` et la coordonnée renvoyée du flux de sortie comme une estimation fiable de latence de sortie. Préservez l'identité du périphérique, du contexte et du cycle de vie lorsque vous interprétez ces preuves.

### Exercice 5 — Proposer un relevé délimité

Que faut-il joindre à une comparaison d'horodatages entre agents ? Donnez une alternative plus simple à l'introduction d'un DSL d'horloges, une condition de rejet et une mesure encore nécessaire pour la latence audio physique.

> **Réponse:** Conservez les identifiants d'horloge, les unités, les origines, les points d'ancrage appariés, les hypothèses de modèle et d'erreur, l'intervalle de validité, les changements du cycle de vie, l'identité du code et les extrémités de la comparaison. Une seule horloge monotone commune d'acquisition peut être plus simple qu'un nouveau protocole. Rejetez ou différez les comparaisons lorsque les correspondances échouent aux bornes sur les points réservés ou qu'un changement d'identité les invalide. Une affirmation de latence audio physique exige une observation de sortie définie et étalonnée indépendamment. C'est une proposition de relevé consultatif ; aucun schéma de relevé, service de synchronisation ou DSL d'horloges n'ont été implémentés.

## Travail de l'apprenant avec accès aux sources

Préparez une revue de transmission contenant l'avance de 21 ms, l'ajustement et le rythme à deux points d'ancrage, les deux prédictions ultérieures, la borne d'erreur pondérée et le rejet du point réservé. Précisez un cas de réinitialisation de l'identité d'horloge et une alternative d'acquisition avec une horloge commune. Consignez l'aide et les hypothèses non résolues. La [grille d'évaluation de la revue](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/tempo-clocks-2026-10-22/reviewer-rubric.json) est préparée, sans véritable décision d'apprenant.

Le [relevé de lecture primaire](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/tempo-clocks-2026-10-22/primary-reading.json) distingue les spécifications des observations. Aucune synchronisation productive d'agents, adaptateur déployé, bénéfice d'écoute ou stabilité d'horloge n'ont été établis.
