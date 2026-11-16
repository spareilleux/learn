---
title: Quand la vélocité déplace la position de pincement dans le moteur de guitare GA
description: Quand la vélocité déplace la position de pincement dans le moteur de guitare GA — Physique
sidebar:
  label: PHY-004 · Quand la vélocité déplace la position de pincement dans le moteur de guitare GA
  order: 4
editUrl: https://github.com/spareilleux/learn/edit/main/streeling/courses/physics/fr/phy-004-velocity-pick-position-guitar-engine.fr.md
---

:::note[Streeling University]
**PHY-004** · Quand la vélocité déplace la position de pincement dans le moteur de guitare GA · intermédiaire · 40 minutes

Généré par le département *Physique* de Demerzel — pas encore relu par moi. [Voir la source](https://github.com/spareilleux/learn/blob/main/streeling/courses/physics/fr/phy-004-velocity-pick-position-guitar-engine.fr.md) · [Mon journal](../../journal/)

Prérequis: [PHY-001](../../physics/phy-001-science-of-guitar-sound/), [PHY-003](../../physics/phy-003-sampling-aliasing-guitar-engine/)
:::

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques de traductions encore à rédiger, d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](https://github.com/spareilleux/learn/blob/main/code/streeling/evidence/representation-release-2026-10-22/README.md) décrit les brouillons de traduction actuels, l’importation et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de physique** | Intermédiaire | 40 minutes | Brouillon source français ; révision et publication en attente, dont l'approbation d'une personne maîtrisant le français

## Objectifs

Vous distinguerez une position physique de pincement de l'heuristique d'excitation du moteur GA, calculerez comment une vélocité d'entrée change davantage que le gain de sortie et concevrez une comparaison isolant la cause d'un changement de timbre. C'est utile pour régler le moteur de guitare WASM : un musicien peut demander une note plus forte en s'attendant au même geste de médiator, alors que le chemin de contrôle actuel modifie plusieurs paramètres à la fois. [PHY-001](../../physics/phy-001-science-of-guitar-sound/) décrit les ondes stationnaires ; [PHY-003](../../physics/phy-003-sampling-aliasing-guitar-engine/) explique pourquoi il faut consigner la fréquence d'échantillonnage du moteur. Aucune ne résout cette question de couplage des commandes.

La limite des preuves compte. La [fixture exécutable PHY-004](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/physics/phy-004/README.md) reproduit **certains calculs du code source figé**. Elle ne synthétise pas d'audio, ne mesure pas de spectre et n'établit pas ce qu'entend un auditeur. La leçon vise à expliciter les explications concurrentes et une expérience décisive avant de modifier le moteur.

## 1. Ce que prédit une position physique de pincement

Pour une corde flexible idéale fixée aux deux extrémités, écrivez une position `p = x/L`, où `L` est la longueur de corde et `0 < p < 1`. Un modèle simple tire la corde en un déplacement triangulaire dont le sommet est à `pL`, puis la relâche. Décomposer cette forme initiale en modes d'ondes stationnaires donne un coefficient de déplacement modal proportionnel à `sin(nπp) / [n² p(1-p)]` pour l'indice harmonique `n`, à hauteur de sommet constante. Cela découle de l'intégration des deux segments droits du triangle contre les modes sinusoïdaux de la corde. C'est un **modèle idéal de déplacement initial**, pas un modèle complet d'enregistrement de guitare.

Le terme sinusoïdal prédit des zéros dépendant de la position : à `p = 1/2`, tout `n` pair vérifie `sin(nπ/2) = 0` ; à `p = 1/4`, chaque quatrième harmonique vérifie `sin(nπ/4) = 0`. Un vrai médiator possède une largeur, une évolution temporelle de force et une durée de contact. Rigidité de la corde, conditions aux extrémités, position du capteur, couplage avec la caisse, amortissement et placement du microphone peuvent tous modifier un spectre observé. Un zéro modal théorique constitue donc une bonne prédiction expérimentale sous hypothèses déclarées, pas la promesse d'une annulation exacte dans un WAV.

Le sens de la **vélocité** dépend de l'interface. Ici, la vélocité MIDI est une valeur de commande dans `[0,1]`, pas une mesure de la vitesse physique du médiator ou du déplacement initial de la corde. Nous ne pouvons en déduire la position réelle de pincement sans correspondance calibrée. Un instrument logiciel peut utiliser une seule entrée pour commander plusieurs paramètres cachés, mais ce choix doit être visible lors de l'évaluation des causes et effets.

### Exercice pratique 1

Dans le modèle idéal de déplacement triangulaire, quels indices harmoniques ont un coefficient initial nul à `p = 1/4` ? L'absence de quatrième harmonique dans une note de guitare capturée prouverait-elle que le musicien a pincé au quart de la corde ?

> **Réponse :** Le facteur sinusoïdal est nul lorsque `n` est un multiple positif de quatre : `n = 4, 8, 12, ...`. Une quatrième harmonique absente ou faible ne prouve pas à elle seule un pincement au quart de la corde. Position du capteur ou du microphone, largeur d'excitation, réponse de la corde et de la caisse, traitement, bruit et fenêtre d'analyse choisie sont des explications possibles. La formule décrit un déplacement initial idéal sous hypothèses fixes.

## 2. Suivre le véritable chemin de contrôle GA

Au [commit GA figé `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs), `engine_note_on(engine, freq, velocity)` appelle `Engine::excite`. La fonction borne `velocity` dans `[0,1]` et fixe la longueur active du tampon Karplus–Strong à `max(2, floor(sample_rate / max(freq,20)))`. La partie fractionnaire est stockée séparément. Pour un **exemple arithmétique contrôlé**, utilisez `44,100 Hz` et un mi E2 de `82.4069 Hz`, donnant `floor(44,100 / 82.4069) = 535` échantillons actifs et un reste fractionnaire d'environ `0.14936`. Comme dans PHY-003, cette fréquence d'échantillonnage appartient à l'exemple choisi ; ce n'est pas une fréquence universelle des navigateurs.

La source calcule ensuite `pick_ratio = clamp(0.18 + 0.60(1 - velocity), 0.1, 0.85)`. Elle arrondit `535 × pick_ratio` à l'entier positif le plus proche et borne le décalage dans le tampon actif. Augmenter la vélocité de `0.25` à `0.50`, puis `0.75`, fait passer les décalages choisis de **337** à **257**, puis **177** échantillons, soit des positions normalisées d'environ **0.630**, **0.480** et **0.331**. C'est un **indice dans le tampon du moteur**, pas une position mesurée en centimètres sur une vraie corde. Le commentaire parle d'une heuristique de position de pincement ; l'implémentation prouve ce qu'elle fait.

La même vélocité multiplie aussi l'excitation de bruit filtré, définit `pluck_mix = clamp(0.15 + 0.35 velocity, 0.05, 0.7)` et contribue au niveau d'attaque. Pendant le rendu, `pluck_mix` entre dans une expression de brillance ; le signal passe ensuite par la rétroaction, l'amortissement, les résonateurs de caisse et la réverbération. Comparer deux notes exportées à des vélocités différentes ne permet donc d'attribuer une différence spectrale ni au seul gain ni à la seule position de pincement. La commande est **couplée** dans l'implémentation figée.

### Exercice pratique 2

À la fréquence d'échantillonnage et au mi E2 de la fixture, calculez le rapport de pincement et le décalage en échantillons pour une vélocité de `0.50`. Qu'est-ce qui reste fixe lorsque seule la vélocité varie entre les trois cas ?

> **Réponse :** `0.18 + 0.60(1 - 0.50) = 0.48` ; `round(535 × 0.48) = round(256.8) = 257`. La fréquence d'échantillonnage et la fréquence de note d'entrée sont fixes ; la longueur entière de 535 échantillons et son reste fractionnaire d'environ `0.14936` restent donc fixes. La vélocité change le rapport, le décalage, le multiplicateur d'excitation, `pluck_mix` et le niveau d'attaque. Le décalage calculé n'est pas une mesure microphonique.

## 3. Reproduire les calculs et respecter leur limite

Exécutez `python state/streeling/fixtures/physics/phy-004/evaluate_pick.py` depuis la racine Demerzel. Le script sans dépendances lit trois cas déclarés et vérifie par assertions la longueur de tampon, les décalages et les valeurs `pluck_mix` de la formule figée. Il vérifie que les décalages diminuent et que `pluck_mix` augmente avec la vélocité. Il évalue aussi la forme avant bruit au décalage choisi. La forme du modèle est `clamp(1 - 2.5 |i/N - offset/N|, 0, 1)` pour l'indice actif `i` ; son pic y vaut donc un par construction. L'excitation Rust complète multiplie cette forme par du bruit pseudo-aléatoire filtré passe-bas et par la vélocité ; la fixture omet volontairement ce chemin avec état.

Cette vérification rejette le **raccourci précis** « la vélocité n'est qu'un gain scalaire dans ce chemin source ». Elle ne rejette **pas** la possibilité que, pour une note rendue et une bande de mesure données, le gain domine un éventuel changement de timbre. L'inspection des formules et une trace des paramètres établissent le couplage ; une comparaison audio est nécessaire pour établir son ampleur perceptive. Les valeurs attendues JSON fixes rendent l'exemple reproductible et révèlent une dérive accidentelle de formule. Si la source GA change, la comparaison figée reste une affirmation historique et exige une nouvelle révision du code.

Une erreur de diagnostic facile consiste à convertir directement le décalage normalisé en coordonnée réelle de pincement, puis à appliquer aux sorties GA les zéros de corde triangulaire idéale de la section 1. Le moteur utilise un bruit filtré et une forme large bornée, pas le déplacement initial triangulaire idéal. Son tampon est actualisé par une boucle de rétroaction avec interpolation, dispersion, amortissement passe-bas et résonateurs. Tout creux modal prédit par la formule idéale constitue donc une **hypothèse à tester** pour GA, pas un résultat de cette fixture.

### Exercice pratique 3

La fixture rapporte les décalages `337`, `257` et `177` aux vélocités croissantes, tandis que son pic de forme vaut `1` dans les trois cas. Un collègue conclut : « Les trois WAV rendus doivent avoir une brillance identique après égalisation du niveau. » Donnez deux raisons pour lesquelles cette conclusion ne découle pas des données.

> **Réponse :** D'abord, la forme se déplace dans le tampon ; des pics égaux ne rendent pas les formes complètes identiques. Ensuite, la vélocité change aussi `pluck_mix`, qui entre dans l'expression de brillance du rendu, ainsi que l'amplitude du bruit filtré et l'attaque. Bruit avec état, filtrage, rétroaction, résonateurs et réverbération sont absents de la fixture. Il faudrait un rendu à niveau égalisé et un spectre localisé dans le temps ou un essai d'écoute pour comparer la brillance réelle.

## 4. Concevoir une comparaison qui isole la question

Supposons qu'un utilisateur indique qu'un mi E2 plus fort semble plus brillant dans la démo WASM. Commencez par l'affirmation restreinte étayée : le code Rust figé associe la vélocité **au moins** à l'échelle d'excitation, au décalage de pincement, au mélange de pincement et à l'attaque. L'AudioWorklet du navigateur peut utiliser une fréquence de contexte différente de l'exemple. Consignez la fréquence réelle, le build ou commit du moteur, la note et la vélocité, le chemin d'enregistrement, la durée, le format de sortie et les empreintes. Comparez des fenêtres alignées sur le début de note et égalisez les niveaux avant de juger l'équilibre spectral ; un spectre du fichier entier peut masquer les différences d'attaque, comme l'explique PHY-002.

Une expérience locale décisive ajouterait une **branche instrumentée ou une injection de paramètres réservée aux tests** pour garder le décalage de pincement fixe en faisant varier la vélocité, puis garder séparément `pluck_mix` et les réglages d'attaque fixes, à fréquence d'échantillonnage identique et si possible avec une graine de bruit déterministe. Répétez les rendus et sauvegardez traces de paramètres et sorties. Comparez ces interventions au moteur inchangé. Si fixer le décalage laisse pratiquement inchangé le changement mesuré de brillance, l'hypothèse simple « le déplacement du pincement est la cause dominante » s'affaiblit. Si cela supprime l'essentiel de la différence à autres commandes constantes, elle gagne du soutien. Choisissez explicitement la métrique, la bande de fréquences, la fenêtre d'attaque et la tolérance avant d'examiner les résultats.

Une solution produit plus simple peut suffire : conserver le couplage actuel de vélocité et le décrire honnêtement plutôt qu'ajouter une commande indépendante de « position physique de pincement ». Une commande indépendante n'est utile que si un musicien ou un workflow audio ComfyUI en aval démontre une tâche pertinente qu'elle permet et si l'état supplémentaire reste composable avec les commandes existantes. L'expérience devrait guider ce choix. Aucun nouveau build du moteur, capture navigateur, couple de WAV, test perceptif ou changement d'interface n'a été exécuté pour PHY-004.

### Exercice pratique 4

Décrivez une comparaison contrôlée pour l'affirmation « le changement de décalage de pincement domine le changement de brillance ». Que faut-il maintenir constant, quelle intervention effectuer et quel résultat affaiblirait l'affirmation ?

> **Réponse :** Figez la révision moteur, la note, la fréquence d'échantillonnage, le profil, le chemin de sortie, la durée et de préférence la graine de bruit ; consignez la trace réelle des paramètres. Rendez deux vélocités avec la correspondance actuelle, puis avec le décalage maintenu à un indice déclaré tout en gardant inchangées les autres correspondances de vélocité. Égalisez les niveaux et comparez une fenêtre d'attaque et une métrique de brillance déclarées sur plusieurs essais. Si fixer le décalage change à peine la différence de brillance liée à la vélocité selon une tolérance prédéclarée, l'affirmation de dominance s'affaiblit. Cela n'identifie pas à soi seul le paramètre restant responsable.

### Exercice pratique 5

Un développeur propose d'exposer `pick_position = 0.25` comme nouveau paramètre d'API WASM, car le modèle idéal prédit une quatrième harmonique nulle. Quelles preuves manquent avant de traiter cette valeur comme une coordonnée physique calibrée et de promettre ce résultat acoustique ?

> **Réponse :** L'API actuelle accepte fréquence et vélocité ; le décalage interne est une heuristique. Il faudrait une correspondance définie de la valeur normalisée d'API vers la construction de l'excitation, des tests source montrant son indépendance de la vélocité ou documentant le couplage, des spectres rendus contrôlés et essais d'écoute sur plusieurs notes et fréquences d'échantillonnage, ainsi qu'un calibrage physique ou perceptif pour parler de vraie coordonnée de corde. L'excitation large actuelle de bruit filtré n'est pas un relâchement triangulaire idéal ; l'annulation de la quatrième harmonique ne peut donc être promise. Une nouvelle API publique engage la compatibilité durablement et devrait suivre les preuves de tâche et la révision.

## Sources et limites

- [Source figée du moteur de guitare GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs) : `Engine::excite` définit longueur de retard, bornes de vélocité, décalage et forme d'excitation ; `Engine::render` combine chemin de brillance et rétroaction ; `engine_note_on` est l'appel exposé. Les calculs de cette leçon s'appliquent à cette révision source.
- [Fixture exécutable PHY-004](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/physics/phy-004/README.md) : reproduction synthétique déterministe de certaines formules source. Elle n'exécute pas Rust, ne synthétise pas d'audio et ne teste pas d'auditeur.
- La formule du déplacement triangulaire idéal suit le modèle de série de sinus de corde à extrémités fixes énoncé en section 1. Elle reste volontairement distincte de l'excitation GA par bruit filtré. Aucune comparaison spectrale du moteur, calibration physique de position de pincement, révision humaine disciplinaire, essai d'apprenant ou consultation publique n'a été réalisée pour PHY-004. Le cycle source anglais antérieur laissait la traduction en attente ; ce brouillon français attend une révision par une personne maîtrisant le français.
