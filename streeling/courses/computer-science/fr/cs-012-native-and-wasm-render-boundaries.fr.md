---
module_id: cs-012-native-and-wasm-render-boundaries
department: computer-science
course: "Délimiter la comparaison des rendus natifs et WASM"
level: intermediate
prerequisites: ["cs-010-compose-fail-fast-ga-computations"]
estimated_duration: "45 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Délimiter la comparaison des rendus natifs et WASM

> **Périmètre du brouillon.** Expérience sur le code source exécutée sous Windows x64. La revue technique humaine, la révision linguistique par une personne maîtrisant la langue, l'exécution par un apprenant et la vérification du HTML public du cours restent à effectuer. Il s'agit d'un support pédagogique ; aucune livraison ni publication de GA en production n'est revendiquée.

## La question du projet

Une personne qui développe GA souhaite pouvoir comparer un rendu de guitare hors ligne lorsqu'elle passe du code natif à [WebAssembly dans Node.js](https://nodejs.org/en/learn/getting-started/nodejs-with-webassembly). Que signifie « même résultat » : un code source, des échantillons flottants ou un fichier audio exporté identiques ? Ce cours distingue ces contrats afin qu'une comparaison de fichiers réussie ne valide pas implicitement une affirmation plus forte.

Lisez le [protocole du laboratoire](../../../../code/streeling/guitar-runtime/README.md), le [programme d'exécution](../../../../code/streeling/guitar-runtime/run.mjs), la [fiche de provenance](../../../../code/streeling/guitar-runtime/source.json) et les [résultats mesurés](../../../../code/streeling/evidence/guitar-runtime-2026-10-22/results.json). Le [moteur Rust de GA](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Rust/guitar-web-wasm-demo/rust-engine/src/lib.rs), inchangé, est fixé par une révision et une empreinte de fichier. Vous apprendrez à préciser le domaine testé, à distinguer égalité et approximation, puis à définir l'expérience nécessaire avant d'élargir une conclusion.

## Fixer l'expérience avant de l'interpréter

Les deux compilations utilisent ce code : un adaptateur natif et la [cible Rust](https://doc.rust-lang.org/rustc/platform-support/wasm32-unknown-unknown.html) `wasm32-unknown-unknown`. Les commandes pédagogiques utilisent `rustc -O` ; les paramètres de publication Cargo du projet d'origine utilisent `opt-level="z"` et LTO. L'identité du code source n'identifie donc pas un binaire publié en amont. Les arguments du compilateur, la cible et la chaîne d'outils doivent accompagner les empreintes du code dans la fiche d'exécution.

Chaque variante initialise un nouveau moteur avec le profil 0 à 44100 Hz, demande un mi grave E2 à 82.4069 Hz avec une vélocité de 0.1, puis produit 176400 échantillons. La référence conserve une décroissance de 0.9978. La candidate applique 0.9976 après l'initialisation et avant la note. Ce sont des traitements distincts : comparez natif et WASM dans chaque traitement avant de comparer les traitements. Une hypothèse erronée reste erronée même si elle est reproductible ; écrivez la relation attendue avant de consulter les résultats.

### Exercice pratique 1

Formulez la prédiction la plus limitée que justifie le code partagé. Une empreinte du code source suffit-elle à prédire l'égalité des flottants entre cibles ?

> **Réponse :** Elle permet de prévoir que l'expérience compile le même texte du moteur, selon la procédure consignée. Elle ne prouve ni une exécution identique des cibles ni l'égalité des sorties flottantes. Exigez une comparaison mesurée pour chaque traitement et conservez les fiches du compilateur et de l'environnement d'exécution. Même une égalité constatée ne concernerait que les entrées et les compilations testées.

## Exécuter une comparaison délimitée

Suivez d'abord les consignes de téléchargement et d'attribution de l'enregistrement de référence dans le laboratoire. Depuis la racine du dépôt Learn, remplacez les deux paramètres et choisissez un répertoire de sortie qui n'existe pas :

```text
node code/streeling/guitar-runtime/run.mjs <new-output-directory> <recorded-wav-path>
```

Le programme appelle les outils installés et consigne leurs arguments réels. L'environnement enregistré utilise Rust 1.94.0 et Node v24.12.0 sous Windows x64. L'exécution sous Linux/WSL et macOS reste à vérifier. Un échec peut laisser des fichiers ; examinez-les et choisissez un autre répertoire neuf pour recommencer. Lire la fiche d'une exécution réussie renseigne sur cette exécution, sans prouver que l'apprenant l'a reproduite.

### Exercice pratique 2

Un collègue nomme la sortie « version WASM de production » parce que son code correspond à celui de GA. Quelles preuves manquent pour employer cette description ?

> **Réponse :** La compilation pédagogique possède ses propres paramètres et empreintes d'artefacts. Il faut comparer la fiche d'une véritable compilation de publication, son binaire et sa provenance de déploiement avant d'affirmer cette identité. Le résultat présent doit être décrit comme une comparaison pédagogique native et Node WebAssembly du code GA fixé. Il ne contient aucun résultat de publication DLL, de DLSS ni de performance.

## Distinguer découpage et changement d'environnement

Le rendu natif principal utilise un seul bloc ; Node WASM emploie des blocs de 128 échantillons. Cette comparaison change à la fois l'environnement et le découpage. Pour isoler le découpage, de nouveaux essais produisent un préfixe de 4096 échantillons en un bloc puis en blocs de 128 échantillons dans chaque environnement. Aucun événement de note ou de paramètre ne survient entre les blocs. Toutes les comparaisons d'octets de ces essais réussissent, et chaque nouveau préfixe correspond à celui de son rendu principal.

Cela étaye l'égalité entre découpages pour ces préfixes et ces appels sans événement. Cela ne démontre pas l'invariance pour toute longueur ou tout événement. En particulier, déclencher une note entre les blocs modifie la séquence d'entrée. Un ordonnanceur de navigateur pourrait aussi transmettre les événements à des frontières différentes ; cet essai hors ligne ne contient aucune observation d'ordonnancement permettant de trancher.

### Exercice pratique 3

Définissez une expérience susceptible de réfuter l'extension de cette conclusion aux événements de paramètre, sans modifier le verdict actuel.

> **Réponse :** Définissez avant l'exécution un calendrier d'événements indexé par échantillon, puis rendez ce même calendrier avec différents découpages dans un environnement. Scindez un bloc lorsqu'un événement tombe à l'intérieur pour appliquer l'événement au même échantillon dans les deux parcours. Une séquence d'octets différente réfuterait l'affirmation élargie. Reporter simplement l'événement à la frontière suivante reviendrait à comparer des entrées différentes.

## Comparer la représentation promise

Les sorties brutes `f32` des rendus principaux natif et WASM diffèrent pour 2918 échantillons de la référence et 2926 de la candidate. La différence absolue maximale vaut 2.9802322387695312e-8 pour chaque variante. Les preuves n'en établissent pas la cause. Ne l'attribuez pas à une instruction, une optimisation du compilateur ou une fonction mathématique sans expérience qui isole cette cause.

Pourtant, les octets des WAV PCM16 sont identiques entre environnements pour chaque variante après quantification par `Math.round(sample * 32767)`. L'arrondi associe plusieurs flottants au même entier. Des octets exportés égaux peuvent donc coexister avec des flottants différents ; ils ne prouvent pas l'identité de l'état flottant interne, qui n'a pas été capturé non plus.

Une comparaison d'octets est simple et décisive lorsque le contrat promet des octets exacts. Une borne d'erreur autorise une approximation, mais exige un domaine, une métrique et une justification documentés. Choisir après coup le maximum observé comme tolérance produit transformerait une mesure en règle d'acceptation non validée.

### Exercice pratique 4

Rédigez un verdict pour la sortie brute et un autre pour l'audio exporté. Qu'est-ce qui justifierait une future borne d'erreur ?

> **Réponse :** L'égalité des flottants bruts entre environnements est réfutée pour cette exécution ; l'égalité des octets WAV quantifiés est confirmée pour chaque variante testée. Une future borne exige une contrainte établie indépendamment de cette observation, des cas représentatifs et un critère d'échec explicite. L'acceptabilité à l'écoute et l'équivalence musicale exigent leurs propres preuves ; cette comparaison d'exports ne fournit ni l'une ni l'autre.

## Inclure l'adaptateur dans le périmètre

Le programme construit une nouvelle vue mémoire après chaque appel de rendu, pour ne pas dépendre d'une vue conservée entre des appels susceptibles de modifier la mémoire. L'adaptateur natif détruit explicitement l'allocation du moteur créée par `Box::into_raw` dans ce code fixé. Ce nettoyage propre à cette source ne garantit pas une ABI générale. Les cas WASM utilisent des instances neuves et brèves ; la durée de vie des allocations lors d'utilisations répétées reste à tester.

Les crêtes du silence valent 0 et les 3 témoins négatifs de PCM malformé sont détectés. Ces contrôles vérifient le dispositif d'essai, pas la lecture dans un navigateur. L'exécution réelle dans Node WebAssembly ne teste ni AudioWorklet, ni chemin vers le périphérique, ni échéance, ni annulation, ni écoute. La candidate améliore l'erreur de décroissance par rapport à l'enregistrement de 0.11416614959438576 dB, sous le seuil préétabli de 1 dB ; l'exécution réussit alors que `candidate_passes_decline_gate` reste faux.

### Exercice pratique 5

Un agent propose de remplacer le programme par un DSL d'orchestration partagé. Formulez un compromis et un critère de rejet avant de l'adopter.

> **Réponse :** Une description partagée pourrait réduire la duplication de la préparation des expériences, mais ajouterait un travail d'interprétation et de traçabilité. Gardez-la comme proposition consultative tant qu'elle ne préserve pas les commandes, le calendrier d'événements, les preuves brutes et quantifiées, ainsi que les verdicts distincts d'exécution et d'acceptation. Rejetez-la si reproduire un écart exige de reconstituer des valeurs implicites. Utilisez d'abord le programme actuel et ses cas délimités ; étudiez séparément le cycle de vie mémoire et le comportement du navigateur avant toute conclusion plus large.
