---
module_id: cyb-004-observe-before-correcting-a-feedback-loop
department: cybernetics
course: "Observer avant de corriger une boucle de rétroaction"
level: intermediate
prerequisites: ["cyb-002-active-dampening-cross-repo-oscillation"]
estimated_duration: "40 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Observer avant de corriger une boucle de rétroaction

> **Brouillon source produit par IA.** Les validations par un spécialiste du domaine, une personne maîtrisant la langue et un apprenant, ainsi que la publication publique du cours en HTML, restent à faire.

## 1. Définir ce que la boucle contrôle

Une nouvelle tentative peut produire un autre journal sans améliorer le système. Avant d'automatiser une correction, identifiez le processus contrôlé, l'intervention autorisée, l'observation et la règle qui transforme les éléments observés en décision. Répéter sans observer l'état pertinent ne démontre pas une amélioration en boucle fermée.

[CYB-002](../en/cyb-002-active-dampening-cross-repo-oscillation.md) présente l'état cible, l'état mesuré et la rétroaction. Nous confrontons ici ce vocabulaire à des traces de projet conservées. Ses champs illustratifs de gouvernance ne deviennent pas de nouvelles exigences de protocole. Une erreur qui diminue sur un seul point n'établit pas la convergence et ne justifie pas une politique universelle de correction.

