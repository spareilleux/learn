---
title: Auditer un classement de voicings selon son contrat de distance
description: Auditer un classement de voicings selon son contrat de distance — Musique
sidebar:
  label: MUS-017 · Auditer un classement de voicings selon son contrat de distance
  order: 17
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/music/fr/mus-017-audit-voice-leading-rankings.fr.md
---

:::note[Streeling University]
**MUS-017** · Auditer un classement de voicings selon son contrat de distance · intermédiaire · 60 minutes

Généré par le département *Musique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/music/fr/mus-017-audit-voice-leading-rankings.fr.md) · [Mon journal](../../journal/)

Prérequis: [MUS-015](../../music/mus-015-choose-voice-leading-equivalences/), [MUS-016](../../music/mus-016-recover-voice-correspondence/)
:::

## Question du projet et livrable

Un agent peut trier correctement des candidats selon un score qui ne respecte pas la relation musicale visée. Construisez un classement de deux candidats, comparez-le à une référence issue d’une énumération indépendante et rédigez une décision de portée limitée. Cet exercice concerne la [classe de distance de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Common/GA.Domain.Services/Atonal/VoiceLeadingSpace.cs) figée. Il n’exécute ni l’index de plus proches voisins ni l’interface utilisateur de GA.

La distinction avec [MUS-022](../../music/mus-022-grothendieck-deltas-icv-distance/) compte : comparer des vecteurs de contenu intervallique répond à une autre question que l’appariement des hauteurs entre les voix. Ici, l’objectif déclaré autorise les changements d’octave et les permutations de la cible, tout en préservant le contenu en classes de hauteurs pour un appariement de coût nul. Les équivalences de transposition et d’inversion restent désactivées.

## 1. Prévoir le classement avant de trier

Utilisez la requête `[60,63,65]` et deux cibles :

| Candidat | Hauteurs avec leur registre | Contenu en classes de hauteurs |
|---|---|---|
| Same | 60, 65, 75 | 0, 5, 3 |
| Near | 60, 63, 66 | 0, 3, 6 |

Same contient exactement le multiensemble de classes de hauteurs de la requête ; une affectation exhaustive peut donc coûter 0. Near modifie la dernière classe d’un demi-ton ; sa meilleure affectation coûte 1. Ces prévisions découlent de l’objectif déclaré, indépendamment de la recherche cyclique du code source.

### Exercice pratique 1

Écrivez une affectation cible de coût nul pour Same et une affectation de coût 1 pour Near.

> **Réponse :** Same : appariez `[60,63,65]` à `[60,75,65]`, pour des coûts circulaires de 0, 0 et 0. Near : appariez `[60,63,65]` à `[60,63,66]`, pour des coûts de 0, 0 et 1. Ces affectations donnent des bornes supérieures ; l’énumération exhaustive du laboratoire conservé confirme les minima de ces cas.

## 2. Comparer deux chemins de calcul réels

