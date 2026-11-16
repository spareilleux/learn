---
module_id: cs-005-agent-handoff-evidence-contract
department: computer-science
course: Transmettre le travail d’un agent sous forme de contrat de preuve
level: intermediate
prerequisites: ["cs-002-governing-agentic-loops"]
estimated_duration: "30 minutes"
produced_by: codex-project-pilot
research_cycle: computer-science-2026-10-11-005
version: "0.1.0"
---

# Transmettre le travail d’un agent sous forme de contrat de preuve

> **Périmètre du brouillon et des traductions.** Le texte technique ci-dessous est un brouillon daté. Les mentions historiques de traductions, d’intégration dans Learn ou de vérifications de publication encore à faire concernent cette étape antérieure ; ce [dossier de traduction](../../../../code/streeling/evidence/locale-completion-2026-10-22/README.md) recense les brouillons actuels et les contrôles effectués. Les essais en conditions réelles encore non réalisés le restent. Les revues humaines du contenu et de la langue, ainsi que l’essai avec un apprenant, restent à effectuer.

> **Département d'informatique** | Niveau intermédiaire | 30 minutes | Brouillon français ; révision du contenu, essai par un apprenant et révision linguistique humaine en attente

## Objectifs

Vous apprendrez à examiner une note de transmission GA, à déterminer ce qu'elle prouve réellement, à tester un scénario fixe pour l'agent destinataire et à rédiger une prochaine action vérifiable indépendamment. Le problème du projet est concret : un agent termine une modification GA et un autre doit décider s'il poursuit, examine ou s'arrête sans hériter d'une affirmation de réussite non étayée.

## 1. Examiner le pont avant de croire la note

Le [pont Antigravity de GA au commit `dc2e74c`](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/Scripts/antigravity-bridge.ps1) possède un mode `-Handoff`. Il écrit un fichier Markdown sous `state/handoffs/` avec `from`, `at`, `branch`, `head`, `working_tree_dirty_lines` et le message libre de l'appelant. Le script demande à Git la branche actuelle, le dernier commit **abrégé** et son sujet, ainsi que le nombre de lignes du statut court. Il n'exécute pas de tests et ne vérifie pas la véracité des affirmations du message. Il ne capture ni révision complète, ni liste des fichiers modifiés, ni empreinte d'artefact, ni permissions du prochain agent. Les [consignes du workspace GA au même commit](https://github.com/GuitarAlchemist/ga/blob/dc2e74cbd992a298f67efb928b5b3754615e1924/CLAUDE.md) demandent l'acteur, la branche, l'objectif, le périmètre d'écriture, les tests, les preuves et la prochaine demande dans une transmission. Ce sont des champs que le producteur et le destinataire doivent vérifier, pas des garanties fournies par le pont.

Le fichier est utile parce qu'il survit à un changement de contexte. C'est une **affirmation accompagnée de pointeurs**, pas une observation en direct. Le destinataire doit le rattacher à un checkout et une révision précis, puis suivre ses preuves. Un `head` abrégé et un compte de lignes modifiées sont des indices ; ils n'identifient pas le contenu non commité exact. Une note dans un répertoire de transmission ignoré par Git peut subsister après le déplacement de sa branche d'origine.

### Exercice pratique 1

À partir des sources figées du pont, nommez trois champs générés depuis Git et trois éléments qu'un destinataire doit encore obtenir indépendamment avant de traiter « tests réussis » comme un résultat vérifié.

> **Réponse :** Le script génère `branch`, le `head` abrégé et `working_tree_dirty_lines`. Il manque encore au destinataire le SHA complet du commit et le checkout actuel, la commande exacte de test avec un résultat lié à cette révision, ainsi que le véritable diff ou artefact avec son emplacement et son identité. Le message libre peut les nommer, mais le script ne les vérifie pas.

## 2. Garder le contrat assez petit pour être vérifié

Une transmission utile nomme **l'acteur**, **l'objectif**, **la branche et la révision complète**, **le périmètre d'écriture**, **les preuves de test**, **l'artefact de sortie** et **la prochaine action**. L'acteur indique au destinataire qui fait l'affirmation ; il ne confère pas d'autorité. La révision précise les sources commitées que l'affirmation décrit. S'il existe des modifications non commitées, consignez aussi leurs chemins et un diff ou patch enregistré. Le périmètre d'écriture nomme les fichiers que le prochain agent peut modifier et toute limite imposant un seul rédacteur. Une affirmation de test nomme la commande, son lieu d'exécution, le résultat et la révision ou l'état du worktree testé. « Non exécuté » est un statut valide ; « réussi » sans résultat consultable ne l'est pas.

