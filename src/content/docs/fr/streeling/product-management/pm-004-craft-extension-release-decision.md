---
title: Décider quand les extensions artisanales sont prêtes à être distribuées
description: Décider quand les extensions artisanales sont prêtes à être distribuées — Gestion de produit et de projet
sidebar:
  label: PM-004 · Décider quand les extensions artisanales sont prêtes à être distribuées
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/product-management/fr/pm-004-craft-extension-release-decision.fr.md
---

:::note[Streeling University]
**PM-004** · Décider quand les extensions artisanales sont prêtes à être distribuées · intermédiaire · 35 minutes

Généré par le département *Gestion de produit et de projet* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/product-management/fr/pm-004-craft-extension-release-decision.fr.md) · [Mon journal](../../journal/)

Prérequis: [PM-002](../../product-management/pm-002-release-evidence-gate/), [PM-003](../../product-management/pm-003-review-queue-flow-metrics/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques de traductions encore à rédiger, d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) décrit les brouillons de traduction actuels, l’importation et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de gestion de produit et de projet** | Niveau intermédiaire | 35 minutes | Brouillon français ; aucune distribution d'extension, révision humaine, expérimentation avec un apprenant ou publication publique du cours ; révision linguistique humaine en attente

## Objectifs et question du projet

Après cette leçon, vous saurez nommer la tâche produit servie par une extension artisanale, distinguer un composant source utile d'une extension installable, appliquer un contrôle de distribution dont les critères ne se compensent pas entre trois cibles et rédiger une décision de distribution qu'une seconde personne peut reproduire. **Question du projet :** quand l'équipe peut-elle annoncer honnêtement la distribution d'extensions ComfyUI, Blender et Godot issues de ses expériences d'audio de guitare et de passage de l'artisanat à la scène ? Dans ce projet, annoncer une distribution exige une version installable avec des artefacts et des notes nommés ; un tag seul ne suffit pas. Une feuille de route, un brouillon de cours, un script source, une expérience locale ou une fixture pédagogique réussie ne constitue pas une telle distribution.

[PM-002](../../product-management/pm-002-release-evidence-gate/) distingue les contrôles de révision, de compilation et de relecture publique d'un cours Streeling. [PM-003](../../product-management/pm-003-review-queue-flow-metrics/) mesure la progression dans cette file de révision de cours. Cette leçon prend une autre décision : savoir si une **extension logicielle** peut être proposée aux utilisateurs. Le cours lui-même conserve ses propres contrôles indépendants de révision et de publication.

## 1. Choisir une tâche utilisateur par extension

Une proposition d'extension doit nommer ce qu'un utilisateur peut installer et faire. Une cible **ComfyUI** possible est un workflow hors ligne d'audio de guitare qui prend un WAV de départ et produit un candidat accompagné de sa provenance. Une cible **Blender** possible est une aide au nettoyage de caractéristiques artisanales qui conserve une identité de caractéristique déclarée pendant le traitement du maillage. Une cible **Godot** possible est un importateur ou inspecteur de scène qui préserve l'identité et le sens dessus/dessous d'un croisement de tissage. Ce sont des *tâches produit candidates*, pas des affirmations selon lesquelles les trois extensions installables existent.