Consultez le [guide des éléments probants](../../../../code/streeling/evidence/feedback-projections-2026-10-22/README.md) et la [tâche de l'apprenant](../../../../code/streeling/evidence/feedback-projections-2026-10-22/learner-task.md). Votre livrable est une note de correction étayée. Cette leçon analyse des artefacts conservés ; elle ne rapporte aucune nouvelle exécution native ni aucun essai avec un apprenant.

### Exercice 1 — Nommer les composants de la boucle

Définissez le processus contrôlé, l'actionneur, le capteur et la décision dans l'[expérience de guitare](../../guitar-acoustics/en/gas-004-run-open-e-decay-candidate.md).

> **Réponse :** Le processus contrôlé est l'expérience fixe du moteur de guitare. L'actionneur est le paramètre de décroissance de base, passé de **0.9978** à **0.9976**. Le capteur mesure la baisse du niveau PCM16 dans des fenêtres relatives au début du son, puis l'erreur absolue par rapport à la référence. La décision compare l'amélioration au seuil déclaré. Le code de sortie du processus renseigne sur l'exécution, une autre propriété.

## 2. Distinguer exécution réussie et objectif atteint

Les [résultats de guitare figés](https://github.com/spareilleux/learn/blob/7eaa68f8d4d32e8d1b495a93775d18135e709811/code/streeling/evidence/guitar-runtime-2026-10-22/results.json) proviennent du moteur source `dc2e74cbd992a298f67efb928b5b3754615e1924`. Les deux variantes appliquent le même quantificateur et la même procédure de mesure à leurs entrées réelles. Leurs erreurs permettent donc cette comparaison arithmétique ; la quantification n'invalide pas toute différence mesurée.

L'[analyse de décision](../../../../code/streeling/evidence/feedback-projections-2026-10-22/feedback-decisions.json) consigne une erreur initiale de **2.837303388606845 dB**, une erreur du candidat de **2.723137239012459 dB** et une amélioration de **0.11416614959438576 dB**. L'exigence déclarée est d'au moins **1 dB**. Le code de sortie **0** et la valeur false de `candidate_passes_decline_gate` peuvent coexister : l'expérience est terminée et le candidat n'atteint pas son objectif.

### Exercice 2 — Calculer l'erreur admissible

Quelle erreur du candidat satisferait le critère nommé ? Le candidat observé est-il admissible ?

> **Réponse :** Soustrayez l'amélioration exigée de l'erreur initiale : le calcul enregistré donne une erreur maximale de **1.8373033886068448 dB** pour le candidat. L'erreur réelle dépasse cette limite. Rejetez ce candidat selon ce critère. Une seule intervention ne fournit ni taux de convergence, ni gradient, ni assurance qu'une autre modification de décroissance sera utile.

## 3. Qualifier les éléments observés avant de corriger

Pour le cas de la scène, [Godot](https://docs.godotengine.org/en/4.6/classes/class_resource.html) doit charger la scène sauvegardée et produire des observations nommées. Le [rapport de lancement échoué](../../../../code/streeling/evidence/weave-scene-2026-10-22/launcher-failed-run-report.json) consigne `godot_execution` avec `spawnSync godot ETIMEDOUT`. La limite de démarrage de **60 secondes** du contrôleur est dépassée. L'admission sémantique préalable a réussi, mais aucun rapport natif n'établit la géométrie ni l'identité des croisements.

Distinguez trois situations. **Observation absente :** le rapport natif attendu n'arrive jamais. **Mesure mal formée :** un rapport arrive avec des valeurs inutilisables, une provenance incorrecte ou une définition de capteur incompatible. **Objectif non atteint :** une observation valide enfreint son critère nommé. Un dépassement de délai n'est pas un défaut géométrique mesuré ; une valeur d'apparence numérique sans unités connues ne constitue pas un échec fiable de l'objectif.

Les [résultats finaux de la scène](../../../../code/streeling/evidence/weave-scene-2026-10-22/results.json) comprennent **190** contrôles natifs réussis et **3** défauts introduits comme témoins. Dans le témoin d'association incorrecte, les contrôles de géométrie et de brin supérieur réussissent, tandis que `ray_crossing_identity` échoue. Cette observation est utile : une géométrie correcte ne suffit pas à établir que l'impact identifie le croisement attendu.

### Exercice 3 — Choisir la catégorie d'échec

Classez le dépassement de délai et le résultat d'association incorrecte. Où placer un rapport utilisant des unités incompatibles ?

> **Réponse :** Le dépassement de délai laisse l'observation native absente. L'association incorrecte est un échec observé du critère d'identité malgré des contrôles géométriques réussis. Des unités incompatibles rendent la mesure proposée inutilisable tant que son interprétation n'est pas corrigée. Diagnostiquez le capteur absent ou défectueux avant de modifier la géométrie.

## 4. Déterminer ce que le capteur distingue

Un capteur projette souvent un état riche vers une représentation plus réduite. L'encodeur conservé utilise [Math.round](https://tc39.es/ecma262/multipage/numbers-and-dates.html#sec-math.round) : `Math.round(sample * 32767)`, stocké en PCM16 signé. Des sorties projetées égales ne révèlent pas toutes les différences entre leurs entrées.

La [relecture de quantification](../../../../code/streeling/evidence/feedback-projections-2026-10-22/quantization.json) trouve **2918** échantillons flottants différents entre le rendu natif initial et [Wasm](https://nodejs.org/en/learn/getting-started/nodejs-with-webassembly), mais **0** échantillon PCM16 différent. À l'échantillon **646**, la valeur native **0.000552888261154294** et celle de Wasm **0.0005528881447389722** deviennent toutes deux **18**. Ce contre-exemple concret délimite ce que l'égalité PCM observe ; ce n'est pas un théorème général sur des dynamiques cachées.

### Exercice 4 — Choisir une observation discriminante

Quelle observation conservée réfute l'égalité brute : les données PCM16 égales ou les échantillons flottants décodés différents ?

> **Réponse :** Les échantillons flottants différents réfutent l'égalité brute. L'égalité PCM16 établit seulement l'égalité à cette projection. Aucun de ces résultats n'établit une équivalence auditive. Choisissez un capteur dont la résolution convient à la question et conservez l'observation plus riche lorsqu'elle existe.

## 5. Effectuer une correction vérifiée, puis s'arrêter

La [caractérisation par exécutable direct](../../../../code/streeling/evidence/weave-scene-2026-10-22/direct-executable-characterization.json) a lancé le même exécutable installé sur le même projet copié et le même script, avec succès en **0.5707436999946367 secondes**. Une tentative antérieure modifiant le dossier parent dans PATH sélectionnait encore le lien, car l'exécutable réel portait un autre nom ; elle n'isolait pas un changement de sélection d'exécutable. Le contrôleur final résout ce lien avant le lancement.

### Exercice 5 — Rédiger une note de correction bornée

Proposez une correction du lancement, sa vérification, sa condition d'arrêt, son critère de réfutation et sa limite de coût.

> **Réponse :** Résolvez le lien de l'exécutable et consignez le chemin sélectionné en conservant les mêmes entrées copiées. Exigez un rapport natif valide avec les contrôles nommés. Arrêtez-vous après cette comparaison bornée ; conservez les journaux d'échec si le démarrage dépasse le délai ou si un contrôle échoue. Un lancement direct résolu qui ne produit toujours pas le rapport réfute l'affirmation que cette correction suffit localement. Limitez la tentative au délai existant et examinez le résultat avant toute autre intervention.

Ce résultat local séquentiel étaye cette hypothèse corrective. Il n'établit ni fiabilité universelle du démarrage, ni gain causal de performance, ni stabilité d'un assemblage C#. L'acceptation humaine reste `null` ; l'assistance sur les sources est en attente. La suite exige une nouvelle question bornée, sans promesse d'amélioration infinie ni de convergence exponentielle.
