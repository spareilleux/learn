---
title: "Journal d’apprentissage"
description: "Progression de rédaction, preuves de vérification et expériences restantes pour Go avancé."
sidebar:
  order: 99
---

## Progression

- [x] Leçon rédigée 1 — [Frontières des packages et des modules](../01-package-and-module-boundaries/)
- [x] Leçon rédigée 2 — [Mémoire, analyse d’échappement et GC](../02-memory-escape-and-gc/)
- [x] Leçon rédigée 3 — [Génériques et itérateurs](../03-generics-and-iterators/)
- [x] Leçon rédigée 4 — [Contrats d’erreur et nil typé](../04-error-contracts-and-typed-nil/)
- [x] Leçon rédigée 5 — [Modèle mémoire, synchronisation et atomiques](../05-memory-model-sync-and-atomics/)
- [x] Leçon rédigée 6 — [Pipelines à concurrence bornée](../06-bounded-pipelines/)
- [x] Leçon rédigée 7 — [Annulation, échéances et arrêt](../07-cancellation-deadlines-and-shutdown/)
- [x] Leçon rédigée 8 — [Frontières HTTP en production](../08-production-http/)
- [x] Leçon rédigée 9 — [Flux et délimitation des messages](../09-streaming-and-framing/)
- [x] Leçon rédigée 10 — [Tests de courses, fuzzing et propriétés](../10-race-fuzz-and-property-tests/)
- [x] Leçon rédigée 11 — [Benchmarks, pprof et trace](../11-benchmarks-pprof-and-trace/)
- [x] Leçon rédigée 12 — [Réflexion, encodage et frontières](../12-reflection-and-encoding/)
- [x] Leçon rédigée 13 — [Dépendances, builds et sécurité](../13-dependencies-builds-and-security/)
- [x] Leçon rédigée 14 — [Un service intégré de tâches HTTP](../14-service-capstone/)
- [x] Tests du module intégré, vet, formatage et quatorze sorties exactes.
- [x] Correspondance des sources et extraits, liens des pages traduites construites.
- [x] Fuzzing actif borné des cibles écrites.
- [ ] CI hébergée Windows/Linux/macOS et détecteur de courses Linux.
- [ ] Lecture anonyme des pages publiques après déploiement Pages.
- [ ] Essai par des apprenants et révision linguistique indépendante.

## 2026-11-07 — Rédaction et vérification préliminaire du module

Les quatorze leçons, la mission et les exercices corrigés ont été rédigés en anglais, français et espagnol. Le code forme un module indépendant utilisant uniquement la bibliothèque standard, avec quatorze commandes et des packages réutilisables : domaine, itération, pipeline, tramage, encodage, provenance, HTTP et service de tâches. Les listings proviennent des fichiers Go versionnés formatés ; aucun commentaire en langue naturelle ne nécessite des variantes entre traductions.

Plusieurs choix pédagogiques sont explicites. Les tâches copient les slices de l’appelant à l’admission sans dépendre d’une convention de constructeur sur une struct exportée. Le producteur et le coordinateur possèdent les fermetures du pipeline. Le service sérialise admission et fermeture, réserve une réponse tamponnée par tâche et ferme définitivement l’admission pendant le drain. Le tramage vérifie la longueur annoncée avant allocation et gère les écritures partielles. Ce sont des décisions rédigées, pas des récits d’expériences échouées.

Le coordinateur a communiqué une exécution préliminaire réelle de `go test -count=1 -timeout=60s ./...` avec Go 1.27.1 sous Windows/amd64, CGO désactivé : les quatorze packages de commandes compilent et les huit packages de tests réussissent. L’auteur du cours n’a pas exécuté cette commande indépendamment. Cette preuve reste préliminaire : le relevé final doit lier tests, snippets, sorties exactes, traductions et révision publiée. Les cases cochées indiquent la rédaction, pas la publication ni l’acceptation humaine.

La documentation Go 1.27 a été consultée pour éviter d’anciennes restrictions sur les méthodes génériques et une description encore expérimentale de JSON v2. Nil typé, lectures partielles et annulation coopérative sont des comportements documentés surprenants depuis C#/Java, pas des bugs amont. Aucun ticket amont n’a été ouvert. Il n’y a pas encore de tableau QA de défauts logiciels ni de tableau Expériences d’hypothèses mesurées : l’auteur n’en a établi aucun.

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

- Un développeur C#/Java peut-il expliquer pourquoi annuler une requête n’implique aucun rollback transactionnel ?
- L’apprenant identifie-t-il le propriétaire de chaque fermeture de canal sans ouvrir les solutions ?
- La méthode de lecture commune aide-t-elle à distinguer garanties sémantiques et mesures du compilateur ?
- Quels contrats de persistance et d’identité d’opération permettraient de rejouer sûrement des effets externes ?
