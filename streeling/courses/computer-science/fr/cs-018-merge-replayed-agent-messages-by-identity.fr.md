---
module_id: "cs-018-merge-replayed-agent-messages-by-identity"
department: "computer-science"
course: "Fusionner les messages d’agent rejoués selon leur identité"
level: "intermediate"
prerequisites: ["cs-005-agent-handoff-evidence-contract"]
estimated_duration: "45 minutes"
produced_by: "codex-project-pilot"
version: "0.1.0"
---

# Fusionner les messages d’agent rejoués selon leur identité

> Ce cours s’appuie sur un cas construit et des sources consultées. Les effectifs, durées, étiquettes et signaux sont des données pédagogiques inventées. La revue technique humaine, la relecture linguistique, les tentatives réelles, l’exécution, l’adoption en production et la publication restent à décider.

Un auteur Learn reçoit deux fois un message de fin parce que l’expéditeur a perdu l’accusé de réception. Compter les livraisons compte deux fois le même travail ; supprimer toute charge utile répétée peut effacer des travaux distincts. Il faut savoir quel résultat logique chaque message désigne. Le prérequis conserve l’identité des artefacts, sans définir l’algèbre du rejeu. Ici, l’identité forme les groupes et l’égalité des contenus détermine leur cohérence.

L’utilitaire Learn conservé place les identifiants de modules et les noms de fichiers dans un ensemble. Cette source montre une représentation de l’appartenance, sans implémenter ce protocole de messages. Un ensemble d’identifiants ne révèle pas qu’un identifiant arrive avec un contenu différent. Notre modèle valide donc chaque groupe avant la somme. Des contenus égaux avec des identités différentes restent des résultats distincts ; une identité associée à des contenus différents reste en conflit. Ce contrat pédagogique ne décrit pas le transport actuel des agents.

