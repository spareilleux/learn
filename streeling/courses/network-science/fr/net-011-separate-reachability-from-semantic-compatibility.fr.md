---
module_id: "net-011-separate-reachability-from-semantic-compatibility"
department: "network-science"
course: "Distinguer accessibilité et compatibilité sémantique"
title: "Distinguer accessibilité et compatibilité sémantique"
level: "intermediate"
prerequisites: ["net-002-capability-graphs-and-projections", "cs-013-preserve-spectral-axes-and-units"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Distinguer accessibilité et compatibilité sémantique

> **Portée du brouillon.** Modèles fixes construits à partir de sources inspectées. Les décisions humaines techniques, linguistiques et d’apprentissage restent en attente. Aucun résultat de flotte active, contrôleur de production, télémétrie utilisateur ou progrès d’apprentissage n’est revendiqué. Le journal distingue tests réellement exécutés, lectures et contrôles prévus.

## Sources à examiner

- [net-002-capability-graphs-and-projections.md](../../network-science/en/net-002-capability-graphs-and-projections.md)
- [cs-013-preserve-spectral-axes-and-units.md](../../computer-science/en/cs-013-preserve-spectral-axes-and-units.md)
- [dag.rs](https://raw.githubusercontent.com/GuitarAlchemist/ix/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-pipeline/src/dag.rs)

Un catalogue contient un chemin de la capture à l'affichage en passant par l'analyse. Le nœud destinataire accepte la longueur du tableau et dessine une image. La composition est-elle correcte ? Un chemin accessible affirme l'existence d'arêtes selon une définition choisie. Il ne garantit pas que coordonnées et échelle correspondent aux attentes du consommateur. Les prérequis apportent la frontière du catalogue et le contexte spectral concret.

Lisez la recherche de chemin IX comme une question structurelle, puis la description de l'organisation par trames dans le cours spectral. Nos fiches producteur et consommateur ont même forme et cadence, mais divergent sur l'orientation et l'échelle. Ces fiches sont des contrats construits, pas un nouveau schéma d'API. Leur taille permet une comparaison complète sans lancer de service.

L'égalité de forme ne prouve pas celle de l'orientation. Le consommateur peut interpréter les positions autrement tout en lisant autant de cellules. De même, des valeurs linéaires et logarithmiques ne s'échangent pas silencieusement parce qu'elles sont numériques. Une conversion réelle doit préciser référence, traitement du zéro et sens exact. Ce cours ne la fournit pas et ne prétend pas qu'un renommage l'effectue.

La compatibilité est une conjonction des champs pédagogiques déclarés. Signalez chaque différence plutôt que de tout appeler échec de transport. Un chemin absent et une charge incompatible demandent des corrections différentes. Même un contrat correspondant laisse ouvertes disponibilité, authentification, identité réelle de l'implémentation et preuve du résultat. Une arête verte ne représente pas implicitement ces garanties.

Pour le travail avec les sources, annotez la définition d'une arête dans le prérequis de catalogue et la sentinelle d'orientation du prérequis spectral. Dessinez la route à la main et comparez les fiches champ par champ. Demandez à un assistant les différences minimales et les preuves nécessaires à un adaptateur, sans l'implémenter. Le contrôle négatif rend le consommateur identique au producteur. Rejetez une affirmation fondée seulement sur l'existence du chemin ou le nombre de cellules.

## Cas fixe et calculs attendus

```json
{
  "values": {
    "edges": [
      [
        "capture",
        "spectrum"
      ],
      [
        "spectrum",
        "display"
      ]
    ],
    "producer": {
      "shape": [
        2,
        3
      ],
      "orientation": "frame-major",
      "sample_rate_hz": 48000,
      "scale": "linear"
    },
    "consumer": {
      "shape": [
        2,
        3
      ],
      "orientation": "bin-major",
      "sample_rate_hz": 48000,
      "scale": "dB"
    }
  },
  "formula": "compatible=shape_match AND orientation_match AND sample_rate_match AND scale_match",
  "expected": {
    "reachable": true,
    "shape_match": true,
    "orientation_match": false,
    "sample_rate_match": true,
    "scale_match": false,
    "compatible": false,
    "mismatches": 2
  },
  "negative_control": "An otherwise identical frame-major linear consumer matches all stated fields; reachability still does not prove a live call.",
  "assumptions": [
    "The listed fields are the full teaching contract; no implicit conversion or live credentials."
  ],
  "limits": "No full spectral API validation, real transport or production adapter is established."
}
```

## Conserver une tentative d’apprenant avec ses sources

Travaillez à partir des entrées épinglées ci-dessus. Avant de demander de l’aide, écrivez votre prédiction pour le cas fixe et son contrôle négatif, avec l’unité de chaque quantité et la frontière exacte de comparaison. Un petit tableau sur papier constitue la référence manuelle directe. Gardez les valeurs intermédiaires, surtout celles qui contredisent votre première prédiction. Cette tâche d’explication utilise des sources existantes et des données fixes ; elle ne demande ni installation, ni service payant, ni nouveau programme.

Utilisez ensuite un assistant pour retrouver le passage pertinent et critiquer votre calcul. Conservez la consigne initiale, la réponse, l’emplacement cité et les modifications acceptées ou rejetées. Une citation est utile seulement si le contenu inspecté étaye l’affirmation précise. Une étape déclarée, un type de données et un commentaire n’apportent pas les mêmes preuves qu’un résultat exécuté. Expliquez cette frontière dans votre réponse finale plutôt que d’emprunter l’autorité d’une étiquette rassurante.

Remettez ensemble référence manuelle, résultat corrigé, résultat du contrôle, critère de réfutation et historique d’aide. Les critères préparés demandent si la portée est identifiée, le calcul correct, le contre-exemple conservé, l’explication étayée et la conclusion limitée à ses preuves. Ils restent indécidés sans réponse réelle d’un apprenant. Les corrigés ci-dessous sont préparés : ils ne prouvent aucun apprentissage. L’évaluateur doit garder un critère échoué et sa cause avant la correction, puis juger séparément la tentative révisée. Les preuves d’exécution et de publication, recueillies ultérieurement, exigent leurs propres relevés liés à la version.

### Exercice 1

L’affichage est-il accessible structurellement ?

<details>
<summary>Réponse 1</summary>

Oui, par `capture -> spectrum -> display` ; cela ne prouve aucun appel observé.

</details>

### Exercice 2

Comparez forme et cadence.

<details>
<summary>Réponse 2</summary>

La forme `[2,3]` et la cadence `48000` correspondent.

</details>

### Exercice 3

Comptez les différences sémantiques.

<details>
<summary>Réponse 3</summary>

`2` : orientation et échelle ; compatibilité globale `false`.

</details>

### Exercice 4

Évaluez le contrôle de fiches identiques.

<details>
<summary>Réponse 4</summary>

Tous les champs déclarés correspondent, mais aucun appel réel réussi n’est observé.

</details>

### Exercice 5

Que doit préciser un adaptateur proposé ?

<details>
<summary>Réponse 5</summary>

Sens des entrées et sorties, conversion, référence, cas limites et preuves de validation indépendante.

</details>

[Dossier de preuves fixes](../../../../code/streeling/evidence/batch50-2026-10-23/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-23/journal.md)
