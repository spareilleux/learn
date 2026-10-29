---
module_id: net-002-capability-graphs-and-projections
department: network-science
course: "Science des réseaux pour les écosystèmes d’IA"
level: early-intermediate
prerequisites: [net-001-scale-free-tool-networks]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
research_cycle: network-science-2026-10-11-002
version: "0.1.0"
---

# Un catalogue de capacités n'est pas un graphe de collaboration

> **Périmètre de la source et du transfert.** Le texte technique ci-dessous provient d’un brouillon archivé. Les mentions historiques d’une absence d’importation ou de compilation dans Learn concernent cette étape antérieure ; ce [dossier de transfert](../../../../code/streeling/evidence/agentic-composition-2026-10-22/README.md) décrit l’importation actuelle et ses vérifications. Les autres expériences indiquées comme non réalisées le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département de science des réseaux** | Niveau : intermédiaire débutant | Durée estimée : 30 minutes | Statut : brouillon français ; révision et publication en attente

## Objectifs

Après cette leçon, vous saurez :

- Construire un graphe à deux types de nœuds à partir du catalogue déclaré de Demerzel reliant dépôts et familles d'outils.
- Projeter ce graphe sur les dépôts en appliquant une règle d'arête explicite et compter ses composantes.
- Expliquer pourquoi une arête de catalogue, une dépendance contractuelle et un appel d'outil observé constituent des preuves différentes.
- Tester l'effet du retrait d'une étiquette sans le présenter comme une véritable panne de service.

## La question du projet

Un coordinateur souhaite réunir l'analyse d'accords de GA et la pondération grammaticale de TARS dans un même workflow. Le [registre de capacités](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/schemas/capability-registry.json) de Demerzel nomme des outils pour les deux dépôts. Ce catalogue prouve-t-il que ces deux outils peuvent être appelés successivement grâce à un transfert fonctionnel entre dépôts ? **Non.** C'est un index de découverte. Nous pouvons représenter ses étiquettes déclarées sous forme de graphe et repérer les recoupements entre descriptions, mais ce graphe n'encode ni contrat d'API, ni identifiants d'accès, ni invocation réussie, ni présence actuelle des services.

Cette leçon utilise uniquement le registre au commit Demerzel `5c4967454ddc740ed937c87719ca4d71a3522e4b` (version du registre `1.1.0`) et la [note sur les contrats entre dépôts](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/docs/architecture/cross-repo-contracts.md) à la même révision. Les nombres ci-dessous ont été recalculés à partir du JSON figé. [NET-001](net-001-scale-free-tool-networks.md) présente le degré, les hubs et les limites d'une affirmation de réseau sans échelle. Ici, la tâche est différente : **choisir le sens d'une arête avant de la compter**. Aucun endpoint MCP actif n'a été interrogé pour cette leçon.

## 1. Construire le graphe déclaré à deux types de nœuds

Ouvrez l'objet JSON `repos`. Ses trois clés de dépôts sont `ix`, `tars` et `ga`. Pour chacun, `tools` associe des **noms de familles** à des tableaux d'outils nommés. Construisez un graphe non orienté à deux types de nœuds : un type représente les dépôts, l'autre les chaînes exactes des noms de familles. Tracez une arête du dépôt `r` vers la famille `f` lorsque `f` est une clé de `repos[r].tools`. On compte ainsi les *familles*, et non les noms d'outils individuels. Par exemple, `ix` possède une arête vers `grammar`, bien que cette famille énumère trois outils `ix_grammar_*`. `tars` possède aussi une arête vers `grammar`, mais les outils qui y figurent portent d'autres noms. L'étiquette commune atteste un mot partagé dans le catalogue ; elle ne prouve pas que les implémentations acceptent les mêmes entrées.

| Nœud de dépôt | Degré déclaré en familles | Un exemple vérifié |
|---|---:|---|
| `ix` | 27 | `grammar` contient `ix_grammar_weights`, `ix_grammar_evolve` et `ix_grammar_search` |
| `tars` | 4 | `grammar` contient `tars_grammar_weight` et `tars_grammar_evolve` |
| `ga` | 5 | `music-theory` contient `ga_scale`, `ga_chord`, `ga_chord_atonal` et `ga_interval` |