Le [laboratoire autonome](https://github.com/spareilleux/learn/tree/codex/streeling-craft-transfer-20261022/code/streeling/voice-leading) compile le code source inchangé de GA avec un adaptateur d’annotations servant uniquement à la compilation. Il énumère aussi indépendamment toutes les permutations indexées de ces petits tableaux. Les [résultats conservés](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/native-results.json) donnent :

| Candidat | Coût natif | Coût exhaustif |
|---|---:|---:|
| Same | 4 | 0 |
| Near | 1 | 1 |

Trier chaque colonne par ordre croissant inverse l’ordre des deux candidats. Le calcul natif classe Near avant Same ; la référence classe Same avant Near. Il s’agit d’un classement local construit. Un consommateur qui normalise ses entrées différemment pourrait ne pas rencontrer ce cas. Ce tableau seul ne permet d’inférer aucun comportement du pipeline de recherche amont.

### Exercice pratique 2

Remplacer l’algorithme de tri corrigerait-il ce désaccord ?

> **Réponse :** Non. Les deux colonnes sont triées correctement selon leurs valeurs. Le désaccord vient du coût calculé pour Same selon le contrat d’équivalence visé. Examinez la représentation et la recherche d’affectations avant de modifier le tri du classement.

## 3. Tester un changement de représentation sans le qualifier de correction

Réduire cette requête et Same modulo 12 donne `[0,3,5]` et `[0,5,3]`. La classe native inchangée renvoie alors 0. Cette transformation supprime l’obstacle particulier lié à l’ordre des hauteurs avec leur registre dans cet exemple. Elle n’a ni corrigé la méthode de production ni démontré un théorème pour toutes les entrées.

Elle supprime aussi les octaves du registre. Si un consommateur a besoin du registre d’une mélodie, conservez séparément les hauteurs d’origine. S’il a besoin d’une correspondance réelle, conservez un témoin comme dans [MUS-016](../../music/mus-016-recover-voice-correspondence/). Un scalaire normalisé ne peut pas reconstruire les informations supprimées.

### Exercice pratique 3

Peut-on utiliser le zéro normalisé pour conclure que le mouvement de la deuxième voix identifiée, avec le registre pris en compte, vaut 0 ?

> **Réponse :** Non. Dans le témoin déclaré, cette voix passe de 63 à 75, soit un mouvement de 12 demi-tons. Le zéro appartient à la comparaison avec équivalence d’octave. Conservez les hauteurs d’origine avec leur registre si ce mouvement compte pour la tâche.

## 4. Exiger une référence indépendante pour détecter les erreurs

Le laboratoire fixe ses résultats attendus avant l’implémentation. Le cas de test amont conservé à sept voix coûte 8 dans les deux chemins ; la référence exhaustive parcourt 5,040 permutations indexées. Reproduire ce seul cas de test ferait manquer le contre-exemple plus petit qui tient compte du registre. Un exemple réussi ne peut pas établir l’affirmation générale d’équivalence.

Le contrôle négatif du laboratoire a délibérément remplacé l’oracle par le résultat natif dans une copie temporaire. Il a été rejeté par `oracle_zero_known_case` : résultat attendu 0, résultat obtenu 4. Cela confirme que le contrôle conservé peut détecter cette perte précise d’indépendance. Cela ne mesure ni une couverture générale des mutations ni la réussite des apprenants. Le [compte rendu du contrôle](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/negative-controls.json) en conserve les limites.

Relancez l’exécution avec [Node.js](https://nodejs.org/api/cli.html) et [.NET](https://learn.microsoft.com/dotnet/core/tools/dotnet-build) déjà installés, à l’aide de la commande de MUS-015. Examinez à la fois le verdict de caractérisation et le verdict distinct sur l’équivalence d’origine. Windows est la seule plateforme évaluée.

### Exercice pratique 4

Pourquoi utiliser le minimum cyclique natif comme « réponse exhaustive attendue » affaiblirait-il l’exercice ?

> **Réponse :** Les deux chemins hériteraient de la même restriction de recherche. Leur accord pourrait alors masquer la permutation manquante de coût nul. Le calcul manuel indépendant et l’énumération exhaustive fournissent des preuves que le résultat du code source ne peut pas apporter sur lui-même.

## 5. Transformer l’expérience en décision d’agent

Rédigez une passation avec la révision source, les tableaux des candidats, le contrat d’équivalence, les deux coûts, les deux ordres et l’observation limitée sur la normalisation. Pour cette comparaison, n’acceptez pas le score natif comme respectant l’équivalence visée. Une correction en production exige sa propre implémentation et des preuves de non-régression ; le laboratoire n’a pas fourni cette correction. Le [dossier de l’apprenant](https://github.com/spareilleux/learn/blob/codex/streeling-craft-transfer-20261022/code/streeling/evidence/voice-leading-2026-10-22/learner-task.md) distingue la vérification factuelle à l’aide des sources, la revue humaine et un éventuel essai instrumental.

### Exercice pratique 5

Un agent propose de normaliser automatiquement les entrées de tous les consommateurs. Que doit-il établir au préalable ?

> **Réponse :** Identifiez le contrat de comparaison de chaque consommateur et déterminez si la hauteur avec son registre, l’identité de la voix ou l’affectation aux cordes doivent être conservées. Vérifiez ensuite le comportement proposé par rapport à ces contrats à l’aide de cas indépendants. Cet exemple étaye un contre-exemple précis et une entrée transformée précise ; il n’autorise pas une politique universelle de normalisation.
