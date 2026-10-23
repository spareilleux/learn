---
module_id: aud-008-measure-a-filter-with-paired-input-and-output
department: audio-engineering
course: "Mesurer un filtre avec une entrée et une sortie appariées"
level: intermediate
prerequisites: ["aud-006-calibrate-spectral-amplitudes", "cs-013-preserve-spectral-axes-and-units", "gas-007-distinguish-body-poles-from-string-partials"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Mesurer un filtre avec une entrée et une sortie appariées

> **Portée du brouillon.** Calculs pédagogiques de signaux périodiques et inspection du code à une révision précise. Les revues humaines technique, linguistique, musicale et pédagogique ainsi que la vérification du HTML du cours déployé restent à effectuer. Aucun nouvel enregistrement, rendu du moteur ou flux de travail [ComfyUI](https://docs.comfy.org/) n'ont été capturés.

## La question du projet

Un agent double l'amplitude d'un partiel rendu et annonce un meilleur filtre de caisse. Le filtre a-t-il changé, ou son entrée ? [GAS-007](../../guitar-acoustics/en/gas-007-distinguish-body-poles-from-string-partials.md) identifie une interface concrète d'entrée et de sortie avant la réverbération. [AUD-006](aud-006-calibrate-spectral-amplitudes.md) traite l'étalonnage des amplitudes. Ici, nous conservons ensemble excitation et réponse.

## 1. Déclarer l'expérience avant de diviser les spectres

Utilisez une réponse impulsionnelle finie pédagogique délibérément petite, sans rapport avec une affirmation de réalisme mesuré de guitare :

```text
h = [3/4, 1/4]
y[n] = (3/4)*x[n] + (1/4)*x[n-1]
H(omega) = 3/4 + (1/4)*exp(-i*omega)
```

Pour l'expérience suivante, x est périodique de période N = 8 ; x[-1] désigne x[7]. Observez une période complète en régime établi. La [convention de TFD](https://www.dsprelated.com/freebooks/mdft/DFT_Definition.html) est la transformée directe non normalisée avec une exponentielle négative. À l'indice fréquentiel k = 2, omega = pi/2, donc H = 0.75 - 0.25i et son module vaut environ 0.790569415.

Cet exemple n'utilise ni fenêtre de Hann ni démarrage tronqué. [CS-013](../../computer-science/en/cs-013-preserve-spectral-axes-and-units.md) explique les axes et les métadonnées de découpage en trames nécessaires en dehors de ce petit exemple.

### Exercice 1 — Identifier les conditions de mesure

Pourquoi x[-1] = x[7] compte-t-il ? Quelles hypothèses permettent Y[k] = H[k]X[k] aux indices fréquentiels sélectionnés ?

> **Réponse:** Cela fournit l'échantillon précédent de la même entrée périodique en régime établi. Le système est le filtre linéaire invariant dans le temps déclaré et l'enregistrement contient une période complète avec des conventions de transformée correspondantes. C'est un filtrage circulaire d'une entrée périodique, et non les huit premiers échantillons d'une convolution linéaire initialisée à zéro. Les enregistrements finis avec d'autres conditions aux limites exigent un traitement distinct.

## 2. Une sortie plus grande peut provenir entièrement d'une entrée plus grande

Le [jeu d'essai apparié](../../../../code/streeling/evidence/filter-phase-2026-10-22/paired-transfer.json) utilise des cosinus à k = 2 avec des amplitudes d'entrée de 0.25 et 0.50 :

| Amplitude du cosinus d'entrée | X[2] | Y[2] | Amplitude du cosinus de sortie, environ |
| --- | --- | --- | --- |
| 0.25 | 1 | 0.75 - 0.25i | 0.197642354 |
| 0.50 | 2 | 1.50 - 0.50i | 0.395284708 |

Diviser les coefficients complexes appariés donne la même réponse du filtre dans les deux essais. Diviser les modules de sortie entre les essais donne 2, ce qui décrit une mise à l'échelle de la sortie, et non un gain de filtre doublé. Aucune sonie ou préférence n'est mesurée.

### Exercice 2 — Résoudre l'amélioration apparente

Calculez Y[2]/X[2] dans les deux essais. Le rapport d'amplitudes de sortie de 2 établit-il une modification de H ?

> **Réponse:** Les deux rapports valent 0.75 - 0.25i, avec un module d'environ 0.790569415. Le filtre est inchangé. Doubler l'excitation double la sortie de ce filtre linéaire ; la comparaison limitée à la sortie confond la force d'entrée avec la réponse.

## 3. Une fréquence non excitée n'est pas un rejet mesuré

À k = 1, le jeu d'essai en cosinus possède des coefficients d'entrée et de sortie analytiquement nuls. De minuscules résidus de TFD en virgule flottante peuvent subsister dans un calcul numérique. Leur rapport n'établit pas la réponse. En fait, la réponse théorique du même filtre à cette fréquence est non nulle.

La situation est aussi fragile au voisinage de zéro. Posez X = 0.000001 à k = 2 et ajoutez un coefficient pédagogique de bruit de sortie de 0.01. Le rapport apparent devient alors 10000.75 - 0.25i, bien que le vrai H reste 0.75 - 0.25i. C'est un exemple de sensibilité, et non un plancher de bruit mesuré ou un seuil universel de rejet.

### Exercice 3 — Refuser un rapport non étayé

Un agent enregistre X[1] = 0 et Y[1] = 0, puis stocke un gain de filtre de 0. Que devrait-il stocker à la place ? Expliquez comment l'exemple de faible excitation modifie son plan d'acquisition.

> **Réponse:** Stockez le rapport comme indéfini ou non mesuré, avec une raison d'excitation insuffisante, et non comme un gain nul. Utilisez une excitation suffisante et une politique explicite de bruit et de conditionnement pour les fréquences d'intérêt. Le terme de bruit 0.01 divisé par l'entrée 0.000001 ajoute 10000 à l'estimation erronée. Un seuil doit découler des conditions réelles de mesure.

## 4. La troncature peut changer la réponse même avec le bon filtre

Pour un témoin distinct, utilisez l'amplitude 0.25 et la phase de départ pi/4, toujours à k = 2. Démarrez maintenant le filtre avec une entrée précédente nulle et ne conservez que N = 8 échantillons de sortie. La convolution linéaire finie complète comporte 9 échantillons ; le dernier a été éliminé. Diviser les spectres tronqués à huit points donne 0.71875 - 0.21875i, et non 0.75 - 0.25i.

### Exercice 4 — Diagnostiquer l'incompatibilité des conditions aux limites

Le rapport tronqué prouve-t-il que l'implémentation du filtre a changé ? Donnez deux façons valides de formuler une nouvelle comparaison.

> **Réponse:** Non. Le témoin a changé la condition aux limites et éliminé une fin de réponse non nulle. Soit vous acquérez un enregistrement déclaré périodique en régime établi, soit vous conservez la convolution finie complète et complétez l'entrée et la sortie avec des zéros jusqu'à une longueur commune de transformée suffisante pour la convolution linéaire. Gardez cohérents l'alignement des échantillons et la normalisation de la transformée. Pour les longues réponses récursives, définissez des tolérances de stabilisation et de fin de réponse ; un court recadrage arbitraire ne suffit pas.

## 5. Préserver la représentation exigée par la question

À la révision d'IX `bd1336b7c4045e427dcdbe80b102790e45da5ce1`, [stft](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L7-L30) renvoie des spectres complexes. La [projection en spectrogramme](https://github.com/GuitarAlchemist/ix/blob/bd1336b7c4045e427dcdbe80b102790e45da5ce1/crates/ix-signal/src/spectral.rs#L32-L54) qui suit renvoie les modules ou leurs valeurs en décibels. Cette projection élimine la phase de chaque coefficient.

Cette distinction dans le code ne garantit pas que des rapports de trames STFT transitoires fenêtrées arbitraires soient des fonctions de transfert exactes. Les limites de fenêtre, la mémoire non observée du filtre, les non-linéarités et les variations temporelles comptent toujours. Une estimation statistique de transfert pour des données bruitées exige un estimateur déclaré et des hypothèses au-delà de l'exemple sans bruit présenté ici.

### Exercice 5 — Préciser le prochain artefact capturé

Pour un test proposé de filtre de caisse dans GA ou ComfyUI, indiquez ce qu'il faut conserver pour qu'un autre agent distingue les changements de gain, de phase et d'excitation. Quel étage du code faut-il isoler, et qu'est-ce qui reste non testé ?

> **Réponse:** Conservez les échantillons d'entrée et de sortie appariés ou leurs transformées complexes correspondantes, la fréquence d'échantillonnage, le temps et l'alignement, les longueurs d'enregistrement et de transformée, les conventions de fenêtre et d'échelle, l'excitation, les paramètres du filtre, la révision du code et les décisions sur le bruit et la stabilisation. Isolez l'interface de la somme normalisée des cordes à la sortie sèche avant réverbération identifiée par GAS-007 ; la réverbération et l'écrêtage en aval exigent des essais distincts. Les sorties limitées aux modules peuvent étayer une question qualifiée sur le module, mais ne peuvent pas fournir la phase complexe manquante. Aucune capture ou adaptateur n'ont été implémentés par ce cours. [INF-008](../../information-theory/en/inf-008-keep-phase-when-waveform-identity-matters.md) donne un contre-exemple exact de phase.

## Travail de l'apprenant avec accès aux sources

Rédigez un plan d'acquisition capable de réfuter l'affirmation « une sortie plus grande signifie un gain de filtre plus grand ». Incluez les deux essais appariés, le refus d'un indice fréquentiel non excité, le calcul de faible excitation, un témoin d'incompatibilité des conditions aux limites et la représentation nécessaire pour la phase. Consignez l'aide et les conditions non résolues. La [grille d'évaluation de la revue](../../../../code/streeling/evidence/filter-phase-2026-10-22/reviewer-rubric.json) contient des critères préparés, et non des résultats d'apprenants.

Le [relevé des sources](../../../../code/streeling/evidence/filter-phase-2026-10-22/primary-readback.json) lie les fichiers sélectionnés. Les calculs pédagogiques n'établissent ni une réponse réelle de guitare, ni un graphe audio fonctionnel, ni une amélioration du moteur ou un résultat perceptif.
