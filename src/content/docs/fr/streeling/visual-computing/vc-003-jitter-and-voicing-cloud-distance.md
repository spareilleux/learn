---
title: Quand le jitter aide-t-il un nuage de voicings ?
description: Quand le jitter aide-t-il un nuage de voicings ? — Informatique visuelle
sidebar:
  label: VC-003 · Quand le jitter aide-t-il un nuage de voicings ?
  order: 3
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/visual-computing/fr/vc-003-jitter-and-voicing-cloud-distance.fr.md
---

:::note[Streeling University]
**VC-003** · Quand le jitter aide-t-il un nuage de voicings ? · intermédiaire · 35 minutes

Généré par le département *Informatique visuelle* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/visual-computing/fr/vc-003-jitter-and-voicing-cloud-distance.fr.md) · [Mon journal](../../journal/)

Prérequis: [VC-002](../../visual-computing/vc-002-godot-react-bridge-evidence/) *(en anglais)*
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques de traductions encore à rédiger, d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) décrit les brouillons de traduction actuels, l’importation et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'informatique visuelle** | Niveau : intermédiaire | Durée estimée : 35 minutes | Statut : brouillon français ; révisions disciplinaire, pédagogique, linguistique et de publication en attente, dont l'approbation d'une personne maîtrisant le français

## Objectifs

Après cette leçon, vous saurez suivre une position 3D de voicing dans le moteur de rendu GA, calculer ce que change sa commande de dispersion, distinguer la visibilité des superpositions des preuves de distance et définir des vérifications absentes du code actuel. Vous saurez aussi quelles observations seraient nécessaires avant de recommander un réglage visuel à de vrais musiciens.

## La question du projet

Le Prime Radiant de GA peut placer des voicings dans un nuage de points Three.js. Quand de nombreuses marques se superposent, une commande de dispersion peut les rendre individuellement visibles. Un guitariste voit alors deux marques éloignées et demande si leurs voicings sont musicalement éloignés. Que devrait dire l'interface et quelles coordonnées un analyste devrait-il comparer ?