L’idempotence du [RFC](https://www.rfc-editor.org/rfc/rfc9110.html#name-idempotent-methods) concerne l’effet voulu de requêtes identiques répétées. Elle ne garantit ni des journaux identiques ni la possibilité de rejouer toute opération. La provenance [W3C](https://www.w3.org/TR/2013/REC-prov-dm-20130430/) distingue aussi une entité de l’activité qui l’utilise. Gardez cette distinction lorsqu’un assistant veut compter chaque livraison comme une nouvelle expérience. Une seconde notification fournit un événement de livraison supplémentaire, sans fournir un nouvel essai.

CS015 attribue déjà les images d’analyse communes au premier auteur et refuse les doublons conflictuels. La question supplémentaire est de fusionner des états accumulés séparément dans un ordre quelconque sans effacer un conflit. Représentez chaque identité logique par l’ensemble de ses contenus observés. Fusionnez les états par union à chaque identité ; une identité absente apporte l’ensemble vide. L’union est associative, commutative et idempotente : regroupement, ordre d’arrivée et rejeu égal ne changent pas l’état final. Un singleton est cohérent ; plusieurs valeurs signalent un conflit. Une nouvelle union ne peut retirer une valeur conflictuelle. Ne sommez les singletons qu’après validation de toutes les identités. Cette algèbre conserve les conflits lors des fusions, au-delà de l’attribution d’un intervalle d’images.

Une fusion composable n’est utile que si producteur et consommateur partagent le périmètre des identités. Une nouvelle révision peut légitimement nécessiter une nouvelle identité. Un horodatage arbitraire ou un nom de wrapper n’établit pas ce lien. Écrivez d’abord les groupes à la main, puis vérifiez si l’outil proposé les préserve, rejette les conflits et conserve les messages pour le diagnostic.

## Sources et périmètre du projet

Lisez le prérequis avant d’utiliser le modèle. Examinez l’artefact conservé du projet à la révision indiquée dans le dossier et repérez le champ ou la branche qui étaye l’observation. La source fournit une représentation ou un comportement déclaré ; elle ne transforme pas le cas inventé en résultat observé du projet. La lecture primaire apporte le concept nommé dans les limites annoncées.

[Prérequis: cs-005-agent-handoff-evidence-contract](../../computer-science/en/cs-005-agent-handoff-evidence-contract.md)

[Artefact conservé du projet](../../../../scripts/streeling-lib.mjs)

[Lecture primaire: RFC 9110, June 2022, section 9.2.2](https://www.rfc-editor.org/rfc/rfc9110.html#name-idempotent-methods)

[Lecture primaire: W3C Recommendation 2013-04-30](https://www.w3.org/TR/2013/REC-prov-dm-20130430/)

## Modèle fixé et contrôle

```json
{
  "values": {
    "messages": [
      {
        "id": "a",
        "value": 3
      },
      {
        "id": "b",
        "value": 5
      },
      {
        "id": "a",
        "value": 3
      }
    ],
    "initial": {}
  },
  "formula": "Group by id; equal repeated values collapse; any unequal values for one id produce conflict; sum unique values only when no conflict.",
  "expected": {
    "unique_count": 2,
    "sum": 8,
    "conflict": false
  },
  "negative_control": {
    "values": {
      "messages": [
        {
          "id": "a",
          "value": 3
        },
        {
          "id": "b",
          "value": 5
        },
        {
          "id": "a",
          "value": 4
        }
      ],
      "initial": {}
    },
    "expected": {
      "unique_count": 2,
      "sum": null,
      "conflict": true
    },
    "why": "Same identity now names unequal content, so replay equivalence fails."
  },
  "assumptions": [
    "Identity is stable for one logical result.",
    "Payload equality is exact; no partial effects are applied before validation."
  ],
  "limits": "An authored merge rule, not an exactly-once transport, authorization or existing GA deduplication implementation."
}
```

### Exercice 1

Calculez la somme des livraisons et celle fondée sur les identités. Laquelle répond à la question des résultats logiques ?

<details><summary>Réponse 1</summary>

La somme des livraisons vaut `11` ; celle des résultats uniques vaut `8` pour `2` identités. La première compte les notifications. Aucune ne prouve l’indépendance des expériences ; le contrat d’identité ne fournit que le regroupement des rejeux.

</details>

### Exercice 2

Rejouez encore le premier message sans modifier son contenu. Que devient la somme acceptée ?

<details><summary>Réponse 2</summary>

Elle reste `8`. Ajouter un membre égal à un groupe cohérent change le nombre de livraisons, sans modifier sa charge utile unique. C’est exactement la propriété d’idempotence limitée proposée.

</details>

### Exercice 3

Appliquez le contenu modifié du contrôle. Choisir silencieusement le premier reçu donne-t-il un total valide ?

<details><summary>Réponse 3</summary>

Non. L’identité `a` désigne `3` et `4` ; donc `conflict=true` et `sum=null`. Choisir un gagnant ajouterait une règle de résolution absente du modèle.

</details>

### Exercice 4

Deux essais réels peuvent-ils renvoyer le même contenu tout en comptant séparément ?

<details><summary>Réponse 4</summary>

Oui, si leurs identités logiques diffèrent. L’égalité du contenu ne suffit pas à reconnaître un travail dupliqué. Il faut conserver l’identité de l’essai et la révision avant d’interpréter le décompte comme preuve.

</details>

### Exercice 5

Quelle vérification avec consultation des sources pourrait rejeter une fusion DSL proposée ?

<details><summary>Réponse 5</summary>

Formez les groupes manuellement et comparez les deux cas. Un total pour le cas conflictuel, ou une somme modifiée après un rejeu égal, réfute le contrat. Aucun transport installé ni effet en production n’a été testé.

</details>

## Travail avec consultation des sources

Commencez par un tableau sur papier avant d’ouvrir les réponses. Recopiez les entrées et leurs unités, appliquez l’opération déclarée et conservez les résultats intermédiaires. Ce calcul direct constitue la référence manuelle pour comparer une réponse assistée ou une notation composable proposée. Une réponse plus courte ne présente aucun avantage démontré si elle perd l’identité d’une entrée, une catégorie d’échec ou le contre-exemple.

Examinez ensuite le passage précis consigné dans le dossier. Ne citez que le petit champ ou la branche nécessaire à votre explication, avec sa révision. Après avoir enregistré votre première réponse, demandez à un assistant de contester une hypothèse. Conservez la consigne, sa réponse, les corrections retenues et les suggestions rejetées. La consultation des sources et la calculatrice sont autorisées ; signalez cette aide pour ne pas présenter le résultat comme un rappel sans assistance.

Appliquez l’entrée modifiée du contrôle négatif et énoncez un résultat observable qui réfuterait votre conclusion avant de recommander un changement. Un contrôle inattendu impose de vérifier le calcul et les hypothèses avant de modifier le fonctionnement du projet. Remettez ensemble la réponse initiale, la réponse corrigée, l’historique des aides et l’incertitude restante. Le dossier prépare cinq critères, un par exercice, dont les décisions restent indéterminées. Les corrigés et vérifications de l’auteur ne remplissent pas ces décisions. Une future comparaison en dogfooding exige des tentatives réelles sur la même tâche et une référence manuelle conservée ; ce cours ne demande aucune nouvelle implémentation d’agent ou de DSL.

[Dossier fixé de l’unité](../../../../code/streeling/evidence/batch50-2026-10-24/unit-b.json) · [Journal de validation](../../../../code/streeling/evidence/batch50-2026-10-24/journal.md)