La somme des degrés du côté des dépôts vaut `27 + 4 + 5 = 36` ; cette définition donne donc **36 arêtes entre dépôts et familles**. On compte **35 nœuds de noms de familles distincts**, car `grammar` est la seule clé de famille répétée ; toutes les autres n'apparaissent que sous un des trois dépôts. Le graphe possède donc `3 + 35 = 38` nœuds. Ce calcul est lié au registre figé ; une révision ultérieure peut ajouter, renommer ou supprimer des déclarations. Ce graphe est aussi volontairement restreint. Il n'inclut pas Demerzel comme nœud de dépôt au seul motif que Demerzel héberge le registre.

### Exercice pratique 1 : compter la bonne unité

Un collègue annonce que « `ix` possède trois arêtes de grammaire » parce que trois outils de grammaire sont énumérés. Selon la règle de cette leçon, quel est le degré de `ix`, quelle est la contribution de la grammaire, et combien de nœuds et d'arêtes contient le graphe complet à deux types ?

> **Réponse :** `ix` a un degré de 27 : une arête par clé de famille de `tools`, dont exactement une arête `ix`–`grammar`. Le graphe figé complet possède 3 nœuds de dépôts et 35 nœuds de familles distincts, soit 38 nœuds ; la somme des degrés côté dépôts donne 36 arêtes d'incidence. Compter les entrées d'outils définirait un autre graphe et d'autres degrés.

## 2. Projeter sur les dépôts, puis interpréter la projection avec soin

Une **projection sur les dépôts** remplace chaque chemin en deux étapes `repo A → family → repo B` par une arête non orientée A–B. Énoncez précisément la règle : relier deux dépôts uniquement si leurs objets `tools` partagent au moins une **clé de famille identique**. L'examen des ensembles figés donne `ix ∩ tars = {grammar}`, `ix ∩ ga = ∅` et `tars ∩ ga = ∅`. La projection à trois nœuds possède donc une arête, `ix`–`tars`. Elle possède deux composantes connexes : `{ix, tars}` et `{ga}`. Dans le graphe initial à deux types, ces deux mêmes composantes contiennent aussi les nœuds de familles qui leur sont rattachés.

La projection a perdu de l'information. Elle ne montre ni les 27 familles de `ix` contre les 4 de `tars`, ni le fait que leurs implémentations de `grammar` sont des outils différents. GA apparaît isolé selon cette **règle d'étiquette exacte**, bien qu'il ait cinq familles d'outils déclarées et puisse participer à d'autres arrangements entre dépôts. Ne renommez pas la famille `spectral` de `ga` en `signal` de `ix`, ou `music-theory` avec une autre étiquette, dans le seul but de tracer une connexion. Une similarité sémantique exige une correspondance révisée et un cas d'usage ; la comparaison de chaînes est reproductible précisément parce qu'elle refuse de deviner.

### Exercice pratique 2 : énumérer les arêtes projetées

Quelles paires de dépôts partagent une clé de famille exacte ? Donnez le nombre d'arêtes, les degrés et les composantes connexes de la projection. L'isolement de `ga` signifie-t-il que son serveur MCP est en panne ?

> **Réponse :** Seuls `ix` et `tars` partagent `grammar` ; la projection possède donc une arête. Ses degrés sont `ix: 1`, `tars: 1`, `ga: 0` ; ses composantes sont `{ix, tars}` et `{ga}`. Le degré projeté nul de `ga` indique seulement que ses cinq **étiquettes** de familles ne correspondent exactement à aucune autre dans ce registre. Il ne dit rien de la disponibilité du serveur ni de l'existence d'un contrat distinct reliant GA à un autre dépôt.

## 3. Une coupure de graphe n'est pas un rapport d'incident