À la révision GA figée [`dc2e74c`](https://github.com/GuitarAlchemist/ga/tree/dc2e74cbd992a298f67efb928b5b3754615e1924), [`VoicingCloud.ts`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/VoicingCloud.ts) récupère un fichier annexe de métadonnées et un tampon binaire de positions, construit un objet Three.js `Points`, colore les points par instrument et expose `setSpread` et `setPointSize`. L'[appelant Prime Radiant](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/ReactComponents/ga-react-components/src/components/PrimeRadiant/ForceRadiant.tsx) tente de le charger lorsque l'URL possède un paramètre `voicings` ; `voicings_url` peut remplacer l'URL de service par défaut. Cette source indique ce que le code tenterait, pas qu'un serveur IX a répondu, qu'un binaire était valide ou qu'un utilisateur a vu une image. Le nombre approximatif d'éléments du corpus et le pourcentage d'amas denses du commentaire ne sont pas mesurés indépendamment dans cette leçon.

## 1. Identifier les grandeurs visuelles

Le chargeur attend `meta.total` points 3D et exactement `meta.total * 3` nombres flottants dans le tampon binaire. Chaque bloc d'instrument fournit un nom, un décalage dans le tampon de base et un nombre de points. Le moteur copie chaque bloc dans un tableau de destination séquentiel, puis choisit une couleur dans sa table guitare, basse ou ukulélé. Les noms inconnus reçoivent du blanc. La couleur est une étiquette de catégorie ; elle n'encode pas une distance musicale. Les métadonnées incluent aussi des bornes, mais cette source vérifie seulement que `bounds` est évalué comme vrai. Elle n'utilise pas ces bornes pour vérifier toutes les coordonnées ou régler automatiquement la caméra.

`PointsMaterial` commence avec une taille de `0.3`, des couleurs par sommet, une atténuation de taille, la transparence, une opacité de `0.85` et l'écriture de profondeur désactivée. Ce sont des choix de dessin. Une marque plus grande peut masquer davantage de voisines, et l'opacité peut modifier l'apparence d'une zone dense. Aucune de ces options ne change les positions de base. Les commentaires indiquent une dispersion par défaut de `1.5` et une taille de point de `0.3` ; les options de fonction le confirment. La vue rendue par défaut est donc déjà dispersée, sauf si l'appelant fournit `spread: 0` ou appelle ensuite `setSpread(0)`.

Pour tous les exercices, utilisez cette **fixture synthétique fixe**. C'est un modèle arithmétique du chemin de code, pas des données IX, une capture navigateur ou un échantillon de voicings mesuré. Supposez que la structure des métadonnées passe la vérification initiale, que toutes les récupérations réussissent et que `bounds` vaut `{ min: [0, 0, 0], max: [10, 0, 0] }`.

| Point de destination | Bloc d'instrument | Position de base issue du binaire |
|---|---|---|
| P0 | `guitar`, décalage 0, nombre 2 | `(0, 0, 0)` |
| P1 | même bloc guitare | `(0.2, 0, 0)` |
| P2 | `bass`, décalage 2, nombre 1 | `(10, 0, 0)` |

Ici, `meta.total = 3` ; le premier bloc couvre les points source 0 et 1, le second le point source 2. La décimale `0.2` est approximative après stockage en flottant 32 bits. Les coordonnées de cette fixture pédagogique sont des coordonnées projetées/d'affichage arbitraires ; elles ne sont ni des hauteurs, ni des frettes, ni le vecteur OPTIC-K complet.

### Exercice 1 : vérifier la longueur du binaire

Combien de flottants le binaire doit-il contenir pour cette fixture ? Que fait le chargeur figé s'il ne contient que huit flottants alors que `meta.total` reste égal à trois ?

> **Réponse :** Il faut `3 * 3 = 9` flottants. Huit échoue à `basePositions.length !== meta.total * 3`, donc `createVoicingCloud` rejette avec une erreur de taille avant de construire le groupe de points. Cette vérification porte sur le nombre total de flottants, pas sur la validité de chaque bloc d'instrument.

## 2. Lire la vue de référence sans dispersion

À `spread = 0`, `rebuildGeometry()` copie les coordonnées des blocs de base et omet sa boucle de nombres aléatoires. Pour la fixture, la distance en coordonnées d'affichage entre P0 et P1 est d'environ `0.2`, contre environ `9.8` entre P1 et P2. Les deux premières marques possèdent le RGB `(0.306, 0.631, 1.000)` de la guitare ; la troisième possède le RGB `(0.482, 0.847, 0.561)` de la basse. Un appel ultérieur à `setSpread(0)` reconstruit depuis les `basePositions` conservées, restaurant ces coordonnées plutôt que soustrayant un décalage aléatoire précédent.

Cette vue sans dispersion est la référence utile lorsque la question porte sur les positions fournies au moteur. Même alors, une distance dans ses trois coordonnées n'est qu'une distance dans cette représentation 3D. `VoicingCloud.ts` ne définit pas la projection source et ne montre pas qu'une distance euclidienne ici égale une similarité dans l'embedding OPTIC-K complet, une proximité perceptive, une jouabilité ou un coût de conduite des voix. Ces relations exigent une projection documentée et une validation distinctes. Le nuage peut communiquer fidèlement une position uniquement par rapport aux positions fournies ; il ne peut établir seul leur sens musical.

### Exercice 2 : lire la géométrie de référence

Avec une dispersion nulle, donnez les trois coordonnées x, les distances approximatives P0–P1 et P1–P2 et l'attribution des couleurs. Cela suffit-il pour classer les paires par similarité OPTIC-K de grande dimension ?

> **Réponse :** Les coordonnées x valent `0`, environ `0.2` et `10` ; y et z sont nulles. Les écarts affichés valent environ `0.2` et `9.8`. P0 et P1 utilisent le RGB guitare `(0.306, 0.631, 1.000)` ; P2 utilise le RGB basse `(0.482, 0.847, 0.561)`. Ces faits classent uniquement les distances dans les coordonnées 3D de la fixture. Ils n'établissent pas le classement des similarités OPTIC-K complètes.

## 3. Calculer l'effet de dispersion

Pour chaque coordonnée de chaque bloc, le code ajoute `(Math.random() + Math.random() - 1) * spread` lorsque `spread > 0`. Deux appels indépendants à `Math.random()` produisent un décalage de distribution triangulaire centré près de zéro, approximativement entre `-spread` et `+spread` par axe. Le code échantillonne séparément x, y et z. C'est une transformation d'affichage ; elle ne modifie pas `basePositions`. Elle peut révéler des marques distinctes dans un amas, mais aussi créer ou inverser les écarts apparents entre certains points. La source ne fournit pas de flux aléatoire avec graine ; répéter un appel positif à `setSpread` produit une nouvelle disposition échantillonnée, pas une disposition reproductible.

Prenez des **tirages hypothétiques**, pas des valeurs navigateur enregistrées : avec `spread = 1.5`, supposons les tirages x de P0 égaux à `0.1` et `0.1`, ceux de P1 à `0.9` et `0.9`. Supposons tous les tirages y et z des deux points égaux à `0.5` et `0.5`, donnant des décalages nuls sur ces axes. P0 reçoit `(0.1 + 0.1 - 1) * 1.5 = -1.2`, donc son x affiché vaut `-1.2`. P1 reçoit `(0.9 + 0.9 - 1) * 1.5 = 1.2`, donc son x affiché vaut environ `1.4`. Leur écart apparent vaut environ `2.6`, treize fois l'écart de base `0.2`. Aucun voicing n'a changé. Les tirages sont choisis pour exposer le calcul, pas pour estimer un résultat typique ou affirmer qu'un rendu actif a produit ces points.

Un analyste comparant ces deux positions projetées devrait utiliser les coordonnées de base sans dispersion ou disposer d'un mode sans dispersion facilement accessible. Une personne voulant compter ou sélectionner des marques superposées peut bénéficier de la dispersion. Un libellé proposé pourrait dire : « La dispersion sépare les marques superposées pour les examiner ; les écarts visibles sont perturbés aléatoirement. » Si un affichage donne une distance entre deux points, il devrait préciser si elle provient des positions 3D fournies ou d'une autre métrique définie, sans la calculer silencieusement sur les positions d'écran perturbées. C'est une recommandation de conception, pas une fonctionnalité vérifiée de l'interface figée.

### Exercice 3 : calculer un écart trompeur

Avec les tirages hypothétiques indiqués, calculez les positions x affichées de P0 et P1 et leur écart à une dispersion de `1.5`. Peut-on citer cet écart comme une dissimilarité musicale mesurée ?

> **Réponse :** P0 passe de `0` à `-1.2`. P1 passe d'environ `0.2` à environ `1.4`. Leur écart affiché vaut environ `2.6`, contre environ `0.2` avant perturbation. C'est une illustration de tirages aléatoires inventés, pas un rendu mesuré ni une preuve de dissimilarité musicale.

## 4. Distinguer les commandes de coordonnées et de glyphes

La méthode `setSpread(amount)` de l'objet de contrôle actualise la dispersion et appelle `rebuildGeometry()`. Cette fonction alloue de nouveaux tableaux de positions et couleurs, recopie le tampon de base initial et remplace la géométrie précédente. `setSpread(0)` donne donc une référence stable pour une fixture bien formée. Rappeler `setSpread(1.5)` rééchantillonne toutefois les décalages ; les marques ne restent pas aux mêmes endroits perturbés. Sélectionner un point dans une disposition dispersée et attendre que sa position d'écran persiste après un nouvel appel positif est risqué sans stratégie de sélection fondée sur son identité.

À l'inverse, `setPointSize(size)` attribue la taille du matériau sans reconstruire les coordonnées. Un glyphe plus grand change la superposition visuelle, mais son centre reste placé par la géométrie actuelle. La source n'implémente ni couche de mesure, ni dispersion avec graine, ni animation avant/après, ni légende de distance. Ce seraient des conceptions ultérieures possibles, chacune nécessitant une vérification comportementale distincte. L'appelant figé utilise `createVoicingCloud(fg.scene(), { serveUrl })` ; ce chemin utilise donc la dispersion et la taille par défaut, sauf modification ultérieure par un autre code. Lire la source ne montre pas ce qui s'est passé à l'écran d'un utilisateur.

### Exercice 4 : prédire deux commandes

Après le jitter hypothétique de l'exercice 3, que deviennent les coordonnées de la fixture si l'on appelle `setSpread(0)` ? Que deviennent-elles si l'on appelle ensuite `setPointSize(0.6)` ? Un nouvel appel à `setSpread(1.5)` conserverait-il les tirages précédents ?

> **Réponse :** `setSpread(0)` reconstruit depuis le tampon de base et donne x `0`, environ `0.2` et `10`. `setPointSize(0.6)` ne change que `PointsMaterial.size`, donc ces centres restent en place. Une reconstruction ultérieure avec dispersion positive tire de nouvelles valeurs aléatoires ; la source n'a ni graine ni décalages par point stockés qui préserveraient la disposition antérieure.

## 5. Rendre le contrat de données révisable

Le chargeur actuel vérifie que `total` est un nombre, `instruments` un tableau, `bounds` une valeur évaluée comme vraie et que le binaire possède `total * 3` flottants. Il ne vérifie pas que `total` est un entier positif ou nul ; que décalages et nombres sont des entiers positifs ou nuls dans les limites du tampon ; que les blocs couvrent chaque point exactement une fois ; que les noms sont attendus ; que les coordonnées sont finies ; ni que les bornes correspondent aux positions. Le tableau de destination commence à zéro, puis se remplit à la copie des blocs. Des points de destination manquants peuvent donc rester à zéro. Un bloc ou binaire mal formé peut déclencher une exception dans les opérations de tableaux typés ou placer des valeurs erronées ; un contrôle global de taille n'est pas un validateur complet.

Pour un contrat de production, un validateur proposé devrait vérifier les règles structurelles et numériques avant le dessin. Il devrait rejeter une couverture source incomplète, chevauchante ou hors limites ; exiger un nombre de destinations copiées égal à `total` ; vérifier des coordonnées finies et des bornes cohérentes ; et définir le traitement des noms d'instrument inconnus. Le projet devrait ensuite tester de vraies données IX contre ce contrat et capturer un vrai rendu navigateur avant d'affirmer couverture ou performance. Pour la décision visuelle, comparez des tâches documentées — compter des marques denses, sélectionner un voicing précis et comparer les positions 3D fournies — avec dispersion nulle et plusieurs dispersions positives. Consignez la révision des données, la caméra, la taille, la dispersion, la précision de sélection et la méthode des participants. Aucune étude utilisateur ni mesure de performance d'exécution de ce type n'est revendiquée ici.

### Exercice 5 : trouver la validation manquante

Conservez `meta.total = 3` et un binaire de neuf flottants, mais modifiez les blocs en `guitar` au décalage 0 avec un nombre de 1 et `bass` au décalage 2 avec un nombre de 1. Avec les vérifications superficielles de la source, combien de points de destination sont remplis ? Que peut devenir le point restant et quelle règle détecterait le problème ?

> **Réponse :** Le contrôle global de structure des métadonnées et celui de longueur de neuf flottants peuvent réussir. La boucle copie deux points dans les cases 0 et 1 ; la case 2 reste remplie de zéros, couleur comprise, car la somme des deux nombres vaut 2 au lieu de `total = 3`. Un validateur exigeant des plages de blocs valides et une couverture complète sans chevauchement avec un total copié de 3 rejetterait cette fixture. C'est un raisonnement fondé sur la source, pas un test exécuté du moteur de rendu.

## Points à retenir et limites

- La dispersion révèle les marques superposées mais modifie leurs séparations affichées. Utilisez une référence sans dispersion pour comparer les coordonnées 3D fournies.
- La taille affecte les glyphes ; la dispersion reconstruit les positions avec de nouveaux décalages aléatoires. La couleur identifie la catégorie d'instrument dans cette implémentation.
- Une distance 3D n'est pas automatiquement une distance OPTIC-K complète, audible ou de jouabilité. Projection et métrique de comparaison exigent des preuves distinctes.
- Les cinq exercices utilisent une petite fixture synthétique et des tirages explicitement choisis. Ils ne mesurent ni corpus réel, ni densité visuelle, ni performance, ni compréhension utilisateur, ni service IX actif.
- Cette leçon identifie les contrôles source et propose une validation renforcée et une observation par tâches. Elle n'affirme pas que ces contrôles ou observations ont été implémentés.

Parmi les leçons voisines, [VC-001](../../visual-computing/vc-001-accessible-fretboard-paths/) traite des chemins d'interaction accessibles et [VC-002](../../visual-computing/vc-002-godot-react-bridge-evidence/) *(en anglais)* examine une autre frontière 3D : l'hôte React et le pont Godot proposé. Aucune ne prouve que ce nuage de voicings a réussi un essai d'utilisabilité. L'inspection s'est limitée aux fichiers GA figés liés ci-dessus ; elle n'a exécuté ni Three.js, ni IX, ni navigateur. Révision humaine disciplinaire, essais d'apprenants et publication restent en attente ; ce brouillon français attend une révision par une personne maîtrisant le français.

*Recherche : `visual-computing-2026-10-11-003`. Brouillon français ; révision linguistique et publication en attente.*
