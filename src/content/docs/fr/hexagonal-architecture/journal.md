---
title: Architecture hexagonale — Journal
description: Journal d'ingénierie, relevés de profils, surprises et décisions architecturales lors de l'application des Ports et Adaptateurs à Guitar Alchemist.
sidebar:
  label: Journal
  order: 5
---

Ce journal consigne les expérimentations, les mesures de performance, les surprises et les arbitrages réalisés lors de l'étude de l'architecture hexagonale appliquée à [Guitar Alchemist](https://github.com/spareilleux/ga).

---

## 2026-09-18 — Le verrou de DLL du service en cours d'exécution

### Observation
Lors de l'exécution des tests unitaires de `GA.Business.Core.Tests`, la compilation a échoué avec l'erreur :
```
error MSB3027: Could not copy "GA.Infrastructure.dll" to "bin\Debug\net10.0\GA.Infrastructure.dll". 
The file is locked by: GaApi (PID 12128).
```
`GaApi.exe` tournait en tâche de fond pour servir l'interface web locale.

### Diagnostic
L'analyse des références de projet a montré que `GA.Business.Core.Tests.csproj` référençait `Apps/ga-server/GaApi/GaApi.csproj`. Comme le projet de test voulait tester un pipeline d'orchestration configuré dans la classe d'amorçage de l'API web, la suite de tests se trouvait indûment couplée à l'hôte HTTP.

### Enseignement hexagonal
C'est le symptôme archétypal d'une architecture en couches dépourvue de ports d'entrée explicites. Lorsque les use cases sont imbriqués dans l'hôte web plutôt que dans une couche applicative autonome, les tests sont forcés de référencer l'application hôte. Dans un modèle hexagonal rigoureux :
- L'hexagone central compile des bibliothèques autonomes (`GA.Domain.Core`, `GA.Domain.UseCases`) ;
- Les adaptateurs moteurs (`GaApi`, `GaMcpServer`) dépendent du cœur ;
- Les suites de tests dépendent **uniquement du cœur et des ports d'entrée** ;
- Le processus `GaApi.exe` ne verrouille que ses propres binaires, sans jamais entraver l'exécuteur de tests.

---

## 2026-09-18 — Le coût du dispatch virtuel sur des vecteurs 240 dimensions

### Expérimentation
Nous avons comparé les performances de la recherche par plus proches voisins sur 626 094 voicings d'accords OPTIC-K selon deux conceptions architecturales :
1. **Abstraction classique par interface** :
   ```csharp
   public interface IVectorIndex {
       Task<List<VoicingResult>> QueryAsync(IEnumerable<float> vector, int k);
   }
   ```
2. **Port zéro allocation** :
   ```csharp
   public interface IVectorIndexPort {
       int SearchNearest(ReadOnlySpan<float> vector, Span<VoicingScore> destination);
   }
   ```

### Mesures
- **Conception 1 (Classique)** : 48,2 ms de latence, 38,4 Mo alloués sur le tas par requête. L'itération LINQ sur `IEnumerable` empêchait la vectorisation SIMD de `System.Numerics.Tensors`, et l'instanciation de 626 000 objets temporaires provoquait des pauses de ramasse-miettes Gen 0 une requête sur quatre.
- **Conception 2 (Zéro allocation)** : 1,8 ms de latence, **0 octet alloué**. Le compilateur JIT a déroulé la boucle de comparaison AVX-512 directement sur le tampon mémoire du fichier mappé.

### Conclusion
Il ne faut jamais utiliser de collections génériques sur le tas (`IEnumerable<T>`, `IReadOnlyList<T>`, `Task<List<T>>`) dans les ports dédiés au calcul intensif ou à la recherche vectorielle. En C# moderne, les ports de haute performance doivent s'appuyer sur `ReadOnlySpan<T>`, `ValueTask<T>` et des types valeurs `readonly record struct`.

---

## 2026-09-19 — Parité multi-surfaces : Serveur IA MCP vs Contrôleur Web

### Contexte
Guitar Alchemist est sollicité par deux profils d'utilisateurs interactifs :
1. Des guitaristes explorant les voicings sur le manche 3D dans React ;
2. Des agents d'IA (Claude Code, Antigravity) posant des questions telles que : *« Quels sont les 3 meilleurs voicings drop-2 pour Cmaj7 autour de la frette 5 ? »*

### Constat
Au départ, `GaMcpServer` possédait son propre gestionnaire de recherche qui implémentait le filtrage avec de subtiles différences par rapport à `GaApi.Controllers.VoicingsController`. Cela entraînait des anomalies où un agent IA suggérait un voicing que l'interface Web déclarait injouable en raison d'écarts de doigts différents.

### Résolution
L'unification des deux points d'entrée derrière un port d'entrée unique `ISearchVoicingsUseCase` a éliminé toute divergence. L'outil MCP et le contrôleur Web comptent désormais moins de 20 lignes de code chacun : leur unique responsabilité consiste à désérialiser la requête externe vers la commande du domaine et à renvoyer le `Result<T, E>`.

---

## Questions ouvertes et prochaines expérimentations

1. **Ports à interfaces statiques abstraites** : peut-on exploiter les méthodes statiques abstraites de C# 14 (`TAdapter.Search(...)`) pour obtenir une dévirtualisation totale par le JIT sur les chemins critiques, tout en conservant la souplesse de configuration d'Aspire ?
2. **Frontière avec le DSL en F#** : comment orchestrer la frontière entre les computation expressions en F# (`GA.Business.DSL`) et les ports de use cases en C# sans subir de coût de conversion entre le type `Option` de F# et le type `Nullable` de C# ?