Le projet dispose déjà de preuves plus limitées. La [leçon CS-004 figée sur la boucle audio](https://github.com/GuitarAlchemist/Demerzel/blob/861b6b1891ef7017c22269d5ec6be4c50953040c/state/streeling/courses/computer-science/en/cs-004-composable-agentic-audio-loop.md) décrit un pont GA ComfyUI local et non fusionné au commit `6fac5735f7ffbb4116ebee05cfc9d7911bb12ce9` ; le workflow fourni charge et enregistre l'audio, mais ne démontre aucune amélioration. La [leçon VC-005 figée sur l'artisanat](https://github.com/GuitarAlchemist/Demerzel/blob/861b6b1891ef7017c22269d5ec6be4c50953040c/state/streeling/courses/visual-computing/en/vc-005-craft-details-through-blender-to-godot.md) cite le script Learn de nettoyage GLB dans Blender et le rapport d'exemple versionné au commit `93d424f872a576ba8bbcd3dd44c9733292373654`, mais ne rapporte aucun import Godot ni essai sur une caractéristique artisanale. La [leçon VC-007 figée sur le tissage](https://github.com/GuitarAlchemist/Demerzel/blob/861b6b1891ef7017c22269d5ec6be4c50953040c/state/streeling/courses/visual-computing/en/vc-007-weave-seams-as-scene-contracts.md) comporte un évaluateur Python synthétique : la parité globale donne zéro violation entre croisements adjacents et la parité locale redémarrée en donne douze. C'est un contre-exemple sémantique, pas une extension Godot. Le [plan Godot mis en attente de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/docs/plans/parked/2026-03-28-feat-godot-integration-plan.md) esquisse un parcours de scène ; ses éléments non cochés restent des plans.

### Exercice 1 : rédiger la promesse utilisateur

Un brouillon d'annonce dit : « Notre suite artisanale ComfyUI, Blender et Godot est prête parce que le pont audio, le script GLB et le validateur de tissage existent. » Corrigez cette déclaration en une phrase vraie au présent et une tâche proposée réfutable.

> **Réponse :** « Le projet dispose d'expériences dans les sources pour l'audio, le nettoyage de maillage et la validation de tissage, avec des provenances différentes et aucune distribution démontrée d'extensions pour les trois cibles. » Une tâche proposée réfutable serait : « Un utilisateur installe l'add-on Godot versionné, importe l'exemple de tissage fourni, clique sur `w3-f0` et obtient la valeur dessus/dessous déclarée de ce croisement dans une trace enregistrée. » Il faut un add-on installable et un reçu d'exécution avant de présenter cette dernière proposition comme un résultat atteint.

## 2. Exiger des preuves à chaque frontière de cible

Pour chaque cible, recueillez quatre types de preuves. L'**implémentation** est un paquet d'extension versionné et installable avec des instructions de configuration et de compatibilité. L'**exécution** est un nouveau test dans la version nommée de l'application, sur une entrée figée, avec commandes, journaux et empreintes des sorties. Le **sens** repose sur un oracle propre à la tâche : pour l'audio, un candidat apparié comparé à la même référence et une tâche d'écoute ; pour Blender, la survie d'une caractéristique artisanale identifiée après nettoyage ; pour Godot, un identifiant stable de croisement et une correspondance dessus/dessous dans la scène et la trace des clics. La **révision humaine** demande à un spécialiste d'examiner l'artefact réel et à un utilisateur non guidé d'accomplir la tâche. Un schéma ou un test unitaire réussi ne remplace pas ces observations.

L'ensemble exige aussi un **rejeu de contrat** entre les frontières : l'identité et l'empreinte de sortie d'un outil doivent être celles de l'entrée du suivant, sans substitution inexpliquée. Conservez les empreintes d'artefacts des trois paquets et de leurs entrées et sorties d'essai. Les versions exactes comptent, car un script examiné à un commit ne prouve pas qu'une extension fonctionne dans une version ultérieure de l'application. Consignez l'accessibilité, les licences, la compatibilité des plateformes et le comportement d'installation dans une véritable liste de contrôle de distribution ; la fixture pédagogique ci-dessous ne les évalue pas.

### Exercice 2 : classer les preuves figées

Lesquelles des quatre colonnes de preuve par cible peut-on marquer comme complètes pour une distribution de trois extensions à partir des seules sources figées ci-dessus ? Le rapport d'exemple Blender versionné de Learn prouve-t-il qu'une caractéristique artisanale a survécu dans une scène Godot ?

> **Réponse :** Aucune des quatre colonnes n'est complète pour une **distribution installable de trois extensions** à partir de ces sources citées. Elles étayent l'examen des sources et certaines vérifications plus limitées, synthétiques ou portant sur un exemple versionné. Le rapport Blender concerne un parcours de nettoyage d'exemple, pas une extension Blender installée avec un verdict sur une caractéristique artisanale ; il ne contient aucun import de scène Godot. Gardez la décision sur l'ensemble en attente et nommez les essais propres aux cibles qui manquent.

## 3. Utiliser des contrôles impératifs avant de classer les améliorations

La [fixture de fiches de distribution](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/product-management/pm-004/release-cards.json) est un **modèle pédagogique**, pas un audit des tags GitHub actuels. Exécutez `python state/streeling/fixtures/product-management/pm-004/evaluate_release.py` depuis la racine Demerzel. Elle vérifie que chaque fiche couvre exactement `comfyui`, `blender` et `godot`, puis énumère les champs de preuve faux. Sa fiche d'instantané des sources ne valide délibérément aucun contrôle d'extension installable : les sources plus limitées du projet citées ci-dessus n'établissent aucun de ces contrôles. Les trois autres fiches sont expressément synthétiques.

L'évaluateur classe un candidat Godot exécutable dont le sens est incorrect comme `reject_candidate`, même si les onze autres champs par cible, le rejeu de contrat et les empreintes passent. Les reçus manquants produisent `hold_for_evidence`. Lorsque tous les contrôles modélisés passent, il renvoie `release_candidate`, ce qui signifie que le paquet *modélisé* pourrait entrer dans une décision finale de distribution. L'évaluateur ne crée jamais de tag, ne vérifie pas de release GitHub et n'établit pas que les reçus de réviseurs existent réellement. Son champ `published` est distinct de la candidature. Évitez de transformer ses valeurs booléennes fictives en véritables scores de qualité.

### Exercice 3 : contester un score pondéré

Dans la fiche synthétique `pretty-but-wrong`, tous les champs sauf `godot.meaning` sont vrais. Un collègue propose de distribuer parce que le taux de réussite est élevé. Que dit l'évaluateur, et pourquoi cet échec doit-il être impossible à compenser ?

> **Réponse :** Il renvoie `reject_candidate` et désigne `godot.meaning` comme manquant. La promesse produit comprend une identité de croisement correcte et un sens dessus/dessous correct dans la scène Godot. Une documentation ComfyUI ou Blender plus complète ne peut pas corriger un croisement Godot erroné. Le score fictif ne représente pas un résultat mesuré de l'équipe.

### Exercice 4 : distinguer la révision de l'achèvement technique

La fiche synthétique `technical-only` marque l'implémentation, l'exécution, le sens, le rejeu de contrat et les empreintes comme vrais pour toutes les cibles, mais les trois champs de révision humaine sont faux. Donnez sa décision, les prochaines preuves à demander et indiquez si une release GitHub existe.

> **Réponse :** La décision est `hold_for_evidence`. Demandez l'identité des réviseurs, les sources exactes et les empreintes d'artefacts, le verdict et les constats propres à chaque cible, ainsi que les résultats de tâches d'utilisateurs non guidés pour chaque extension. `published_tag` est faux ; ni la fiche ni le programme Python ne créent de release GitHub. Ses booléens techniques sont des données pédagogiques inventées, pas de véritables reçus de tests.

## 4. Découper la distribution à une frontière utile

Un ensemble peut devenir un goulot d'étranglement si une cible immature bloque deux cibles utilisables. Déterminez si les utilisateurs ont réellement besoin d'une installation atomique. Le workflow audio et le parcours d'artisanat 3D servent des tâches différentes ; des distributions indépendantes d'extensions peuvent donc coûter moins cher à valider. Une distribution d'intégration entre outils devrait venir ensuite si une tâche utilisateur traverse réellement ces outils et si le rejeu de contrat peut être démontré. Séparer les versions ne permet pas de cacher un contrôle sémantique échoué : chaque distribution cible doit encore passer ses propres contrôles de paquet, d'exécution, de sens et humains. Publiez une matrice explicite de compatibilité pour tout workflow combiné.

Fixez une règle d'arrêt avant l'implémentation. Pour un inspecteur proposé de tissage Godot, rejetez un import si un croisement cliqué correspond au mauvais identifiant stable ou à la mauvaise valeur dessus/dessous déclarée. Pour une aide proposée au nettoyage Blender, rejetez un candidat si la caractéristique artisanale identifiée disparaît, même lorsque le nombre de triangles baisse. Pour un workflow audio, un candidat identique octet pour octet est un témoin sans changement ; une modification spectrale nécessite des fenêtres appariées et une écoute, pas une affirmation automatique « le son est meilleur ». Ces règles lient la distribution à la valeur utilisateur au lieu de faire de la compilation elle-même la mesure de réussite.

### Exercice 5 : décider de la distribution

La fiche synthétique `candidate-after-reviews` passe tous les contrôles modélisés, mais contient `published_tag: false`. Un responsable demande : « Les extensions sont-elles distribuées ? » Donnez le bon statut et deux vérifications concrètes à effectuer ensuite. Expliquez ensuite ce que l'équipe devrait dire de l'instantané réel des sources figées.

> **Réponse :** La fiche synthétique est une **candidate à la distribution**, pas une distribution. Examinez indépendamment les paquets et reçus nommés, y compris les contrôles de compatibilité et de licence omis par cette fixture ; puis, en cas d'approbation, créez la véritable release taguée et téléchargez/installez les artefacts anonymement pour vérifier le parcours documenté. Pour le véritable instantané des sources figées, dites seulement que des expériences et plans pertinents existent et que la distribution des trois extensions est en attente. La fiche pédagogique n'apporte aucune véritable approbation ni preuve de distribution publique.

## Points à retenir et limites

- Nommez l'installation et la tâche de l'utilisateur avant de décider si trois outils ont besoin d'une seule distribution.
- Utilisez des contrôles impératifs propres à chaque cible pour l'installabilité, l'exécution, le sens et les preuves de tâches humaines. Un score global ne peut pas compenser un résultat promis incorrect.
- Une fixture réussie prouve que le **modèle de décision** se comporte comme écrit, pas qu'une extension, une révision humaine, une release taguée ou une page publique de cours existe.

Les liens de sources ci-dessus sont des exemples liés à des révisions. Cette leçon n'a exécuté ni ComfyUI, ni Blender, ni Godot ; elle n'a examiné aucun véritable paquet d'extension, mesuré la qualité audio, révisé un objet artisanal avec des utilisateurs ou publié de release GitHub. PM-004 lui-même attend la révision du contenu, l'essai par un apprenant et la révision linguistique, ainsi que l'intégration Learn et une relecture publique anonyme.