L'artefact est l'objet à examiner : chemin, commit, PR, reçu ou journal de test, avec une identité telle qu'une empreinte lorsqu'un fichier peut être remplacé. La prochaine action est une instruction de portée limitée, telle que « examiner le diff et relancer ce test nommé, puis demander une révision » ; elle ne doit pas autoriser silencieusement une fusion ou une publication. Pour une transmission entre dépôts voisins, nommez le dépôt en plus du chemin. Le répertoire `state/handoffs/` de GA est un espace local de coordination ; un agent dans Demerzel ne peut pas en déduire l'autorisation d'y lire ou écrire.

Utilisez cette **fixture pédagogique fixe**, pas comme une affirmation sur une session GA actuelle :

```text
H1: note in ga/state/handoffs/example.md
from: agent
branch: codex/example-voicing
head: a1b2c3d fix: adjust voicing selection
working_tree_dirty_lines: 2
body: "Done. Tests passed. Continue the PR."

H2: receiver's independent probe of the same checkout
branch: codex/example-voicing
full HEAD: bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
git status --short: M Common/VoicingRule.cs; ?? state/results/voicing.json
test log: absent
claimed output receipt: absent
wrapper: running
```

Le HEAD abrégé `a1b2c3d` de H1 ne correspond pas au préfixe du HEAD complet `bbbb...` de H2 ; ce sont donc des révisions commitées différentes. La fixture ne dit pas quand H1 a été écrit par rapport à H2 ni si l'une des révisions est ancêtre de l'autre. N'inventez pas cet historique. Il faut vérifier la révision et l'artefact de la transmission avant de poursuivre le travail.

### Exercice pratique 2

Que peut conclure le destinataire du compte de lignes modifiées de `2` de H1 et du statut court de H2 ? Comparez les deux HEAD : H1 peut-il décrire la révision commitée actuelle de H2, et que reste-t-il d'inconnu ?

> **Réponse :** La note rapportait deux lignes de statut lors de sa création, tandis que la vérification montre maintenant un chemin modifié et un chemin non suivi. Les comptes et noms de chemins seuls ne montrent ni les octets ni si les deux mêmes modifications ont subsisté. Le `a1b2c3d` de H1 n'est pas le préfixe du HEAD `bbbb...` de H2 ; H1 et H2 identifient donc des révisions commitées différentes. Leur ascendance et leur chronologie restent inconnues. Examinez le diff actuel et l'artefact non suivi avant de décider de la portée restante des affirmations de H1.

### Exercice pratique 3

H1 dit « tests réussis ». Le destinataire ne trouve aucun journal de test. Rédigez le statut véridique le plus affirmatif possible et les preuves minimales nécessaires pour le renforcer.

> **Réponse :** Statut : **réussite des tests déclarée, non vérifiée**. Demandez la commande exacte, le résultat d'exécution et le checkout ou la révision, avec l'identité de l'état non commité utilisé, ou relancez le test dans le checkout examiné et enregistrez la sortie. Une nouvelle réussite sur H2 vérifierait H2 ; elle ne prouverait pas rétroactivement l'ancienne affirmation de H1.

## 3. Distinguer présence, progrès et achèvement

L'[observation wmux de CS-004](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/computer-science/cs-004/wmux-dogfood-observation.md) est un véritable exemple de portée limitée. Un fournisseur s'est exécuté et a quitté avec le code 0, mais les lectures du dépôt voisin et l'écriture du reçu ont été refusées. Le wrapper attentif au marqueur n'a trouvé ni le marqueur requis ni l'artefact. Le coordinateur a donc consigné qu'**aucune révision n'avait été achevée**. Un wrapper `running` indique l'état d'un processus à un instant donné. Un prompt livré indique un envoi. Même le code de sortie 0 dit seulement qu'un processus s'est terminé avec succès selon ses propres règles. Aucun de ces faits ne prouve que l'artefact demandé existe ou satisfait la tâche.