Supposons qu'un analyste retire le **nœud de famille `grammar` de ce modèle** pour voir quelle étiquette porte la connexion projetée. Le graphe initial à deux types possède alors 34 nœuds de familles et 34 arêtes d'incidence : supprimer la famille partagée supprime ses deux arêtes vers les dépôts. Les degrés des dépôts deviennent `ix: 26`, `tars: 3` et `ga: 5`. La projection sur les dépôts n'a plus d'arêtes et comporte trois nœuds de dépôts isolés. C'est un petit exemple de point d'articulation : selon la règle choisie, le seul mot partagé du catalogue constitue l'unique chemin en deux étapes entre `ix` et `tars`.

C'est un résultat de sensibilité concernant une **taxonomie statique**. Il ne simule pas l'arrêt d'un serveur MCP et ne prouve pas qu'un agent perd une capacité grammaticale fonctionnelle. Retirer une étiquette d'un document JSON peut correspondre à un renommage, à un nettoyage du catalogue ou à une suppression réelle ; le graphe seul ne permet pas de trancher. Pour étudier la résilience opérationnelle, définissez les nœuds comme des services ou des appels réels, recueillez des arêtes de dépendance observées et testez le mode de défaillance à partir de ces pièces justificatives.

### Exercice pratique 3 : retirer une famille

Après suppression du nœud de famille `grammar`, calculez les nombres de nœuds et d'arêtes du graphe à deux types et le nombre de composantes de la projection sur les dépôts. Quelle conclusion opérationnelle n'est pas étayée ?

> **Réponse :** Le graphe à deux types contient `3 + 34 = 37` nœuds et `36 - 2 = 34` arêtes d'incidence. La projection sur les dépôts possède zéro arête et trois composantes, une par dépôt. Cela ne montre **pas** qu'un service de grammaire actif est tombé en panne ou que le travail s'est arrêté ; seul un nœud de nom de famille déclaré a été retiré du graphe analytique.

## 4. Changer la règle d'arête change l'affirmation

La [note figée sur les contrats entre dépôts](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/docs/architecture/cross-repo-contracts.md) décrit un graphe *différent*. Pour son point d'intégration BAML, Demerzel possède [`baml_src/schema.baml`](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/baml_src/schema.baml) et nomme `ix`, `ga` et `hari` comme consommateurs prévus. Si la question est « Qui devrait réagir à un changement de schéma BAML ? », représentez les arêtes orientées **producteur déclaré → consommateur prévu** : `Demerzel → ix`, `Demerzel → ga` et `Demerzel → hari`. Ce graphe possède quatre nœuds de dépôts nommés et trois arêtes déclarées. Il ne découle pas des étiquettes `tools` communes. `hari` et Demerzel sont absents de la projection à trois dépôts du registre, car cette projection utilise une autre entrée et une autre règle de nœuds.

La note contractuelle qualifie explicitement la génération côté consommateurs à partir de ce contrat BAML de **non livrée** à la date du document figé : aucun consommateur ne génère encore à partir de celui-ci. Elle prévient aussi que ses déclarations de disponibilité vieillissent. Les trois flèches sont donc des **arêtes de coordination prévues**, et non trois intégrations fonctionnelles observées. Un diagramme de projet utile distingue les arêtes déclarées et observées par les styles de trait, les dates et les pièces justificatives ; il ne transforme pas silencieusement une flèche de conception en appel d'exécution. De même, l'absence de flèche BAML vers `tars` ne prouve pas l'absence de toute autre relation avec TARS : ce paragraphe traite d'un seul point d'intégration nommé.

### Exercice pratique 4 : comparer deux graphes

Dessinez le graphe BAML du producteur vers les consommateurs nommés dans la note contractuelle. Pourquoi serait-il incorrect d'ajouter ses trois flèches aux 36 arêtes entre dépôts et familles et d'appeler cette somme un réseau unique ? Pour laquelle de ces flèches la note figée fournit-elle une preuve confirmée de génération active ?

> **Réponse :** Le graphe BAML déclaré comporte `Demerzel → ix`, `Demerzel → ga` et `Demerzel → hari` : quatre nœuds de dépôts et trois arêtes orientées prévues. Les 36 arêtes du catalogue relient des nœuds de dépôts à des nœuds de noms de familles et constituent des déclarations non orientées ; additionner des arêtes de nature différente produit un nombre sans signification stable. La note figée indique que la génération côté consommateurs n'est pas livrée ; elle ne confirme **aucune** flèche de génération active côté consommateur.

