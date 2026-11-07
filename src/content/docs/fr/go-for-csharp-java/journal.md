---
title: "Go pour développeurs C# et Java — Journal"
description: "Éléments datés de rédaction et de vérification du cours Go standard."
sidebar:
  order: 99
---

## Progression

- [x] Rédigé: [Chaîne d’outils et modules](../01-toolchain-and-modules/).
- [x] Rédigé: [Valeurs, types et chaînes](../02-values-types-and-strings/).
- [x] Rédigé: [Contrôle de flux et fonctions](../03-control-flow-and-functions/).
- [x] Rédigé: [Tableaux et slices](../04-arrays-and-slices/).
- [x] Rédigé: [Maps et structures](../05-maps-and-structs/).
- [x] Rédigé: [Pointeurs et méthodes](../06-pointers-and-methods/).
- [x] Rédigé: [Interfaces et composition](../07-interfaces-and-composition/).
- [x] Rédigé: [Erreurs, defer et ressources](../08-errors-defer-and-resources/).
- [x] Rédigé: [Fichiers, JSON et Unicode](../09-files-json-and-unicode/).
- [x] Rédigé: [Génériques et collections](../10-generics-and-collections/).
- [x] Rédigé: [Goroutines et canaux](../11-goroutines-and-channels/).
- [x] Rédigé: [HTTP et context](../12-http-and-context/).
- [x] Rédigé: [Tests](../13-testing/).
- [x] Rédigé: [Projet final en ligne de commande](../14-cli-capstone/).
- [x] Tests du module intégré, vet, formatage et quatorze sorties exactes.
- [x] Correspondance des sources et extraits, liens des pages traduites construites.
- [x] Fuzzing actif borné des cibles écrites.
- [ ] CI hébergée Windows/Linux/macOS et détecteur de courses Linux.
- [ ] Lecture anonyme des pages publiques après déploiement Pages.
- [ ] Essai par des apprenants et révision linguistique indépendante.

## 2026-11-07 — Rédaction complète et vérification préliminaire du module

Le cours standard a été rédigé comme cours général Learn, en dehors de Streeling. Quatorze leçons relient modules et sémantique des valeurs à un véritable CLI de journal d’étude. Les versions anglaise, française et espagnole contiennent des explications complètes et deux exercices corrigés par leçon. Noms de fichiers, extraits Go, commandes et sorties attendues correspondent entre langues.

L’exemple conserve une progression cohérente : internal/study possède enregistrements typés, sélection, totaux, lecture JSON et flux annulable ; internal/cli assemble options, acquisition et rapport ; internal/webapi fournit une petite frontière HTTP testée en mémoire. La dernière commande réutilise ces packages au lieu de répéter une démonstration isolée. Le module n’a aucune dépendance tierce.

Les extraits proviennent directement des fichiers main.go formatés, évitant ainsi une divergence entre sources et trois traductions. La leçon treize reproduit aussi exactement une fonction de test compilée. Les sorties attendues ont été consignées dans examples.json avant exécution et restent marquées comme attendues jusqu’à la vérification finale du coordinateur sur l’ensemble terminé. Aucun diagnostic de compilation ni mesure de performance n’a été inventé.

Une correction liée à la version a été intégrée à la rédaction : Go 1.27 autorise les méthodes génériques concrètes, tandis que les méthodes d’interface ne peuvent toujours pas déclarer leurs propres paramètres de types. Le comportement JSON est relié aux API encoding/json utilisées et aux tests explicites, sans extrapolation d’une ancienne implémentation. Autre distinction essentielle : un pointeur nil contenu dans une interface conserve son type dynamique et ne forme donc pas une interface nil.

