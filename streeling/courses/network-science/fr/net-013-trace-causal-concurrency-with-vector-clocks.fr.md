---
module_id: "net-013-trace-causal-concurrency-with-vector-clocks"
department: "network-science"
course: "Tracer la concurrence causale avec des horloges vectorielles"
level: "intermediate"
prerequisites: ["net-008-map-clock-domains-before-ordering-events", "inf-012-retain-event-order-in-a-handoff-summary"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Tracer la concurrence causale avec des horloges vectorielles

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Deux agents modifient des notes distinctes et écrivent au coordinateur. Un tri par horloge physique peut placer une action avant l’autre sans dépendance entre elles. Le prérequis sur les horloges aligne les coordonnées ; celui sur les résumés conserve l’ordre. Ce cours ajoute un ordre causal partiel qui peut laisser les événements incomparables. Une liste totale facilite l’affichage, mais son ordre ne décrit pas automatiquement la causalité.

Chaque composante représente la connaissance des événements d’un nœud fixe. Comparez les vecteurs composante par composante. L’un précède l’autre seulement si toutes ses composantes sont inférieures ou égales et au moins une strictement inférieure. Si chacun possède une information absente de l’autre, aucun ne domine : les événements sont concurrents dans le modèle. Additionner les composantes ou trier lexicographiquement perd cette distinction.

L’article original de [Lamport](https://lamport.azurewebsites.net/pubs/time-clocks.pdf) définit la relation par séquence locale, envoi/réception et transitivité. Les notes de [Cambridge](https://www.cl.cam.ac.uk/teaching/2021/ConcDisSys/dist-sys-notes.pdf) décrivent les horloges vectorielles et la réception. Fusionnez par maximum composante par composante, puis incrémentez celle du destinataire. Cela conserve la connaissance entrante et l’événement de réception ; ajouter un total scalaire ne préserverait pas ces informations.

La source [F#](https://learn.microsoft.com/dotnet/fsharp/) conservée déclare une composition parallèle de résultats. Elle ne fournit aucun horodatage et ne prouve pas l’ordre réel des callbacks. Nos vecteurs construits supposent toute communication pertinente représentée et aucune identité réutilisée. Une enveloppe de trace reste consultative jusqu’à comparaison avec un graphe manuel sur une tâche réelle. La concurrence ne dit pas non plus si les écritures sont autorisées ou sûres : il faut le contrat distinct de propriété et d’effets.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: net-008-map-clock-domains-before-ordering-events](../../network-science/en/net-008-map-clock-domains-before-ordering-events.md)

[Prérequis: inf-012-retain-event-order-in-a-handoff-summary](../../information-theory/en/inf-012-retain-event-order-in-a-handoff-summary.md)

[Artefact conservé du projet](../../../../code/streeling/functional-composition/vendor/GaAsync.fs)

[Lecture primaire: Lamport 1978, Communications of ACM 21(7), pp. 558-565](https://lamport.azurewebsites.net/pubs/time-clocks.pdf)

[Lecture primaire: Kleppmann, Cambridge Distributed Systems 2020/21](https://www.cl.cam.ac.uk/teaching/2021/ConcDisSys/dist-sys-notes.pdf)

[Lecture primaire: Microsoft F# documentation, read 2026-10-24](https://learn.microsoft.com/dotnet/fsharp/)

## Modèle fixé et contrôle

```json
{
  "values": {
    "a": [
      2,
      0
    ],
    "b": [
      0,
      3
    ],
    "receiver_local": [
      0,
      3
    ],
    "incoming": [
      2,
      0
    ],
    "receiver_index": 1
  },
  "formula": "a precedes b iff every a[i]<=b[i] and at least one strict; concurrent iff neither precedes nor equal; receive=max(local,incoming) componentwise then increment receiver component.",
  "expected": {
    "a_before_b": false,
    "b_before_a": false,
    "concurrent": true,
    "receive_clock": [
      2,
      4
    ],
    "a_before_receive": true
  },
  "negative_control": {
    "values": {
      "a": [
        2,
        0
      ],
      "b": [
        3,
        1
      ],
      "receiver_local": [
        3,
        1
      ],
      "incoming": [
        2,
        0
      ],
      "receiver_index": 1
    },
    "expected": {
      "a_before_b": true,
      "b_before_a": false,
      "concurrent": false,
      "receive_clock": [
        3,
        2
      ],
      "a_before_receive": true
    },
    "why": "Componentwise dominance replaces incomparability when causal knowledge includes the earlier event."
  },
  "assumptions": [
    "Fixed node identities and component order.",
    "Clocks are generated by the stated local-event/send/receive discipline with complete modeled communication."
  ],
  "limits": "Authored vectors are not live agent traces; omitted channels or restarted identities invalidate causal interpretation. No physical duration or permission follows."
}
```

### Exercice 1

Comparez les vecteurs principaux. Un événement précède-t-il causalement l’autre ?

<details><summary>Réponse 1</summary>

Aucun ne domine : `a=[2,0]` est supérieur dans la première composante et `b=[0,3]` dans la seconde. Donc `concurrent=true`. Les sommes ne fournissent pas de relation causale.

</details>

### Exercice 2

Calculez le vecteur de réception en gardant l’ordre de l’incrément.

<details><summary>Réponse 2</summary>

Le maximum vaut `[2,3]` ; incrémenter la composante destinataire `1` donne `[2,4]`. La fusion précède l’incrément. L’indice dépend de l’ordre fixe des composantes déclaré.

</details>

### Exercice 3

L’événement initial précède-t-il la réception ?

<details><summary>Réponse 3</summary>

Oui. `[2,0]` est inférieur ou égal à `[2,4]` partout et strictement inférieur quelque part ; donc `a_before_receive=true`. C’est une relation causale, sans estimation de durée.

</details>

### Exercice 4

Appliquez le contrôle de dominance et comparez.

<details><summary>Réponse 4</summary>

Pour `b=[3,1]`, `a_before_b=true` et `concurrent=false`. L’horloge reçue vaut `[3,2]`. La connaissance causale supplémentaire change la relation plutôt qu’un simple horodatage affiché.

</details>

### Exercice 5

Qu’est-ce qui peut invalider l’interprétation d’une trace réelle ?

<details><summary>Réponse 5</summary>

Canaux absents, compteurs remis à zéro, identités réutilisées ou ordre des composantes modifié brisent les hypothèses. Un tri total ou une déclaration parallèle ne remplace pas les traces manquantes et n’autorise pas les écritures concurrentes.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