Le [relevé de nouvelle tentative ciblée](https://github.com/GuitarAlchemist/Demerzel/blob/17f82a4b4b913d7c64942a3d3ff670abf4e6f85c/state/streeling/fixtures/computer-science/cs-004/review-followup-20261004.md) décrit une observation plus solide : les lectures et l'écriture déclarées sont apparues dans le panneau, un fichier de reçu existait avec le marqueur exact et le wrapper l'a vérifié. Cela étaye une révision consultative de portée limitée à cet instant. Cela ne transforme toujours pas la révision en cours publié et ne prouve pas que toutes les futures exécutions d'agents pourront lire les dépôts voisins.

### Exercice pratique 4

Pour la première tentative CS-004, classez « prompt livré », « wrapper en cours d'exécution », « sortie fournisseur 0 » et « révision achevée ». Quels faits observés déterminent la dernière affirmation ?

> **Réponse :** Les trois premiers sont respectivement l'envoi, un état transitoire du processus et la terminaison du fournisseur. « Révision achevée » est faux pour cette tentative : deux lectures requises et l'écriture du reçu ont été refusées, et le wrapper n'a trouvé aucun marqueur d'achèvement ni artefact. Le destinataire devrait consigner la limite de capacité en échec et un contrôle préalable limité des permissions comme prochaine action.

## 4. Rédiger une transmission exploitable par le destinataire

Supposons qu'un agent GA ait modifié une règle de voicing sans exécuter de tests. Le destinataire peut utiliser la structure suivante. Ne remplacez les valeurs fictives que par des valeurs observées :

```text
actor: <agent identity and surface>
goal: <one user-visible behavior to verify>
repository / checkout: <repo and absolute worktree path>
branch / full HEAD: <branch and 40-character SHA>
uncommitted state: <status paths plus diff or patch identity>
write scope / owner: <exact paths the next actor may edit; current writer>
tests: NOT RUN; <specific command proposed for this checkout>
artifact: <diff, receipt, or output path and hash, or MISSING>
next action: <one bounded inspection or test, then report result>
```

Si un chemin source est inaccessible, indiquez **non évalué**. Si un reçu manque, indiquez **manquant**. Ne reconstituez pas les preuves manquantes à partir de l'historique du chat. Le destinataire devrait confirmer le checkout, résoudre le commit, examiner le diff et l'artefact, puis exécuter ou examiner le test nommé avant de poursuivre. C'est un contrat de preuve, car chaque champ dispose soit d'une vérification, soit d'un état inconnu explicite.

### Exercice pratique 5

Réécrivez le corps de H1 sous forme d'une transmission que le destinataire H2 peut exploiter sans affirmer une réussite non observée. Incluez les sept éléments du contrat et une prochaine action respectant le périmètre de preuve de H2.

> **Réponse :** « Acteur : agent (interface inconnue). Objectif : évaluer la modification de sélection de voicing. Dépôt/checkout : GA, chemin du checkout H2 à consigner. Branche/HEAD complet : `codex/example-voicing` à `bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb`, observé par H2 ; H1 identifie une autre révision commitée, d'ascendance et de chronologie inconnues. Périmètre d'écriture/responsable : non précisé ; suspendre les modifications jusqu'à confirmation du responsable et des chemins autorisés. État non commité : `Common/VoicingRule.cs` modifié et `state/results/voicing.json` non suivi ; examiner leur contenu. Tests : H1 annonce une réussite, mais aucun journal n'est présent, donc elle n'est pas vérifiée. Artefact : reçu annoncé absent ; le JSON non suivi actuel exige un examen et une identité. Prochaine action : résoudre le commit de H1 par rapport à H2, examiner le diff et le JSON, obtenir ou relancer le test exact dans H2 et rapporter les preuves avant de poursuivre la PR. » L'interface inconnue de l'acteur, le périmètre et le reçu manquant restent explicites.

## Sources et limites

Le pont et les consignes GA ci-dessus sont figés au commit GA `dc2e74cbd992a298f67efb928b5b3754615e1924` ; les observations CS-004 sont figées au [commit Demerzel `6bc584d`](https://github.com/GuitarAlchemist/Demerzel/blob/6bc584d7ca1cd9eb1b1481e1100eeeb74e983863/state/streeling/fixtures/computer-science/cs-004/wmux-dogfood-observation.md). H1 et H2 sont explicitement synthétiques et n'établissent aucun statut actuel de processus ou de dépôt. Le reçu local complet de la nouvelle tentative CS-004 se trouve hors de ce dépôt de cours ; cette leçon s'appuie donc sur son résumé vérifié, pas sur une relecture indépendante de ce reçu. Aucune nouvelle exécution d'agent, révision du contenu, expérimentation avec un apprenant, révision de localisation ou publication n'est revendiquée. [CS-002](cs-002-governing-agentic-loops.md) traite des bornes de boucle ; cette leçon traite de la transmission de preuves entre acteurs.