Le coordinateur a signalé une exécution préliminaire réussie du module sous Go 1.27.1, Windows/amd64, avec CGO désactivé. La commande exacte était go test -count=1 -timeout=60s ./... depuis code/go-for-csharp-java. Les quatorze packages de commandes ont compilé et les tests cli, study et webapi ont réussi. Ce résultat a été fourni par le coordinateur ; l’agent de rédaction n’a pas exécuté les tests Go. La vérification finale doit relier cette preuve aux sources et pages terminées.

Le code a été formaté avec gofmt. Les tests écrits couvrent partage et clonage de slices, modification de structures, interfaces à pointeur nil, validation et causes enveloppées, JSON malformé, UTF-8 invalide, octets et runes, limites et ordre de sélection, transformation générique, annulation, HTTP et erreurs d’entrée/sortie CLI. Une cible de fuzzing existe ; aucune campagne, mesure de vitesse ou séance réelle d’apprentissage n’est revendiquée.

Le coordinateur a ensuite exécuté les quatorze commandes du cours standard et confirmé que chaque sortie correspondait exactement à examples.json, saut de ligne final compris. Il a aussi signalé la réussite de go vet ./... et des contrôles de formatage dans le même environnement Go 1.27.1 sous Windows, CGO désactivé. Ce sont des résultats d’exécution préliminaires réels, pas des captures inventées ; les contrôles finaux doivent encore relier la documentation terminée et son état de publication.

## 2026-11-07 — Vérification technique intégrée

Les deux modules ont été exécutés avec Go 1.27.1 sous Windows/amd64, CGO désactivé. Dans ce module, `go test -count=1 -timeout=60s ./...`, `go vet ./...`, les contrôles de formatage et les quatorze exemples `go run ./cmd/lNN` ont réussi. Chaque sortie correspond exactement à `examples.json`, saut de ligne final compris. Le contrôle intégré valide 96 pages, les extraits Go identiques aux sources, 84 blocs de sorties traduits, les corrigés et la structure des journaux. La construction du site a réussi ; les liens des articles et leurs ancres se résolvent sur les 99 routes concernées. Le [relevé de vérification lisible par machine](https://github.com/spareilleux/learn/blob/main/docs/verification/2026-11-07-go-courses-local.json) conserve les commandes, résultats et empreintes SHA-256 des sources.

Les essais de fuzzing bornés utilisent `-fuzztime=5s -parallel=2` : `FuzzLoad` du module standard, puis `FuzzReverse` et `FuzzFrames` du module avancé ont réussi. Le lancement du benchmark avancé sur une seule itération a réussi ; il ne constitue pas une référence de performance représentative. Après simplification de l’exemple JSON avec `bytes.NewReader`, les tests du niveau standard, la sortie exacte de cet exemple et vet ont de nouveau réussi. Les extraits ont été synchronisés dans les trois langues.

L’audit a révélé un vrai défaut du contrôleur : la détection insensible à la casse du marqueur `TODO` rejetait le mot espagnol courant « todo ». Un test de régression a d’abord échoué, puis réussi après correction de la casse ; les seize tests du contrôleur et les dix-neuf tests Node existants passent. Il s’agissait d’un défaut de validation des cours, pas de Go. Aucun essai par un apprenant, scan de vulnérabilités, profil CPU, trace ou rapport d’échappement n’est revendiqué. La CI hébergée, le détecteur de courses et la publication restent des validations distinctes.


## À vérifier

- Consulter la CI hébergée Windows, Linux et macOS, dont le détecteur de courses Linux.
- Relire sans authentification les pages EN/FR/ES déployées et consigner la révision publiée.
- Mesurer une charge représentative avant de tirer des conclusions de performance, de profilage, de trace ou d’échappement.
- Observer de vraies tentatives d’exercices et obtenir une révision linguistique indépendante ; ces observations restent à faire.

## Questions ouvertes

- Les lecteurs C# et Java expliquent-ils correctement le pointeur nil typé avant la solution ? Il faut observer des apprenants.
- Leurs schémas de propriété des slices permettent-ils de prévoir le projet final ? Cette question demande aussi une observation réelle.
