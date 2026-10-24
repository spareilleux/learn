---
module_id: phi-005-test-idempotence-beyond-replayed-values
department: philosophy
course: "Tester l'idempotence au-delà des valeurs renvoyées lors d'une répétition"
level: intermediate
prerequisites: ["phi-002-when-is-an-advisory-decision-justified", "net-007-separate-dag-readiness-from-admission"]
estimated_duration: "35 minutes"
produced_by: codex-project-pilot
version: "0.1.0"
---

# Tester l'idempotence au-delà des valeurs renvoyées lors d'une répétition

> **Portée du brouillon.** Réponses réelles d'outils IX dans un cadre limité, code public du cache et du moteur d'exécution à une révision précise et contre-exemples de transitions d'état conçus pour le cours. La revue technique humaine, la relecture par des personnes maîtrisant la langue, les essais avec des apprenants et la vérification du HTML du cours déployé restent à effectuer. Aucun stockage durable de déduplication, reprise après incident, exécuteur d'effets concurrents ni modification externe réelle n'ont été testés.

## La question du projet

Un agent répète un pipeline et voit le même résultat. Que permet de conclure cette observation ? La [définition de l'idempotence dans la RFC 9110](https://www.rfc-editor.org/rfc/rfc9110.html#section-9.2.2) porte sur l'effet voulu de la répétition d'une requête, sans exiger des réponses identiques octet par octet. Sa sémantique des méthodes HTTP ne s'applique pas automatiquement à des outils d'agents arbitraires. Nous utilisons cette distinction pour examiner les affirmations sur la répétition dans IX et de petits contre-exemples mathématiques.

Le [moteur d'exécution public d'IX](https://github.com/GuitarAlchemist/ix/blob/456df065ee837e33b5bbe22a4df0616a4fcb76e5/crates/ix-agent/src/tools.rs#L408-L450), fixé à la révision `456df065ee837e33b5bbe22a4df0616a4fcb76e5`, peut renvoyer des valeurs en cache lorsqu'un nom d'actif est fourni. Mettre un calcul en cache et dédupliquer un effet externe voulu relèvent de contrats différents. [PHI-002](phi-002-when-is-an-advisory-decision-justified.md) distinguait les preuves et l'autorité ; ce cours teste une affirmation particulière à l'aide de contre-exemples et de limites d'observation.

## 1. Énoncer la propriété testée

Le [modèle d'état conçu pour le cours](../../../../code/streeling/evidence/retry-admission-2026-10-22/effect-identity-model.json) compare deux opérations sur un état entier. Set7 remplace l'état par 7 ; l'incrémentation ajoute 1. Pour les états initiaux -2, 0 et 5, appliquer Set7 deux fois donne le même état final qu'une seule application. Incrémenter deux fois donne une unité de plus qu'incrémenter une fois.

Les deux opérations peuvent renvoyer l'étiquette de réponse « ok » après chaque appel. Des suites de réponses égales ne distinguent donc pas la transition d'état voulue idempotente de celle qui ne l'est pas. L'invariant doit nommer l'état ou l'effet comparé. Les journaux d'audit peuvent tout de même enregistrer chaque requête sans modifier l'idempotence de l'opération voulue ; n'élargissez pas silencieusement cette propriété à tous les effets accessoires.

### Exercice 1 : construire un contre-exemple

En partant de 0, donnez l'état après un puis deux appels à Set7, puis après une et deux incrémentations. Les deux renvoient « ok » à chaque fois. L'égalité des réponses établit-elle l'identité de l'effet voulu ?

> **Réponse:** Set7 donne 7 et 7 ; l'incrémentation donne 1 et 2. Des réponses « ok » identiques se produisent dans les deux cas ; leur seule égalité n'établit donc pas l'idempotence du changement d'état voulu.

## 2. Lire les preuves réelles de répétition à leur juste portée

Deux [appels réels au pipeline IX](../../../../code/streeling/evidence/retry-admission-2026-10-22/execution-tool-probes.json) exécutent les trois mêmes petites étapes statistiques. Leurs tables de résultats numériques concordent, avec des moyennes de 2, 5 et 15. Tous deux indiquent une liste vide de résultats servis depuis le cache et des clés de cache nulles. Le schéma exposé par l'outil n'offrait aucun champ de nom d'actif ; cet exercice ne l'a donc pas contourné pour demander une mise en cache. L'égalité des résultats ici n'est pas une preuve d'utilisation du cache.

L'ordre d'exécution indiqué des étapes sœurs change entre les appels. Les réponses complètes ne sont donc pas égales, même si les tables numériques le sont. Les durées indiquées sont de 0 ms ; le moteur examiné enregistre les millisecondes écoulées, donc un champ à zéro ne prouve pas un coût de calcul nul. La révision du service est inconnue et aucun des appels ne modifie une ressource métier externe.

### Exercice 2 : borner la conclusion sur la répétition

Que permet d'établir l'égalité des moyennes 2, 5 et 15 pour ces entrées ? La personne chargée de la revue peut-elle affirmer avoir mesuré une utilisation du cache, des réponses complètes identiques, un coût nul ou des effets externes dédupliqués ?

> **Réponse:** Les sorties numériques observées concordent pour ces petites entrées répétées. Les listes vides et les clés nulles ne fournissent aucune mesure d'utilisation du cache ; l'ordre d'exécution différent réfute l'identité des réponses complètes. Une durée indiquée de zéro milliseconde ne prouve pas un coût nul, et aucune déduplication d'effets externes n'a été testée.

## 3. Identifier la requête logique, et pas seulement ses arguments

L'[article de l'AWS Builders' Library sur les API idempotentes](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/) explique pourquoi des arguments égaux peuvent représenter une nouvelle tentative ou une opération distincte voulue. Le modèle séquentiel conçu pour le cours explicite cette distinction. Deux requêtes d'incrémentation portant la même clé logique job-A appliquent l'incrément voulu une seule fois selon une règle idéale de déduplication atomique, donnant l'état final 1. Attribuer une nouvelle clé à chaque tentative l'applique deux fois, donnant 2. Deux tâches logiques véritablement distinctes peuvent aussi produire intentionnellement 2 avec les mêmes arguments.

Cette règle mathématique suppose un enregistrement et une application de l'effet atomiques. Elle ne les implémente pas. Les tentatives concurrentes, les incidents entre la modification et l'enregistrement du jeton, la conservation des clés et les changements d'intention exigent un véritable contrat et des tests de défaillance avant de justifier une affirmation sur un service durable.

### Exercice 3 : distinguer les nouvelles tentatives du nouveau travail

En partant de 0, comparez les clés job-A/job-A à job-A-attempt-1/job-A-attempt-2 selon la règle idéale. Pourquoi ne faut-il pas fusionner automatiquement deux tâches distinctes ayant les mêmes arguments ?

> **Réponse:** La clé logique répétée applique une seule incrémentation et aboutit à 1 ; des clés de tentative distinctes en appliquent deux et aboutissent à 2. Deux tâches logiques distinctes peuvent viser deux effets malgré des arguments égaux. L'égalité des arguments ne suffit pas à identifier l'intention logique de l'appelant.

## 4. Examiner ce que la clé de cache lie réellement

Dans le moteur à la révision fixée, la clé de cache est dérivée du nom de l'actif, du nom de l'outil et des arguments résolus sérialisés. L'expression n'inclut pas directement l'identifiant de l'étape, la révision de l'implémentation de l'outil ou celle de l'état externe. Il s'agit d'une observation limitée du code, et non d'une affirmation selon laquelle tous les caches IX suivent la même politique ou tous ces champs sont toujours nécessaires.

Pour un calcul pur assorti d'un contrat d'entrée versionné adéquat, la réutilisation d'une valeur peut convenir. Pour une opération dont le sens dépend d'un état externe modifiable ou d'une implémentation modifiée, ces prémisses exigent un examen supplémentaire. Une clé correspondante ne prouve ni que la clé couvre toutes les entrées sémantiques ni qu'un effet externe antérieur a été validé durablement une seule fois. Aucune exécution servie depuis le cache ni aucun test de collision délibérée n'ont été réalisés ici.

### Exercice 4 : contester une affirmation d'identité insuffisante

L'implémentation d'un outil change tandis que le nom de l'actif, le nom de l'outil et les arguments résolus restent identiques. L'expression de clé examinée lie-t-elle directement la nouvelle révision de l'implémentation ? Une valeur renvoyée depuis le cache suffirait-elle à établir une déduplication correcte des effets externes ?

> **Réponse:** Non. Cette expression n'inclut pas directement la révision de l'implémentation. Une valeur en cache ne suffit pas non plus à établir la déduplication durable d'un effet externe. La personne chargée de la revue a besoin d'une politique justifiée des entrées sémantiques et de leur versionnement, ainsi que de preuves concernant le contrat des effets ; cette inspection du code ne fournit pas ces tests.

## 5. Préserver l'incertitude après une erreur

L'essai délibéré d'un outil absent signale un échec à l'étape b sans dossier final de résultats partiels. Dans le moteur à la révision fixée, une étape précédente peut être lancée avant qu'une erreur ultérieure ne fasse sortir de la boucle. Pour le service réel à la révision inconnue, l'erreur renvoyée seule ne fournit pas une trace complète des tentatives. L'absence d'un agrégat renvoyé ne doit pas devenir une preuve qu'aucun travail antérieur n'a eu lieu.

Pour tester une affirmation sur des effets répétés, déclarez à l'avance l'effet voulu, l'identité logique, les nouvelles tentatives admissibles et l'état observable. Comparez des requêtes uniques et répétées, en incluant un cas de réponse perdue et une reprise après une tentative interrompue. Vérifiez l'effet lui-même, et pas seulement les étiquettes de succès. Ce sont des tests proposés, et non des résultats obtenus ou un mécanisme de déduplication installé. [CYB-006](../../cybernetics/en/cyb-006-bound-retry-feedback-and-workload.md) montre pourquoi réessayer après un résultat inconnu peut aussi amplifier le travail actif.

### Exercice 5 : identifier la preuve manquante

Un pipeline renvoie une erreur à b. Une personne chargée de la revue conclut que l'étape précédente a n'a produit aucun effet et autorise une nouvelle tentative inconditionnelle du pipeline entier. Qu'est-ce qui n'est pas étayé ? Proposez une observation plus discriminante sans inventer une reprise réussie.

> **Réponse:** L'erreur seule ne prouve pas que a ne s'est jamais exécutée ou n'a produit aucun effet. Examinez les observations à l'échelle des tentatives et vérifiez l'effet voulu sous la même identité de requête logique, ou appuyez-vous sur un contrat d'idempotence validé séparément et couvrant cet effet. Cet essai n'a démontré ni reprise réussie ni sécurité d'une nouvelle tentative inconditionnelle.

## Travail de l'apprenant avec accès aux sources

Effectuez le [travail préparé](../../../../code/streeling/evidence/retry-admission-2026-10-22/learner-task.md) en distinguant l'égalité des valeurs renvoyées, l'égalité des effets, l'identité et les observations manquantes. Utilisez les contre-exemples fixés pour rejeter une affirmation trop large sur la répétition. Les décisions humaines et celles des apprenants restent à recueillir.