## 5. Transformer le graphe en question de routage délimitée

Le registre répertorie `ga_chord` dans la famille `music-theory` de GA et `tars_grammar_weight` dans la famille `grammar` de TARS. Un coordinateur pourrait *proposer* une tâche en deux étapes : demander à GA des données d'accords, puis demander à TARS de pondérer une grammaire à partir d'une entrée définie explicitement. Le catalogue identifie des outils candidats ; il ne précise pas si leurs sorties et leurs entrées sont compatibles. Avant de considérer le chemin comme exécutable, consignez les versions et schémas exacts des outils, la transformation entre leurs données, l'autorisation, la gestion des erreurs et une invocation de test réussie à une heure donnée. Si un élément manque, qualifiez le lien de proposé ou d'inconnu. Un diagramme qui montre cette incertitude est plus utile qu'un chemin visuellement complet mais non vérifié.

### Exercice pratique 5 : rendre une affirmation de routage réfutable

Un plan indique : « GA et TARS sont déconnectés parce que la projection du registre n'a pas d'arête ; par conséquent, `ga_chord` ne peut pas alimenter `tars_grammar_weight`. » Reformulez cette affirmation pour la rendre testable. Quel résultat établirait seulement le chemin précis, plutôt qu'une affirmation générale sur tout l'écosystème ?

> **Réponse :** « Le registre figé ne contient aucune arête d'**étiquette de famille commune** entre GA et TARS. La possibilité de transformer la sortie de `ga_chord` en entrée valide de `tars_grammar_weight` reste inconnue tant que leurs schémas actuels et un appel de test autorisé n'ont pas été vérifiés. » Une correspondance versionnée entre entrées et sorties, accompagnée d'une invocation réussie et consignée, étayerait ce chemin précis dans les conditions testées. Elle ne prouverait ni toutes les intégrations GA/TARS ni une disponibilité permanente des services.

## Points à retenir

- Nommez les types de nœuds et la règle d'arête avant de calculer degrés, chemins ou composantes.
- La projection par étiquette exacte est reproductible, mais perd les détails des outils et ne dit rien à elle seule de leur connexion à l'exécution.
- Une famille du catalogue, un point d'intégration contractuel prévu et un appel observé exigent des couches de graphe et des preuves distinctes.
- Retirer un nœud du catalogue montre la sensibilité du modèle, pas une panne réelle.
- Trois nœuds de dépôts ne peuvent pas établir le comportement en loi de puissance présenté dans NET-001.

## Preuves du projet et limites

- Commit Demerzel `5c4967454ddc740ed937c87719ca4d71a3522e4b` : [registre de capacités v1.1.0](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/schemas/capability-registry.json), [note sur les contrats entre dépôts](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/docs/architecture/cross-repo-contracts.md) et [contrat source BAML](https://github.com/GuitarAlchemist/Demerzel/blob/5c4967454ddc740ed937c87719ca4d71a3522e4b/baml_src/schema.baml). Les nombres de familles 27/4/5 et l'intersection des étiquettes communes ont été recalculés à partir de ce JSON figé avant la rédaction.
- Cette leçon traite les noms de familles comme des chaînes exactes. Elle ne mesure ni disponibilité réelle des outils MCP, ni compatibilité des schémas, ni trafic réel, ni latence, ni propagation des pannes. Les déclarations de non-livraison et de disponibilité de la note contractuelle sont historiques et doivent être vérifiées à nouveau avant toute décision opérationnelle.
- Lors du cycle source anglais antérieur, aucun essai d'apprenant, examen disciplinaire, révision linguistique par une personne maîtrisant la langue, sync/build Learn ou contrôle public anonyme n'avait été réalisé pour NET-002. Ce brouillon français attend encore l'approbation d'une personne maîtrisant le français ; sa traduction n'établit aucun de ces résultats.
